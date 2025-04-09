# Deploying SecuriWatch on a Server

This guide provides instructions for deploying SecuriWatch on a production server, with security best practices.

## Prerequisites

- A Linux server with at least 4GB RAM, 2 CPUs, and 50GB storage (recommended minimum, adjust based on load)
- Docker and Docker Compose installed
- Internet access to pull Docker images
- SSH access to the server

## Step 1: Prepare the Server

1. Update your server:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. Install dependencies if not already installed:
   ```bash
   sudo apt install -y curl git openssl docker-compose-plugin
   # Or install docker-compose manually if needed
   ```

3. Increase virtual memory for Elasticsearch:
   ```bash
   sudo sysctl -w vm.max_map_count=262144
   echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
   ```

4. Configure firewall to allow only necessary ports:
   ```bash
   sudo ufw allow 22/tcp     # SSH
   sudo ufw allow 80/tcp     # HTTP (redirects to HTTPS)
   sudo ufw allow 443/tcp    # HTTPS (main dashboard)
   sudo ufw enable
   ```

## Step 2: Install SecuriWatch

Use the recommended installer script:

```bash
curl -sL https://raw.githubusercontent.com/christophernader/securiwatch/main/install.sh | sudo bash -s -- -d /opt/securiwatch
```

This will install SecuriWatch to `/opt/securiwatch`. Change the `-d` flag if you prefer a different directory.

## Step 3: Configure SecuriWatch for Production

Navigate to the installation directory (e.g., `/opt/securiwatch`):
```bash
cd /opt/securiwatch
```

1. Create and customize the environment file:
   ```bash
   # .env might have been created by the installer
   # If not, copy the example:
   # sudo cp .env.example .env
   sudo nano .env
   ```

2. Update the environment variables:
   - Set `HOST_ADDRESS` to your server's domain or IP
   - Configure email/webhook settings for alerts
   - **Resource Limits**: Uncomment and adjust the `*_CPU_LIMIT` and `*_MEM_LIMIT` variables based on your server's capacity. Start with the defaults if unsure.
   - Set strong passwords for `WAZUH_API_PASSWORD`

3. Generate strong SSL certificates:
   - **For production, use Let's Encrypt**:
     ```bash
     # Stop NGINX temporarily if running
     sudo docker-compose stop nginx
     
     # Install certbot
     sudo apt install -y certbot python3-certbot-nginx
     
     # Generate certificates (use --nginx plugin if NGINX is already set up for the domain)
     sudo certbot certonly --standalone -d your-domain.com --non-interactive --agree-tos -m your-email@example.com
     
     # Copy certificates to the right location
     sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem config/nginx/ssl/securiwatch.crt
     sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem config/nginx/ssl/securiwatch.key
     
     # Set correct permissions
     sudo chmod 600 config/nginx/ssl/securiwatch.key
     ```
   - Alternatively, use the included script for self-signed certs (not recommended for production):
     ```bash
     sudo ./generate-certs.sh
     ```

4. Generate strong credentials for the dashboard:
   ```bash
   # Replace 'admin' and 'your-secure-password' with your preferred credentials
   sudo echo "admin:$(openssl passwd -apr1 your-secure-password)" > config/nginx/.htpasswd
   sudo chmod 600 config/nginx/.htpasswd
   ```

## Step 4: Start SecuriWatch

1. Apply configuration changes and start services:
   ```bash
   # Ensure you are in the installation directory
   cd /opt/securiwatch 
   
   sudo docker-compose up -d
   ```

2. Verify all services are running:
   ```bash
   sudo docker-compose ps
   ```

3. Test access to the dashboard:
   - Open `https://your-domain.com` in a browser

## Step 5: Secure Your Deployment

1. **Configure Regular Backups**:
   - The Elasticsearch data is stored in the `elasticsearch-data` volume.
   - Configuration files are in the `/opt/securiwatch` directory.
   - Set up a backup strategy for these volumes and files. Example using a script:
   ```bash
   sudo nano backup.sh
   ```
   
   Content for backup.sh (adjust paths):
   ```bash
   #!/bin/bash
   BACKUP_DIR="/var/backups/securiwatch"
   DATE=$(date +%Y-%m-%d)
   SOURCE_DIR="/opt/securiwatch"
   
   # Create backup directory
   mkdir -p "$BACKUP_DIR/$DATE"
   
   # Backup configurations
   rsync -a --delete "$SOURCE_DIR/config/" "$BACKUP_DIR/$DATE/config/"
   rsync -a --delete "$SOURCE_DIR/.env" "$BACKUP_DIR/$DATE/.env"
   
   # Backup Docker volumes
   # Stop containers that write to volumes for consistency
   docker-compose -f "$SOURCE_DIR/docker-compose.yml" stop elasticsearch wazuh-manager filebeat
   
   rsync -a --delete "/var/lib/docker/volumes/elasticsearch-data/_data/" "$BACKUP_DIR/$DATE/elasticsearch-data/"
   rsync -a --delete "/var/lib/docker/volumes/wazuh-manager-config/_data/" "$BACKUP_DIR/$DATE/wazuh-manager-config/"
   rsync -a --delete "/var/lib/docker/volumes/wazuh-manager-data/_data/" "$BACKUP_DIR/$DATE/wazuh-manager-data/"
   rsync -a --delete "/var/lib/docker/volumes/filebeat-data/_data/" "$BACKUP_DIR/$DATE/filebeat-data/"
   
   # Restart containers
   docker-compose -f "$SOURCE_DIR/docker-compose.yml" start elasticsearch wazuh-manager filebeat
   
   # Compress backup
   tar -czf "$BACKUP_DIR/securiwatch-backup-$DATE.tar.gz" -C "$BACKUP_DIR" "$DATE"
   
   # Remove temp files
   rm -rf "$BACKUP_DIR/$DATE"
   
   # Keep only last 7 backups
   ls -t "$BACKUP_DIR"/securiwatch-backup-*.tar.gz | tail -n +8 | xargs -r rm
   ```

2. Make the backup script executable and schedule it:
   ```bash
   sudo chmod +x backup.sh
   # Add to crontab for daily execution at 2 AM
   (crontab -l ; echo "0 2 * * * /opt/securiwatch/backup.sh") | sudo crontab -
   ```

3. **Set up Log Rotation** for Docker container logs:
   ```bash
   sudo nano /etc/docker/daemon.json
   ```
   
   Add or modify the following configuration:
   ```json
   {
     "log-driver": "json-file",
     "log-opts": {
       "max-size": "10m",
       "max-file": "3"
     }
   }
   ```
   Restart Docker: `sudo systemctl restart docker`

4. **Set up Health Monitoring**:
   ```bash
   # Make the health check script executable
   sudo chmod +x scripts/healthcheck.sh
   
   # Add to crontab to run every 15 minutes
   (crontab -l ; echo "*/15 * * * * cd /opt/securiwatch && ./scripts/healthcheck.sh > /opt/securiwatch/healthcheck.log 2>&1") | sudo crontab -
   ```

## Step 6: Additional Security Measures

1. **Set up fail2ban** to protect against brute force attacks on the dashboard:
   ```bash
   sudo apt install -y fail2ban
   
   # Create a custom filter
   sudo nano /etc/fail2ban/filter.d/securiwatch-auth.conf
   ```
   
   Add the following content:
   ```
   [Definition]
   failregex = ^<HOST> -.*"(GET|POST|PUT).*" 401
   ignoreregex =
   ```
   
   Configure the jail:
   ```bash
   sudo nano /etc/fail2ban/jail.d/securiwatch.conf
   ```
   
   Add the following content:
   ```
   [securiwatch-auth]
   enabled = true
   port = http,https
   filter = securiwatch-auth
   logpath = /var/lib/docker/containers/*/*-json.log # Adjust if using a different log driver
   maxretry = 5
   bantime = 3600
   ```
   
   Restart fail2ban:
   ```bash
   sudo systemctl restart fail2ban
   ```
   *Note: The `logpath` for fail2ban might need adjustment depending on your Docker logging setup.* 

2. **Set up Server Monitoring** (optional):
   - Consider using tools like Prometheus + Node Exporter + Grafana, or Datadog, Netdata, etc.
   - Example setup for Node Exporter (see previous versions of this guide or official docs).

## Troubleshooting

### Service fails to start

- Check logs: `sudo docker-compose logs [service_name]`
- Verify environment variables in `.env` file
- Ensure sufficient resources (RAM, CPU, disk) - check `sudo docker stats`
- Check healthcheck status: `sudo docker-compose ps`

### Cannot access dashboard

- Check NGINX logs: `sudo docker-compose logs nginx`
- Verify SSL certificates are correctly placed and have correct permissions
- Check firewall rules: `sudo ufw status`

### Alerts not being processed

- Check alerter logs: `sudo docker-compose logs alerter`
- Verify SMTP or webhook configuration in `.env` and `alerter/config.yml`

## Security Update Policy

Regularly update your SecuriWatch installation:

1. Navigate to the installation directory:
   ```bash
   cd /opt/securiwatch
   ```

2. Run the update script:
   ```bash
   sudo ./update.sh
   ```

3. Monitor security advisories for underlying components:
   - Elasticsearch: https://www.elastic.co/security/
   - Wazuh: https://wazuh.com/blog/
   - NGINX: https://nginx.org/en/security_advisories.html 