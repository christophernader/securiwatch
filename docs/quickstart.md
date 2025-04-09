# SecuriWatch Quickstart Guide

This quickstart guide will help you get SecuriWatch up and running in minutes with minimal configuration.

## Instant Setup (Copy & Paste)

The absolute quickest way to get started:

```bash
curl -sL https://raw.githubusercontent.com/christophernader/securiwatch/main/install.sh | bash
```

This will download the installer script and run it automatically, handling all the setup for you.

## Direct Download Setup

If you prefer to download and extract manually:

```bash
mkdir securiwatch && cd securiwatch && curl -sL https://github.com/christophernader/securiwatch/archive/refs/heads/main.tar.gz | tar -xzf - --strip-components 1 && ./setup.sh
```

This single command will:
1. Create a directory called `securiwatch`
2. Download the latest release
3. Extract all files
4. Run the setup script automatically

## Standard Setup

1. **Prerequisites**:
   - Docker and Docker Compose installed
   - Git installed (optional, for cloning the repository)

2. **Installation**:

   ```bash
   # Clone the repository (or download the ZIP file)
   git clone https://github.com/christophernader/securiwatch.git
   cd securiwatch
   
   # Run the setup script (recommended for first-time users)
   ./setup.sh
   
   # OR simply start with docker-compose
   docker-compose up -d
   ```

3. **Access the Dashboard**:
   - Open https://localhost in your browser
   - Default credentials: `admin` / `securiwatch`

You're done! SecuriWatch is now running with default settings.

## What's Next?

- **Add More Log Sources**: See [Adding Log Sources](adding-log-sources.md)
- **Configure Alerts**: Edit `.env` and `alerter/config.yml` to set up email or webhook notifications
- **Customize Dashboards**: Access Kibana at https://localhost/kibana/

## Common Commands

```bash
# Stop all services
docker-compose down

# View logs for all services
docker-compose logs -f

# View logs for a specific service
docker-compose logs -f [service_name]

# Check service status
docker-compose ps

# Run the health check script
./scripts/healthcheck.sh
```

## Default Ports

| Service       | Port  | Description                   |
|---------------|-------|-------------------------------|
| HTTPS         | 443   | Main SecuriWatch dashboard    |
| HTTP          | 80    | Redirects to HTTPS            |
| Elasticsearch | 9200  | Elasticsearch API (internal)  |
| Kibana        | 5601  | Kibana UI (accessed via NGINX)|
| Wazuh API     | 55000 | Wazuh Manager API (internal)  |
| Logstash      | 5044  | Filebeat input                |
| Logstash      | 5140  | Syslog input (UDP)            |
| Logstash      | 5000  | TCP log input                 |

## Server Deployment

Ready to deploy to a production server? See [Server Deployment Guide](server-deployment.md). 