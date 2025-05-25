# 🧪 Testing Guide

This directory contains validation tests for the `stratus-tf-aca-gh-vending` module.

## 📋 **Test Overview**

### **Validation Tests (`validation_test.tf`)**
- **Purpose**: Test configuration validation logic and business rules
- **Dependencies**: None (uses mock data and test scenarios)
- **Speed**: Fast (< 30 seconds)
- **Use Case**: Development, CI/CD pipelines, configuration validation

## 🎯 **What the Tests Cover**

### **✅ Configuration Structure**
- YAML configuration format validation
- Required fields and structure verification
- Nested object validation (reviewers, policies, etc.)

### **✅ Naming Conventions**
- Environment name format validation
- Repository name format validation
- Azure resource naming compliance

### **✅ Security Policies**
- Production environment security requirements
- Wait timer limits and validation
- Reviewer configuration validation

### **✅ Policy Conflict Detection**
- Branch vs tag policy conflicts
- Mutually exclusive configuration detection
- GitHub API limitation awareness

### **✅ Variable & Secret Format**
- GitHub variable naming conventions (UPPERCASE_WITH_UNDERSCORES)
- Secret naming conventions
- Value validation (non-empty secrets)

### **✅ Remote State Structure**
- Expected `github_environment_config` structure
- Required Azure variables presence
- Role assignment structure validation

## 🚀 **Running the Tests**

The validation tests are **always safe to run** and don't require any external resources:

```bash
# Navigate to tests directory
cd tests

# Initialize Terraform
terraform init

# Run validation tests
terraform apply -auto-approve

# View results
terraform output validation_test_results
```

**Expected Output:**
```json
{
  "test_type": "Validation Tests",
  "test_scope": "Configuration validation without external dependencies",
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

## 🔧 **Understanding Test Results**

### **✅ Passing Tests**
- **Green checkmarks** indicate validation rules are working correctly
- Tests validate both positive cases (valid configs) and negative cases (invalid configs)

### **⚠️ Expected Failures**
- **Policy conflicts test** is designed to fail when it detects conflicting configurations
- This demonstrates the validation logic is working correctly

### **❌ Actual Failures**
- If other tests fail, there may be issues with the validation logic
- Check the test output for specific failure details

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
# Ensure all validation tests pass
cd tests
terraform apply -auto-approve

# Check for any unexpected failures
terraform output validation_test_results
```

### **In CI/CD:**
```bash
# Add to your CI pipeline
cd tests
terraform init
terraform apply -auto-approve
```

## 📝 **Test Data**

The tests use three main test configurations:

### **1. Valid Minimal Configuration**
```yaml
repositories:
  - repo: "test-repo"
    environments:
      - name: "dev"
        container_environment: "dev"
```

### **2. Valid Comprehensive Configuration**
```yaml
repositories:
  - repo: "test-repo-comprehensive"
    environments:
      - name: "dev-plan"
        container_environment: "dev"
        wait_timer: 0
        prevent_self_review: false
        reviewers:
          users: [{ username: "test-user" }]
          teams: [{ name: "test-team" }]
        deployment_branch_policy:
          protected_branches: false
          custom_branch_policies: true
          custom_branches: ["main", "develop"]
        variables:
          TEST_VAR: "test-value"
          DEBUG_MODE: "true"
        secrets:
          - name: "TEST_SECRET"
            value: "secret-value"
```

### **3. Invalid Configuration (Conflicting Policies)**
```yaml
repositories:
  - repo: "test-repo-invalid"
    environments:
      - name: "conflicting-env"
        container_environment: "dev"
        deployment_branch_policy:
          protected_branches: true
        deployment_tag_policy:
          enabled: true
          tag_patterns: ["v*"]
```

## 🔧 **Troubleshooting**

### **Tests Not Running:**
- Check Terraform version (requires >= 1.6.0)
- Verify test provider is available: `terraform providers`
- Ensure you're in the `tests/` directory

### **Unexpected Test Failures:**
- Review the specific test assertion that failed
- Check if validation logic in the main module changed
- Verify test data matches expected format

### **Adding New Tests:**
1. Add new test scenarios to `locals.test_configs`
2. Create new `test_assertions` resource
3. Add test coverage to output
4. Update this README with new test descriptions

## 🎯 **Integration Testing**

For **real integration testing** with actual Azure/GitHub resources:

1. **Use the module directly** in a test environment
2. **Create test tfvars** with real subscription/token values
3. **Run terraform apply** in a dedicated test directory
4. **Verify resources** are created correctly in Azure/GitHub
5. **Clean up** with `terraform destroy`

**Example integration test setup:**
```bash
# Create test directory
mkdir integration-test
cd integration-test

# Create test configuration
cat > main.tf << EOF
module "test" {
  source = "../"
  
  code_name                  = "test"
  environment               = "integration"
  subscription_id           = var.test_subscription_id
  state_storage_account_name = var.test_storage_account
  github_token              = var.test_github_token
  github_env_file           = "test-environments.yaml"
}
EOF

# Create test variables
cat > terraform.tfvars << EOF
test_subscription_id = "your-subscription-id"
test_storage_account = "yourstorageaccount"
test_github_token = "your-github-token"
EOF

# Run integration test
terraform init
terraform apply
terraform destroy  # Clean up
```

## 📚 **Related Documentation**

- [Terraform Testing](https://developer.hashicorp.com/terraform/language/tests)
- [Module Development](../README.md)
- [Contributing Guide](../CONTRIBUTING.md)
- [Troubleshooting Guide](../TROUBLESHOOTING.md) 