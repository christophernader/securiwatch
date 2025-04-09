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

# Check if docker compose is installed (V2 preferred)
if ! docker compose version &> /dev/null; then
    echo -e "${YELLOW}Warning: Docker Compose V2 (plugin) not found. Trying V1...${NC}"
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}Error: Docker Compose (V1 or V2) is not installed. Please install Docker Compose first.${NC}"
        exit 1
    fi
fi

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is not installed. Please install curl first.${NC}"
    exit 1
fi

# Define installation directory explicitly
# Use explicit path instead of $HOME to avoid potential env issues
INSTALL_DIR="/home/chris/securiwatch" 

echo "Current user: $(whoami)"
echo "Target install directory: $INSTALL_DIR"

# Check if installation directory exists
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Directory '$INSTALL_DIR' already exists.${NC}"
    ls -ld "$INSTALL_DIR" # DEBUG: Show ownership/permissions
    echo -e "Would you like to:"
    echo -e "  [1] Overwrite the existing directory (All data will be lost!)"
    echo -e "  [2] Cancel installation"
    read -p "Please choose (1-2): " choice

    case $choice in
        1)
            echo -e "${YELLOW}Warning: Removing existing directory '$INSTALL_DIR'...${NC}"
            # Try removing without sudo first, then with if needed
            if ! rm -rf "$INSTALL_DIR"; then
                echo -e "${YELLOW}Failed to remove as user, trying with sudo...${NC}"
                if sudo rm -rf "$INSTALL_DIR"; then
                    echo -e "${GREEN}Removed existing directory with sudo.${NC}"
                else
                    echo -e "${RED}Error: Failed to remove existing directory even with sudo. Please remove it manually and try again.${NC}"
                    exit 1
                fi
            else
                 echo -e "${GREEN}Removed existing directory as user.${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Installation cancelled.${NC}"
            exit 1
            ;;
    esac
fi

echo -e "${GREEN}Creating directory: $INSTALL_DIR${NC}"
mkdir -p "$INSTALL_DIR"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to create directory '$INSTALL_DIR'. Check parent directory permissions.${NC}"
    # DEBUG: Show permissions of parent directory
    ls -ld "$(dirname "$INSTALL_DIR")"
    exit 1
fi

echo -e "${GREEN}DEBUG: Directory created. Checking ownership/permissions:${NC}"
ls -ld "$INSTALL_DIR" # DEBUG: Show ownership/permissions after creation

cd "$INSTALL_DIR" || exit 1 # Exit if cd fails
echo -e "${GREEN}DEBUG: Changed directory to: $(pwd)${NC}" # DEBUG: Confirm current directory

# DEBUG: Test write permissions
echo -e "${GREEN}DEBUG: Testing write permissions in $(pwd)...${NC}"
touch test_write_file
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Cannot write test file in '$INSTALL_DIR'. Check permissions.${NC}"
    exit 1
else
    echo -e "${GREEN}DEBUG: Write test successful.${NC}"
    rm test_write_file
fi

# Download and extract SecuriWatch
echo -e "${GREEN}Downloading and extracting SecuriWatch...${NC}"
# Using -v for verbose tar output
curl -#L https://github.com/christophernader/securiwatch/archive/refs/heads/main.tar.gz | tar -xzvf - --strip-components 1

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download and extract SecuriWatch.${NC}"
    cd .. && rm -rf "$INSTALL_DIR" # Clean up failed install
    exit 1
fi

echo -e "${GREEN}Download complete!${NC}"

# Make scripts executable
chmod +x setup.sh generate-certs.sh scripts/healthcheck.sh update.sh install.sh

# Run the setup script
echo -e "${GREEN}Running setup script (will require sudo for Docker)...${NC}"
./setup.sh # setup.sh will handle sudo internally for docker commands

if [ $? -ne 0 ]; then
    echo -e "${RED}Setup script failed. Please check the output above for errors.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "SecuriWatch has been installed in: ${GREEN}$INSTALL_DIR${NC}"
echo -e "Data will be stored within this directory (under ./data)."
echo -e ""
echo -e "Quick Tips:"
echo -e " * Dashboard URL: ${GREEN}https://localhost:8443${NC} (or your server IP)"
echo -e " * NOTE: Default install uses port 8443 for HTTPS."
echo -e " * Default login: ${GREEN}admin / securiwatch${NC}"
echo -e " * Documentation: ${GREEN}docs/README.md${NC}"
echo -e ""
echo -e "Change to the SecuriWatch directory to run commands:"
echo -e "${BLUE}cd $INSTALL_DIR${NC}"
echo "" 