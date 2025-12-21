#!/bin/bash
#
# PDeploy Secure Installation Script (Private Repository)
# Version: 1.0.0-private
# Supports: Private GitHub repositories with token authentication
#
# Usage:
#   export PDEPLOY_VERSION=v1.0.0
#   export GITHUB_TOKEN=your_token_here
#   bash install-secure.sh
#
# Or with interactive token input:
#   export PDEPLOY_VERSION=v1.0.0
#   bash install-secure.sh
#

set -e

# Configuration
GITHUB_REPO="${GITHUB_REPO:-Cellsave/dev-gen}"
VERSION="${PDEPLOY_VERSION:-v1.0.0}"
INSTALL_DIR="${PDEPLOY_INSTALL_DIR:-$HOME/pdeploy}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_prompt() { echo -e "${BLUE}[INPUT]${NC} $*"; }

# Error handler
error_exit() {
    log_error "$1"
    log_error "Installation failed. Please check the error message above."
    exit 1
}

# Request GitHub token if not provided
request_github_token() {
    if [ -z "$GITHUB_TOKEN" ]; then
        echo ""
        echo "================================"
        echo "GitHub Token Required"
        echo "================================"
        echo ""
        echo "This repository is private and requires authentication."
        echo ""
        echo "To generate a GitHub Personal Access Token:"
        echo "  1. Go to: https://github.com/settings/tokens"
        echo "  2. Click 'Generate new token' → 'Generate new token (classic)'"
        echo "  3. Set token name: 'PDeploy Installation'"
        echo "  4. Select scope: 'repo' (Full control of private repositories)"
        echo "  5. Click 'Generate token'"
        echo "  6. Copy the token (you won't see it again!)"
        echo ""
        log_prompt "Enter your GitHub Personal Access Token:"
        read -s GITHUB_TOKEN
        echo ""
        
        if [ -z "$GITHUB_TOKEN" ]; then
            error_exit "GitHub token is required for private repository access"
        fi
        
        log_info "Token received (hidden for security)"
    else
        log_info "Using GitHub token from environment variable"
    fi
}

# Validate GitHub token
validate_github_token() {
    log_info "Validating GitHub token..."
    
    local test_url="https://api.github.com/repos/${GITHUB_REPO}"
    local response=$(curl -s -w "%{http_code}" -H "Authorization: token ${GITHUB_TOKEN}" "$test_url" -o /dev/null)
    
    if [ "$response" = "200" ]; then
        log_info "✓ Token validated successfully"
        return 0
    elif [ "$response" = "401" ]; then
        error_exit "Invalid GitHub token. Please check your token and try again."
    elif [ "$response" = "404" ]; then
        error_exit "Repository not found or token doesn't have access to ${GITHUB_REPO}"
    else
        error_exit "Failed to validate token (HTTP $response)"
    fi
}

# Download file with authentication
download_with_retry() {
    local url="$1"
    local output="$2"
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "Downloading: $(basename "$output") (attempt $attempt/$max_attempts)"
        
        if curl -fsSL --max-time 30 \
            -H "Authorization: token ${GITHUB_TOKEN}" \
            -H "Accept: application/vnd.github.v3.raw" \
            "$url" -o "$output"; then
            log_info "✓ Downloaded: $(basename "$output")"
            return 0
        fi
        
        log_warn "Download failed, retrying in 2 seconds..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    error_exit "Failed to download $(basename "$output") after $max_attempts attempts"
}

# Verify file checksum
verify_checksum() {
    local file="$1"
    local expected="$2"
    
    if [ -z "$expected" ]; then
        log_warn "No checksum provided for $file, skipping verification"
        return 0
    fi
    
    log_info "Verifying checksum: $(basename "$file")"
    
    if ! command -v sha256sum &> /dev/null; then
        log_warn "sha256sum not found, skipping checksum verification"
        return 0
    fi
    
    local actual=$(sha256sum "$file" | awk '{print $1}')
    
    if [ "$actual" = "$expected" ]; then
        log_info "✓ Checksum verified: $(basename "$file")"
        return 0
    else
        log_error "Checksum mismatch for $file"
        log_error "Expected: $expected"
        log_error "Actual:   $actual"
        return 1
    fi
}

# Check system requirements
check_system() {
    log_info "Checking system requirements..."
    
    # Check OS
    if [ ! -f /etc/os-release ]; then
        error_exit "Cannot determine OS. /etc/os-release not found."
    fi
    
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        log_warn "This script is designed for Ubuntu. Detected: $ID"
        log_warn "Installation may not work correctly."
    else
        log_info "✓ Ubuntu detected: $VERSION_ID"
    fi
    
    # Check Python 3
    if ! command -v python3 &> /dev/null; then
        error_exit "Python 3 is required but not installed. Install with: sudo apt install python3"
    fi
    log_info "✓ Python 3 detected: $(python3 --version | awk '{print $2}')"
    
    # Check curl
    if ! command -v curl &> /dev/null; then
        error_exit "curl is required but not installed. Install with: sudo apt install curl"
    fi
    log_info "✓ curl detected"
    
    # Check sha256sum
    if ! command -v sha256sum &> /dev/null; then
        log_warn "sha256sum not found. Checksum verification will be skipped."
    else
        log_info "✓ sha256sum detected"
    fi
    
    # Check disk space (at least 100MB)
    local available=$(df -m "$HOME" | tail -1 | awk '{print $4}')
    if [ "$available" -lt 100 ]; then
        log_warn "Low disk space: ${available}MB available. At least 100MB recommended."
    else
        log_info "✓ Sufficient disk space: ${available}MB available"
    fi
}

# Create backup of existing installation
create_backup() {
    if [ -d "$INSTALL_DIR" ]; then
        local backup_dir="${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Existing installation found. Creating backup: $backup_dir"
        cp -r "$INSTALL_DIR" "$backup_dir"
        log_info "✓ Backup created: $backup_dir"
    fi
}

# Download and parse manifest
download_manifest() {
    local manifest_url="https://raw.githubusercontent.com/${GITHUB_REPO}/${VERSION}/manifest-${VERSION}.json"
    local manifest_file="/tmp/pdeploy-manifest.json"
    
    log_info "Downloading manifest file..."
    
    if ! download_with_retry "$manifest_url" "$manifest_file"; then
        log_warn "Manifest file not available, proceeding without checksum verification"
        return 1
    fi
    
    log_info "✓ Manifest downloaded"
    echo "$manifest_file"
}

# Install PDeploy files
install_files() {
    local manifest_file="$1"
    local base_url="https://raw.githubusercontent.com/${GITHUB_REPO}/${VERSION}"
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/modules/backend/docker"
    mkdir -p "$INSTALL_DIR/modules/backend/node22"
    mkdir -p "$INSTALL_DIR/modules/backend/sqlite"
    mkdir -p "$INSTALL_DIR/modules/frontend/react18"
    mkdir -p "$INSTALL_DIR/modules/server/linux-tools"
    
    # Files to download
    declare -A files=(
        ["pdeploy.html"]=""
        ["orchestrator.py"]=""
        ["install.sh"]=""
        ["cleanup.sh"]=""
        ["update.sh"]=""
        ["modules/backend/docker/main.sh"]=""
        ["modules/backend/node22/main.sh"]=""
        ["modules/backend/sqlite/main.sh"]=""
        ["modules/frontend/react18/main.sh"]=""
        ["modules/server/linux-tools/main.sh"]=""
    )
    
    # Load checksums from manifest if available
    if [ -n "$manifest_file" ] && [ -f "$manifest_file" ]; then
        log_info "Loading checksums from manifest..."
        for file in "${!files[@]}"; do
            checksum=$(python3 -c "import json; print(json.load(open('$manifest_file')).get('files', {}).get('$file', ''))" 2>/dev/null || echo "")
            files["$file"]="$checksum"
        done
    fi
    
    # Download and verify each file
    local failed=0
    for file in "${!files[@]}"; do
        local url="${base_url}/${file}"
        local output="${INSTALL_DIR}/${file}"
        local checksum="${files[$file]}"
        
        if ! download_with_retry "$url" "$output"; then
            log_error "Failed to download: $file"
            failed=1
            continue
        fi
        
        if [ -n "$checksum" ]; then
            if ! verify_checksum "$output" "$checksum"; then
                log_error "Checksum verification failed: $file"
                failed=1
                continue
            fi
        fi
    done
    
    if [ $failed -eq 1 ]; then
        error_exit "One or more files failed to download or verify"
    fi
    
    # Make scripts executable
    log_info "Setting executable permissions..."
    chmod +x "$INSTALL_DIR/orchestrator.py" 2>/dev/null || true
    chmod +x "$INSTALL_DIR/install.sh" 2>/dev/null || true
    chmod +x "$INSTALL_DIR/cleanup.sh" 2>/dev/null || true
    chmod +x "$INSTALL_DIR/update.sh" 2>/dev/null || true
    chmod +x "$INSTALL_DIR"/modules/*/main.sh 2>/dev/null || true
    chmod +x "$INSTALL_DIR"/modules/*/*/main.sh 2>/dev/null || true
    
    log_info "✓ All files installed successfully"
}

# Main installation flow
main() {
    echo ""
    echo "================================"
    echo "PDeploy Secure Installation"
    echo "Version: $VERSION"
    echo "Repository: $GITHUB_REPO (Private)"
    echo "================================"
    echo ""
    
    # Request and validate GitHub token
    request_github_token
    validate_github_token
    
    # System checks
    check_system
    
    # Create backup if needed
    create_backup
    
    # Download manifest
    manifest_file=$(download_manifest) || manifest_file=""
    
    # Install files
    install_files "$manifest_file"
    
    # Success message
    echo ""
    echo "================================"
    echo "Installation Complete!"
    echo "================================"
    echo ""
    echo "PDeploy has been installed to: $INSTALL_DIR"
    echo ""
    echo "Next steps:"
    echo "  1. cd $INSTALL_DIR"
    echo "  2. python3 -m http.server 8000"
    echo "  3. Open browser to: http://localhost:8000/pdeploy.html"
    echo ""
    echo "Security Note:"
    echo "  - This installation used version: $VERSION"
    echo "  - Checksum verification: $([ -n "$manifest_file" ] && echo "ENABLED" || echo "SKIPPED")"
    echo "  - Repository access: AUTHENTICATED"
    echo ""
    echo "For production deployment, see PRODUCTION_DEPLOYMENT_GUIDE.md"
    echo ""
}

# Run main function
main
