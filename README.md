# PDeploy - VM Preparation Dashboard

**PDeploy** is a lightweight, browser-based automation tool designed for non-technical server administrators to prepare Ubuntu x64 VMs with one-touch installation of software libraries and applications.

## Features

- **Single-File Bootstrap**: Everything starts from a single `pdeploy.html` file
- **Browser-Based UI**: No complex CLI commands - just checkboxes and buttons
- **Modular Architecture**: Extensible module system for easy additions
- **AI-Assisted Guidance**: Built-in AI chat for troubleshooting and recommendations
- **Sequential Installation**: Conflict-free installation with progress tracking
- **Real-Time Feedback**: Live terminal output and progress bars
- **Application Deployment**: Intelligent deployment with AI-driven method selection

## Quick Start

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Cellsave/dev-gen/main/install.sh | bash
cd ~/pdeploy
python3 -m http.server 8000
# Open browser to: http://localhost:8000/pdeploy.html
```

### Prerequisites

- Ubuntu x64 VM (tested on Ubuntu 20.04+)
- Internet connection
- Modern web browser (Chrome, Firefox, Edge)
- Python 3 (pre-installed on Ubuntu)

### Installation

1. **Download PDeploy**:
   ```bash
   wget https://raw.githubusercontent.com/Cellsave/dev-gen/main/pdeploy.html
   ```

2. **Start Local Web Server**:
   ```bash
   python3 -m http.server 8000
   ```

3. **Open in Browser**:
   Navigate to `http://localhost:8000/pdeploy.html`

4. **Login**:
   - Enter any username and password (stored locally for single-user sessions)

5. **Select Libraries**:
   - Check the boxes for libraries you want to install
   - Click "Start Installation"

6. **Monitor Progress**:
   - Watch real-time progress bars and terminal output
   - AI assistant provides guidance and troubleshooting

## Utilities

### Cleanup

Remove temporary files and directories created during installation while preserving PDeploy core files:

```bash
cd ~/pdeploy
./cleanup.sh
```

**What gets removed:**
- `/opt/frontend-apps/` - React projects
- `~/databases/` - SQLite test databases
- `~/.npm-global/` - npm global packages
- Build artifacts and temporary files

**What gets preserved:**
- `pdeploy.html`
- `orchestrator.py`
- `modules/` - Installation scripts
- Documentation files

### Update

Check and update all installed libraries to their latest versions:

```bash
cd ~/pdeploy
./update.sh
```

**Features:**
- Checks Docker, Node.js, SQLite, React packages, and system packages
- Shows available updates with version information
- Interactive update process with confirmation
- Updates npm, system packages, and library-specific components

## Available Modules

### Backend Libraries

#### Docker
- **Description**: Container platform for application deployment
- **Includes**: Docker Engine, Docker Compose, Buildx
- **Use Case**: Containerized applications, microservices

#### Node.js 22
- **Description**: JavaScript runtime with TypeScript and Express
- **Includes**: Node.js 22.x, npm, TypeScript, Express, ts-node
- **Use Case**: Backend APIs, server-side JavaScript applications

#### SQLite
- **Description**: Lightweight embedded database
- **Includes**: SQLite3, development libraries
- **Use Case**: Local databases, development, small applications

### Frontend Libraries

#### React 18
- **Description**: Complete React development environment
- **Includes**: 
  - React 18 with TypeScript
  - Vite (fast build tool)
  - Tailwind CSS (utility-first CSS)
  - Monaco Editor (VS Code editor component)
  - D3.js (data visualization)
- **Use Case**: Modern web applications, SPAs, dashboards
- **Location**: `/opt/frontend-apps/react-app`

### Server & Security

#### Linux Tools
- **Description**: Essential server utilities and security tools
- **Includes**:
  - Development tools (git, curl, wget, build-essential)
  - Network utilities (net-tools, dnsutils, tcpdump)
  - Terminal tools (vim, nano, htop, tmux, screen)
  - Security (UFW firewall, Fail2ban)
- **Use Case**: Server hardening, development, troubleshooting

## Architecture

### Component Overview

```
pdeploy/
├── pdeploy.html           # Main dashboard (self-contained)
├── orchestrator.py        # Module execution engine
├── modules/
│   ├── backend/
│   │   ├── docker/
│   │   │   └── main.sh
│   │   ├── node22/
│   │   │   └── main.sh
│   │   └── sqlite/
│   │       └── main.sh
│   ├── frontend/
│   │   └── react18/
│   │       └── main.sh
│   └── server/
│       └── linux-tools/
│           └── main.sh
└── README.md
```

### Module Structure

Each module follows a standardized template:

```bash
#!/bin/bash
# Module functions:
# - pre_check()   : Verify dependencies and system compatibility
# - install()     : Perform installation
# - configure()   : Post-installation configuration
# - validate()    : Test installation success
# - output_json() : Emit progress and status in JSON format
```

### Data Flow

1. User selects modules in browser UI
2. Dashboard sends module list to orchestrator
3. Orchestrator executes modules sequentially
4. Each module emits JSON progress updates
5. Dashboard displays real-time progress and logs
6. AI assistant monitors and provides guidance

## Application Deployment

After libraries are installed, you can deploy your application:

1. **Enter Repository URL**: Provide your GitHub/GitLab repository URL
2. **AI Analysis**: AI examines your repo and installed libraries
3. **Deployment Method**: AI selects optimal method:
   - **Docker**: If Dockerfile exists and Docker is installed
   - **Script-based**: If install.sh or package.json exists
4. **Secret Management**: Secure forms for environment variables
5. **Validation**: Automated testing and health checks

## AI Assistant

The built-in AI assistant provides:

- **Proactive Monitoring**: Watches installation logs for issues
- **Error Troubleshooting**: Suggests fixes for common problems
- **Best Practices**: Recommends optimal configurations
- **Interactive Help**: Answer questions about modules and setup

### Supported AI Providers

- **Grok API**: Cloud-based AI (requires API key)
- **Ollama**: Local AI (auto-installed on request)
- **OpenAI**: GPT models (requires API key)

## Extending PDeploy

### Adding New Modules

1. **Create Module Directory**:
   ```bash
   mkdir -p modules/category/module-name
   ```

2. **Create main.sh Script**:
   ```bash
   #!/bin/bash
   # Follow the standardized template
   # Implement: pre_check, install, configure, validate
   # Output JSON with: status, progress, message, logs
   ```

3. **Make Executable**:
   ```bash
   chmod +x modules/category/module-name/main.sh
   ```

4. **Update Dashboard** (optional):
   - Add module to `modules` object in `pdeploy.html`
   - Add display name to `formatModuleName()` function

5. **Push to GitHub**:
   ```bash
   git add modules/category/module-name/
   git commit -m "Add module-name module"
   git push
   ```

The dashboard will automatically discover new modules from the GitHub repository!

## Security Considerations

- **Single-User Design**: Not intended for multi-user environments
- **Local Authentication**: Credentials stored in browser localStorage
- **Script Validation**: Verify scripts before execution (checksums recommended)
- **Firewall Configuration**: UFW enabled with SSH, HTTP, HTTPS allowed
- **Intrusion Prevention**: Fail2ban configured for SSH protection
- **Sudo Access**: Required for system-level installations

## Troubleshooting

### Module Installation Fails

1. Check terminal logs for specific error messages
2. Ask AI assistant for help
3. Verify internet connectivity
4. Ensure sufficient disk space
5. Check module dependencies are installed first

### Dashboard Won't Load

1. Verify Python web server is running
2. Check firewall allows port 8000
3. Try different browser
4. Clear browser cache and localStorage

### Permission Errors

1. Ensure user has sudo privileges
2. Check file permissions on module scripts
3. Verify script is executable (`chmod +x`)

### Docker Group Permissions

After Docker installation, log out and back in for group permissions to take effect, or run:
```bash
newgrp docker
```

## System Requirements

- **OS**: Ubuntu 20.04+ (x64)
- **RAM**: Minimum 1GB, 2GB recommended
- **Disk**: 10GB free space minimum
- **Network**: Internet connection required
- **Browser**: Modern browser with JavaScript enabled

## Use Cases

### Development Environment Setup
Install Node.js, React, and development tools for web development.

### Container Platform
Set up Docker for containerized application deployment.

### Secure Server
Install Linux tools with firewall and intrusion prevention.

### Full Stack Environment
Install backend (Node.js, SQLite), frontend (React), and server tools in one go.

## Contributing

To contribute new modules or improvements:

1. Fork the repository
2. Create a feature branch
3. Follow the module template structure
4. Test thoroughly on clean Ubuntu VM
5. Submit pull request with documentation

## License

MIT License - See LICENSE file for details

## Support

- **Issues**: Report bugs on GitHub Issues
- **Discussions**: Join GitHub Discussions
- **Documentation**: Check this README and inline code comments

## Roadmap

- [ ] Additional modules (Nginx, PostgreSQL, Redis)
- [ ] Interactive terminal mode
- [ ] Module dependency resolution
- [ ] Rollback functionality
- [ ] Multi-VM orchestration
- [ ] Custom module templates
- [ ] Enhanced AI integration
- [ ] Docker Compose support
- [ ] Kubernetes setup module

## Credits

Developed for non-technical server administrators who need reliable, automated VM preparation without complex CLI operations.

---

**PDeploy** - Making server setup simple, one click at a time.
