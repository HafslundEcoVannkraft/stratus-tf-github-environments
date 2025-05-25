# 🧪 Testing Guide

This directory contains testing infrastructure for the `stratus-tf-aca-gh-vending` module.

## 📋 **Test Types**

### **1. Validation Tests (`validation_test.tf`)**
- **Purpose**: Test configuration validation logic and business rules
- **Dependencies**: None (uses mock data and test scenarios)
- **Speed**: Fast (< 30 seconds)
- **Use Case**: Development, CI/CD pipelines, configuration validation
- **Runs**: Locally with `terraform plan/apply`

### **2. Integration Tests (GitHub Actions)**
- **Purpose**: Test the actual module deployment with real Azure/GitHub resources
- **Dependencies**: Azure subscription, GitHub token, real infrastructure
- **Speed**: Slower (5-10 minutes)
- **Use Case**: Pre-release validation, end-to-end testing
- **Runs**: Automatically on PRs and pushes via GitHub Actions

## 🎯 **Why Two Different Approaches?**

**The module cannot be tested as a child module because:**
- ✅ **Provider configurations** are defined directly in the module
- ✅ **Import blocks** are used (only allowed in root modules)  
- ✅ **Backend configuration** exists in the module

**Therefore:**
- **Validation tests** test the logic without calling the module
- **Integration tests** run the module directly as a root module

## 🚀 **Running Validation Tests**

Validation tests use standard Terraform features and work with any version >= 1.3.0:

```bash
# Navigate to tests directory
cd tests

# Initialize Terraform
terraform init

# Run validation tests
terraform plan

# Apply to see full results
terraform apply -auto-approve
```

**Expected Output:**
```json
{
  "test_summary": {
    "total_test_groups": 6,
    "passed_groups": 5,
    "failed_groups": 1,
    "overall_status": "FAILED"
  },
  "test_coverage": {
    "yaml_structure": "✅ YAML configuration structure validation",
    "naming_validation": "✅ Naming convention validation", 
    "security_policies": "✅ Security policy validation",
    "policy_conflicts": "⚠️ Policy conflict detection (expected to find conflicts)",
    "variable_secret_format": "✅ Variable and secret format validation",
    "remote_state_structure": "✅ Remote state structure validation"
  }
}
```

## 🔗 **Running Integration Tests**

Integration tests run automatically via GitHub Actions but can also be triggered manually.

### **Automatic Triggers:**
- **Pull Requests** to `main` branch
- **Pushes** to `main` branch  
- **File changes** in `*.tf`, `tests/**`, or workflow files

### **Manual Trigger:**
1. Go to **Actions** tab in GitHub
2. Select **Integration Tests** workflow
3. Click **Run workflow**
4. Choose whether to destroy resources after test (default: true)

### **Required Secrets:**
Configure these in your repository settings:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AZURE_CLIENT_ID` | Azure Service Principal Client ID | `12345678-1234-1234-1234-123456789012` |
| `AZURE_TENANT_ID` | Azure Tenant ID | `87654321-4321-4321-4321-210987654321` |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | `11111111-2222-3333-4444-555555555555` |
| `TEST_STORAGE_ACCOUNT_NAME` | Storage account for test state | `teststorageaccount` |
| `TEST_RESOURCE_GROUP_NAME` | Resource group for test resources | `test-rg` |

### **What Integration Tests Do:**

1. **🏗️ Setup Phase:**
   - Create test `github-environments.yaml` configuration
   - Create test `terraform.tfvars` with test values
   - Authenticate with Azure using OIDC

2. **🧪 Test Phase:**
   - Run `terraform init`, `validate`, `plan`
   - Apply the module to create real resources
   - Validate module outputs (environments, identities, roles)
   - Test GitHub API to verify environments were created
   - Verify environment variables and secrets

3. **🧹 Cleanup Phase:**
   - Destroy all created resources
   - Emergency cleanup on failure

### **Test Configuration:**

The integration tests use this configuration:

```yaml
repositories:
  - repo: "stratus-tf-aca-gh-vending-test"
    environments:
      - name: "integration-test-plan"
        container_environment: "dev"
        wait_timer: 0
        prevent_self_review: false
        variables:
          INTEGRATION_TEST: "true"
          TEST_TYPE: "plan"
      - name: "integration-test-apply"
        container_environment: "dev"
        wait_timer: 5
        prevent_self_review: true
        reviewers:
          teams:
            - name: "stratus-az-platform-approvers"
        variables:
          INTEGRATION_TEST: "true"
          TEST_TYPE: "apply"
```

## 🎯 **What Each Test Type Validates**

### **Validation Tests:**
- ✅ **Configuration structure**: YAML format and required fields
- ✅ **Naming conventions**: Environment and repository naming
- ✅ **Security policies**: Production environment requirements
- ✅ **Policy conflicts**: Branch vs tag policy conflicts
- ✅ **Variable format**: GitHub variable/secret naming
- ✅ **Remote state structure**: Expected output format

### **Integration Tests:**
- ✅ **Module execution**: Terraform init, plan, apply succeed
- ✅ **Azure resources**: Managed identities and role assignments created
- ✅ **GitHub integration**: Environments, variables, secrets configured
- ✅ **Output validation**: Module outputs have expected structure
- ✅ **API validation**: GitHub API confirms resource creation
- ✅ **Cleanup**: All resources properly destroyed

## 🔧 **Understanding Test Results**

### **✅ Validation Test Results**
- **Green checkmarks** indicate validation rules are working correctly
- **⚠️ Expected failures** show conflict detection is working
- **❌ Actual failures** indicate issues with validation logic

### **✅ Integration Test Results**
- **GitHub Actions** provides detailed logs and status
- **PR comments** show test results and configuration
- **Failed tests** include error details and cleanup status

## 🛠 **Development Workflow**

### **During Development:**
```bash
# Quick validation during development
cd tests
terraform apply -auto-approve
terraform output validation_test_results
```

### **Before Committing:**
```bash
# Ensure validation tests pass
cd tests
terraform apply -auto-approve

# Check for any unexpected failures
terraform output validation_test_results
```

### **Before Merging PR:**
- ✅ **Validation tests** pass locally
- ✅ **Integration tests** pass in GitHub Actions
- ✅ **PR comments** show successful test results

## 📝 **Test Files**

### **Validation Tests:**
- `validation_test.tf` - Main validation logic
- `test-github-environments.yaml` - Example configuration

### **Integration Tests:**
- `.github/workflows/integration-test.yml` - GitHub Actions workflow
- `integration-github-environments.yaml` - Comprehensive test configuration

### **Documentation:**
- `README.md` - This testing guide

## 🔧 **Troubleshooting**

### **Validation Tests Not Running:**
- Check Terraform version (requires >= 1.3.0)
- Ensure you're in the `tests/` directory
- Run `terraform init` if providers are missing

### **Integration Tests Failing:**

**Authentication Issues:**
- Verify Azure service principal has correct permissions
- Check GitHub token has required scopes (`repo`, `workflow`, `read:org`)
- Ensure OIDC is configured correctly

**Resource Issues:**
- Check Azure subscription limits
- Verify test resource group exists
- Ensure storage account is accessible

**GitHub API Issues:**
- Verify repository `stratus-tf-aca-gh-vending-test` exists
- Check GitHub token permissions
- Ensure team `stratus-az-platform-approvers` exists

### **Adding New Tests:**

**For Validation Tests:**
1. Add new test scenarios to `locals.test_configs`
2. Create new validation logic
3. Add new `check` blocks
4. Update documentation

**For Integration Tests:**
1. Modify `integration-github-environments.yaml`
2. Update GitHub Actions workflow
3. Add new validation steps
4. Test manually first

## 📚 **Related Documentation**

- [Module Development](../README.md)
- [Contributing Guide](../CONTRIBUTING.md)
- [Troubleshooting Guide](../TROUBLESHOOTING.md)
- [GitHub Actions Documentation](https://docs.github.com/en/actions) 