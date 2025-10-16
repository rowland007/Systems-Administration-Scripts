#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or use sudo."
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
            echo "Unsupported operating system: $OS. This script only supports Ubuntu, Debian, Fedora, CentOS, and RHEL."
            exit 1
            ;;
    esac
else
    echo "Cannot determine operating system (no /etc/os-release file)"
    exit 1
fi

echo "Detected OS: $OS"
echo "Package Manager: $PKG_MANAGER"

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
        echo "Docker repository setup not implemented for $OS"
        exit 1
        ;;
esac

echo "Docker repository setup completed for $OS"

# Install Docker packages based on package manager
echo "Installing Docker packages..."
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

echo "Testing Docker installation..."
docker run hello-world

echo "Docker installation completed successfully!"