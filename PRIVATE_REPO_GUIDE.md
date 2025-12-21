# PDeploy Private Repository Guide

This guide explains how to work with PDeploy in a private GitHub repository environment, including token management, access control, and best practices.

---

## Overview

PDeploy is hosted in a **private GitHub repository** (`Cellsave/dev-gen`) to protect proprietary code and maintain licensing control. Access requires authentication via GitHub Personal Access Tokens.

---

## GitHub Personal Access Token (PAT)

### What is a Personal Access Token?

A Personal Access Token (PAT) is a secure alternative to passwords for authenticating with GitHub's API and accessing private repositories. Tokens can be scoped to specific permissions and easily revoked.

### Why Tokens Instead of Passwords?

- ✅ **Fine-grained permissions**: Only grant necessary access
- ✅ **Easy revocation**: Disable tokens without changing password
- ✅ **Audit trail**: Track token usage in GitHub settings
- ✅ **Automation-friendly**: Safe for scripts and CI/CD
- ✅ **No 2FA prompts**: Works seamlessly with automated tools

---

## Generating a GitHub Token

### Step-by-Step Instructions

1. **Navigate to GitHub Settings**
   - Go to: https://github.com/settings/tokens
   - Or: Profile → Settings → Developer settings → Personal access tokens → Tokens (classic)

2. **Generate New Token**
   - Click **"Generate new token"**
   - Select **"Generate new token (classic)"**

3. **Configure Token**
   - **Note**: `PDeploy Installation` (or descriptive name)
   - **Expiration**: 90 days (recommended) or custom
   - **Select scopes**:
     - ✅ **`repo`** - Full control of private repositories
       - This includes: `repo:status`, `repo_deployment`, `public_repo`, `repo:invite`, `security_events`

4. **Generate and Copy**
   - Click **"Generate token"**
   - **Copy the token immediately** (you won't see it again!)
   - Store securely (password manager recommended)

### Token Scopes Explained

| Scope | Description | Required for PDeploy? |
|-------|-------------|----------------------|
| `repo` | Full control of private repositories | ✅ **YES** |
| `public_repo` | Access public repositories only | ❌ NO (insufficient) |
| `read:org` | Read organization membership | ❌ NO |
| `workflow` | Update GitHub Actions workflows | ❌ NO |

**Important:** PDeploy requires the full `repo` scope to access private repositories.

---

## Using Tokens with PDeploy

### Method 1: Interactive Token Input (Recommended for Manual Use)

```bash
export PDEPLOY_VERSION=v1.0.0
curl -fsSL https://raw.githubusercontent.com/Cellsave/dev-gen/v1.0.0/install-secure.sh | bash
```

**What happens:**
1. Script detects no token in environment
2. Displays instructions for generating token
3. Prompts you to enter token (input hidden for security)
4. Validates token before proceeding
5. Uses token for all subsequent downloads

**Advantages:**
- ✅ Token not stored in shell history
- ✅ Secure input (hidden from terminal)
- ✅ Clear instructions provided
- ✅ Immediate validation

### Method 2: Environment Variable (Recommended for Automation)

```bash
export PDEPLOY_VERSION=v1.0.0
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
curl -fsSL https://raw.githubusercontent.com/Cellsave/dev-gen/v1.0.0/install-secure.sh | bash
```

**Advantages:**
- ✅ No manual input required
- ✅ Suitable for automation/CI/CD
- ✅ Can be sourced from secure vault
- ✅ Easy to script

**Security Note:** Clear the token from environment after use:
```bash
unset GITHUB_TOKEN
```

### Method 3: Configuration File (Advanced)

Create a secure configuration file:

```bash
# Create config file (readable only by user)
cat > ~/.pdeploy_config << 'EOF'
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
export PDEPLOY_VERSION=v1.0.0
EOF

# Secure the file
chmod 600 ~/.pdeploy_config

# Source before installation
source ~/.pdeploy_config
bash install-secure.sh

# Clean up
unset GITHUB_TOKEN
```

---

## Token Security Best Practices

### DO ✅

1. **Store securely**
   - Use password manager (1Password, LastPass, Bitwarden)
   - Or secure vault (HashiCorp Vault, AWS Secrets Manager)
   - Never in plain text files

2. **Use minimal scopes**
   - Only `repo` scope for PDeploy
   - Don't grant unnecessary permissions

3. **Set expiration**
   - 90 days recommended
   - Rotate regularly

4. **Monitor usage**
   - Check GitHub Settings → Developer settings → Personal access tokens
   - Review "Last used" timestamps

5. **Revoke when done**
   - Delete tokens no longer needed
   - Revoke immediately if compromised

6. **Use separate tokens**
   - Different tokens for different purposes
   - Easier to track and revoke

### DON'T ❌

1. **Never commit to version control**
   ```bash
   # BAD - Never do this!
   git add .env
   git commit -m "Add config"
   ```

2. **Never share tokens**
   - Each user should have their own token
   - Sharing makes revocation difficult

3. **Never log in plain text**
   ```bash
   # BAD - Token visible in logs
   echo "Using token: $GITHUB_TOKEN"
   ```

4. **Never use in URLs**
   ```bash
   # BAD - Token visible in shell history
   curl https://ghp_xxx@raw.githubusercontent.com/...
   ```

5. **Never store in shell history**
   ```bash
   # Use space prefix to avoid history (bash)
    export GITHUB_TOKEN=xxx
   
   # Or disable history temporarily
   set +o history
   export GITHUB_TOKEN=xxx
   set -o history
   ```

---

## Token Validation

### How PDeploy Validates Tokens

The installation script validates your token before proceeding:

```bash
# Test API access
curl -s -w "%{http_code}" \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  "https://api.github.com/repos/Cellsave/dev-gen" \
  -o /dev/null
```

**Response codes:**
- `200` - ✅ Token valid, access granted
- `401` - ❌ Invalid token
- `404` - ❌ Repository not found or no access
- `403` - ❌ Rate limited or insufficient permissions

### Manual Token Testing

Test your token before installation:

```bash
# Set token
export GITHUB_TOKEN=your_token_here

# Test repository access
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/Cellsave/dev-gen

# Expected output: Repository JSON (if successful)
# Error output: {"message": "Not Found"} (if no access)
```

---

## Troubleshooting

### Issue: "Invalid GitHub token"

**Cause:** Token is malformed, expired, or revoked

**Solutions:**
1. Verify token is copied correctly (no spaces/newlines)
2. Check token hasn't expired (GitHub Settings → Tokens)
3. Ensure token has `repo` scope
4. Generate new token if necessary

### Issue: "Repository not found or token doesn't have access"

**Cause:** Token lacks permissions or repository access

**Solutions:**
1. Verify you have access to `Cellsave/dev-gen`
2. Check token has **`repo`** scope (not just `public_repo`)
3. Contact repository administrator for access
4. Ensure organization membership is active

### Issue: "Token validation failed (HTTP 403)"

**Cause:** Rate limiting or IP restrictions

**Solutions:**
1. Wait 60 minutes (GitHub rate limit reset)
2. Check for IP-based restrictions
3. Verify organization security settings
4. Contact GitHub support if persistent

### Issue: Token appears in shell history

**Prevention:**
```bash
# Method 1: Space prefix (bash)
 export GITHUB_TOKEN=xxx

# Method 2: Disable history temporarily
set +o history
export GITHUB_TOKEN=xxx
set -o history

# Method 3: Clear history after use
history -d $((HISTCMD-1))
unset GITHUB_TOKEN
```

---

## Access Management

### Repository Administrator Tasks

**Granting Access:**
1. Go to repository Settings → Collaborators
2. Click "Add people"
3. Enter username
4. Select permission level:
   - **Read**: View and clone only
   - **Write**: Push changes (not recommended for users)
   - **Admin**: Full control (only for maintainers)

**Recommended:** Grant **Read** access for PDeploy users

**Revoking Access:**
1. Go to repository Settings → Collaborators
2. Find user
3. Click "Remove"

### User Access Verification

Check your access level:

```bash
export GITHUB_TOKEN=your_token_here

curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/Cellsave/dev-gen \
  | grep -E '"permissions"|"private"'
```

**Expected output:**
```json
"private": true,
"permissions": {
  "admin": false,
  "push": false,
  "pull": true
}
```

---

## Automation & CI/CD

### GitHub Actions

```yaml
name: Deploy PDeploy

on:
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Install PDeploy
        env:
          GITHUB_TOKEN: ${{ secrets.PDEPLOY_TOKEN }}
          PDEPLOY_VERSION: v1.0.0
        run: |
          curl -fsSL https://raw.githubusercontent.com/Cellsave/dev-gen/v1.0.0/install-secure.sh | bash
```

**Setup:**
1. Go to repository Settings → Secrets → Actions
2. Add secret: `PDEPLOY_TOKEN` with your token value
3. Use `${{ secrets.PDEPLOY_TOKEN }}` in workflows

### Jenkins

```groovy
pipeline {
    agent any
    environment {
        GITHUB_TOKEN = credentials('pdeploy-github-token')
        PDEPLOY_VERSION = 'v1.0.0'
    }
    stages {
        stage('Install PDeploy') {
            steps {
                sh '''
                    curl -fsSL https://raw.githubusercontent.com/Cellsave/dev-gen/v1.0.0/install-secure.sh | bash
                '''
            }
        }
    }
}
```

### Ansible

```yaml
---
- name: Install PDeploy
  hosts: servers
  vars:
    pdeploy_version: v1.0.0
    github_token: "{{ lookup('env', 'GITHUB_TOKEN') }}"
  tasks:
    - name: Download and run installer
      shell: |
        export GITHUB_TOKEN={{ github_token }}
        export PDEPLOY_VERSION={{ pdeploy_version }}
        curl -fsSL https://raw.githubusercontent.com/Cellsave/dev-gen/{{ pdeploy_version }}/install-secure.sh | bash
      no_log: true  # Hide token from logs
```

---

## Token Rotation

### Why Rotate Tokens?

- ✅ Limit exposure window if compromised
- ✅ Meet security compliance requirements
- ✅ Remove unused/forgotten tokens
- ✅ Maintain audit trail

### Rotation Schedule

| Environment | Recommended Frequency |
|-------------|----------------------|
| Production | Every 90 days |
| Development | Every 180 days |
| Testing | Every 90 days |
| Personal | Every 90-180 days |

### Rotation Process

1. **Generate new token**
   - Follow generation instructions above
   - Use same scopes as old token

2. **Update systems**
   - Update environment variables
   - Update CI/CD secrets
   - Update configuration files

3. **Test new token**
   - Verify access works
   - Test installation process

4. **Revoke old token**
   - Go to GitHub Settings → Tokens
   - Click "Delete" on old token

5. **Document change**
   - Update internal documentation
   - Notify team if shared system

---

## Licensing Considerations

### Token Usage and Licensing

- Tokens grant **access** to the repository
- Tokens do **not** grant **license** to use PDeploy
- Separate licensing mechanism required for commercial use

### Future Licensing Integration

**Planned for v1.1.0:**
- License key validation during installation
- Token for repository access + License key for usage
- Offline license validation
- License expiration checks

**Example future flow:**
```bash
export GITHUB_TOKEN=ghp_xxx
export PDEPLOY_LICENSE_KEY=lic_xxx
bash install-secure.sh
```

---

## Monitoring & Auditing

### GitHub Audit Log

**Organization owners can:**
1. Go to Organization Settings → Audit log
2. Filter by:
   - Action: `repo.access`
   - Repository: `Cellsave/dev-gen`
3. Review access patterns

### Token Usage Tracking

**Individual users can:**
1. Go to Settings → Developer settings → Personal access tokens
2. Check "Last used" column
3. Review token activity

**Best practice:** Review monthly and revoke unused tokens

---

## Support

### Token Issues

- **GitHub Support**: https://support.github.com
- **Repository Admin**: Contact your system administrator
- **Internal IT**: security@cellsave.com

### Documentation

- **GitHub PAT Docs**: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token
- **PDeploy README**: [README.md](README.md)
- **Security Analysis**: [SECURITY_ANALYSIS.md](SECURITY_ANALYSIS.md)

---

## Quick Reference

### Generate Token
```
https://github.com/settings/tokens → Generate new token (classic)
Scope: repo
Expiration: 90 days
```

### Install with Token (Interactive)
```bash
export PDEPLOY_VERSION=v1.0.0
curl -fsSL https://raw.githubusercontent.com/Cellsave/dev-gen/v1.0.0/install-secure.sh | bash
# Enter token when prompted
```

### Install with Token (Environment)
```bash
export PDEPLOY_VERSION=v1.0.0
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
curl -fsSL https://raw.githubusercontent.com/Cellsave/dev-gen/v1.0.0/install-secure.sh | bash
unset GITHUB_TOKEN
```

### Test Token
```bash
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/Cellsave/dev-gen
```

### Revoke Token
```
https://github.com/settings/tokens → Find token → Delete
```

---

**PDeploy Private Repository Guide** - Version 1.0.0  
**Last Updated:** December 20, 2024  
**Status:** Production Ready
