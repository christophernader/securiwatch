#!/bin/bash

# SecuriWatch Update Script

# Set color variables
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}     SecuriWatch Update Assistant     ${NC}"
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

# Backup current configuration
echo -e "${GREEN}Backing up current configuration...${NC}"
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r config "$BACKUP_DIR/"
cp docker-compose.yml "$BACKUP_DIR/"
cp .env "$BACKUP_DIR/" 2>/dev/null || echo -e "${YELLOW}No .env file found to backup.${NC}"

# Pull latest changes if in a git repository
if [ -d ".git" ]; then
    echo -e "${GREEN}Pulling latest changes from git repository...${NC}"
    git pull
    
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}Warning: Could not pull the latest changes. You may have local modifications.${NC}"
        echo -e "Would you like to continue with the update anyway? (y/n)"
        read -r continue_update
        if [[ ! "$continue_update" =~ ^[Yy]$ ]]; then
            echo -e "${RED}Update canceled.${NC}"
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}Not a git repository. Skipping code update.${NC}"
    echo -e "Please manually update your files if needed."
fi

# Pull latest Docker images
echo -e "${GREEN}Pulling latest Docker images...${NC}"
docker-compose pull

# Stop running services
echo -e "${GREEN}Stopping running services...${NC}"
docker-compose down

# Start services with new images
echo -e "${GREEN}Starting services with updated images...${NC}"
docker-compose up -d

# Run health check
echo -e "${GREEN}Running health check...${NC}"
./scripts/healthcheck.sh

echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}Update Complete!${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "Configuration backup saved to: ${GREEN}$BACKUP_DIR${NC}"
echo -e "If you encounter any issues, you can restore from this backup or check the logs."
echo ""
echo -e "To view logs: ${BLUE}docker-compose logs -f${NC}"
echo -e "To restore backup: ${BLUE}cp -r $BACKUP_DIR/* .${NC}"
echo "" 