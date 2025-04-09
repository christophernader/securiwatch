#!/bin/bash

# SecuriWatch Installer Script
# To use: curl -sL https://raw.githubusercontent.com/christophernader/securiwatch/main/install.sh | bash

# Set color variables
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}      SecuriWatch Installer          ${NC}"
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

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is not installed. Please install curl first.${NC}"
    exit 1
fi

# Create installation directory
INSTALL_DIR="securiwatch"
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Directory '$INSTALL_DIR' already exists.${NC}"
    echo -e "Would you like to:"
    echo -e "  [1] Install to a different directory"
    echo -e "  [2] Overwrite the existing directory"
    echo -e "  [3] Cancel installation"
    read -p "Please choose (1-3): " choice
    
    case $choice in
        1)
            read -p "Enter a new directory name: " INSTALL_DIR
            if [ -d "$INSTALL_DIR" ]; then
                echo -e "${RED}Error: Directory '$INSTALL_DIR' also exists. Please run the installer again with a different name.${NC}"
                exit 1
            fi
            ;;
        2)
            echo -e "${YELLOW}Warning: Overwriting existing directory '$INSTALL_DIR'.${NC}"
            rm -rf "$INSTALL_DIR"
            ;;
        *)
            echo -e "${RED}Installation cancelled.${NC}"
            exit 1
            ;;
    esac
fi

echo -e "${GREEN}Creating directory: $INSTALL_DIR${NC}"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Download and extract SecuriWatch
echo -e "${GREEN}Downloading SecuriWatch...${NC}"
curl -sL https://github.com/christophernader/securiwatch/archive/refs/heads/main.tar.gz | tar -xzf - --strip-components 1

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download and extract SecuriWatch.${NC}"
    exit 1
fi

echo -e "${GREEN}Download complete!${NC}"

# Make scripts executable
chmod +x setup.sh generate-certs.sh scripts/healthcheck.sh update.sh

# Run the setup script
echo -e "${GREEN}Running setup script...${NC}"
./setup.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}Setup script failed. Please check the output above for errors.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "SecuriWatch has been installed in: ${GREEN}$(pwd)${NC}"
echo -e ""
echo -e "Quick Tips:"
echo -e " * Dashboard URL: ${GREEN}https://localhost${NC}"
echo -e " * Default login: ${GREEN}admin / securiwatch${NC}"
echo -e " * Documentation: ${GREEN}docs/README.md${NC}"
echo -e ""
echo -e "Change to the SecuriWatch directory to run commands:"
echo -e "${BLUE}cd $(pwd)${NC}"
echo "" 