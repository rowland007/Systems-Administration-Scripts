#!/bin/bash

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common.sh"

# Display Docker logo
display_logo "Docker" "Build, Share, and Run Any App, Anywhere"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or use sudo.${NC}"
    exit 1
fi

# Initialize variables
OS=""
PKG_MANAGER=""

# Detect OS and package manager
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    
    case $OS in
        "ubuntu"|"debian")
            export PKG_MANAGER="apt"
            ;;
        "fedora"|"centos"|"rhel")
            export PKG_MANAGER="dnf"
            ;;
        *)
            echo -e "${RED}Unsupported operating system: $OS${NC}"
            echo -e "${YELLOW}This script only supports Ubuntu, Debian, Fedora, CentOS, and RHEL.${NC}"
            exit 1
            ;;
    esac
else
    echo -e "${RED}Cannot determine operating system (no /etc/os-release file)${NC}"
    exit 1
fi

echo -e "${GREEN}Detected OS: $OS${NC}"
echo -e "${GREEN}Package Manager: $PKG_MANAGER${NC}"

# Add Docker repository based on package manager
case $PKG_MANAGER in
    "apt")
        # Add Docker's official GPG key
        apt update
        apt install -y ca-certificates curl
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/$OS/gpg -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc

        # Add the repository to Apt sources
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$OS \
          $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" | \
          tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt update
        ;;
    
    "dnf")
        # Add Docker repository for RHEL-based systems
        dnf -y install dnf-plugins-core
        dnf config-manager --add-repo https://download.docker.com/linux/$OS/docker-ce.repo
        ;;
    
    *)
        echo -e "${RED}Docker repository setup not implemented for $OS${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}Docker repository setup completed for $OS${NC}"

# Install Docker packages based on package manager
echo -e "${YELLOW}Installing Docker packages...${NC}"
case $PKG_MANAGER in
    "apt")
        apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        systemctl start docker
        ;;
    "dnf")
        dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        systemctl enable --now docker
        ;;
esac

echo -e "${YELLOW}Testing Docker installation...${NC}"
if ! docker run hello-world; then
    echo -e "${RED}Docker test failed. Please check the error messages above.${NC}"
    exit 1
fi

echo -e "${GREEN}Docker installation completed successfully!${NC}"