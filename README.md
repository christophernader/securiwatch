# SecuriWatch - Docker Security Monitoring

A containerized security monitoring solution that provides easy-to-read logs and alerts for security breaches.

## Instant Installation

Installs to `$HOME/securiwatch` and uses port `8443` by default.

```bash
curl -sL https://raw.githubusercontent.com/christophernader/securiwatch/main/install.sh | bash
```

That's it! Access the dashboard at https://localhost:8443

**Default credentials:** `admin` / `securiwatch`

## One-Liner Installation

If you prefer to download and extract manually:

```bash
# Create directory and install in one command
mkdir securiwatch && cd securiwatch && curl -sL https://github.com/christophernader/securiwatch/archive/refs/heads/main.tar.gz | tar -xzf - --strip-components 1 && ./setup.sh
```

## Standard Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/christophernader/securiwatch.git
   cd securiwatch
   ```
2. Run setup:
   ```bash
   ./setup.sh
   ```
3. Access the dashboard at https://localhost:8443

## Features

- Real-time monitoring of system logs and security events
- Web-based dashboard for visualizing security incidents
- Alerting for suspicious activities
- Support for various log sources
- Easy deployment via Docker
- Data stored locally in `./data` subdirectories (uses bind mounts)

## Configuration Options

The default configuration works out of the box, but you can customize:

1. **Ports & Resources**: Edit `.env` file:
   ```bash
   # If .env doesn't exist after setup
   # cp .env.example .env 
   nano .env
   ```
   - Change `HTTP_PORT`, `HTTPS_PORT`
   - Adjust resource limits (`*_CPU_LIMIT`, `*_MEM_LIMIT`)

2. **Log Sources**: See [Adding Log Sources](docs/adding-log-sources.md)

3. **Alert Notifications**: Configure email or webhook alerts:
   ```bash
   # Edit alerter configuration
   nano alerter/config.yml
   # Also uncomment and set SMTP/Webhook vars in .env
   ```

## System Requirements

- Docker and Docker Compose (V1 or V2)
- Linux Host (tested on Debian/Ubuntu)
- 2+ CPU cores
- 4GB+ RAM
- 20GB+ storage space (available where you install SecuriWatch, e.g., `/home`)

## Server Deployment

For production deployment on a remote server, see [Server Deployment Guide](docs/server-deployment.md).

## Creating Your Own Git Repository

If you want to maintain your own version of SecuriWatch:

```bash
# Clone this repository
git clone https://github.com/christophernader/securiwatch.git
cd securiwatch

# Remove the existing git history
rm -rf .git

# Initialize a new git repository
git init
git add .
git commit -m "Initial commit"

# Add your remote repository
git remote add origin https://github.com/YOUR-USERNAME/your-new-repo.git
git push -u origin main
```

## Updating

To update SecuriWatch to the latest version:

```bash
# Ensure you are in the securiwatch directory
cd ~/securiwatch
./update.sh
```

## Documentation

For detailed documentation, see the [docs](docs/) directory.

## License

[MIT License](LICENSE) 