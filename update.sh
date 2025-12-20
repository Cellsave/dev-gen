#!/bin/bash
# PDeploy Update Utility
# Checks and updates all installed libraries to their latest versions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}PDeploy Update Utility${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

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

echo -e "${CYAN}Checking installed libraries and available updates...${NC}"
echo ""

# Track updates
UPDATES_AVAILABLE=0
UPDATES_APPLIED=0
LIBRARIES_CHECKED=0

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to compare versions
version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# Docker Check
check_docker() {
    echo -e "${BLUE}[1/5]${NC} Checking Docker..."
    ((LIBRARIES_CHECKED++))
    
    if command_exists docker; then
        CURRENT_VERSION=$(docker --version | grep -oP '\d+\.\d+\.\d+' | head -1)
        echo -e "  ${GREEN}✓${NC} Docker installed: ${CYAN}$CURRENT_VERSION${NC}"
        
        # Check for updates (requires internet)
        echo -e "  ${YELLOW}ℹ${NC} Checking for Docker updates..."
        
        # Docker updates through apt
        sudo apt update -qq 2>/dev/null
        AVAILABLE=$(apt-cache policy docker-ce 2>/dev/null | grep Candidate | awk '{print $2}')
        
        if [ -n "$AVAILABLE" ]; then
            echo -e "  ${CYAN}→${NC} Latest available: $AVAILABLE"
            if [ "$CURRENT_VERSION" != "$AVAILABLE" ]; then
                echo -e "  ${YELLOW}⚠${NC} Update available!"
                ((UPDATES_AVAILABLE++))
                return 1
            else
                echo -e "  ${GREEN}✓${NC} Already up to date"
            fi
        else
            echo -e "  ${BLUE}ℹ${NC} Unable to check for updates (Docker not from apt)"
        fi
    else
        echo -e "  ${YELLOW}⊘${NC} Docker not installed"
    fi
    return 0
}

# Node.js Check
check_nodejs() {
    echo ""
    echo -e "${BLUE}[2/5]${NC} Checking Node.js..."
    ((LIBRARIES_CHECKED++))
    
    if command_exists node; then
        CURRENT_VERSION=$(node --version)
        echo -e "  ${GREEN}✓${NC} Node.js installed: ${CYAN}$CURRENT_VERSION${NC}"
        
        # Check npm
        if command_exists npm; then
            NPM_VERSION=$(npm --version)
            echo -e "  ${GREEN}✓${NC} npm installed: ${CYAN}$NPM_VERSION${NC}"
            
            # Check for npm updates
            echo -e "  ${YELLOW}ℹ${NC} Checking for npm updates..."
            LATEST_NPM=$(npm view npm version 2>/dev/null)
            if [ -n "$LATEST_NPM" ]; then
                echo -e "  ${CYAN}→${NC} Latest npm: $LATEST_NPM"
                if [ "$NPM_VERSION" != "$LATEST_NPM" ]; then
                    echo -e "  ${YELLOW}⚠${NC} npm update available!"
                    ((UPDATES_AVAILABLE++))
                    return 1
                else
                    echo -e "  ${GREEN}✓${NC} npm up to date"
                fi
            fi
        fi
        
        # Check for Node.js updates
        echo -e "  ${YELLOW}ℹ${NC} Checking for Node.js updates..."
        echo -e "  ${BLUE}ℹ${NC} Current: $CURRENT_VERSION (use nvm or NodeSource for updates)"
    else
        echo -e "  ${YELLOW}⊘${NC} Node.js not installed"
    fi
    return 0
}

# SQLite Check
check_sqlite() {
    echo ""
    echo -e "${BLUE}[3/5]${NC} Checking SQLite..."
    ((LIBRARIES_CHECKED++))
    
    if command_exists sqlite3; then
        CURRENT_VERSION=$(sqlite3 --version | awk '{print $1}')
        echo -e "  ${GREEN}✓${NC} SQLite installed: ${CYAN}$CURRENT_VERSION${NC}"
        
        # Check for updates
        sudo apt update -qq 2>/dev/null
        AVAILABLE=$(apt-cache policy sqlite3 2>/dev/null | grep Candidate | awk '{print $2}')
        
        if [ -n "$AVAILABLE" ]; then
            echo -e "  ${CYAN}→${NC} Latest available: $AVAILABLE"
            INSTALLED=$(apt-cache policy sqlite3 2>/dev/null | grep Installed | awk '{print $2}')
            if [ "$INSTALLED" != "$AVAILABLE" ]; then
                echo -e "  ${YELLOW}⚠${NC} Update available!"
                ((UPDATES_AVAILABLE++))
                return 1
            else
                echo -e "  ${GREEN}✓${NC} Already up to date"
            fi
        fi
    else
        echo -e "  ${YELLOW}⊘${NC} SQLite not installed"
    fi
    return 0
}

# React/Frontend Check
check_react() {
    echo ""
    echo -e "${BLUE}[4/5]${NC} Checking React environment..."
    ((LIBRARIES_CHECKED++))
    
    REACT_DIR="/opt/frontend-apps/react-app"
    if [ -d "$REACT_DIR" ]; then
        echo -e "  ${GREEN}✓${NC} React project found: $REACT_DIR"
        
        if [ -f "$REACT_DIR/package.json" ]; then
            cd "$REACT_DIR"
            
            # Check for outdated packages
            echo -e "  ${YELLOW}ℹ${NC} Checking for package updates..."
            OUTDATED=$(npm outdated 2>/dev/null | wc -l)
            
            if [ "$OUTDATED" -gt 1 ]; then
                echo -e "  ${YELLOW}⚠${NC} $((OUTDATED-1)) packages have updates available"
                echo -e "  ${CYAN}→${NC} Run 'npm outdated' in $REACT_DIR for details"
                ((UPDATES_AVAILABLE++))
                cd "$SCRIPT_DIR"
                return 1
            else
                echo -e "  ${GREEN}✓${NC} All packages up to date"
            fi
            cd "$SCRIPT_DIR"
        fi
    else
        echo -e "  ${YELLOW}⊘${NC} React project not found"
    fi
    return 0
}

# System packages check
check_system() {
    echo ""
    echo -e "${BLUE}[5/5]${NC} Checking system packages..."
    ((LIBRARIES_CHECKED++))
    
    echo -e "  ${YELLOW}ℹ${NC} Updating package lists..."
    sudo apt update -qq 2>/dev/null
    
    # Check for upgradable packages
    UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -v "Listing" | wc -l)
    
    if [ "$UPGRADABLE" -gt 0 ]; then
        echo -e "  ${YELLOW}⚠${NC} $UPGRADABLE system packages can be upgraded"
        ((UPDATES_AVAILABLE++))
        return 1
    else
        echo -e "  ${GREEN}✓${NC} All system packages up to date"
    fi
    return 0
}

# Run all checks
check_docker
DOCKER_UPDATE=$?

check_nodejs
NODE_UPDATE=$?

check_sqlite
SQLITE_UPDATE=$?

check_react
REACT_UPDATE=$?

check_system
SYSTEM_UPDATE=$?

# Summary
echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${CYAN}Update Summary${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo "Libraries checked: $LIBRARIES_CHECKED"
echo "Updates available: $UPDATES_AVAILABLE"
echo ""

if [ "$UPDATES_AVAILABLE" -gt 0 ]; then
    echo -e "${YELLOW}Updates are available!${NC}"
    echo ""
    read -p "Do you want to apply updates now? (y/N) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${GREEN}Applying updates...${NC}"
        echo ""
        
        # Update npm if needed
        if [ "$NODE_UPDATE" -eq 1 ] && command_exists npm; then
            echo -e "${BLUE}Updating npm...${NC}"
            sudo npm install -g npm@latest
            ((UPDATES_APPLIED++))
        fi
        
        # Update SQLite if needed
        if [ "$SQLITE_UPDATE" -eq 1 ]; then
            echo -e "${BLUE}Updating SQLite...${NC}"
            sudo apt install --only-upgrade sqlite3 -y
            ((UPDATES_APPLIED++))
        fi
        
        # Update React packages if needed
        if [ "$REACT_UPDATE" -eq 1 ] && [ -d "/opt/frontend-apps/react-app" ]; then
            echo -e "${BLUE}Updating React packages...${NC}"
            cd "/opt/frontend-apps/react-app"
            npm update
            ((UPDATES_APPLIED++))
            cd "$SCRIPT_DIR"
        fi
        
        # Update system packages if needed
        if [ "$SYSTEM_UPDATE" -eq 1 ]; then
            echo -e "${BLUE}Updating system packages...${NC}"
            sudo apt upgrade -y
            ((UPDATES_APPLIED++))
        fi
        
        # Update Docker if needed
        if [ "$DOCKER_UPDATE" -eq 1 ]; then
            echo -e "${BLUE}Updating Docker...${NC}"
            sudo apt install --only-upgrade docker-ce docker-ce-cli containerd.io -y
            ((UPDATES_APPLIED++))
        fi
        
        echo ""
        echo -e "${GREEN}✓ Updates applied: $UPDATES_APPLIED${NC}"
        echo ""
        echo -e "${YELLOW}Note: You may need to restart services or log out/in for changes to take effect.${NC}"
    else
        echo -e "${YELLOW}Updates cancelled. Run this script again to apply updates.${NC}"
    fi
else
    echo -e "${GREEN}✓ All libraries are up to date!${NC}"
fi

echo ""
echo -e "${BLUE}================================${NC}"
echo ""
