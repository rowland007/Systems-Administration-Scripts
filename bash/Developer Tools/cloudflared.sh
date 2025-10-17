#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

clear
echo -e "${ORANGE}"
echo '     ██████╗██╗      ██████╗ ██╗   ██╗██████╗ ███████╗██╗      █████╗ ██████╗ ███████╗'
echo '    ██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗██╔════╝██║     ██╔══██╗██╔══██╗██╔════╝'
echo '    ██║     ██║     ██║   ██║██║   ██║██║  ██║█████╗  ██║     ███████║██████╔╝█████╗  '
echo '    ██║     ██║     ██║   ██║██║   ██║██║  ██║██╔══╝  ██║     ██╔══██║██╔══██╗██╔══╝  '
echo '    ╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝██║     ███████╗██║  ██║██║  ██║███████╗'
echo '     ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝'
echo -e "${CYAN}                                 TUNNEL DAEMON${NC}"
echo
echo -e "${ORANGE}     ╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${ORANGE}     ║${NC}              Cloudflared Installation & Setup              ${ORANGE}║${NC}"
echo -e "${ORANGE}     ║${NC}        Secure tunnels to your local web server           ${ORANGE}║${NC}"
echo -e "${ORANGE}     ║${NC}     Connect your infrastructure to Cloudflare's edge     ${ORANGE}║${NC}"
echo -e "${ORANGE}     ╚════════════════════════════════════════════════════════════╝${NC}"
echo

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or use sudo.${NC}"
    exit 1
fi

# Function to handle errors
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# Initialize variables
OS=""
PKG_MANAGER=""
CMD=""


# Detect OS and package manager
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID

    case $OS in
        "ubuntu"|"debian"|"linuxmint"|"pop")
            PKG_MANAGER="apt"
            CMD="apt update && apt full-upgrade -y"
            ;;
        "fedora")
            PKG_MANAGER="dnf"
            CMD="dnf -y update"
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            if command -v dnf &>/dev/null; then
                PKG_MANAGER="dnf"
                CMD="dnf -y update"
            else
                PKG_MANAGER="yum"
                CMD="yum -y update"
            fi
            ;;
        "arch"|"manjaro"|"endeavouros")
            PKG_MANAGER="pacman"
            CMD="pacman -Syu --noconfirm"
            ;;
        "alpine")
            PKG_MANAGER="apk"
            CMD="apk update && apk upgrade"
            ;;
        "opensuse"*|"sles")
            PKG_MANAGER="zypper"
            CMD="zypper --non-interactive update"
            ;;
        *)
            handle_error "Unsupported operating system: $OS"
            ;;
    esac
else
    handle_error "Cannot determine operating system (no /etc/os-release file)"
fi

echo -e "${GREEN}Detected OS: $OS${NC}"
echo -e "${GREEN}Package Manager: $PKG_MANAGER${NC}"



# Add Cloudflare GPG key
execute_command "mkdir -p --mode=0755 /usr/share/keyrings"
execute_command "curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null"

# Add Cloudflare repo to apt repositories
execute_command "echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list"

# Install cloudflared
execute_command "apt update && apt install -y cloudflared"