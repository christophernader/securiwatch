# Deploying SecuriWatch on a Server

This guide provides instructions for deploying SecuriWatch on a production server, with security best practices.

## Prerequisites

- A Linux server with at least 4GB RAM, 2 CPUs, and 50GB storage
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
   sudo apt install -y curl git openssl
   ```

3. Increase virtual memory for Elasticsearch:
   ```bash
   sudo sysctl -w vm.max_map_count=262144
   echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
   ```

4. Configure firewall to allow only necessary ports:
   ```bash
   sudo ufw allow 22/tcp     # SSH
   sudo ufw allow 80/tcp     # HTTP
   sudo ufw allow 443/tcp    # HTTPS
   sudo ufw enable
   ```

## Step 2: Transfer SecuriWatch to the Server

1. Clone the repository or transfer files using SCP:
   ```bash
   git clone [your-repo-url] securiwatch
   cd securiwatch
   ```
   
   Or using SCP:
   ```bash
   scp -r /path/to/securiwatch user@your-server:/home/user/
   ```

## Step 3: Configure SecuriWatch for Production

1. Create a secure environment file:
   ```bash
   cp .env.example .env
   nano .env
   ```

2. Update the environment variables:
   - Set `HOST_ADDRESS` to your server's domain or IP
   - Configure email settings for alerts
   - Set strong passwords for all services

3. Update docker-compose.yml for production:
   - Remove port exposures for internal services:
     - Remove `9200:9200` for Elasticsearch
     - Consider restricting other ports as needed

4. Generate strong SSL certificates:
   - For testing, use the included script:
     ```bash
     ./generate-certs.sh
     ```
   - For production, use Let's Encrypt:
     ```bash
     # Install certbot
     sudo apt install -y certbot
     
     # Generate certificates
     sudo certbot certonly --standalone -d your-domain.com
     
     # Copy certificates to the right location
     sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem config/nginx/ssl/securiwatch.crt
     sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem config/nginx/ssl/securiwatch.key
     ```

5. Generate strong credentials for the dashboard:
   ```bash
   # Replace 'admin' and 'your-secure-password' with your preferred credentials
   echo "admin:$(openssl passwd -apr1 your-secure-password)" > config/nginx/.htpasswd
   ```

## Step 4: Start SecuriWatch

1. Run the setup script:
   ```bash
   ./setup.sh
   ```

2. Verify all services are running:
   ```bash
   docker-compose ps
   ```

3. Test access to the dashboard:
   - Open `https://your-domain.com` in a browser

## Step 5: Secure Your Deployment

1. Configure regular backups:
   ```bash
   # Create a backup script
   nano backup.sh
   ```
   
   Content for backup.sh:
   ```bash
   #!/bin/bash
   BACKUP_DIR="/path/to/backups"
   DATE=$(date +%Y-%m-%d)
   
   # Create backup directory
   mkdir -p "$BACKUP_DIR/$DATE"
   
   # Backup Elasticsearch indices
   docker-compose exec -T elasticsearch elasticsearch-dump \
     --input=http://localhost:9200/securiwatch-* \
     --output="$BACKUP_DIR/$DATE/securiwatch-indices.json" \
     --type=data
   
   # Backup configurations
   cp -r config "$BACKUP_DIR/$DATE/"
   
   # Compress backup
   tar -czf "$BACKUP_DIR/securiwatch-backup-$DATE.tar.gz" "$BACKUP_DIR/$DATE"
   
   # Remove temp files
   rm -rf "$BACKUP_DIR/$DATE"
   
   # Keep only last 7 backups
   ls -t "$BACKUP_DIR"/securiwatch-backup-*.tar.gz | tail -n +8 | xargs -r rm
   ```

2. Make the backup script executable and schedule it:
   ```bash
   chmod +x backup.sh
   
   # Add to crontab for daily execution at 2 AM
   (crontab -l ; echo "0 2 * * * /home/user/securiwatch/backup.sh") | crontab -
   ```

3. Set up log rotation:
   ```bash
   sudo nano /etc/logrotate.d/docker
   ```
   
   Add the following configuration:
   ```
   /var/lib/docker/containers/*/*.log {
       rotate 7
       daily
       compress
       missingok
       delaycompress
       copytruncate
   }
   ```

4. Set up health monitoring:
   ```bash
   # Make the health check script executable
   chmod +x scripts/healthcheck.sh
   
   # Add to crontab to run every 15 minutes
   (crontab -l ; echo "*/15 * * * * /home/user/securiwatch/scripts/healthcheck.sh > /home/user/securiwatch/healthcheck.log 2>&1") | crontab -
   ```

## Step 6: Additional Security Measures

1. Set up fail2ban to protect against brute force attacks:
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
   logpath = /var/log/nginx/access.log
   maxretry = 5
   bantime = 3600
   ```
   
   Restart fail2ban:
   ```bash
   sudo systemctl restart fail2ban
   ```

2. Set up server monitoring (optional):
   ```bash
   # Install node_exporter for Prometheus
   curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
   tar -xvf node_exporter-1.3.1.linux-amd64.tar.gz
   sudo mv node_exporter-1.3.1.linux-amd64/node_exporter /usr/local/bin/
   
   # Create systemd service
   sudo nano /etc/systemd/system/node_exporter.service
   ```
   
   Add the following content:
   ```
   [Unit]
   Description=Node Exporter
   After=network.target
   
   [Service]
   User=node_exporter
   Group=node_exporter
   Type=simple
   ExecStart=/usr/local/bin/node_exporter
   
   [Install]
   WantedBy=multi-user.target
   ```
   
   Start the service:
   ```bash
   sudo useradd -rs /bin/false node_exporter
   sudo systemctl daemon-reload
   sudo systemctl start node_exporter
   sudo systemctl enable node_exporter
   ```

## Troubleshooting

### Service fails to start

- Check logs: `docker-compose logs [service_name]`
- Verify environment variables in `.env` file
- Ensure sufficient resources (RAM, CPU, disk)

### Cannot access dashboard

- Check NGINX logs: `docker-compose logs nginx`
- Verify SSL certificates are correctly placed
- Check firewall rules: `sudo ufw status`

### Alerts not being processed

- Check alerter logs: `docker-compose logs alerter`
- Verify SMTP or webhook configuration in `.env`

## Security Update Policy

Regularly update your SecuriWatch installation:

1. Pull the latest code:
   ```bash
   git pull
   ```

2. Update Docker images:
   ```bash
   docker-compose pull
   ```

3. Restart services:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

4. Monitor security advisories for underlying components:
   - Elasticsearch: https://www.elastic.co/security/
   - Wazuh: https://wazuh.com/blog/
   - NGINX: https://nginx.org/en/security_advisories.html 