#!/bin/bash
# PDeploy Cleanup Utility
# Removes temporary directories and files created during installation
# Keeps pdeploy.html and core structure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}PDeploy Cleanup Utility${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo -e "${YELLOW}This will remove temporary files and directories created by PDeploy.${NC}"
echo -e "${YELLOW}The following will be preserved:${NC}"
echo "  - pdeploy.html"
echo "  - orchestrator.py"
echo "  - modules/ (installation scripts)"
echo "  - README.md, LICENSE, CONTRIBUTING.md"
echo ""
echo -e "${RED}The following will be removed:${NC}"
echo "  - /opt/frontend-apps/ (React projects)"
echo "  - ~/databases/ (SQLite test databases)"
echo "  - ~/.npm-global/ (npm global packages)"
echo "  - Build artifacts and temporary files"
echo ""

read -p "Do you want to continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cleanup cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}Starting cleanup...${NC}"
echo ""

# Track what was cleaned
CLEANED_COUNT=0
CLEANED_SIZE=0

# Function to safely remove directory
safe_remove() {
    local dir=$1
    local description=$2
    
    if [ -d "$dir" ]; then
        SIZE=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo -e "  ${YELLOW}Removing:${NC} $description ($SIZE)"
        sudo rm -rf "$dir" 2>/dev/null || rm -rf "$dir" 2>/dev/null
        if [ ! -d "$dir" ]; then
            echo -e "  ${GREEN}✓ Removed${NC}"
            ((CLEANED_COUNT++))
        else
            echo -e "  ${RED}✗ Failed to remove${NC}"
        fi
    else
        echo -e "  ${BLUE}ℹ${NC} $description not found (already clean)"
    fi
}

# Function to clean files matching pattern
clean_pattern() {
    local pattern=$1
    local description=$2
    
    COUNT=$(find . -name "$pattern" 2>/dev/null | wc -l)
    if [ "$COUNT" -gt 0 ]; then
        echo -e "  ${YELLOW}Removing:${NC} $description ($COUNT files)"
        find . -name "$pattern" -delete 2>/dev/null
        echo -e "  ${GREEN}✓ Removed${NC}"
        ((CLEANED_COUNT++))
    fi
}

echo -e "${BLUE}[1/6]${NC} Cleaning frontend applications..."
safe_remove "/opt/frontend-apps" "React applications directory"

echo ""
echo -e "${BLUE}[2/6]${NC} Cleaning database files..."
safe_remove "$HOME/databases" "SQLite databases directory"

echo ""
echo -e "${BLUE}[3/6]${NC} Cleaning npm global packages..."
safe_remove "$HOME/.npm-global" "npm global directory"

echo ""
echo -e "${BLUE}[4/6]${NC} Cleaning build artifacts..."
clean_pattern "*.pyc" "Python bytecode files"
clean_pattern "__pycache__" "Python cache directories"
clean_pattern "node_modules" "Node.js modules (if any)"
clean_pattern "*.log" "Log files"

echo ""
echo -e "${BLUE}[5/6]${NC} Cleaning temporary files..."
clean_pattern "*.tmp" "Temporary files"
clean_pattern ".DS_Store" "macOS metadata"
clean_pattern "Thumbs.db" "Windows thumbnails"

echo ""
echo -e "${BLUE}[6/6]${NC} Cleaning package manager cache..."
if [ -d "$HOME/.npm/_logs" ]; then
    echo -e "  ${YELLOW}Removing:${NC} npm logs"
    rm -rf "$HOME/.npm/_logs" 2>/dev/null
    echo -e "  ${GREEN}✓ Removed${NC}"
fi

# Clean apt cache if running as root or with sudo
if [ "$EUID" -eq 0 ] || sudo -n true 2>/dev/null; then
    echo ""
    echo -e "${BLUE}[Bonus]${NC} Cleaning system package cache..."
    echo -e "  ${YELLOW}Running:${NC} apt autoremove and autoclean"
    sudo apt autoremove -y -qq 2>/dev/null
    sudo apt autoclean -y -qq 2>/dev/null
    echo -e "  ${GREEN}✓ System cache cleaned${NC}"
fi

echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}Cleanup Complete!${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo "Summary:"
echo "  - Items cleaned: $CLEANED_COUNT"
echo "  - PDeploy core files preserved"
echo ""
echo -e "${GREEN}Your PDeploy installation is now clean and ready.${NC}"
echo ""

# Show what's left
echo "Remaining PDeploy files:"
ls -lh pdeploy.html orchestrator.py 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo ""
