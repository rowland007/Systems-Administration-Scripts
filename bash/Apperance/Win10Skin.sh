#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

clear
echo -e "${BLUE}"
echo '    ██╗    ██╗██╗███╗   ██╗ ██╗ ██████╗ '
echo '    ██║    ██║██║████╗  ██║███║██╔═████╗'
echo '    ██║ █╗ ██║██║██╔██╗ ██║╚██║██║██╔██║'
echo '    ██║███╗██║██║██║╚██╗██║ ██║████╔╝██║'
echo '    ╚███╔███╔╝██║██║ ╚████║ ██║╚██████╔╝'
echo '     ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝ ╚═╝ ╚═════╝ '
echo
echo -e "${CYAN}     ╔═══════════════════════════════════╗"
echo -e "     ║     XFCE Windows 10 Theme        ║"
echo -e "     ║  Transform Linux into Windows 10  ║"
echo -e "     ╚═══════════════════════════════════╝${NC}"
echo
echo -e "${WHITE}     [ Kali Undercover - Stealth Mode ]${NC}"
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

# Check if XFCE4 is installed
if ! command -v xfce4-session >/dev/null 2>&1; then
    echo -e "${RED}XFCE4 is not installed.${NC}"
    echo -e "${YELLOW}Would you like to install XFCE4? (y/n)${NC}"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installing XFCE4...${NC}"
        apt update
        apt install -y xfce4 xfce4-goodies
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}XFCE4 installed successfully!${NC}"
        else
            echo -e "${RED}Failed to install XFCE4. Please install it manually.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}XFCE4 is required for this theme. Exiting.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}System checks passed. Your system is compatible with the Windows 10 skin.${NC}"

# Create temporary directory for downloads
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR" || exit 1

# Define package URLs
declare -A PACKAGES=(
    ["kali-undercover"]="https://archive.kali.org/kali/pool/main/k/kali-undercover/kali-undercover_2025.4.1_all.deb"
    ["kali-themes-common"]="https://archive.kali.org/kali/pool/main/k/kali-themes/kali-themes-common_2025.4.2_all.deb"
    ["kali-wallpapers-2025"]="https://archive.kali.org/kali/pool/main/k/kali-wallpapers/kali-wallpapers-2025_2025.1.2_all.deb"
)

# Install wget if not present
if ! command -v wget >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing wget...${NC}"
    apt install -y wget
fi

# Download packages
echo -e "${YELLOW}Downloading required packages...${NC}"
for pkg_name in "${!PACKAGES[@]}"; do
    echo -e "${YELLOW}Downloading ${pkg_name}...${NC}"
    if ! wget -q "${PACKAGES[$pkg_name]}"; then
        echo -e "${RED}Failed to download ${pkg_name}. Please check your internet connection.${NC}"
        cd / && rm -rf "$TEMP_DIR"
        exit 1
    fi
done

# Install packages
echo -e "${YELLOW}Installing packages...${NC}"
if ! apt install -y ./*.deb; then
    echo -e "${RED}Failed to install packages. Please check the error messages above.${NC}"
    cd / && rm -rf "$TEMP_DIR"
    exit 1
fi

# Cleanup
cd / && rm -rf "$TEMP_DIR"
echo -e "${GREEN}Successfully installed all required packages!${NC}"

# Ask user if they want to apply the Windows 10 skin now
echo -e "${YELLOW}Would you like to apply the Windows 10 skin now? (y/n)${NC}"
read -r apply_theme

if [[ "$apply_theme" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Applying Windows 10 skin...${NC}"
    if [ -n "$SUDO_USER" ]; then
        # If script was run with sudo, use SUDO_USER
        echo -e "${YELLOW}Running kali-undercover as user $SUDO_USER${NC}"
        su - "$SUDO_USER" -c "DISPLAY=:0 kali-undercover"
    else
        # If script was run with su or direct root login
        REAL_USER=$(who | grep -v root | head -n 1 | cut -d' ' -f1)
        if [ -n "$REAL_USER" ]; then
            echo -e "${YELLOW}Running kali-undercover as user $REAL_USER${NC}"
            su - "$REAL_USER" -c "DISPLAY=:0 kali-undercover"
        else
            echo -e "${RED}Could not determine the regular user. Please run 'kali-undercover' manually as a non-root user.${NC}"
            exit 1
        fi
    fi
    echo -e "${GREEN}Windows 10 skin applied successfully!${NC}"
else
    echo -e "${YELLOW}You can apply the Windows 10 skin later by running the 'kali-undercover' command in a terminal as a regular user (not root).${NC}"
fi

echo -e "${GREEN}Installation complete! Enjoy your new theme!${NC}"
