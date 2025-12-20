#!/bin/bash
# PDeploy Quick Installation Script
# Downloads and sets up PDeploy on Ubuntu VM

set -e

echo "================================"
echo "PDeploy Installation Script"
echo "================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on Ubuntu
if [ ! -f /etc/os-release ]; then
    echo -e "${RED}Error: Cannot detect OS${NC}"
    exit 1
fi

. /etc/os-release
if [[ "$ID" != "ubuntu" ]]; then
    echo -e "${RED}Error: This script requires Ubuntu${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Ubuntu detected: $VERSION${NC}"

# Check for Python 3
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is required but not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Python 3 detected: $(python3 --version)${NC}"

# Create installation directory
INSTALL_DIR="$HOME/pdeploy"
echo ""
echo "Installation directory: $INSTALL_DIR"

if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Warning: Directory already exists${NC}"
    read -p "Do you want to overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 1
    fi
    rm -rf "$INSTALL_DIR"
fi

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo ""
echo "Downloading PDeploy files from GitHub..."

# Download main files
GITHUB_RAW="https://raw.githubusercontent.com/Cellsave/dev-gen/main"

# Download pdeploy.html
if curl -fsSL "$GITHUB_RAW/pdeploy.html" -o pdeploy.html; then
    echo -e "${GREEN}✓ Downloaded pdeploy.html${NC}"
else
    echo -e "${RED}✗ Failed to download pdeploy.html${NC}"
    exit 1
fi

# Download orchestrator
if curl -fsSL "$GITHUB_RAW/orchestrator.py" -o orchestrator.py; then
    chmod +x orchestrator.py
    echo -e "${GREEN}✓ Downloaded orchestrator.py${NC}"
else
    echo -e "${RED}✗ Failed to download orchestrator.py${NC}"
    exit 1
fi

# Download modules
echo ""
echo "Downloading installation modules..."

mkdir -p modules/{backend,frontend,server}

# Backend modules
for module in docker node22 sqlite; do
    mkdir -p "modules/backend/$module"
    if curl -fsSL "$GITHUB_RAW/modules/backend/$module/main.sh" -o "modules/backend/$module/main.sh"; then
        chmod +x "modules/backend/$module/main.sh"
        echo -e "${GREEN}✓ Downloaded $module module${NC}"
    else
        echo -e "${YELLOW}⚠ Failed to download $module module${NC}"
    fi
done

# Frontend modules
for module in react18; do
    mkdir -p "modules/frontend/$module"
    if curl -fsSL "$GITHUB_RAW/modules/frontend/$module/main.sh" -o "modules/frontend/$module/main.sh"; then
        chmod +x "modules/frontend/$module/main.sh"
        echo -e "${GREEN}✓ Downloaded $module module${NC}"
    else
        echo -e "${YELLOW}⚠ Failed to download $module module${NC}"
    fi
done

# Server modules
for module in linux-tools; do
    mkdir -p "modules/server/$module"
    if curl -fsSL "$GITHUB_RAW/modules/server/$module/main.sh" -o "modules/server/$module/main.sh"; then
        chmod +x "modules/server/$module/main.sh"
        echo -e "${GREEN}✓ Downloaded $module module${NC}"
    else
        echo -e "${YELLOW}⚠ Failed to download $module module${NC}"
    fi
done

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "PDeploy has been installed to: $INSTALL_DIR"
echo ""
echo "To start PDeploy:"
echo "  1. cd $INSTALL_DIR"
echo "  2. python3 -m http.server 8000"
echo "  3. Open browser to: http://localhost:8000/pdeploy.html"
echo ""
echo "For remote access:"
echo "  Replace 'localhost' with your server IP address"
echo ""
echo -e "${YELLOW}Note: Ensure firewall allows port 8000 if accessing remotely${NC}"
echo ""
