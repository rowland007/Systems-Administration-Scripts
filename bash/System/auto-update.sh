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

# Function to handle errors
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# Initialize variables
OS=""
PKG_MANAGER=""
UPDATE_CMD=""

# Detect OS and package manager
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID

    case $OS in
        "ubuntu"|"debian"|"linuxmint"|"pop")
            PKG_MANAGER="apt"
            UPDATE_CMD="apt update && apt full-upgrade -y"
            ;;
        "fedora")
            PKG_MANAGER="dnf"
            UPDATE_CMD="dnf -y update"
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            if command -v dnf &>/dev/null; then
                PKG_MANAGER="dnf"
                UPDATE_CMD="dnf -y update"
            else
                PKG_MANAGER="yum"
                UPDATE_CMD="yum -y update"
            fi
            ;;
        "arch"|"manjaro"|"endeavouros")
            PKG_MANAGER="pacman"
            UPDATE_CMD="pacman -Syu --noconfirm"
            ;;
        "alpine")
            PKG_MANAGER="apk"
            UPDATE_CMD="apk update && apk upgrade"
            ;;
        "opensuse"*|"sles")
            PKG_MANAGER="zypper"
            UPDATE_CMD="zypper --non-interactive update"
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

# Create the update script
UPDATE_SCRIPT="/usr/local/sbin/update-script.sh"
echo -e "${YELLOW}Creating update script at $UPDATE_SCRIPT${NC}"

cat > "$UPDATE_SCRIPT" << EOL
#!/bin/bash

# Log file setup
LOG_FILE="/var/log/system-update.log"
TIMESTAMP=\$(date '+%Y-%m-%d %H:%M:%S')

# Redirect all output to log file
exec 1> >(tee -a \$LOG_FILE)
exec 2>&1

echo "=== System update started at \$TIMESTAMP ==="

# Run system updates
echo "Running system updates..."
$UPDATE_CMD

echo "=== System update completed at \$(date '+%Y-%m-%d %H:%M:%S') ==="
echo "----------------------------------------"
EOL

# Make the script executable
chmod +x "$UPDATE_SCRIPT" || handle_error "Failed to make update script executable"

# Create cron entries
echo -e "${YELLOW}Creating cron entries...${NC}"

# Remove any existing cron entries for the update script
crontab -l 2>/dev/null | grep -v "$UPDATE_SCRIPT" | crontab -

# Add new cron entries
(crontab -l 2>/dev/null; echo "0 1 * * * $UPDATE_SCRIPT # Daily system update") | crontab -
(crontab -l 2>/dev/null; echo "@reboot $UPDATE_SCRIPT # Update at system reboot") | crontab -

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Successfully configured automatic system updates!${NC}"
    echo -e "${YELLOW}The system will automatically update:${NC}"
    echo -e "  - Every day at 1:00 AM"
    echo -e "  - At system reboot"
    echo -e "${YELLOW}Logs will be written to /var/log/system-update.log${NC}"
else
    handle_error "Failed to create cron entries"
fi