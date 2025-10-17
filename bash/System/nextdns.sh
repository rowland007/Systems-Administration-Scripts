#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ASCII Art
clear
echo -e "${BLUE}"
echo '    ███╗   ██╗███████╗██╗  ██╗████████╗██████╗ ███╗   ██╗███████╗'
echo '    ████╗  ██║██╔════╝╚██╗██╔╝╚══██╔══╝██╔══██╗████╗  ██║██╔════╝'
echo '    ██╔██╗ ██║█████╗   ╚███╔╝    ██║   ██║  ██║██╔██╗ ██║███████╗'
echo '    ██║╚██╗██║██╔══╝   ██╔██╗    ██║   ██║  ██║██║╚██╗██║╚════██║'
echo '    ██║ ╚████║███████╗██╔╝ ██╗   ██║   ██████╔╝██║ ╚████║███████║'
echo '    ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═════╝ ╚═╝  ╚═══╝╚══════╝'
echo -e "${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}                NextDNS Root CA Installation                       ${NC}"
echo -e "${BLUE}              Secure DNS Resolution Made Easy                      ${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo

# Function to handle errors
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    # Clean up downloaded certificate if it exists
    [ -f NextDNS.cer ] && rm -f NextDNS.cer
    exit 1
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    handle_error "Please run as root or use sudo"
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR" || handle_error "Failed to create temporary directory"

# Cleanup function
cleanup() {
    cd / && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Download NextDNS certificate
echo -e "${YELLOW}Downloading NextDNS Root CA...${NC}"
if ! wget -q https://nextdns.io/ca -O NextDNS.cer 2>/dev/null; then
    handle_error "Failed to download NextDNS certificate"
fi
echo -e "${GREEN}Certificate downloaded successfully${NC}"

# Function to configure Firefox-based browser
configure_firefox_browser() {
    local browser_name="$1"
    local profile_dir="$2"
    local config_file="$3"
    
    if [ -d "$profile_dir" ]; then
        local profile=$(grep "Path=" "$profile_dir/profiles.ini" 2>/dev/null | head -n 1 | cut -d'=' -f2)
        if [ -n "$profile" ]; then
            echo -e "${YELLOW}Configuring $browser_name...${NC}"
            
            # Create cert9.db if it doesn't exist
            [ ! -f "$profile_dir/$profile/cert9.db" ] && touch "$profile_dir/$profile/cert9.db"
            
            # Import certificate
            certutil -A -n "NextDNS Root CA" -t "C,," -i NextDNS.cer -d "sql:$profile_dir/$profile" >/dev/null 2>&1 || \
                handle_error "Failed to import certificate to $browser_name"
            
            # Configure DNS over HTTPS and enterprise roots
            cat > "$profile_dir/$profile/$config_file" << EOL
user_pref("security.enterprise_roots.enabled", true);
user_pref("network.trr.mode", 3);
user_pref("network.trr.uri", "https://dns.nextdns.io");
user_pref("network.trr.custom_uri", "https://dns.nextdns.io");
user_pref("network.trr.bootstrapAddress", "45.90.28.0");
EOL
            echo -e "${GREEN}$browser_name configuration completed${NC}"
            return 0
        fi
    fi
    return 1
}

# Check for browsers
FIREFOX_FOUND=false
LIBREWOLF_FOUND=false
CHROME_FOUND=false

# Check for Firefox
if command -v firefox >/dev/null 2>&1; then
    FIREFOX_FOUND=true
    echo -e "${YELLOW}Firefox detected${NC}"
    FIREFOX_DIR="$HOME/.mozilla/firefox"
    configure_firefox_browser "Firefox" "$FIREFOX_DIR" "user.js" || \
        echo -e "${YELLOW}Warning: Could not configure Firefox - profile directory not found${NC}"
fi

# Check for LibreWolf
if command -v librewolf >/dev/null 2>&1; then
    LIBREWOLF_FOUND=true
    echo -e "${YELLOW}LibreWolf detected${NC}"
    LIBREWOLF_DIR="$HOME/.librewolf"
    configure_firefox_browser "LibreWolf" "$LIBREWOLF_DIR" "user.js" || \
        echo -e "${YELLOW}Warning: Could not configure LibreWolf - profile directory not found${NC}"
fi

# Configure Chrome/Chromium
configure_chrome() {
    local browser="$1"
    local config_dir="$2"
    
    echo -e "${YELLOW}Configuring $browser...${NC}"
    
    # Ensure the config directory exists
    mkdir -p "$config_dir"
    
    # Create or update the Secure DNS configuration
    cat > "$config_dir/Local State" << EOL
{
   "dns_over_https": {
      "templates": {
         "nextdns": "https://dns.nextdns.io"
      }
   },
   "dns_over_https_servers": [ "https://dns.nextdns.io" ],
   "doh_mode": 2
}
EOL
    
    echo -e "${GREEN}$browser DNS over HTTPS configured${NC}"
}

# Check for Chrome/Chromium
if command -v google-chrome >/dev/null 2>&1 || command -v chromium >/dev/null 2>&1; then
    CHROME_FOUND=true
    echo -e "${YELLOW}Chrome/Chromium detected${NC}"
    
    # Add certificate to system trust store
    echo -e "${YELLOW}Adding certificate to system trust store...${NC}"
    if [ -d "/usr/local/share/ca-certificates" ]; then
        cp NextDNS.cer /usr/local/share/ca-certificates/nextdns.crt
        update-ca-certificates >/dev/null 2>&1 || handle_error "Failed to update system certificates"
        echo -e "${GREEN}Certificate added to system trust store${NC}"
        
        # Configure Chrome if found
        if command -v google-chrome >/dev/null 2>&1; then
            configure_chrome "Chrome" "$HOME/.config/google-chrome"
        fi
        
        # Configure Chromium if found
        if command -v chromium >/dev/null 2>&1; then
            configure_chrome "Chromium" "$HOME/.config/chromium"
        fi
    else
        handle_error "System certificate directory not found"
    fi
fi

if ! $FIREFOX_FOUND && ! $LIBREWOLF_FOUND && ! $CHROME_FOUND; then
    handle_error "No supported browsers (Firefox, LibreWolf, or Chrome/Chromium) found"
fi

# Success message with browser-specific notes
echo -e "${GREEN}NextDNS Root CA installation completed successfully!${NC}"
echo
echo -e "${YELLOW}Configuration Summary:${NC}"
[ "$FIREFOX_FOUND" = true ] && echo -e "- Firefox: Certificate installed and DNS over HTTPS configured"
[ "$LIBREWOLF_FOUND" = true ] && echo -e "- LibreWolf: Certificate installed and DNS over HTTPS configured"
if [ "$CHROME_FOUND" = true ]; then
    echo -e "- Chrome/Chromium: Certificate installed in system store and DNS over HTTPS configured"
    if command -v google-chrome >/dev/null 2>&1; then
        echo -e "  - Chrome: DoH configuration added"
    fi
    if command -v chromium >/dev/null 2>&1; then
        echo -e "  - Chromium: DoH configuration added"
    fi
fi
echo
echo -e "${YELLOW}Notes:"
echo -e "1. Please ${RED}restart${NC} ${YELLOW}your browsers for changes to take effect"
echo -e "2. DNS over HTTPS has been ${GREEN}enabled${NC} ${YELLOW}for all detected browsers${NC}"
