# 🔐 Authentication Guide

This guide explains how to authenticate with GitHub for the `stratus-tf-aca-gh-vending` module.

## 🎯 **Recommended: GitHub CLI Authentication**

GitHub CLI authentication is the **recommended approach** for security, convenience, and reliability.

### **Why GitHub CLI is Better**

| Feature | GitHub CLI | Personal Access Token |
|---------|------------|----------------------|
| **Expiration** | ✅ Never expires | ❌ Can expire (max 1 year) |
| **Scope Management** | ✅ Automatic | ❌ Manual configuration |
| **Security** | ✅ OAuth flow | ❌ Long-lived secrets |
| **Rotation** | ✅ Easy (`gh auth refresh`) | ❌ Manual regeneration |
| **Multi-account** | ✅ Built-in switching | ❌ Manual token management |
| **Terraform Integration** | ✅ Automatic detection | ❌ Manual configuration |

### **Setup GitHub CLI Authentication**

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

### **Using GitHub CLI with Terraform**

The terraform-provider-github **automatically detects** and uses GitHub CLI authentication when no explicit token is provided.

#### **Automatic Detection (Recommended)**

```hcl
# No explicit token needed - provider automatically uses gh CLI
provider "github" {
  owner = "your-organization"
}
```

#### **Explicit Token (Alternative)**

```hcl
# Explicitly use GitHub CLI token
provider "github" {
  owner = "your-organization"
  token = var.github_token
}
```

```bash
# Set token from GitHub CLI
export GITHUB_TOKEN=$(gh auth token)
terraform apply
```

### **Using in GitHub Actions Workflows**

```yaml
# In your workflow file
- name: Run Terraform
  run: |
    gh workflow run your-workflow.yml \
      -f github_token=$(gh auth token) \
      -f tfvars_file=environments.yaml
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
   - ✅ `repo` - Full control of private repositories
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
3. **Regularly refresh tokens**: `gh auth refresh`
4. **Use organization SSO** if available
5. **Monitor token usage** in GitHub settings

### **Personal Access Token Security**

1. **Set short expiration periods** (90 days maximum)
2. **Use fine-grained tokens** when possible
3. **Rotate tokens regularly**
4. **Store tokens securely** (never in code)
5. **Revoke unused tokens** immediately
6. **Monitor token usage** in GitHub settings

### **Environment Security**

```bash
# Never commit tokens to version control
echo "GITHUB_TOKEN=*" >> .gitignore

# Use environment variables
export GITHUB_TOKEN=$(gh auth token)

# Clear tokens after use
unset GITHUB_TOKEN
```

## 📚 **Additional Resources**

- [GitHub CLI Manual](https://cli.github.com/manual/)
- [GitHub CLI Authentication](https://cli.github.com/manual/gh_auth)
- [Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [Fine-grained Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token#creating-a-fine-grained-personal-access-token)
- [Token Expiration and Revocation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/token-expiration-and-revocation) 