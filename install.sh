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

# Check prerequisites
if ! command -v docker &> /dev/null; then echo -e "${RED}Error: Docker not installed.${NC}"; exit 1; fi
if ! command -v curl &> /dev/null; then echo -e "${RED}Error: curl not installed.${NC}"; exit 1; fi
if ! docker compose version &> /dev/null && ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose (V1 or V2) not installed.${NC}"; exit 1
fi

# Define installation directory in user's home
INSTALL_DIR="$HOME/securiwatch" 
TEMP_TAR="$INSTALL_DIR/source.tar.gz"

echo "Current user: $(whoami)"
echo "Target install directory: $INSTALL_DIR"

# Handle existing directory
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Directory '$INSTALL_DIR' already exists.${NC}"
    ls -ld "$INSTALL_DIR"
    read -p "Overwrite existing directory (y/N)? " -n 1 -r
    echo # Move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation cancelled.${NC}"
        exit 1
    fi
    echo -e "${YELLOW}Removing existing directory '$INSTALL_DIR'...${NC}"
    if ! rm -rf "$INSTALL_DIR"; then
        if sudo rm -rf "$INSTALL_DIR"; then
            echo -e "${GREEN}Removed existing directory with sudo.${NC}"
        else
            echo -e "${RED}Error: Failed to remove '$INSTALL_DIR'. Please remove it manually.${NC}"; exit 1
        fi
    else
         echo -e "${GREEN}Removed existing directory as user.${NC}"
    fi
fi

# Create directory
echo -e "${GREEN}Creating directory: $INSTALL_DIR${NC}"
mkdir -p "$INSTALL_DIR"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to create directory '$INSTALL_DIR'. Check parent permissions.${NC}"
    ls -ld "$(dirname "$INSTALL_DIR")"
    exit 1
fi
ls -ld "$INSTALL_DIR"

cd "$INSTALL_DIR" || exit 1
echo -e "${GREEN}DEBUG: Changed directory to: $(pwd)${NC}"

# Download archive first
SOURCE_URL="https://github.com/christophernader/securiwatch/archive/refs/heads/main.tar.gz"
echo -e "${GREEN}Downloading source archive from $SOURCE_URL...${NC}"
curl -#L "$SOURCE_URL" -o "$TEMP_TAR"

if [ $? -ne 0 ] || [ ! -f "$TEMP_TAR" ]; then
    echo -e "${RED}Error: Failed to download source archive.${NC}"
    cd .. && rm -rf "$INSTALL_DIR" # Clean up
    exit 1
fi
echo -e "${GREEN}Download complete. Archive saved to $TEMP_TAR${NC}"

# Extract the downloaded archive
echo -e "${GREEN}Extracting archive...${NC}"
tar -xzvf "$TEMP_TAR" --strip-components 1

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to extract source archive.${NC}"
    # Don't delete the whole dir, just the failed tarball maybe?
    rm -f "$TEMP_TAR"
    exit 1
fi

# Clean up downloaded archive
echo -e "${GREEN}Extraction complete. Removing temporary archive...${NC}"
rm "$TEMP_TAR"

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