# SecuriWatch Quickstart Guide

Get SecuriWatch running in minutes on your local machine or home server.

## Instant Setup (Copy & Paste)

Installs to `$HOME/securiwatch` and uses port `8443` by default.

```bash
curl -sL https://raw.githubusercontent.com/christophernader/securiwatch/main/install.sh | bash
```

This downloads and runs the installer script, handling all setup.

## Standard Setup

1. **Prerequisites**:
   - Docker & Docker Compose (V1 or V2)
   - Git

2. **Installation**:
   ```bash
   git clone https://github.com/christophernader/securiwatch.git
   cd securiwatch
   ./setup.sh
   ```

3. **Access Dashboard**:
   - Open `https://localhost:8443` (or `https://YOUR_SERVER_IP:8443`)
   - Default login: `admin` / `securiwatch`

## What's Next?

- **Change Ports/Resources**: Edit `.env`
- **Add Log Sources**: See [Adding Log Sources](adding-log-sources.md)
- **Configure Alerts**: Edit `.env` and `alerter/config.yml`
- **Customize Dashboards**: Access Kibana at `https://localhost:8443/kibana/`

## Common Commands

*Run these from the `~/securiwatch` directory.*

```bash
# Use 'docker compose' (V2) or 'docker-compose' (V1)
COMPOSE_CMD="docker compose"
# Check if V2 exists, fallback to V1
if ! command -v docker compose &> /dev/null; then COMPOSE_CMD="docker-compose"; fi

# Stop all services
sudo $COMPOSE_CMD down

# Start all services
sudo $COMPOSE_CMD up -d

# View logs for all services
sudo $COMPOSE_CMD logs -f

# View logs for a specific service
sudo $COMPOSE_CMD logs -f [service_name]

# Check service status
sudo $COMPOSE_CMD ps

# Run the health check script
./scripts/healthcheck.sh
```

## Default Ports Used

| Host Port | Container Port | Service       | Description                |
|-----------|----------------|---------------|----------------------------|
| 8443      | 443            | NGINX         | Main dashboard (HTTPS)     |
| 8080      | 80             | NGINX         | Redirects to HTTPS         |
| 5044      | 5044           | Logstash      | Filebeat input             |
| 5140/udp  | 5140/udp       | Logstash      | Syslog input               |
| 5000      | 5000           | Logstash      | TCP log input              |
| 1514/udp  | 1514/udp       | Wazuh Manager | Agent Syslog               |
| 1515      | 1515           | Wazuh Manager | Agent Enrollment           |
| 55000     | 55000          | Wazuh Manager | Wazuh API (Internal Only)  |

## Server Deployment

Ready to deploy to a production server? See [Server Deployment Guide](server-deployment.md). 