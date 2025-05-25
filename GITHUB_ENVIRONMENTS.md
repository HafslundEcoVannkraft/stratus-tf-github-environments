# 🌍 GitHub Environments for Integration Testing

## 📋 **Overview**

The integration test workflow uses GitHub environments to simplify Azure federated credential configuration and improve security. This document explains the benefits and setup process.

## 🎯 **Benefits of GitHub Environments**

### **🔐 Enhanced Security**
- **Environment-specific credentials**: Separate federated credentials per environment
- **Access control**: Restrict who can run integration tests
- **Approval workflows**: Optional manual approval for sensitive operations
- **Audit trail**: Better tracking of environment-specific deployments

### **🔧 Simplified Configuration**
- **Specific subject claims**: More precise federated credential targeting
- **Environment variables**: Centralized configuration per environment
- **Protection rules**: Built-in safeguards for production environments

### **📊 Better Organization**
- **Clear separation**: Test vs production credentials
- **Environment history**: Track deployments per environment
- **Status visibility**: See environment-specific deployment status

## 🛠️ **Setup Instructions**

### **1. Create GitHub Environment**

1. Go to your repository → **Settings** → **Environments**
2. Click **New environment**
3. Name: `integration-test`
4. Configure protection rules (optional):
   - **Required reviewers**: Add team members for approval
   - **Wait timer**: Add delay before deployment
   - **Deployment branches**: Restrict to specific branches

### **2. Configure Environment Variables**

In the `integration-test` environment, add these variables:

```bash
AZURE_CLIENT_ID=your-service-principal-client-id
AZURE_TENANT_ID=your-azure-tenant-id
AZURE_SUBSCRIPTION_ID=your-azure-subscription-id
GH_APP_ID=your-github-app-id
```

### **3. Configure Azure Federated Credential**

#### **Azure CLI Setup**
```bash
# Set variables
APP_ID="your-service-principal-app-id"
REPO_OWNER="HafslundEcoVannkraft"
REPO_NAME="stratus-tf-aca-gh-vending"
ENVIRONMENT_NAME="integration-test"

# Create federated credential for the integration-test environment
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "stratus-tf-aca-gh-vending-integration-test",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$REPO_OWNER'/'$REPO_NAME':environment:'$ENVIRONMENT_NAME'",
    "description": "GitHub Actions integration test environment for stratus-tf-aca-gh-vending",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

#### **Azure Portal Setup**
1. Go to **Azure Active Directory** → **App registrations**
2. Select your service principal
3. Go to **Certificates & secrets** → **Federated credentials**
4. Click **Add credential**
5. Select **GitHub Actions deploying Azure resources**
6. Configure:
   - **Organization**: `HafslundEcoVannkraft`
   - **Repository**: `stratus-tf-aca-gh-vending`
   - **Entity type**: `Environment`
   - **Environment name**: `integration-test`
   - **Name**: `stratus-tf-aca-gh-vending-integration-test`

## 🔍 **Federated Credential Subject Claims**

### **Environment-Specific Subject**
```
repo:HafslundEcoVannkraft/stratus-tf-aca-gh-vending:environment:integration-test
```

**Benefits:**
- ✅ **Precise targeting**: Only the integration-test environment can use this credential
- ✅ **Security isolation**: Other workflows cannot access these credentials
- ✅ **Clear audit trail**: All token requests are tied to the specific environment

### **Comparison with Repository-Wide Subject**
```
repo:HafslundEcoVannkraft/stratus-tf-aca-gh-vending:ref:refs/heads/main
```

**Limitations:**
- ❌ **Broad access**: Any workflow on main branch can use the credential
- ❌ **Less granular**: Cannot distinguish between different types of operations
- ❌ **Security risk**: Accidental credential usage in other workflows

## 🚀 **Workflow Integration**

### **Job Configuration**
```yaml
test-sequential:
  name: Test ${{ matrix.github_env_file }}
  runs-on: ubuntu-latest
  environment: integration-test  # 🔑 Key configuration
  env:
    ARM_USE_OIDC: true
    ARM_CLIENT_ID: ${{ vars.AZURE_CLIENT_ID }}
    ARM_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}
    ARM_SUBSCRIPTION_ID: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

### **Automatic Token Exchange**
When the job runs:
1. **GitHub generates OIDC token** with environment-specific subject claim
2. **Azure validates the token** against the federated credential
3. **Azure issues access token** for the service principal
4. **Terraform uses the token** for Azure operations

## 🔒 **Security Best Practices**

### **Environment Protection Rules**
```yaml
# Recommended protection rules for integration-test environment
protection_rules:
  - required_reviewers: 1        # Require manual approval
  - wait_timer: 0               # No delay for integration tests
  - deployment_branches:        # Restrict to specific branches
    - main
    - develop
```

### **Principle of Least Privilege**
- **Service Principal Roles**:
  - `Contributor` (on test resource groups only)
  - `Storage Blob Data Contributor` (on test storage accounts only)
- **Environment Access**:
  - Limit to integration test team members
  - Regular access reviews

### **Credential Rotation**
```bash
# Rotate federated credentials periodically
az ad app federated-credential delete --id $APP_ID --federated-credential-id $CRED_ID
az ad app federated-credential create --id $APP_ID --parameters @new-credential.json
```

## 🧪 **Testing the Configuration**

### **Verify Environment Setup**
```bash
# Check environment configuration
gh api repos/HafslundEcoVannkraft/stratus-tf-aca-gh-vending/environments/integration-test

# List environment variables
gh api repos/HafslundEcoVannkraft/stratus-tf-aca-gh-vending/environments/integration-test/variables
```

### **Test Federated Credential**
```bash
# Trigger integration test workflow
gh workflow run integration-test.yml

# Monitor workflow execution
gh run list --workflow=integration-test.yml
gh run view --log
```

### **Verify Azure Token Exchange**
Check the workflow logs for successful Azure login:
```
✅ Azure OIDC authentication configured:
  - Client ID: 12345678-1234-1234-1234-123456789012
  - Tenant ID: 87654321-4321-4321-4321-210987654321
  - Subscription ID: abcdef12-3456-7890-abcd-ef1234567890
```

## 🔧 **Troubleshooting**

### **Common Issues**

#### **Federated Credential Not Found**
```
Error: AADSTS70021: No matching federated identity record found
```
**Solution**: Verify the subject claim matches exactly:
```bash
# Check the subject claim in your federated credential
az ad app federated-credential list --id $APP_ID --query "[].subject"
```

#### **Environment Not Found**
```
Error: Environment 'integration-test' not found
```
**Solution**: Create the environment in GitHub repository settings.

#### **Missing Environment Variables**
```
Error: Missing required Azure authentication environment variables
```
**Solution**: Add variables to the GitHub environment (not repository variables).

### **Debug Commands**
```bash
# List all federated credentials
az ad app federated-credential list --id $APP_ID

# Check environment configuration
gh api repos/OWNER/REPO/environments/integration-test

# View workflow run details
gh run view RUN_ID --log
```

## 📚 **Additional Resources**

- [GitHub Environments Documentation](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [Azure Federated Credentials](https://docs.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation)
- [GitHub OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)

---

**💡 Pro Tip**: Use different environments (`integration-test`, `staging`, `production`) with separate federated credentials for complete isolation and security. 