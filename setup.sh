#!/bin/bash

# SecuriWatch setup script

# Set color variables
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}     SecuriWatch Setup Assistant     ${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

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

# Make sure docker volumes exist
echo -e "${GREEN}Creating required Docker volumes...${NC}"
docker volume create elasticsearch-data >/dev/null 2>&1
docker volume create wazuh-manager-config >/dev/null 2>&1
docker volume create wazuh-manager-data >/dev/null 2>&1
docker volume create filebeat-data >/dev/null 2>&1

# Set up virtual memory for Elasticsearch
echo -e "${GREEN}Checking system parameters for Elasticsearch...${NC}"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    CURRENT_VM_MAX=$(sysctl -n vm.max_map_count)
    if [ "$CURRENT_VM_MAX" -lt 262144 ]; then
        echo -e "${GREEN}Setting vm.max_map_count=262144 (requires sudo)${NC}"
        sudo sysctl -w vm.max_map_count=262144 >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo -e "${RED}Warning: Failed to set vm.max_map_count. Elasticsearch may not start properly.${NC}"
            echo -e "Please run this command manually: ${BLUE}sudo sysctl -w vm.max_map_count=262144${NC}"
        else
            echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1
        fi
    else
        echo -e "${GREEN}vm.max_map_count already set correctly (${CURRENT_VM_MAX})${NC}"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${BLUE}macOS detected.${NC}"
    echo -e "If Elasticsearch fails to start due to memory limits, you may need to run:"
    echo -e "  ${BLUE}screen ~/Library/Containers/com.docker.docker/Data/vms/0/tty${NC}"
    echo -e "  ${BLUE}sysctl -w vm.max_map_count=262144${NC}"
fi

# Pull Docker images first to show progress
echo -e "${GREEN}Pulling Docker images (this may take a few minutes)...${NC}"
docker-compose pull

# Start the stack
echo -e "${GREEN}Starting SecuriWatch...${NC}"
docker-compose up -d

echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "SecuriWatch is now running. Access the dashboard at:"
echo -e "${GREEN}https://localhost${NC}"
echo ""
echo -e "Default credentials: ${GREEN}admin / securiwatch${NC}"
echo -e "${RED}IMPORTANT: Change these credentials before deploying to production!${NC}"
echo ""
echo -e "Kibana dashboard: ${GREEN}https://localhost/kibana/${NC}"
echo ""
echo -e "To stop SecuriWatch:       ${BLUE}docker-compose down${NC}"
echo -e "To view logs:              ${BLUE}docker-compose logs -f${NC}"
echo -e "To check service status:   ${BLUE}docker-compose ps${NC}"
echo -e "To run health check:       ${BLUE}./scripts/healthcheck.sh${NC}"
echo ""
echo -e "For documentation, see:    ${BLUE}docs/README.md${NC}"
echo "" 