#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to handle errors
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    # Clean up if temp file exists
    [ -f /tmp/Joplin_install_and_update.sh ] && rm /tmp/Joplin_install_and_update.sh
    exit 1
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required commands
for cmd in wget bash; do
    if ! command_exists "$cmd"; then
        handle_error "$cmd is required but not installed. Please install it first."
    fi
done

# Determine the correct user to run the installation
if [ "$EUID" -eq 0 ]; then
    # Script is running as root (either direct or via sudo)
    if [ -n "$SUDO_USER" ]; then
        INSTALL_USER="$SUDO_USER"
    else
        # If running as root directly, try to find a real user
        INSTALL_USER=$(who | grep -v root | head -n 1 | cut -d' ' -f1)
        if [ -z "$INSTALL_USER" ]; then
            handle_error "Could not determine the real user. Please run this script as a regular user or with sudo."
        fi
    fi
    echo -e "${YELLOW}Installing Joplin for user: $INSTALL_USER${NC}"
else
    # Script is running as regular user
    INSTALL_USER="$USER"
    echo -e "${YELLOW}Installing Joplin for current user: $INSTALL_USER${NC}"
fi

# Check if we have a valid user
if ! id "$INSTALL_USER" >/dev/null 2>&1; then
    handle_error "Invalid user: $INSTALL_USER"
fi

# Check if home directory exists and is writable
USER_HOME=$(eval echo ~"$INSTALL_USER")
if [ ! -d "$USER_HOME" ]; then
    handle_error "Home directory not found for user: $INSTALL_USER"
fi

if [ ! -w "$USER_HOME" ] && [ "$EUID" -ne 0 ]; then
    handle_error "No write permission to $USER_HOME"
fi

# Download Joplin installation script
echo -e "${YELLOW}Downloading Joplin installation script...${NC}"
if [ "$EUID" -eq 0 ]; then
    # Running as root/sudo
    su - "$INSTALL_USER" -c "wget -O /tmp/Joplin_install_and_update.sh https://raw.githubusercontent.com/laurent22/joplin/dev/Joplin_install_and_update.sh" || \
        handle_error "Failed to download Joplin installation script"
else
    # Running as regular user
    wget -O /tmp/Joplin_install_and_update.sh https://raw.githubusercontent.com/laurent22/joplin/dev/Joplin_install_and_update.sh || \
        handle_error "Failed to download Joplin installation script"
fi

# Make script executable
chmod +x /tmp/Joplin_install_and_update.sh || handle_error "Failed to make installation script executable"

# Run installation script
echo -e "${YELLOW}Installing Joplin...${NC}"
if [ "$EUID" -eq 0 ]; then
    # Running as root/sudo
    su - "$INSTALL_USER" -c "bash /tmp/Joplin_install_and_update.sh --prerelease" || \
        handle_error "Joplin installation failed"
else
    # Running as regular user
    bash /tmp/Joplin_install_and_update.sh --prerelease || \
        handle_error "Joplin installation failed"
fi

# Clean up
rm -f /tmp/Joplin_install_and_update.sh || echo -e "${YELLOW}Warning: Could not remove temporary installation script${NC}"

echo -e "${GREEN}Joplin has been successfully installed for user $INSTALL_USER!${NC}"
