# SecuriWatch - Docker Security Monitoring

A containerized security monitoring solution that provides easy-to-read logs and alerts for security breaches.

## Instant Installation

Just copy and paste this command to install SecuriWatch:

```bash
curl -sL https://raw.githubusercontent.com/christophernader/securiwatch/main/install.sh | bash
```

That's it! Access the dashboard at https://localhost

**Default credentials:** `admin` / `securiwatch`

## One-Liner Installation

If you prefer to download and extract manually:

```bash
# Create directory and install in one command
mkdir securiwatch && cd securiwatch && curl -sL https://github.com/christophernader/securiwatch/archive/refs/heads/main.tar.gz | tar -xzf - --strip-components 1 && ./setup.sh
```

## Standard Installation

```bash
# Clone the repository
git clone https://github.com/christophernader/securiwatch.git
cd securiwatch

# Start the monitoring stack with default configuration
./setup.sh

# OR to just start the services:
docker-compose up -d
```

Access the dashboard at https://localhost

**Default credentials:** `admin` / `securiwatch`

## Features

- Real-time monitoring of system logs and security events
- Web-based dashboard for visualizing security incidents
- Alerting for suspicious activities
- Support for various log sources
- Easy deployment via Docker

## Configuration Options

The default configuration works out of the box, but you can customize:

1. **Environment Variables**: Edit `.env` file:
   ```bash
   cp .env.example .env
   nano .env
   ```

2. **Log Sources**: See [Adding Log Sources](docs/adding-log-sources.md)

3. **Alert Notifications**: Configure email or webhook alerts:
   ```
   # Edit alerter configuration
   nano alerter/config.yml
   ```

## System Requirements

- Docker and Docker Compose 
- 2+ CPU cores
- 4GB+ RAM
- 20GB+ storage space

## Server Deployment

For production deployment on a remote server, see [Server Deployment Guide](docs/server-deployment.md).

## Creating Your Own Git Repository

If you want to maintain your own version of SecuriWatch:

```bash
# Create a new repository on GitHub/GitLab first, then:
git clone https://github.com/christophernader/securiwatch.git
cd securiwatch

# Remove the existing git history
rm -rf .git

# Initialize a new git repository
git init
git add .
git commit -m "Initial commit"

# Add your remote repository
git remote add origin https://github.com/yourusername/your-new-repo.git
git push -u origin main
```

## Updating

To update SecuriWatch to the latest version:

```bash
./update.sh
```

## Documentation

For detailed documentation, see the [docs](docs/) directory.

## License

[MIT License](LICENSE) 