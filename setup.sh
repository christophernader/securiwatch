#!/bin/bash

# SecuriWatch setup script

# Function to check if sudo is needed and available
check_sudo() {
    # Check if we are already root
    if [ "$(id -u)" -eq 0 ]; then
        return 0 # No sudo needed
    fi
    # Check if sudo exists
    if command -v sudo &> /dev/null; then
        # Check if user can run sudo without password or prompt if needed
        if sudo -n true 2>/dev/null; then
            return 0 # Sudo available without password
        else
            echo -e "${YELLOW}Requesting sudo permissions for Docker operations...${NC}"
            if sudo true; then
                return 0 # Sudo granted
            else
                echo -e "${RED}Error: sudo permissions not granted.${NC}"
                return 1 # Sudo failed
            fi
        fi
    else
        echo -e "${RED}Error: sudo command not found. Please run this script as root or install sudo.${NC}"
        return 1 # Sudo not found
    fi
}

# Function to run command with sudo if needed
run_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

# Set color variables
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}     SecuriWatch Setup Assistant     ${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check docker daemon is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}Error: Docker daemon is not running. Please start Docker first.${NC}"
    exit 1
fi

# Check Docker Compose V2 or V1
DOCKER_COMPOSE_CMD=""
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
     echo -e "${RED}Error: Docker Compose (V1 or V2) is not installed. Please install Docker Compose first.${NC}"
     exit 1
fi
echo -e "${GREEN}Using Docker Compose command: $DOCKER_COMPOSE_CMD${NC}"

# Request sudo permissions early if needed for Docker
if ! check_sudo; then
    exit 1
fi

# Create required data directories within the current path
echo -e "${GREEN}Creating local data directories...${NC}"
mkdir -p ./data/elasticsearch
mkdir -p ./data/wazuh-manager-config
mkdir -p ./data/wazuh-manager-data
mkdir -p ./data/filebeat

# Create environment file if it doesn't exist
echo -e "${GREEN}Checking environment file...${NC}"
if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${GREEN}Created .env file with default settings.${NC}"
    echo -e "${BLUE}TIP: You can customize settings in the .env file later if needed.${NC}"
else
    echo -e "${GREEN}.env file already exists. Using existing configuration.${NC}"
fi

# Generate SSL certificates automatically
echo -e "${GREEN}Generating SSL certificates...${NC}"
./generate-certs.sh

# Make sure docker volumes (now bind mounts) don't need creating, but check permissions
echo -e "${GREEN}Checking directory permissions for Docker...${NC}"
# Attempt to set ownership to current user for data dirs - might fail, Docker handles some itself
chown -R "$(id -u):$(id -g)" ./data > /dev/null 2>&1 || true 
# Elasticsearch needs specific permissions
if [ -d ./data/elasticsearch ]; then
    echo -e "${GREEN}Setting permissions for Elasticsearch data directory...${NC}"
    run_sudo chown -R 1000:1000 ./data/elasticsearch
fi

# Set up virtual memory for Elasticsearch (needs sudo)
echo -e "${GREEN}Checking system parameters for Elasticsearch...${NC}"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    CURRENT_VM_MAX=$(sysctl -n vm.max_map_count)
    if [ "$CURRENT_VM_MAX" -lt 262144 ]; then
        echo -e "${GREEN}Setting vm.max_map_count=262144 (requires sudo)${NC}"
        if run_sudo sysctl -w vm.max_map_count=262144 >/dev/null 2>&1; then
            # Make persistent
            echo "vm.max_map_count=262144" | run_sudo tee -a /etc/sysctl.conf >/dev/null 2>&1
        else
            echo -e "${RED}Warning: Failed to set vm.max_map_count. Elasticsearch may not start properly.${NC}"
            echo -e "Please run this command manually: ${BLUE}sudo sysctl -w vm.max_map_count=262144${NC}"
        fi
    else
        echo -e "${GREEN}vm.max_map_count already set correctly (${CURRENT_VM_MAX})${NC}"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${BLUE}macOS detected.${NC}"
    echo -e "If Elasticsearch fails to start due to memory limits, you may need to increase Docker Desktop's allocated memory and potentially run:"
    echo -e "  ${BLUE}screen ~/Library/Containers/com.docker.docker/Data/vms/0/tty${NC}"
    echo -e "  ${BLUE}sysctl -w vm.max_map_count=262144${NC}"
fi

# Pull Docker images first to show progress
echo -e "${GREEN}Pulling Docker images (this may take a few minutes)...${NC}"
run_sudo $DOCKER_COMPOSE_CMD pull

# Start the stack
echo -e "${GREEN}Starting SecuriWatch...${NC}"
run_sudo $DOCKER_COMPOSE_CMD up -d

echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "SecuriWatch is now running. Access the dashboard at:"
echo -e "${GREEN}https://localhost:8443${NC} (or your server IP)"
echo -e " * NOTE: Default install uses port 8443 for HTTPS."
echo ""
echo -e "Default credentials: ${GREEN}admin / securiwatch${NC}"
echo -e "${RED}IMPORTANT: Change these credentials before deploying to production!${NC}"

echo ""
echo -e "Kibana dashboard: ${GREEN}https://localhost:8443/kibana/${NC}"
echo ""
echo -e "To stop SecuriWatch:       ${BLUE}$DOCKER_COMPOSE_CMD down${NC}"
echo -e "To view logs:              ${BLUE}$DOCKER_COMPOSE_CMD logs -f${NC}"
echo -e "To check service status:   ${BLUE}$DOCKER_COMPOSE_CMD ps${NC}"
echo -e "To run health check:       ${BLUE}./scripts/healthcheck.sh${NC}"
echo ""
echo -e "For documentation, see:    ${BLUE}docs/README.md${NC}"
echo "" 