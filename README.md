# PDeploy - VM Preparation Dashboard

**PDeploy** is a lightweight, browser-based automation tool designed for non-technical server administrators to prepare Ubuntu x64 VMs with one-touch installation of software libraries and applications.

## 🔒 Private Repository Notice

This repository is **private** and requires authentication for access. You'll need a GitHub Personal Access Token to install PDeploy.

## Security Notice

**Version 1.0.0** includes enhanced security features:

- ✅ SHA256 checksum verification for all downloads
- ✅ Version pinning for stable deployments
- ✅ Automatic rollback on installation failures
- ✅ Download retry logic with exponential backoff
- ✅ Manifest-based integrity checking
- ✅ **GitHub token authentication for private repository access**

## Features

- **Single-File Bootstrap**: Everything starts from a single `pdeploy.html` file
- **Browser-Based UI**: No complex CLI commands - just checkboxes and buttons
- **Modular Architecture**: Extensible module system for easy additions
- **AI-Assisted Guidance**: Built-in AI chat for troubleshooting and recommendations
- **Sequential Installation**: Conflict-free installation with progress tracking
- **Real-Time Feedback**: Live terminal output and progress bars
- **Application Deployment**: Intelligent deployment with AI-driven method selection
- **Rollback Capability**: Automatic recovery from failed installations
- **Integrity Verification**: Checksum validation for secure downloads
- **🆕 Private Repository Support**: Secure access with GitHub token authentication
- **🆕 Monitoring Stack**: Integrated ELK, Prometheus, and Grafana installation
- **🆕 System Audit**: Dynamic resource validation before deployment

## Quick Start

### 🔐 Secure Installation (Private Repository)

**Step 1: Generate GitHub Personal Access Token**

1. Go to: <https://github.com/settings/tokens>
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Set token name: `PDeploy Installation`
4. Select scope: **`repo`** (Full control of private repositories)
5. Click **"Generate token"**
6. **Copy the token** (you won't see it again!)

**Step 2: Install PDeploy**

```bash
# Method 1: Interactive (token prompt)
export PDEPLOY_VERSION=v1.0.0
curl -fsSL https://raw.githubusercontent.com/Cellsave/dev-gen/v1.0.0/install-secure.sh | bash
# You'll be prompted to enter your token

# Method 2: Environment variable (no prompt)
export PDEPLOY_VERSION=v1.0.0
export GITHUB_TOKEN=your_token_here
curl -fsSL https://raw.githubusercontent.com/Cellsave/dev-gen/v1.0.0/install-secure.sh | bash
```

**Step 3: Start PDeploy**

```bash
cd ~/pdeploy
# Install dependencies
pip3 install -r requirements.txt
# Start the backend server
python3 server.py
# Open browser to: http://localhost:8000/pdeploy.html
```

### 🔑 Token Security Best Practices

- ✅ **Never commit tokens to version control**
- ✅ **Use environment variables for automation**
- ✅ **Set minimal required scopes** (only `repo` for PDeploy)
- ✅ **Rotate tokens regularly** (every 90 days recommended)
- ✅ **Delete tokens when no longer needed**
- ✅ **Use separate tokens for different purposes**
- ❌ **Never share tokens** with others
- ❌ **Never log tokens** in plain text

### Prerequisites

- Ubuntu x64 VM (tested on Ubuntu 20.04+)
- Internet connection
- Modern web browser (Chrome, Firefox, Edge)
- Python 3 (pre-installed on Ubuntu)
- **GitHub Personal Access Token** with `repo` scope

### Manual Installation (with Token)

For maximum control and security:

1. **Set up authentication:**

   ```bash
   export GITHUB_TOKEN=your_token_here
   export PDEPLOY_VERSION=v1.0.0
   ```

2. **Download installation script:**

   ```bash
   curl -H "Authorization: token $GITHUB_TOKEN" \
     -H "Accept: application/vnd.github.v3.raw" \
     -fsSL "https://raw.githubusercontent.com/Cellsave/dev-gen/${PDEPLOY_VERSION}/install-secure.sh" \
     -o install-secure.sh
   ```

3. **Inspect the script** (recommended):

   ```bash
   less install-secure.sh
   ```

4. **Run installation:**

   ```bash
   chmod +x install-secure.sh
   ./install-secure.sh
   ```

5. **Start web server:**

   ```bash
   cd ~/pdeploy
   pip3 install -r requirements.txt
   python3 server.py
   ```

6. **Open in browser:**
   Navigate to `http://localhost:8000/pdeploy.html`

## Version Information

| Version | Release Date | Status | Security Features |
|---------|--------------|--------|-------------------|
| **v1.0.0** | 2024-12-20 | ✅ Stable | Checksums, Version pinning, Rollback, Token auth |
| main | Rolling | ⚠️ Development | Basic security only |

**Recommendation:** Always use tagged versions (e.g., `v1.0.0`) for production deployments.

## Utilities

### Cleanup

Remove temporary files and directories created during installation while preserving PDeploy core files:

```bash
cd ~/pdeploy
./cleanup.sh
```

### Update

Check and update all installed libraries to their latest versions:

```bash
cd ~/pdeploy
./update.sh
```

## Available Modules

### Backend Libraries

- **Docker**: Container platform for application deployment
- **Node.js 22**: JavaScript runtime with TypeScript and Express
- **SQLite**: Lightweight embedded database

### Frontend Libraries

- **React 18**: Complete React development environment with Vite, Tailwind CSS, Monaco Editor, and D3.js

### Server & Security

- **Linux Tools**: Essential server utilities and security tools (git, curl, wget, UFW, Fail2ban)

### Monitoring Stack (New)

- **Filebeat**: Lightweight log shipper
- **Logstash**: Server-side data processing pipeline
- **Elasticsearch**: Search and analytics engine (Requires ~2GB RAM)
- **Kibana**: Window into the Elastic Stack
- **Prometheus**: Monitoring system and time series database
- **Grafana**: Observability and data visualization

## Architecture

```
pdeploy/
├── pdeploy.html           # Main dashboard (self-contained)
├── server.py              # Flask backend server
├── orchestrator.py        # Module execution engine
├── audit.py               # 🆕 System resource auditor
├── requirements.txt       # Python dependencies
├── install.sh             # Quick installation script
├── install-secure.sh      # 🆕 Secure installation with token auth
├── manifest-v1.0.0.json   # Integrity manifest
├── cleanup.sh             # Cleanup utility
├── update.sh              # Update utility
└── modules/
    ├── backend/
    │   ├── docker/
    │   ├── node22/
    │   └── sqlite/
    ├── frontend/
    │   └── react18/
    ├── monitoring/        # 🆕 ELK & Prometheus Stack
    │   ├── filebeat/
    │   ├── logstash/
    │   ├── elasticsearch/
    │   ├── kibana/
    │   ├── prometheus/
    │   └── grafana/
    └── server/
        └── linux-tools/
```

## Security Considerations

### 🔒 Private Repository Security

**Token Management:**

- Tokens grant access to private repositories
- Store tokens securely (environment variables, not files)
- Never share tokens or commit them to repositories
- Rotate tokens regularly (90 days recommended)
- Revoke tokens immediately if compromised

**Access Control:**

- Only authorized users should have repository access
- Use minimal required token scopes (`repo` only)
- Monitor token usage in GitHub settings
- Enable two-factor authentication on GitHub account

### Installation Security

- **Use Secure Installation**: Always use `install-secure.sh` for production
- **Version Pinning**: Specify exact versions (e.g., `v1.0.0`) instead of `main`
- **Verify Checksums**: Check `checksums.txt` for manual installations
- **Review Scripts**: Inspect installation scripts before execution
- **Network Security**: Use HTTPS for all downloads (enforced by default)

### Authentication & Access

- **Single-User Design**: Not intended for multi-user environments
- **Local Authentication**: Credentials stored in browser localStorage
- **Production Deployment**: Use Nginx with HTTP Basic Auth or OAuth

### Security Documentation

For comprehensive security analysis and production deployment guidelines:

- **[SECURITY_ANALYSIS.md](SECURITY_ANALYSIS.md)** - Detailed security assessment
- **[PRODUCTION_DEPLOYMENT_GUIDE.md](PRODUCTION_DEPLOYMENT_GUIDE.md)** - Production setup instructions
- **[PRIVATE_REPO_GUIDE.md](PRIVATE_REPO_GUIDE.md)** - Private repository best practices

## Troubleshooting

### Token Authentication Issues

**Issue: "Invalid GitHub token"**

```
Solution:
1. Verify token has 'repo' scope
2. Check token hasn't expired
3. Ensure token is correctly copied (no extra spaces)
4. Generate new token if necessary
```

**Issue: "Repository not found or token doesn't have access"**

```
Solution:
1. Verify you have access to Cellsave/dev-gen
2. Check repository name is correct
3. Ensure token has 'repo' scope (not just 'public_repo')
4. Contact repository administrator for access
```

**Issue: "Token validation failed"**

```
Solution:
1. Check internet connectivity
2. Verify GitHub API is accessible
3. Try with a fresh token
4. Check for firewall/proxy issues
```

### Module Installation Fails

1. Check terminal logs for specific error messages
2. Ask AI assistant for help
3. Verify internet connectivity
4. Ensure sufficient disk space
5. Check module dependencies are installed first
6. Verify GitHub token is still valid

### Dashboard Won't Load

1. Verify Python web server is running
2. Check firewall allows port 8000
3. Try different browser
4. Clear browser cache and localStorage

### Permission Errors

1. Ensure user has sudo privileges
2. Check file permissions on module scripts
3. Verify script is executable (`chmod +x`)

## System Requirements

- **OS**: Ubuntu 20.04+ (x64)
- **RAM**: Minimum 1GB, 2GB recommended
- **Disk**: 10GB free space minimum
- **Network**: Internet connection required
- **Browser**: Modern browser with JavaScript enabled
- **GitHub**: Personal Access Token with `repo` scope

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

1. Request repository access from administrator
2. Fork the repository (if permitted)
3. Create a feature branch
4. Follow the module template structure
5. Test thoroughly on clean Ubuntu VM
6. Update checksums for new files
7. Submit pull request with documentation

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## License

Proprietary - See LICENSE file for details

**Note:** This is a private repository. Unauthorized access, copying, or distribution is prohibited.

## Support

### Documentation

- **README.md** - Main documentation (this file)
- **SECURITY_ANALYSIS.md** - Security assessment
- **PRODUCTION_DEPLOYMENT_GUIDE.md** - Production setup
- **INSTALLATION_GUIDE.md** - Installation instructions
- **PRIVATE_REPO_GUIDE.md** - Private repository guidelines

### Community

- **GitHub Issues**: <https://github.com/Cellsave/dev-gen/issues> (requires access)
- **Internal Support**: Contact your system administrator

### Security

- **Report vulnerabilities**: <security@cellsave.com>
- **Token issues**: Contact repository administrator

## Changelog

### v1.0.0 (2024-12-20)

**Security Enhancements:**

- ✅ Added `install-secure.sh` with SHA256 checksum verification
- ✅ Added GitHub token authentication for private repository
- ✅ Created `manifest-v1.0.0.json` for integrity checking
- ✅ Implemented version pinning support
- ✅ Added download retry logic with exponential backoff
- ✅ Automatic backup creation before installation

**New Features:**

- ✅ Enhanced orchestrator with rollback capability
- ✅ Execution logging to disk
- ✅ Configuration file support for retry policies
- ✅ Snapshot management for system state
- ✅ Interactive and environment-based token input

**Documentation:**

- ✅ Added SECURITY_ANALYSIS.md
- ✅ Added PRODUCTION_DEPLOYMENT_GUIDE.md
- ✅ Added PRIVATE_REPO_GUIDE.md
- ✅ Updated README with private repository instructions

## Roadmap

### ✅ Completed (v1.0.0)

- [x] Checksum verification
- [x] Version pinning
- [x] Rollback functionality
- [x] Enhanced security documentation
- [x] Private repository support with token authentication

### 🔄 In Progress (v1.1.0 - Q1 2025)

- [ ] GPG signature verification
- [ ] Automated testing framework
- [ ] CI/CD pipeline
- [ ] Module dependency resolution
- [ ] License key management integration

### 📋 Planned (v2.0.0 - Q2 2025)

- [ ] Additional modules (Nginx, PostgreSQL, Redis)
- [ ] Interactive terminal mode
- [ ] Multi-VM orchestration
- [ ] Custom module templates
- [ ] Enhanced AI integration
- [ ] Docker Compose support
- [ ] Kubernetes setup module

## Credits

Developed by Cellsave for internal VM preparation and deployment automation.

**Security Audit:** Independent code quality and compliance analysis conducted December 2024.

---

**PDeploy** - Making server setup simple, secure, and reliable - one click at a time.

**Version:** 1.0.0 | **Status:** ✅ Production Ready | **Security:** 🔒 Enhanced | **Access:** 🔐 Private

---

**Important:** This is a private repository. Ensure you have proper authorization before accessing or using PDeploy.
