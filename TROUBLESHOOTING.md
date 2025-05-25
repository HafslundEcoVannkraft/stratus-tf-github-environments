# 🔧 Troubleshooting Guide

This guide helps you resolve common issues when using the `stratus-tf-aca-gh-vending` module.

## 🚨 **Most Common Issues**

### **1. Authentication & Token Issues**

> **💡 Recommended Approach**: Use GitHub CLI authentication instead of Personal Access Tokens for better security and convenience.

#### **GitHub CLI Authentication (Recommended)**

**Setup GitHub CLI Authentication:**
```bash
# Install GitHub CLI if not already installed
# macOS: brew install gh
# Windows: winget install GitHub.cli
# Linux: See https://github.com/cli/cli#installation

# Authenticate with GitHub
gh auth login

# Verify authentication
gh auth status

# Get your token (for use in workflows)
gh auth token
```

**Benefits of GitHub CLI tokens:**
- ✅ **Never expire** (long-lived OAuth tokens)
- ✅ **Automatic scope management** (no manual scope configuration)
- ✅ **Secure storage** (handled by GitHub CLI)
- ✅ **Easy rotation** (just run `gh auth refresh`)
- ✅ **Works automatically** with terraform-provider-github

#### **GitHub CLI Token Issues**

**GitHub CLI Not Authenticated**
```
Error: gh auth token: not logged in
```

**Solutions:**
- Run `gh auth login` to authenticate
- Choose "Login with a web browser" for the most secure flow
- Ensure you're logged into the correct GitHub account with `gh auth status`
- If using multiple accounts, switch with `gh auth switch`

**GitHub CLI Token Scope Issues**
```
Error: Resource not accessible by integration
```

**Solutions:**
- GitHub CLI tokens automatically have the correct scopes
- If you see this error, re-authenticate: `gh auth logout` then `gh auth login`
- Ensure you're authenticated to the correct organization
- Check your organization's OAuth app policies

#### **Personal Access Token Issues (Not Recommended)**

> **⚠️ Warning**: Personal Access Tokens are less secure and can expire. Use GitHub CLI authentication instead.

**Token Authentication Failed**
```
Error: 401 Unauthorized
```

**Solutions:**
- **Switch to GitHub CLI**: Run `gh auth login` instead of using PATs
- If you must use PATs, verify token has required scopes: `repo`, `workflow`, `read:org`
- Check token expiration date in GitHub Settings → Developer settings → Personal access tokens
- Ensure token belongs to the correct organization

**Token Expired**
```
Error: Bad credentials
```

**Solutions:**
- **Switch to GitHub CLI**: GitHub CLI tokens never expire
- If using PATs, regenerate the expired token in GitHub settings
- Set longer expiration periods (up to 1 year) or no expiration for PATs
- Consider using fine-grained personal access tokens for better security

**Token Scope Insufficient**
```
Error: Resource not accessible by integration
```

**Solutions:**
- **Switch to GitHub CLI**: Automatic scope management
- For PATs, add missing scopes:
  - `repo` - Required for repository access
  - `workflow` - Required for GitHub Actions environments
  - `read:org` - Required for team/user lookups
- Create a new token with proper scopes if you can't modify existing one

### **2. Azure Permissions & Access**

#### **Azure Subscription Access Denied**
```
Error: Insufficient privileges to complete the operation
```

**Solutions:**
- Verify you have `Contributor` or `Owner` role on the Azure subscription
- Check if your account has access to the specified subscription ID
- Ensure you're authenticated to the correct Azure tenant
- Run `az account show` to verify current subscription context

#### **Remote State Access Issues**
```
Error: Failed to read remote state
```

**Solutions:**
- Verify the remote state storage account exists and is accessible
- Check if your account has `Storage Blob Data Reader` role on the storage account
- Ensure the state file exists at the specified path
- Verify the resource group and storage account names are correct

### **3. Configuration & YAML Issues**

#### **Invalid Environment Names**
```
Error: Environment name 'my_env' must be alphanumeric with hyphens
```

**Solutions:**
- Use only letters, numbers, and hyphens in environment names
- Don't start or end with hyphens
- Avoid Windows reserved names (CON, PRN, AUX, NUL)
- Keep names under 50 characters

#### **Repository Not Found**
```
Error: Repository 'org/repo' not found
```

**Solutions:**
- Verify the repository exists and you have access
- Check the repository name format: `owner/repo-name`
- Ensure your GitHub token has access to the repository
- For private repositories, verify your token has appropriate permissions

#### **Container Environment Mapping Missing**
```
Error: container_environment 'dev' not found in remote state
```

**Solutions:**
- Check that the Container App Environment exists in your remote state
- Verify the environment key matches exactly (case-sensitive)
- Ensure the remote state is up-to-date
- Run `terraform refresh` on your infrastructure state first

### **4. GitHub API & Resource Issues**

#### **Conflicting Deployment Policies**
```
Error: Cannot use protected_branches with tag policies
```

**Solutions:**
- Choose either `protected_branches: true` OR `tag_policy.enabled: true`, not both
- Use branch policies for development environments
- Use tag policies for production environments
- This is a GitHub API limitation, not a module issue

#### **Reviewer Not Found**
```
Error: User 'username' not found in organization
```

**Solutions:**
- Verify the username exists and is a member of your GitHub organization
- Check team names/slugs are correct and exist
- Ensure users have accepted organization invitations
- For teams, use either `name` or `slug`, not both

### **5. Terraform State & Import Issues**

#### **Resource Already Exists**
```
Error: Resource already exists
```

**Solutions:**
- Use Terraform import to bring existing resources under management
- Check if environments were created manually in GitHub
- Remove duplicate resource definitions
- Use the module's import functionality for existing environments

#### **State Lock Issues**
```
Error: Error acquiring the state lock
```

**Solutions:**
- Wait for other Terraform operations to complete
- Check if someone else is running Terraform on the same state
- Force unlock if necessary: `terraform force-unlock LOCK_ID`
- Verify your backend configuration is correct

## 🔍 **Advanced Troubleshooting**

### **Enable Debug Logging**
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
terraform apply
```

### **Validate Configuration**
```bash
# Check YAML syntax
terraform validate

# Plan without applying
terraform plan

# Check remote state access
terraform refresh
```

### **Authentication Verification**
```bash
# Verify GitHub CLI authentication
gh auth status

# Test GitHub API access
gh api user

# Get current token (for debugging)
gh auth token

# Check token scopes (if using PAT)
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user
```

### **GitHub API Rate Limiting** *(Rare)*
If you encounter rate limiting (very unlikely with normal usage):
- The terraform provider handles this automatically
- Reduce batch size if deploying 100+ environments
- Consider using GitHub Enterprise for higher limits
- Add small delays between large operations

## 📞 **Getting Help**

### **Before Opening an Issue:**
1. Check this troubleshooting guide
2. Verify your configuration against the examples
3. **Try GitHub CLI authentication** if using Personal Access Tokens
4. Enable debug logging and check for specific error messages
5. Test with a minimal configuration first

### **When Opening an Issue:**
- Include the specific error message
- Specify your authentication method (GitHub CLI vs PAT)
- Provide your Terraform version and provider versions
- Share a minimal reproduction case (remove sensitive data)
- Include relevant logs (sanitize any secrets)

### **Quick Self-Checks:**
- ✅ **Using GitHub CLI authentication** (recommended)
- ✅ GitHub CLI authenticated: `gh auth status`
- ✅ Azure subscription access confirmed
- ✅ Remote state accessible
- ✅ YAML configuration validates
- ✅ Repository and environment names follow conventions
- ✅ No conflicting deployment policies

## 🚀 **Performance Tips**

### **For Large Deployments:**
- Deploy in smaller batches if you have 50+ environments
- Use consistent naming conventions
- Group related environments in the same repository
- Consider using multiple state files for very large setups

### **Best Practices:**
- **Use GitHub CLI authentication** instead of Personal Access Tokens
- Test with minimal configuration first
- Use plan operations before apply
- Keep environment names short and descriptive
- Document your container environment mappings
- Regular backup of Terraform state
 