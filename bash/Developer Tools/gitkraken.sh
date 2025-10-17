#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# URL Variables
export DEB_URL='https://api.gitkraken.dev/releases/production/linux/x64/active/gitkraken-amd64.deb'
export RPM_URL='https://api.gitkraken.dev/releases/production/linux/x64/active/gitkraken-amd64.rpm'
export TAR_URL='https://api.gitkraken.dev/releases/production/linux/x64/active/gitkraken-amd64.tar.gz'

# Clear screen and display ASCII art
clear
echo -e "${CYAN}"
echo '    ██████╗ ██╗████████╗██╗  ██╗██████╗  █████╗ ██╗  ██╗███████╗███╗   ██╗'
echo '   ██╔════╝ ██║╚══██╔══╝██║ ██╔╝██╔══██╗██╔══██╗██║ ██╔╝██╔════╝████╗  ██║'
echo '   ██║  ███╗██║   ██║   █████╔╝ ██████╔╝███████║█████╔╝ █████╗  ██╔██╗ ██║'
echo '   ██║   ██║██║   ██║   ██╔═██╗ ██╔══██╗██╔══██║██╔═██╗ ██╔══╝  ██║╚██╗██║'
echo '   ╚██████╔╝██║   ██║   ██║  ██╗██║  ██║██║  ██║██║  ██╗███████╗██║ ╚████║'
echo '    ╚═════╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝'
echo
echo -e "${WHITE}     ╔════════════════════════════════════════════════════════╗"
echo -e "     ║            GitKraken Installation Script               ║"
echo -e "     ║        Legendary Git GUI for Linux Systems             ║"
echo -e "     ╚════════════════════════════════════════════════════════╝${NC}"
echo

# Function to display error messages and exit
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    rm gitkraken.deb 2> /dev/null || rm gitkraken.rpm 2> /dev/null
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

# Function to set up auto-update cron job
setup_cron() {
    info_msg "Setting up weekly auto-update cron job..."
    
    # Create update script with proper error handling and logging
    cat > /usr/local/bin/gitkraken-update.sh << 'EOF'
#!/bin/bash

# Set up logging
exec 1> >(logger -s -t $(basename $0)) 2>&1

# Define color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

DEB_URL='https://api.gitkraken.dev/releases/production/linux/x64/active/gitkraken-amd64.deb'
RPM_URL='https://api.gitkraken.dev/releases/production/linux/x64/active/gitkraken-amd64.rpm'

# Function to log messages
log() {
    echo -e "$1"
}

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR" || exit 1

# Clean up function
cleanup() {
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

if command -v apt &> /dev/null; then
    # Debian-based system
    log "${BLUE}Downloading latest GitKraken .deb package...${NC}"

    if wget -q -O gitkraken.deb $DEB_URL; then
        log "${BLUE}Installing GitKraken update...${NC}"
        if apt install -y gitkraken.deb; then
            log "${GREEN}GitKraken has been successfully updated!${NC}"
        else
            log "${RED}Failed to install GitKraken update${NC}"
            rm gitkraken.deb
            exit 1
        fi
    else
        log "${RED}Failed to download GitKraken update${NC}"
        exit 1
    fi
elif command -v dnf &> /dev/null || command -v yum &> /dev/null; then
    # RHEL-based system
    PKG_MANAGER="dnf"
    if ! command -v dnf &> /dev/null; then
        PKG_MANAGER="yum"
    fi
    
    log "${BLUE}Downloading latest GitKraken .rpm package...${NC}"
    if wget -q -O gitkraken.rpm $RPM_URL; then
        log "${BLUE}Installing GitKraken update...${NC}"
        if $PKG_MANAGER install -y gitkraken.rpm; then
            log "${GREEN}GitKraken has been successfully updated!${NC}"
        else
            log "${RED}Failed to install GitKraken update${NC}"
            rm gitkraken.rpm
            exit 1
        fi
    else
        log "${RED}Failed to download GitKraken update${NC}"
        exit 1
    fi
else
    log "${RED}Unsupported operating system${NC}"
    exit 1
fi
EOF
    
    chmod +x /usr/local/bin/gitkraken-update.sh
    
    # Add cron job for weekly updates (Sunday at 3 AM)
    echo "0 3 * * 0 root /usr/local/bin/gitkraken-update.sh" > /etc/cron.d/gitkraken-update
    chmod 644 /etc/cron.d/gitkraken-update
    
    success_msg "Auto-update cron job configured successfully"
}

# Check if script is running as root
if [ "$EUID" -ne 0 ]; then
    error_exit "This script must be run as root. Please use sudo."
fi

# Create temporary directory for downloads
# TEMP_DIR=$(mktemp -d) && cd $TEMP_DIR || error_exit "Failed to create temporary directory"

# Detect OS and install GitKraken
if command -v apt &> /dev/null; then
    # Debian-based system
    info_msg "Detected Debian-based system. Installing GitKraken..."
    
    # Install required dependencies
    if command -v wget &> /dev/null; then
        info_msg "wget is already installed."
    else
        info_msg "Installing wget..."
        apt update && apt install -y wget || error_exit "Failed to install wget"
    fi
    
    # Download latest .deb package
    info_msg "Downloading GitKraken..."
    wget -O gitkraken.deb $DEB_URL || error_exit "Failed to download GitKraken"
    
    # Install package
    info_msg "Installing GitKraken..."
    apt install -y ./gitkraken.deb || error_exit "Failed to install GitKraken"
    
    # Set up auto-updates
    setup_cron

elif command -v dnf &> /dev/null || command -v yum &> /dev/null; then
    # RHEL-based system
    info_msg "Detected RHEL-based system. Installing GitKraken..."
    
    # Determine package manager
    PKG_MANAGER="dnf"
    if ! command -v dnf &> /dev/null; then
        PKG_MANAGER="yum"
    fi
    
    # Download latest .rpm package
    info_msg "Downloading GitKraken..."
    wget -O gitkraken.rpm $RPM_URL || error_exit "Failed to download GitKraken"
    
    # Install package
    info_msg "Installing GitKraken..."
    $PKG_MANAGER install -y ./gitkraken.rpm || error_exit "Failed to install GitKraken"
    
    # Set up auto-updates
    setup_cron

else
    error_exit "Unsupported operating system. This script supports Debian and RHEL-based systems only."
fi

# Clean up
#cd .. > /dev/null
rm gitkraken.deb || rm gitkraken.rpm #"$TEMP_DIR"

success_msg "GitKraken has been successfully installed!"