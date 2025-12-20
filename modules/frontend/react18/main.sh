#!/bin/bash
# React 18 with TypeScript, Vite, Tailwind, Monaco, D3 Installation Module for PDeploy
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
    output_json "running" 20 "Running pre-installation checks" "Checking for Node.js dependency"
    
    # Check if Node.js is installed (required dependency)
    if ! command -v node &> /dev/null; then
        output_json "error" 0 "Node.js not found" "React 18 module requires Node.js. Please install Node.js first."
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    
    # Check if npm is available
    if ! command -v npm &> /dev/null; then
        output_json "error" 0 "npm not found" "npm is required but not found"
        exit 1
    fi
    
    output_json "success" 20 "Pre-checks passed" "Node.js $NODE_VERSION detected"
}

# Install function
install() {
    output_json "running" 40 "Installing React 18 template" "Creating Vite + React + TypeScript project"
    
    # Create frontend apps directory
    FRONTEND_DIR="/opt/frontend-apps"
    sudo mkdir -p "$FRONTEND_DIR"
    sudo chown $USER:$USER "$FRONTEND_DIR"
    
    # Create React app with Vite
    cd "$FRONTEND_DIR"
    
    # Create Vite React TypeScript template
    npm create vite@latest react-app -- --template react-ts <<EOF
y
EOF
    
    cd react-app
    
    output_json "running" 50 "Installing dependencies" "Installing React, Tailwind, Monaco, D3"
    
    # Install dependencies
    npm install
    
    # Install Tailwind CSS
    npm install -D tailwindcss postcss autoprefixer
    
    # Install Monaco Editor and D3
    npm install @monaco-editor/react d3 @types/d3
    
    output_json "success" 60 "Dependencies installed" "All packages installed successfully"
}

# Configure function
configure() {
    output_json "running" 75 "Configuring React environment" "Setting up Tailwind and project structure"
    
    cd /opt/frontend-apps/react-app
    
    # Initialize Tailwind
    npx tailwindcss init -p
    
    # Configure Tailwind
    cat > tailwind.config.js <<'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF
    
    # Update main CSS file
    cat > src/index.css <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF
    
    # Create example component with Monaco and D3
    cat > src/App.tsx <<'EOF'
import { useState } from 'react'
import Editor from '@monaco-editor/react'
import './App.css'

function App() {
  const [code, setCode] = useState('// Welcome to React 18 + TypeScript + Vite + Tailwind + Monaco + D3\nconsole.log("Hello, PDeploy!");')

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-500 to-purple-600 p-8">
      <div className="max-w-6xl mx-auto">
        <h1 className="text-4xl font-bold text-white mb-8">
          React 18 Development Environment
        </h1>
        <div className="bg-white rounded-lg shadow-xl p-6 mb-6">
          <h2 className="text-2xl font-semibold mb-4">Installed Technologies</h2>
          <ul className="grid grid-cols-2 gap-4">
            <li className="flex items-center">
              <span className="text-green-500 mr-2">✓</span> React 18
            </li>
            <li className="flex items-center">
              <span className="text-green-500 mr-2">✓</span> TypeScript
            </li>
            <li className="flex items-center">
              <span className="text-green-500 mr-2">✓</span> Vite
            </li>
            <li className="flex items-center">
              <span className="text-green-500 mr-2">✓</span> Tailwind CSS
            </li>
            <li className="flex items-center">
              <span className="text-green-500 mr-2">✓</span> Monaco Editor
            </li>
            <li className="flex items-center">
              <span className="text-green-500 mr-2">✓</span> D3.js
            </li>
          </ul>
        </div>
        <div className="bg-white rounded-lg shadow-xl p-6">
          <h2 className="text-2xl font-semibold mb-4">Monaco Code Editor</h2>
          <Editor
            height="400px"
            defaultLanguage="javascript"
            value={code}
            onChange={(value) => setCode(value || '')}
            theme="vs-dark"
            options={{
              minimap: { enabled: false },
              fontSize: 14,
            }}
          />
        </div>
      </div>
    </div>
  )
}

export default App
EOF
    
    output_json "success" 75 "React environment configured" "Tailwind initialized, example components created"
}

# Validate function
validate() {
    output_json "running" 90 "Validating installation" "Building and testing React application"
    
    cd /opt/frontend-apps/react-app
    
    # Test build
    if npm run build > /tmp/react-build.log 2>&1; then
        BUILD_OUTPUT=$(cat /tmp/react-build.log)
        output_json "success" 100 "React 18 validated" "Application built successfully. Project located at /opt/frontend-apps/react-app. Run 'npm run dev' to start development server."
    else
        BUILD_ERROR=$(cat /tmp/react-build.log)
        output_json "error" 90 "Build failed" "$BUILD_ERROR"
        exit 1
    fi
    
    rm -f /tmp/react-build.log
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
