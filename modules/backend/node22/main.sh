#!/bin/bash
# Node.js 22 with Express and TypeScript Installation Module for PDeploy
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
    output_json "running" 25 "Running pre-installation checks" "Checking for existing Node.js installation"
    
    # Check if Node.js 22 already installed
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        if [[ "$NODE_VERSION" == v22* ]]; then
            output_json "success" 100 "Node.js 22 already installed" "$NODE_VERSION with npm $(npm --version)"
            exit 0
        else
            output_json "running" 25 "Different Node.js version detected" "Will install Node.js 22 alongside $NODE_VERSION"
        fi
    fi
    
    output_json "success" 25 "Pre-checks passed" "Ready to install Node.js 22"
}

# Install function
install() {
    output_json "running" 50 "Installing Node.js 22" "Downloading and installing Node.js 22.x"
    
    # Install prerequisites
    sudo apt-get update -qq
    sudo apt-get install -y -qq ca-certificates curl gnupg
    
    # Download and run NodeSource setup script for Node.js 22
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    
    # Install Node.js
    sudo apt-get install -y -qq nodejs
    
    # Install global packages: TypeScript and Express generator
    sudo npm install -g typescript express-generator ts-node @types/node @types/express
    
    output_json "success" 50 "Node.js 22 installed" "Node.js and npm installed successfully"
}

# Configure function
configure() {
    output_json "running" 75 "Configuring Node.js environment" "Setting up PATH and npm global directory"
    
    # Create npm global directory for user (to avoid sudo for global installs)
    mkdir -p ~/.npm-global
    npm config set prefix '~/.npm-global'
    
    # Add to PATH if not already there
    if ! grep -q "npm-global/bin" ~/.bashrc; then
        echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
    fi
    
    output_json "success" 75 "Node.js configured" "Environment variables set"
}

# Validate function
validate() {
    output_json "running" 90 "Validating installation" "Testing Node.js, npm, TypeScript, and Express"
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        output_json "error" 90 "Node.js command not found" "Installation may have failed"
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    
    # Check TypeScript
    if ! command -v tsc &> /dev/null; then
        output_json "error" 90 "TypeScript not found" "TypeScript installation may have failed"
        exit 1
    fi
    
    TSC_VERSION=$(tsc --version)
    
    # Check Express generator
    if ! command -v express &> /dev/null; then
        output_json "warning" 95 "Express generator not in PATH" "May need to restart shell or use npx express"
    fi
    
    # Create a simple test
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    
    # Test Node.js execution
    echo "console.log('test');" | node > /dev/null 2>&1
    
    # Test TypeScript compilation
    echo "const test: string = 'hello';" > test.ts
    tsc test.ts > /dev/null 2>&1
    
    cd - > /dev/null
    rm -rf "$TEST_DIR"
    
    output_json "success" 100 "Node.js 22 validated" "Node $NODE_VERSION, npm $NPM_VERSION, TypeScript installed and working"
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
