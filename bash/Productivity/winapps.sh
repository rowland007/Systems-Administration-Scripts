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