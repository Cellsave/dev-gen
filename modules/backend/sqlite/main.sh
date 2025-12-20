#!/bin/bash
# SQLite Installation Module for PDeploy
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
    output_json "running" 25 "Running pre-installation checks" "Checking for existing SQLite installation"
    
    # Check if SQLite already installed
    if command -v sqlite3 &> /dev/null; then
        SQLITE_VERSION=$(sqlite3 --version | awk '{print $1}')
        output_json "success" 100 "SQLite already installed" "SQLite version $SQLITE_VERSION"
        exit 0
    fi
    
    output_json "success" 25 "Pre-checks passed" "Ready to install SQLite"
}

# Install function
install() {
    output_json "running" 50 "Installing SQLite" "Installing SQLite3 package"
    
    # Update package index
    sudo apt-get update -qq
    
    # Install SQLite
    sudo apt-get install -y -qq sqlite3 libsqlite3-dev
    
    output_json "success" 50 "SQLite installed" "SQLite3 and development libraries installed"
}

# Configure function
configure() {
    output_json "running" 75 "Configuring SQLite" "Setting up SQLite environment"
    
    # Create a directory for SQLite databases if it doesn't exist
    mkdir -p ~/databases
    
    # Set proper permissions
    chmod 755 ~/databases
    
    output_json "success" 75 "SQLite configured" "Database directory created at ~/databases"
}

# Validate function
validate() {
    output_json "running" 90 "Validating installation" "Testing SQLite functionality"
    
    # Check SQLite command
    if ! command -v sqlite3 &> /dev/null; then
        output_json "error" 90 "SQLite command not found" "Installation may have failed"
        exit 1
    fi
    
    SQLITE_VERSION=$(sqlite3 --version | awk '{print $1}')
    
    # Create a test database
    TEST_DB=$(mktemp)
    
    # Test database creation and operations
    sqlite3 "$TEST_DB" "CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT);" 2>&1
    sqlite3 "$TEST_DB" "INSERT INTO test (name) VALUES ('test');" 2>&1
    RESULT=$(sqlite3 "$TEST_DB" "SELECT name FROM test WHERE id=1;" 2>&1)
    
    # Clean up test database
    rm -f "$TEST_DB"
    
    if [[ "$RESULT" == "test" ]]; then
        output_json "success" 100 "SQLite validated" "SQLite $SQLITE_VERSION working correctly"
    else
        output_json "error" 90 "SQLite test failed" "Database operations failed"
        exit 1
    fi
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
