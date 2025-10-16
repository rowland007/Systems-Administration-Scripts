#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD_BLUE='\033[1;34m'
NC='\033[0m' # No Color

clear
# Signal ASCII Art Logo
echo -e "${BLUE}"
echo '    ███████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██╗     '
echo '    ██╔════╝██║██╔════╝ ████╗  ██║██╔══██╗██║     '
echo '    ███████╗██║██║  ███╗██╔██╗ ██║███████║██║     '
echo '    ╚════██║██║██║   ██║██║╚██╗██║██╔══██║██║     '
echo '    ███████║██║╚██████╔╝██║ ╚████║██║  ██║███████╗'
echo '    ╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝'
echo -e "${NC}"
echo -e "${BOLD_BLUE}============================================================${NC}"
echo -e "${BOLD_BLUE}                 Signal Desktop Installer                    ${NC}"
echo -e "${BOLD_BLUE}       Privacy that fits in your pocket since 2013         ${NC}"
echo -e "${BOLD_BLUE}============================================================${NC}"
echo

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

# Progress counter function
progress() {
    local duration=$1
    local step=0.25  # Update every 0.25 seconds
    local progress=0
    local cols=$(tput cols)
    local bar_size=$((cols - 35))  # Reserve space for text and percentage

    while [ $progress -le 100 ]; do
        printf "\r${BLUE}[%-${bar_size}s] %3d%%" "$(printf '#%.0s' $(seq 1 $((progress * bar_size / 100))))" "$progress"
        progress=$((progress + 2))
        sleep $step
    done
    echo -e "${NC}"
}

# 1. Install our official public software signing key
echo -e "${YELLOW}Downloading and installing Signal's GPG key...${NC}"
if ! wget -O- https://updates.signal.org/desktop/apt/keys.asc 2>/dev/null | gpg --dearmor > signal-desktop-keyring.gpg 2>/dev/null; then
    handle_error "Failed to download Signal's GPG key"
fi
progress 0.5

if ! cat signal-desktop-keyring.gpg | tee /usr/share/keyrings/signal-desktop-keyring.gpg >/dev/null 2>&1; then
    handle_error "Failed to install Signal's GPG key"
fi

# 2. Add Signal repository
echo -e "${YELLOW}Adding Signal repository...${NC}"
if ! wget -O signal-desktop.sources https://updates.signal.org/static/desktop/apt/signal-desktop.sources 2>/dev/null; then
    handle_error "Failed to download Signal's repository configuration"
fi
progress 0.5

if ! cat signal-desktop.sources | tee /etc/apt/sources.list.d/signal-desktop.sources >/dev/null 2>&1; then
    handle_error "Failed to add Signal's repository"
fi

# 3. Update package database and install Signal
echo -e "${YELLOW}Updating package database...${NC}"
if ! apt update >/dev/null 2>&1; then
    handle_error "Failed to update package database"
fi
progress 1

echo -e "${YELLOW}Installing Signal Desktop...${NC}"
if ! DEBIAN_FRONTEND=noninteractive apt install -y signal-desktop >/dev/null 2>&1; then
    handle_error "Failed to install Signal Desktop"
fi
progress 2

echo -e "${GREEN}Signal Desktop has been successfully installed!${NC}"
echo -e "${YELLOW}You can start Signal Desktop from your application menu or by running 'signal-desktop'${NC}"