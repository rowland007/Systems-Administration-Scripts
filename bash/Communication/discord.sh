#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

clear
echo -e "${PURPLE}"
echo '    ██████╗ ██╗███████╗ ██████╗ ██████╗ ██████╗ ██████╗ '
echo '    ██╔══██╗██║██╔════╝██╔════╝██╔═══██╗██╔══██╗██╔══██╗'
echo '    ██║  ██║██║███████╗██║     ██║   ██║██████╔╝██║  ██║'
echo '    ██║  ██║██║╚════██║██║     ██║   ██║██╔══██╗██║  ██║'
echo '    ██████╔╝██║███████║╚██████╗╚██████╔╝██║  ██║██████╔╝'
echo '    ╚═════╝ ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ '
echo
echo -e "${CYAN}     ╔════════════════════════════════════════════╗"
echo -e "     ║        Discord PTB Installer & Updater       ║"
echo -e "     ║     Chat, Share, and Hang with Your Squad    ║"
echo -e "     ╚════════════════════════════════════════════╝${NC}"
echo

# Function to handle errors
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    [ -f /tmp/discord-installer.deb ] && rm -f /tmp/discord-installer.deb
    exit 1
}

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


# Function to update Discord
update_discord() {
    echo -e "${YELLOW}Downloading Discord PTB...${NC}"
    if ! wget -q -O /tmp/discord-installer.deb "https://discord.com/api/download/ptb?platform=linux&format=deb"; then
        handle_error "Failed to download Discord"
    fi

    echo -e "${YELLOW}Installing Discord PTB...${NC}"
    if ! DEBIAN_FRONTEND=noninteractive apt install -y /tmp/discord-installer.deb >/dev/null 2>&1; then
        handle_error "Failed to install Discord"
    fi

    rm -f /tmp/discord-installer.deb
    echo -e "${GREEN}Discord PTB has been successfully updated!${NC}"
}

# Create auto-update script
AUTO_UPDATE_SCRIPT="/usr/local/sbin/discord-updater.sh"
echo -e "${YELLOW}Creating auto-update script...${NC}"

cat > "$AUTO_UPDATE_SCRIPT" << 'EOL'
#!/bin/bash
LOGFILE="/var/log/discord-update.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "=== Discord update started at $TIMESTAMP ===" >> "$LOGFILE"
if wget -q -O /tmp/discord-installer.deb "https://discord.com/api/download/ptb?platform=linux&format=deb"; then
    if DEBIAN_FRONTEND=noninteractive apt install -y /tmp/discord-installer.deb >> "$LOGFILE" 2>&1; then
        echo "Discord PTB updated successfully" >> "$LOGFILE"
    else
        echo "Failed to install Discord PTB" >> "$LOGFILE"
    fi
    rm -f /tmp/discord-installer.deb
else
    echo "Failed to download Discord PTB" >> "$LOGFILE"
fi
echo "=== Update completed at $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOGFILE"
echo "----------------------------------------" >> "$LOGFILE"
EOL

# Make the script executable
chmod +x "$AUTO_UPDATE_SCRIPT" || handle_error "Failed to make auto-update script executable"

# Add to crontab (runs every Sunday at 2 AM)
echo -e "${YELLOW}Setting up weekly auto-updates...${NC}"
(crontab -l 2>/dev/null | grep -v "discord-updater.sh"; echo "0 2 * * 0 $AUTO_UPDATE_SCRIPT") | crontab - || \
    handle_error "Failed to create cron job"

# Initial update
echo -e "${YELLOW}Performing initial Discord installation...${NC}"
update_discord

echo -e "${GREEN}Discord PTB installation and auto-update configuration completed!${NC}"
echo -e "${YELLOW}Auto-updates will run every Sunday at 2 AM${NC}"
echo -e "${YELLOW}Update logs will be written to /var/log/discord-update.log${NC}"
