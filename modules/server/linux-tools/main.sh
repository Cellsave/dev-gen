#!/bin/bash
# Linux Tools Installation Module for PDeploy
# Installs essential server tools, security packages, and utilities
# Standardized module following PDeploy architecture

set -e

# Output JSON status
output_json() {
    local status=$1
    local progress=$2
    local message=$3
    local logs=$4
    echo "{\"status\":\"$status\",\"progress\":$progress,\"message\":\"$message\",\"logs\":\"$logs\"}"
}

# Pre-check function
pre_check() {
    output_json "running" 20 "Running pre-installation checks" "Verifying Ubuntu system"
    
    # Check if Ubuntu
    if [ ! -f /etc/os-release ]; then
        output_json "error" 0 "Cannot detect OS" "Missing /etc/os-release"
        exit 1
    fi
    
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        output_json "error" 0 "Unsupported OS" "This module requires Ubuntu"
        exit 1
    fi
    
    output_json "success" 20 "Pre-checks passed" "Ubuntu $VERSION_ID detected"
}

# Install function
install() {
    output_json "running" 40 "Updating package lists" "Running apt update"
    
    # Update package lists
    sudo apt-get update -qq
    
    output_json "running" 50 "Upgrading existing packages" "Running apt upgrade"
    
    # Upgrade existing packages
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq
    
    output_json "running" 60 "Installing essential tools" "Installing development and utility packages"
    
    # Install essential development and utility tools
    sudo apt-get install -y -qq \
        curl \
        wget \
        git \
        unzip \
        zip \
        tar \
        build-essential \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        htop \
        vim \
        nano \
        net-tools \
        dnsutils \
        iputils-ping \
        traceroute \
        tcpdump \
        screen \
        tmux \
        jq \
        tree
    
    output_json "running" 70 "Installing security tools" "Installing UFW and Fail2ban"
    
    # Install security tools
    sudo apt-get install -y -qq ufw fail2ban
    
    output_json "success" 75 "Installation complete" "All packages installed successfully"
}

# Configure function
configure() {
    output_json "running" 80 "Configuring firewall" "Setting up UFW rules"
    
    # Configure UFW (Uncomplicated Firewall)
    # Allow SSH
    sudo ufw allow ssh > /dev/null 2>&1 || true
    sudo ufw allow 22/tcp > /dev/null 2>&1 || true
    
    # Allow HTTP and HTTPS
    sudo ufw allow http > /dev/null 2>&1 || true
    sudo ufw allow https > /dev/null 2>&1 || true
    sudo ufw allow 80/tcp > /dev/null 2>&1 || true
    sudo ufw allow 443/tcp > /dev/null 2>&1 || true
    
    # Enable UFW (with --force to avoid interactive prompt)
    echo "y" | sudo ufw enable > /dev/null 2>&1 || true
    
    output_json "running" 85 "Configuring Fail2ban" "Setting up intrusion prevention"
    
    # Configure Fail2ban
    sudo systemctl enable fail2ban > /dev/null 2>&1
    sudo systemctl start fail2ban > /dev/null 2>&1
    
    # Create basic Fail2ban configuration for SSH
    sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF
    
    sudo systemctl restart fail2ban > /dev/null 2>&1
    
    output_json "success" 90 "Configuration complete" "Firewall and security services configured"
}

# Validate function
validate() {
    output_json "running" 95 "Validating installation" "Checking installed packages and services"
    
    # Check essential commands
    MISSING_COMMANDS=""
    for cmd in curl wget git vim htop ufw fail2ban-client; do
        if ! command -v $cmd &> /dev/null; then
            MISSING_COMMANDS="$MISSING_COMMANDS $cmd"
        fi
    done
    
    if [ -n "$MISSING_COMMANDS" ]; then
        output_json "error" 95 "Validation failed" "Missing commands:$MISSING_COMMANDS"
        exit 1
    fi
    
    # Check UFW status
    UFW_STATUS=$(sudo ufw status | head -n 1)
    
    # Check Fail2ban status
    FAIL2BAN_STATUS=$(sudo systemctl is-active fail2ban)
    
    # Collect version information
    VERSIONS="curl $(curl --version | head -n 1), git $(git --version), vim $(vim --version | head -n 1)"
    
    output_json "success" 100 "Linux Tools validated" "All essential tools installed. UFW: $UFW_STATUS, Fail2ban: $FAIL2BAN_STATUS"
}

# Main execution
main() {
    pre_check
    install
    configure
    validate
}

# Run main function
main
