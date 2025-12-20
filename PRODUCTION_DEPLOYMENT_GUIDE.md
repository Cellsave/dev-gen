# PDeploy - Production Deployment Guide

**Version:** 1.0  
**Last Updated:** December 20, 2024  
**Target Audience:** DevOps Engineers, System Administrators  

---

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [System Requirements](#system-requirements)
3. [Security Hardening](#security-hardening)
4. [Step-by-Step Deployment](#step-by-step-deployment)
5. [Post-Deployment Verification](#post-deployment-verification)
6. [Monitoring & Maintenance](#monitoring--maintenance)
7. [Troubleshooting](#troubleshooting)
8. [Rollback Procedures](#rollback-procedures)

---

## Pre-Deployment Checklist

### ✅ Before You Begin

- [ ] **Ubuntu Server Ready** - Fresh Ubuntu 22.04 LTS or later
- [ ] **Root/Sudo Access** - Required for system package installation
- [ ] **Internet Connection** - Stable connection for downloads
- [ ] **Firewall Configuration** - Plan which ports to expose
- [ ] **Backup System** - Have backup/snapshot capability
- [ ] **SSH Access** - Secure remote access configured
- [ ] **Documentation Review** - Read this guide completely
- [ ] **Security Analysis** - Review SECURITY_ANALYSIS.md
- [ ] **Test Environment** - Test deployment in non-production first

### 📋 Information to Gather

| Item | Example | Your Value |
|------|---------|------------|
| Server IP Address | 192.168.1.100 | __________ |
| Server Hostname | pdeploy.example.com | __________ |
| SSH Port | 22 | __________ |
| Admin User | ubuntu | __________ |
| Firewall Rules | UFW/iptables | __________ |
| SSL Certificate | Let's Encrypt/Custom | __________ |

---

## System Requirements

### Minimum Requirements

| Component | Requirement | Recommended |
|-----------|-------------|-------------|
| **OS** | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |
| **CPU** | 2 cores | 4+ cores |
| **RAM** | 2 GB | 4+ GB |
| **Disk** | 20 GB free | 50+ GB |
| **Network** | 10 Mbps | 100+ Mbps |
| **Python** | 3.8+ | 3.11+ |

### Supported Platforms

✅ **Fully Supported:**
- Ubuntu 22.04 LTS (Jammy Jellyfish)
- Ubuntu 20.04 LTS (Focal Fossa)
- Ubuntu 24.04 LTS (Noble Numbat)

⚠️ **Partially Supported:**
- Debian 11/12 (may require adjustments)
- Linux Mint 21+ (Ubuntu-based)

❌ **Not Supported:**
- CentOS/RHEL (different package manager)
- Windows/macOS (not tested)
- Docker containers (requires privileged mode)

---

## Security Hardening

### Phase 1: System Preparation

#### 1.1 Update System Packages

```bash
# Update package lists
sudo apt update

# Upgrade all packages
sudo apt upgrade -y

# Install security updates
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
```

#### 1.2 Configure Firewall

```bash
# Install UFW if not present
sudo apt install ufw -y

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (change port if needed)
sudo ufw allow 22/tcp

# Allow PDeploy web interface
sudo ufw allow 8000/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

#### 1.3 Secure SSH Access

```bash
# Edit SSH configuration
sudo nano /etc/ssh/sshd_config

# Recommended settings:
# PermitRootLogin no
# PasswordAuthentication no  # Use key-based auth
# Port 2222  # Change default port
# AllowUsers ubuntu  # Restrict users

# Restart SSH
sudo systemctl restart sshd
```

#### 1.4 Install Fail2Ban

```bash
# Install fail2ban
sudo apt install fail2ban -y

# Create local configuration
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Edit configuration
sudo nano /etc/fail2ban/jail.local

# Enable and start
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### Phase 2: User Setup

#### 2.1 Create Dedicated User (Optional but Recommended)

```bash
# Create pdeploy user
sudo adduser pdeploy

# Add to sudo group (if needed)
sudo usermod -aG sudo pdeploy

# Switch to pdeploy user
su - pdeploy
```

#### 2.2 Set Up SSH Keys

```bash
# On your local machine
ssh-keygen -t ed25519 -C "pdeploy@example.com"

# Copy to server
ssh-copy-id -i ~/.ssh/id_ed25519.pub pdeploy@server-ip
```

---

## Step-by-Step Deployment

### Method 1: Secure Installation (Recommended)

#### Step 1: Download Installation Script

```bash
# Create working directory
mkdir -p ~/pdeploy-setup
cd ~/pdeploy-setup

# Download install script
curl -fsSL https://raw.githubusercontent.com/Cellsave/dev-gen/main/install.sh -o install.sh

# Download cleanup script
curl -fsSL https://raw.githubusercontent.com/Cellsave/dev-gen/main/cleanup.sh -o cleanup.sh

# Download update script
curl -fsSL https://raw.githubusercontent.com/Cellsave/dev-gen/main/update.sh -o update.sh
```

#### Step 2: Review Scripts

```bash
# Review installation script
less install.sh

# Check for suspicious content
grep -i "curl\|wget\|rm\|sudo" install.sh

# Verify source URLs
grep "GITHUB_RAW" install.sh
```

#### Step 3: Verify Checksums (When Available)

```bash
# Download checksums
curl -fsSL https://raw.githubusercontent.com/Cellsave/dev-gen/main/SHA256SUMS -o SHA256SUMS

# Verify
sha256sum -c SHA256SUMS
```

#### Step 4: Make Scripts Executable

```bash
chmod +x install.sh cleanup.sh update.sh
```

#### Step 5: Run Installation

```bash
# Run with logging
./install.sh 2>&1 | tee pdeploy-install.log

# Check for errors
echo "Exit code: $?"
```

#### Step 6: Verify Installation

```bash
# Check installed files
ls -la ~/pdeploy/

# Expected output:
# pdeploy.html
# orchestrator.py
# modules/
# cleanup.sh
# update.sh
```

### Method 2: One-Line Installation (Quick but Less Secure)

```bash
# ⚠️ WARNING: Review security implications first
curl -fsSL https://raw.githubusercontent.com/Cellsave/dev-gen/main/install.sh | bash
```

**Use this method only if:**
- You trust the repository completely
- You're in a test/development environment
- You've reviewed the script previously

---

## Post-Deployment Verification

### Verification Checklist

#### 1. File Integrity Check

```bash
cd ~/pdeploy

# Check core files exist
test -f pdeploy.html && echo "✓ pdeploy.html found" || echo "✗ Missing pdeploy.html"
test -f orchestrator.py && echo "✓ orchestrator.py found" || echo "✗ Missing orchestrator.py"
test -f cleanup.sh && echo "✓ cleanup.sh found" || echo "✗ Missing cleanup.sh"
test -f update.sh && echo "✓ update.sh found" || echo "✗ Missing update.sh"

# Check modules
test -d modules/backend/docker && echo "✓ Docker module found" || echo "✗ Missing Docker module"
test -d modules/backend/node22 && echo "✓ Node22 module found" || echo "✗ Missing Node22 module"
test -d modules/backend/sqlite && echo "✓ SQLite module found" || echo "✗ Missing SQLite module"
test -d modules/frontend/react18 && echo "✓ React18 module found" || echo "✗ Missing React18 module"
test -d modules/server/linux-tools && echo "✓ Linux-tools module found" || echo "✗ Missing Linux-tools module"
```

#### 2. Permissions Check

```bash
# Check execute permissions
ls -l orchestrator.py cleanup.sh update.sh modules/*/*/main.sh

# All should have -rwxr-xr-x or similar
```

#### 3. Python Environment Check

```bash
# Verify Python 3
python3 --version

# Should be 3.8 or higher
```

#### 4. Start Web Server

```bash
cd ~/pdeploy

# Start HTTP server
python3 -m http.server 8000 &

# Save PID
echo $! > pdeploy.pid

# Wait for startup
sleep 2
```

#### 5. Test Local Access

```bash
# Test HTTP access
curl -s http://localhost:8000/pdeploy.html | grep -i "PDeploy" && echo "✓ Web interface accessible" || echo "✗ Web interface failed"

# Test orchestrator
python3 orchestrator.py --help 2>&1 | grep -i "usage" && echo "✓ Orchestrator working" || echo "✗ Orchestrator failed"
```

#### 6. Test Remote Access

```bash
# From another machine
curl -s http://YOUR_SERVER_IP:8000/pdeploy.html | grep -i "PDeploy"

# Or open in browser
# http://YOUR_SERVER_IP:8000/pdeploy.html
```

#### 7. Test Module Execution

```bash
# Test SQLite module (fastest)
cd ~/pdeploy
python3 orchestrator.py sqlite

# Should output JSON with status
```

---

## Production Configuration

### 1. Reverse Proxy Setup (Nginx)

#### Install Nginx

```bash
sudo apt install nginx -y
```

#### Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/pdeploy
```

```nginx
server {
    listen 80;
    server_name pdeploy.example.com;

    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name pdeploy.example.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/pdeploy.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/pdeploy.example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Proxy to PDeploy
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support (if needed)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Access logs
    access_log /var/log/nginx/pdeploy-access.log;
    error_log /var/log/nginx/pdeploy-error.log;
}
```

#### Enable Configuration

```bash
# Create symlink
sudo ln -s /etc/nginx/sites-available/pdeploy /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### 2. SSL Certificate (Let's Encrypt)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtain certificate
sudo certbot --nginx -d pdeploy.example.com

# Test auto-renewal
sudo certbot renew --dry-run
```

### 3. Systemd Service

Create a systemd service for automatic startup:

```bash
sudo nano /etc/systemd/system/pdeploy.service
```

```ini
[Unit]
Description=PDeploy Web Interface
After=network.target

[Service]
Type=simple
User=pdeploy
WorkingDirectory=/home/pdeploy/pdeploy
ExecStart=/usr/bin/python3 -m http.server 8000
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service
sudo systemctl enable pdeploy

# Start service
sudo systemctl start pdeploy

# Check status
sudo systemctl status pdeploy
```

---

## Monitoring & Maintenance

### Daily Checks

```bash
# Check service status
sudo systemctl status pdeploy

# Check logs
sudo journalctl -u pdeploy -n 50

# Check disk space
df -h

# Check memory usage
free -h
```

### Weekly Maintenance

```bash
# Update libraries
cd ~/pdeploy
./update.sh

# Review logs
sudo tail -100 /var/log/nginx/pdeploy-access.log
sudo tail -100 /var/log/nginx/pdeploy-error.log

# Check for security updates
sudo apt update
sudo apt list --upgradable
```

### Monthly Tasks

```bash
# Full system update
sudo apt update && sudo apt upgrade -y

# Clean up temporary files
cd ~/pdeploy
./cleanup.sh

# Review firewall rules
sudo ufw status numbered

# Check fail2ban status
sudo fail2ban-client status
```

### Monitoring Tools

#### Install Monitoring Stack (Optional)

```bash
# Install htop for process monitoring
sudo apt install htop -y

# Install netdata for comprehensive monitoring
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# Access at http://YOUR_SERVER_IP:19999
```

---

## Troubleshooting

### Common Issues

#### Issue 1: Port 8000 Already in Use

```bash
# Find process using port 8000
sudo lsof -i :8000

# Kill process
sudo kill -9 PID

# Or use different port
python3 -m http.server 8080
```

#### Issue 2: Permission Denied

```bash
# Fix ownership
sudo chown -R $USER:$USER ~/pdeploy

# Fix permissions
chmod +x ~/pdeploy/*.sh
chmod +x ~/pdeploy/orchestrator.py
find ~/pdeploy/modules -name "main.sh" -exec chmod +x {} \;
```

#### Issue 3: Module Download Failed

```bash
# Check internet connection
ping -c 3 github.com

# Check GitHub status
curl -I https://github.com

# Retry installation
cd ~/pdeploy-setup
./install.sh
```

#### Issue 4: Web Interface Not Loading

```bash
# Check if server is running
ps aux | grep "http.server"

# Check firewall
sudo ufw status

# Check if port is listening
sudo netstat -tlnp | grep 8000

# Test local access
curl http://localhost:8000/pdeploy.html
```

#### Issue 5: Nginx 502 Bad Gateway

```bash
# Check if PDeploy is running
sudo systemctl status pdeploy

# Check Nginx error logs
sudo tail -50 /var/log/nginx/pdeploy-error.log

# Restart services
sudo systemctl restart pdeploy
sudo systemctl restart nginx
```

### Debug Mode

```bash
# Run with verbose output
cd ~/pdeploy
python3 -m http.server 8000 --bind 0.0.0.0

# Test orchestrator with debug
python3 -c "import sys; sys.path.insert(0, '.'); import orchestrator; print(orchestrator.__file__)"
```

---

## Rollback Procedures

### Scenario 1: Installation Failed

```bash
# Remove incomplete installation
rm -rf ~/pdeploy

# Re-run installation
cd ~/pdeploy-setup
./install.sh
```

### Scenario 2: Module Corrupted

```bash
# Re-download specific module
cd ~/pdeploy
MODULE="sqlite"
curl -fsSL "https://raw.githubusercontent.com/Cellsave/dev-gen/main/modules/backend/$MODULE/main.sh" -o "modules/backend/$MODULE/main.sh"
chmod +x "modules/backend/$MODULE/main.sh"
```

### Scenario 3: Complete System Rollback

```bash
# Stop services
sudo systemctl stop pdeploy
sudo systemctl stop nginx

# Remove PDeploy
rm -rf ~/pdeploy

# Restore from backup (if available)
# tar -xzf pdeploy-backup.tar.gz -C ~/

# Or reinstall from scratch
cd ~/pdeploy-setup
./install.sh
```

### Backup Strategy

#### Create Backup

```bash
# Backup PDeploy directory
tar -czf pdeploy-backup-$(date +%Y%m%d).tar.gz ~/pdeploy

# Move to safe location
mv pdeploy-backup-*.tar.gz /backup/pdeploy/
```

#### Restore from Backup

```bash
# Remove current installation
rm -rf ~/pdeploy

# Restore from backup
tar -xzf /backup/pdeploy/pdeploy-backup-YYYYMMDD.tar.gz -C ~/
```

---

## Production Best Practices

### Security

1. **Use HTTPS Only** - Never expose PDeploy over HTTP in production
2. **Implement Authentication** - Add basic auth or OAuth
3. **Restrict Access** - Use firewall rules to limit access
4. **Regular Updates** - Run `./update.sh` weekly
5. **Monitor Logs** - Check for suspicious activity
6. **Backup Regularly** - Daily backups recommended

### Performance

1. **Use Reverse Proxy** - Nginx for better performance
2. **Enable Caching** - Cache static assets
3. **Monitor Resources** - Watch CPU/RAM usage
4. **Optimize Modules** - Disable unused modules
5. **Use SSD Storage** - For better I/O performance

### Reliability

1. **Systemd Service** - Auto-restart on failure
2. **Health Checks** - Monitor service availability
3. **Redundancy** - Consider multiple instances
4. **Disaster Recovery** - Test restore procedures
5. **Documentation** - Keep deployment notes

---

## Quick Reference

### Essential Commands

```bash
# Start PDeploy
cd ~/pdeploy && python3 -m http.server 8000 &

# Stop PDeploy
kill $(cat pdeploy.pid)

# Update libraries
./update.sh

# Clean temporary files
./cleanup.sh

# Check status
sudo systemctl status pdeploy

# View logs
sudo journalctl -u pdeploy -f

# Restart service
sudo systemctl restart pdeploy
```

### File Locations

| File/Directory | Path | Purpose |
|----------------|------|---------|
| PDeploy Installation | `~/pdeploy/` | Main directory |
| Web Interface | `~/pdeploy/pdeploy.html` | Dashboard |
| Orchestrator | `~/pdeploy/orchestrator.py` | Module executor |
| Modules | `~/pdeploy/modules/` | Installation scripts |
| Nginx Config | `/etc/nginx/sites-available/pdeploy` | Reverse proxy |
| Systemd Service | `/etc/systemd/system/pdeploy.service` | Auto-start |
| Logs | `/var/log/nginx/pdeploy-*.log` | Access/error logs |

---

## Support & Resources

### Documentation

- **README**: `/home/ubuntu/pdeploy/README.md`
- **Security Analysis**: `SECURITY_ANALYSIS.md`
- **Test Results**: `TEST_RESULTS.md`

### Repository

- **GitHub**: https://github.com/Cellsave/dev-gen
- **Issues**: https://github.com/Cellsave/dev-gen/issues
- **Releases**: https://github.com/Cellsave/dev-gen/releases

### Community

- **Discussions**: GitHub Discussions
- **Bug Reports**: GitHub Issues
- **Feature Requests**: GitHub Issues

---

## Appendix

### A. Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PDEPLOY_VERSION` | `main` | Git branch/tag to install |
| `PDEPLOY_REPO` | `Cellsave/dev-gen` | GitHub repository |
| `INSTALL_DIR` | `~/pdeploy` | Installation directory |

### B. Port Reference

| Port | Service | Protocol | Required |
|------|---------|----------|----------|
| 22 | SSH | TCP | Yes |
| 80 | HTTP | TCP | Optional |
| 443 | HTTPS | TCP | Recommended |
| 8000 | PDeploy | TCP | Yes |
| 19999 | Netdata | TCP | Optional |

### C. Firewall Rules

```bash
# Minimal (SSH + PDeploy)
sudo ufw allow 22/tcp
sudo ufw allow 8000/tcp

# Production (SSH + HTTPS)
sudo ufw allow 22/tcp
sudo ufw allow 443/tcp

# Development (All)
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8000/tcp
```

---

**Document Version:** 1.0  
**Last Updated:** December 20, 2024  
**Maintained By:** Cellsave Development Team  
**License:** MIT
