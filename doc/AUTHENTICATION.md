# 🔐 Authentication Guide

This is the **comprehensive authentication guide** for the `stratus-tf-github-environments` module. This guide covers all authentication methods, security considerations, and troubleshooting.

> **📚 Related Documentation:**
>
> - [README.md](../README.md) - Quick setup and usage examples
> - [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Common issues and solutions
> - [AI_CONTEXT.md](./AI_CONTEXT.md) - Context for AI-assisted development

## 📋 **Table of Contents**

- [🎯 Recommended: GitHub CLI Authentication](#-recommended-github-cli-authentication)
- [🤔 GitHub CLI vs GitHub App: When to Use What?](#-github-cli-vs-github-app-when-to-use-what)
- [🔧 Setup GitHub CLI Authentication](#-setup-github-cli-authentication)
- [🔄 Managing Multiple Accounts](#-managing-multiple-accounts)
- [🛠 Troubleshooting Authentication](#-troubleshooting-authentication)
- [🔒 Security Best Practices](#-security-best-practices)
- [🔑 Alternative: Personal Access Tokens](#-alternative-personal-access-tokens)
- [🤖 GitHub App Authentication (Enterprise)](#-github-app-authentication-enterprise)

## 🎯 **Recommended: GitHub CLI Authentication**

GitHub CLI authentication is the **recommended approach** for security, convenience, and reliability.

## 🤔 **GitHub CLI vs GitHub App: When to Use What?**

### **🎯 Stratus Default: GitHub CLI Tokens (Recommended)**

**For most Stratus teams, use GitHub CLI tokens because:**

- **One-time setup**: Configuring GitHub environments is typically a one-time task per project
- **No approval overhead**: GitHub Apps require manual workflow to order app and private key from administrators
- **Immediate access**: `gh auth login` and you're ready to go
- **Perfect for occasional use**: Most teams configure environments once and rarely change them

### **🏢 GitHub Apps: For Special Requirements**

**Consider GitHub Apps only if your team:**

- **Creates/destroys environments frequently** (multiple times per week)
- **Has specific compliance requirements** for app-based authentication
- **Already has GitHub Apps** set up for other purposes

**Note**: The workflow supports GitHub App authentication, and we use it for module testing, but it's not the default recommendation for regular Stratus teams.

### **💡 Quick Decision**

- **Most Stratus teams** → Use GitHub CLI tokens (default pattern)
- **High-frequency environment changes** → Consider GitHub Apps
- **Compliance requirements** → GitHub Apps may be required

## 🔧 **Setup GitHub CLI Authentication**

#### **1. Install GitHub CLI**

```bash
# macOS
brew install gh

# Windows
winget install GitHub.cli

# Ubuntu/Debian
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Other platforms: https://github.com/cli/cli#installation
```

#### **2. Authenticate with GitHub**

```bash
# Start authentication flow
gh auth login

# Choose options:
# ? What account do you want to log into? GitHub.com
# ? What is your preferred protocol for Git operations? HTTPS
# ? Authenticate Git with your GitHub credentials? Yes
# ? How would you like to authenticate GitHub CLI? Login with a web browser

# Follow the browser flow to complete authentication
```

#### **3. Verify Authentication**

```bash
# Check authentication status
gh auth status

# Expected output:
# github.com
#   ✓ Logged in to github.com as your-username (oauth_token)
#   ✓ Git operations for github.com configured to use https protocol.
#   ✓ Token: gho_************************************

# Test API access
gh api user

# Get your token (for use in workflows)
gh auth token
```

### **Using GitHub CLI with the Module**

This module always runs as a **workflow dispatch** where you provide the GitHub token as a required input parameter. You don't need to configure any Terraform providers directly - the module handles all GitHub API authentication internally.

### **Using GitHub CLI to Dispatch Workflows**

```bash
# Dispatch the vending workflow from your terminal
gh workflow run github-environment-vending.yml \
  -f github_token=$(gh auth token) \
  -f tfvars_file=dev.tfvars

# Check workflow status
gh run list --workflow=github-environment-vending.yml

# View workflow logs
gh run view --log
```

## 🔑 **Alternative: Personal Access Tokens**

> **⚠️ Not Recommended**: Use GitHub CLI authentication instead for better security and convenience.

If you must use Personal Access Tokens (PATs), here's how to set them up properly:

### **Classic Personal Access Tokens**

#### **1. Create Token**

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Set expiration (recommend 90 days maximum)
4. Select required scopes:
   - ✅ `repo` - Full control of your private repositories
   - ✅ `workflow` - Update GitHub Action workflows
   - ✅ `read:org` - Read org and team membership

#### **2. Use Token**

```bash
# Set as environment variable
export GITHUB_TOKEN=ghp_your_token_here

# Or pass directly to Terraform
terraform apply -var="github_token=ghp_your_token_here"
```

### **Fine-grained Personal Access Tokens**

#### **1. Create Fine-grained Token**

1. Go to GitHub Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Click "Generate new token"
3. Select resource owner (your organization)
4. Set expiration (recommend 90 days maximum)
5. Select repository access (specific repositories or all)
6. Configure permissions:
   - **Repository permissions:**
     - Actions: Write
     - Environments: Write
     - Metadata: Read
     - Secrets: Write
     - Variables: Write
   - **Organization permissions:**
     - Members: Read

#### **2. Token Limitations**

- ❌ May not work with all GitHub API endpoints
- ❌ Organization policies may restrict usage
- ❌ More complex permission management
- ❌ Still subject to expiration

## 🔄 **Managing Multiple Accounts**

### **GitHub CLI Multi-account Support**

```bash
# List authenticated accounts
gh auth status

# Switch between accounts
gh auth switch

# Login to additional account
gh auth login --hostname github.com

# Use specific account
gh auth token --hostname github.com --user specific-username
```

### **Organization-specific Authentication**

```bash
# Authenticate to specific organization
gh auth login

# Verify organization access
gh api orgs/your-organization/members/your-username

# Check organization OAuth policies
gh api orgs/your-organization
```

## 🛠 **Troubleshooting Authentication**

### **Common Issues**

#### **"Not logged in" Error**

```bash
# Check status
gh auth status

# Re-authenticate if needed
gh auth logout
gh auth login
```

#### **"Resource not accessible" Error**

```bash
# Check organization membership
gh api orgs/your-organization/members/your-username

# Check OAuth app policies
gh api orgs/your-organization

# Re-authenticate with correct scopes
gh auth logout
gh auth login
```

#### **Token Scope Issues**

```bash
# GitHub CLI tokens have automatic scopes
# If you see scope errors, re-authenticate:
gh auth logout
gh auth login
```

### **Verification Commands**

```bash
# Test basic authentication
gh auth status

# Test API access
gh api user

# Test organization access
gh api orgs/your-organization

# Test repository access
gh api repos/your-organization/your-repository

# Get current token
gh auth token

# Check token scopes (for debugging)
curl -H "Authorization: token $(gh auth token)" \
     -H "Accept: application/vnd.github.v3+json" \
     https://api.github.com/user
```

## 🔒 **Security Best Practices**

### **GitHub CLI Security**

1. **Use web browser authentication** for the most secure flow
2. **Enable 2FA** on your GitHub account
3. **Periodic token refresh**: Run `gh auth refresh` monthly for security hygiene
4. **Use organization SSO** if available
5. **Monitor token usage** in GitHub settings
6. **Secure workstation practices**:
   - **Lock your screen** when away from your workstation
   - **Use full disk encryption** on development machines
   - **Keep OS and software updated** with security patches
7. **Network security**:
   - **Avoid public WiFi** for sensitive operations
   - **Use VPN** when working remotely
8. **Session management**:
   - **Logout when switching contexts**: `gh auth logout` when switching between personal/work accounts
   - **Logout on shared machines**: Always `gh auth logout` on shared or temporary workstations
   - **Regular security reviews**: Check `gh auth status` and GitHub's "Applications" settings quarterly
9. **Emergency procedures**:
   - **Immediate logout** if you suspect compromise: `gh auth logout`
   - **Revoke all tokens** in GitHub settings if needed
   - **Report security incidents** to your organization's security team

### **Personal Access Token Security**

1. **Set short expiration periods** (90 days maximum)
2. **Use fine-grained tokens** when possible
3. **Rotate tokens regularly**
4. **Store tokens securely** (never in code)
5. **Revoke unused tokens** immediately
6. **Monitor token usage** in GitHub settings

### **Environment Security**

```bash
# ✅ Protect sensitive files
echo ".env" >> .gitignore
echo ".env.local" >> .gitignore
echo "*.env" >> .gitignore
echo "*.token" >> .gitignore
echo "secrets/" >> .gitignore

# Use environment variables (not files)
export GITHUB_TOKEN=$(gh auth token)

# Clear tokens after use
unset GITHUB_TOKEN
```

## 🤖 **GitHub App Authentication (Enterprise)**

For enterprise environments and automated testing, GitHub App authentication provides enhanced security and better audit trails.

### **Benefits of GitHub App Authentication**

- **🔐 Enhanced Security**: Fine-grained permissions and automatic token expiration
- **📊 Better Audit Trails**: All actions logged under the app's identity
- **🏢 Organization Control**: Admins control app installations and permissions
- **⏰ Automatic Expiration**: Installation tokens expire in 1 hour
- **🔄 No Personal Dependencies**: Not tied to individual user accounts

### **Setup GitHub App**

#### **1. Create GitHub App**

1. Go to GitHub Settings → Developer settings → GitHub Apps
2. Click "New GitHub App"
3. Configure basic information:
   - **App name**: `stratus-aca-vending-app`
   - **Homepage URL**: Your organization's URL
   - **Webhook URL**: Not required for this use case

#### **2. Set Permissions**

**Repository permissions:**

- **Actions**: Write (to dispatch workflows)
- **Contents**: Read (to read repository files)
- **Environments**: Write (to create and manage environments)
- **Metadata**: Read (required for basic repository access)
- **Secrets**: Write (to manage environment secrets)
- **Variables**: Write (to manage environment variables)

**Organization permissions:**

- **Administration**: Read (to validate team and user assignments)

#### **3. Generate Private Key**

1. In your GitHub App settings, scroll to "Private keys"
2. Click "Generate a private key"
3. Download and securely store the `.pem` file

#### **4. Install App**

1. Go to your GitHub App settings
2. Click "Install App" in the left sidebar
3. Install in your organization
4. Grant access to required repositories

### **Using GitHub App in Integration Tests**

The enhanced integration test workflow uses GitHub App authentication:

```yaml
# In .github/workflows/integration-test.yml
- name: Generate GitHub App Token
  id: app-token
  uses: actions/create-github-app-token@v1
  with:
    app-id: ${{ secrets.GITHUB_APP_ID }}
    private-key: ${{ secrets.GITHUB_APP_PRIVATE_KEY }}
    owner: ${{ github.repository_owner }}

- name: Use App Token
  run: |
    gh workflow run github-environment-vending.yml \
      -f github_token="${{ steps.app-token.outputs.token }}" \
      -f tfvars_file=integration-test.tfvars
```

### **Required Secrets**

Add these secrets to your repository:

```bash
# GitHub App ID (found in app settings)
GITHUB_APP_ID=123456

# GitHub App Private Key (contents of the .pem file)
GITHUB_APP_PRIVATE_KEY=-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----
```

### **Manual Token Generation**

For local testing or manual workflows:

```bash
#!/bin/bash
# generate-app-token.sh

APP_ID="your-app-id"
INSTALLATION_ID="your-installation-id"  # Found in app installations
PRIVATE_KEY_PATH="path/to/private-key.pem"

# Generate JWT token (requires python3 and PyJWT)
JWT=$(python3 -c "
import jwt
import time
from pathlib import Path

app_id = '$APP_ID'
private_key = Path('$PRIVATE_KEY_PATH').read_text()

payload = {
    'iat': int(time.time()),
    'exp': int(time.time()) + 600,  # 10 minutes
    'iss': app_id
}

token = jwt.encode(payload, private_key, algorithm='RS256')
print(token)
")

# Get installation token
INSTALLATION_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens" | \
  jq -r '.token')

# Use with GitHub CLI
echo "$INSTALLATION_TOKEN" | gh auth login --with-token
```

### **Integration Test Features**

The enhanced integration test now provides:

- **🔐 GitHub App Authentication**: Tests both GitHub App and standard token authentication
- **🚀 Real Workflow Dispatch**: Actually runs the `github-environment-aca.yml` workflow
- **⏱️ Workflow Monitoring**: Waits for and monitors the dispatched workflow completion
- **✅ End-to-End Verification**: Verifies GitHub environments were actually created
- **🧹 Automatic Cleanup**: Dispatches destroy workflow for cleanup
- **📊 Comprehensive Reporting**: Detailed test results and workflow links

### **Security Considerations**

#### **Private Key Management**

- **🔒 Never commit private keys** to repositories
- **🏦 Use secure storage** (Azure Key Vault, GitHub Secrets, etc.)
- **🔄 Rotate keys regularly** following security policies
- **👥 Limit access** to private keys

#### **Installation Security**

- **🎯 Limit repository access** to only required repositories
- **👀 Monitor app usage** through GitHub's audit logs
- **🔍 Regular permission reviews** to ensure least privilege
- **🚨 Immediate revocation** if compromise is suspected

#### **Token Handling**

- **⏰ Short-lived tokens**: Installation tokens expire in 1 hour
- **🔐 Secure transmission**: Use HTTPS and secure environment variables
- **📝 Audit logging**: All API calls are logged under the app's identity
- **🚫 No persistent storage**: Tokens should not be stored long-term

This GitHub App approach provides enterprise-grade security while enabling comprehensive integration testing of the entire workflow.
