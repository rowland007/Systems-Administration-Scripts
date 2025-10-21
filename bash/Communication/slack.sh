#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if flatpak remote exists
flatpak_remote_exists() {
    flatpak remotes --show-disabled | grep -q "^$1"
}

# Clear screen and display ASCII art
clear
echo -e "${CYAN}"
echo '    ███████╗██╗      █████╗  ██████╗██╗  ██╗'
echo '    ██╔════╝██║     ██╔══██╗██╔════╝██║ ██╔╝'
echo '    ███████╗██║     ███████║██║     █████╔╝ '
echo '    ╚════██║██║     ██╔══██║██║     ██╔═██╗ '
echo '    ███████║███████╗██║  ██║╚██████╗██║  ██╗'
echo '    ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝'
echo
echo -e "${WHITE}     ╔════════════════════════════════════════════════════════╗"
echo -e "     ║              Slack Installation Script                 ║"
echo -e "     ║        Where Work Happens - Desktop for Linux          ║"
echo -e "     ╚════════════════════════════════════════════════════════╝${NC}"
echo

# Function to display error messages and exit
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Function to display success messages
success_msg() {
    echo -e "${GREEN}$1${NC}"
}

# Function to display info messages
info_msg() {
    echo -e "${YELLOW}$1${NC}"
}

# Set up user's crontab for updates
setup_user_cron() {
    info_msg "Setting up weekly auto-update in user's crontab..."
    
    # Check if the crontab entry already exists
    if ! crontab -l 2>/dev/null | grep -q "flatpak update.*com.slack.Slack"; then
        (crontab -l 2>/dev/null; echo "0 3 * * 0 flatpak update --user -y com.slack.Slack") | crontab -
        success_msg "Auto-update has been added to your crontab"
    else
        info_msg "Auto-update already configured in crontab"
    fi
}

# Only set up cron if user wants it
read -p "Would you like to set up automatic updates for Slack? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    setup_user_cron
fi

# Check if Flatpak is already installed
install_flatpak() {
    if ! command_exists flatpak; then
        info_msg "Flatpak is not installed. Root access required to install Flatpak..."
        if [ "$EUID" -ne 0 ]; then
            if command_exists sudo; then
                sudo apt update && sudo apt install -y flatpak || error_exit "Failed to install Flatpak"
            else
                error_exit "Flatpak is not installed and sudo is not available. Please install Flatpak first."
            fi
        else
            if command_exists apt; then
                apt update && apt install -y flatpak || error_exit "Failed to install Flatpak"
            elif command_exists dnf; then
                dnf install -y flatpak || error_exit "Failed to install Flatpak"
            elif command_exists yum; then
                yum install -y flatpak || error_exit "Failed to install Flatpak"
            else
                error_exit "Could not find a compatible package manager to install Flatpak"
            fi
        fi
    fi
}

# Warn if running as root
if [ "$EUID" -eq 0 ]; then
    info_msg "Warning: Running as root. Flatpak applications can be installed without root privileges."
    info_msg "Consider running this script as a regular user next time."
    echo
fi

# Install Flatpak if needed
install_flatpak

# Check if Flathub remote is added for the current user
if ! flatpak_remote_exists "flathub"; then
    info_msg "Adding Flathub repository for user..."
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || \
        error_exit "Failed to add Flathub repository"
fi

# Install Slack from Flathub for the current user
info_msg "Installing Slack from Flathub..."
flatpak install --user -y flathub com.slack.Slack || error_exit "Failed to install Slack"

# Display completion message

success_msg "Slack has been successfully installed!"