#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or use sudo.${NC}"
    exit 1
fi

# Check if running a Debian-based distribution
if [ ! -f "/etc/debian_version" ]; then
    echo -e "${RED}This script only works on Debian-based distributions.${NC}"
    exit 1
fi

# Create temporary directory for downloads
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR" || {
    echo -e "${RED}Failed to create temporary directory${NC}"
    exit 1
}

# Cleanup function
cleanup() {
    cd / && rm -rf "$TEMP_DIR"
}

# Set trap for cleanup on script exit
trap cleanup EXIT

# Function to handle errors
handle_error() {
    echo -e "${RED}$1${NC}"
    exit 1
}

echo -e "${YELLOW}Installing Signal Desktop...${NC}"

# 1. Install our official public software signing key
echo -e "${YELLOW}Downloading and installing Signal's GPG key...${NC}"
if ! wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg; then
    handle_error "Failed to download Signal's GPG key"
fi

if ! cat signal-desktop-keyring.gpg | tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null; then
    handle_error "Failed to install Signal's GPG key"
fi

# 2. Add Signal repository
echo -e "${YELLOW}Adding Signal repository...${NC}"
if ! wget -O signal-desktop.sources https://updates.signal.org/static/desktop/apt/signal-desktop.sources; then
    handle_error "Failed to download Signal's repository configuration"
fi

if ! cat signal-desktop.sources | tee /etc/apt/sources.list.d/signal-desktop.sources > /dev/null; then
    handle_error "Failed to add Signal's repository"
fi

# 3. Update package database and install Signal
echo -e "${YELLOW}Updating package database...${NC}"
if ! apt update; then
    handle_error "Failed to update package database"
fi

echo -e "${YELLOW}Installing Signal Desktop...${NC}"
if ! apt install -y signal-desktop; then
    handle_error "Failed to install Signal Desktop"
fi

echo -e "${GREEN}Signal Desktop has been successfully installed!${NC}"
echo -e "${YELLOW}You can start Signal Desktop from your application menu or by running 'signal-desktop'${NC}"