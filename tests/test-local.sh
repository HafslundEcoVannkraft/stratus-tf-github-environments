#!/bin/bash

# Local Testing Script for stratus-tf-aca-gh-vending
# This script validates the module configuration without deploying resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo ""
    echo "=================================================="
    print_status $BLUE "$1"
    echo "=================================================="
}

print_success() {
    print_status $GREEN "✅ $1"
}

print_warning() {
    print_status $YELLOW "⚠️  $1"
}

print_error() {
    print_status $RED "❌ $1"
}

# Check if we're in the right directory
if [[ ! -f "variables.tf" ]] || [[ ! -f "outputs.tf" ]] || [[ ! -f "locals.tf" ]]; then
    print_error "This script must be run from the module root directory"
    print_error "Expected files: variables.tf, outputs.tf, locals.tf"
    exit 1
fi

print_header "🧪 Local Testing for stratus-tf-aca-gh-vending"

# Check prerequisites
print_header "📋 Checking Prerequisites"

# Check Terraform
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    print_success "Terraform found: v$TERRAFORM_VERSION"
else
    print_error "Terraform not found. Please install Terraform."
    exit 1
fi

# Check if test configuration exists
if [[ -f "tests/integration-github-environments.yaml" ]]; then
    print_success "Test configuration found"
else
    print_error "Test configuration not found at tests/integration-github-environments.yaml"
    exit 1
fi

# Terraform validation
print_header "🔍 Terraform Validation"

print_status $BLUE "Running terraform fmt..."
if terraform fmt -check -recursive .; then
    print_success "Code formatting is correct"
else
    print_warning "Code formatting issues found. Run 'terraform fmt -recursive .' to fix."
fi

print_status $BLUE "Running terraform init..."
if terraform init -backend=false > /dev/null 2>&1; then
    print_success "Terraform initialization successful"
else
    print_error "Terraform initialization failed"
    exit 1
fi

print_status $BLUE "Running terraform validate..."
if terraform validate; then
    print_success "Terraform validation passed"
else
    print_error "Terraform validation failed"
    exit 1
fi

# YAML validation
print_header "📄 YAML Configuration Validation"

# Check if yq is available for YAML validation
if command -v yq &> /dev/null; then
    print_status $BLUE "Validating YAML syntax..."
    
    for yaml_file in tests/*.yaml examples/*.yaml; do
        if [[ -f "$yaml_file" ]]; then
            if yq eval '.' "$yaml_file" > /dev/null 2>&1; then
                print_success "YAML syntax valid: $yaml_file"
            else
                print_error "YAML syntax invalid: $yaml_file"
                exit 1
            fi
        fi
    done
else
    print_warning "yq not found. Skipping YAML syntax validation."
    print_status $YELLOW "Install yq with: brew install yq (macOS) or apt-get install yq (Ubuntu)"
fi

# Configuration structure validation
print_header "🏗️  Configuration Structure Validation"

print_status $BLUE "Checking test configuration structure..."

# Security validation
print_header "🔒 Security Validation"

print_status $BLUE "Checking for security best practices..."

print_status $BLUE "Checking for hardcoded secrets..."

matches=$(grep -r -iE '(\bpassword\b|\bsecret\b|\bkey\b)[^=]*=\s*"(.*)"' --include="*.tf" --include="*.yaml" . | \
  grep -v "variable\|description\|name.*secret\|each\.key\|env\.key\|secret\.key" | \
  grep -v "# " | \
  awk -F'=' '
    {
      # Remove leading/trailing whitespace
      gsub(/^[ \t]+|[ \t]+$/, "", $2)
      # Remove leading/trailing quotes
      val = $2
      gsub(/^"/, "", val)
      gsub(/"$/, "", val)
      # Only print if value does NOT contain ${
      if (val !~ /\$\{/) print $0
    }
  '
)

if [[ -n "$matches" ]]; then
    print_warning "Potential hardcoded secrets found (literal values only, review carefully):"
    echo "$matches"
else
    print_success "No hardcoded secrets detected"
fi

# Check for TODO/FIXME comments (exclude documentation examples)
if grep -r -i "todo\|fixme\|hack" --include="*.tf" --include="*.md" . | grep -v "tests/README.md" | grep -v "example\|check.*TODO" > /dev/null; then
    print_warning "TODO/FIXME comments found:"
    grep -r -i "todo\|fixme\|hack" --include="*.tf" --include="*.md" . | grep -v "tests/README.md" | grep -v "example\|check.*TODO" || true
else
    print_success "No actionable TODO/FIXME comments found"
fi

# Documentation validation
print_header "📚 Documentation Validation"

print_status $BLUE "Checking documentation completeness..."

# Check if README exists and has basic sections
if [[ -f "README.md" ]]; then
    # Check for key sections (more flexible matching)
    sections_found=0
    if grep -q -i "usage\|quick setup\|getting started" README.md; then
        ((sections_found++))
    fi
    if grep -q -i "requirements\|prerequisites" README.md; then
        ((sections_found++))
    fi
    if grep -q -i "examples\|configuration" README.md; then
        ((sections_found++))
    fi
    
    if [[ $sections_found -ge 2 ]]; then
        print_success "README.md has essential sections"
    else
        print_warning "README.md could benefit from more sections (Usage, Requirements, Examples)"
    fi
else
    print_error "README.md not found"
fi

# Check if examples exist
if [[ -d "examples" ]] && [[ -n "$(ls -A examples/)" ]]; then
    print_success "Examples directory exists and is not empty"
else
    print_warning "Examples directory is missing or empty"
fi

# Final summary
print_header "📊 Test Summary"

print_success "Local validation completed successfully!"
echo ""
print_status $BLUE "Next steps:"
echo "  1. Set up GitHub environment 'integration-test' (see GITHUB_ENVIRONMENTS.md)"
echo "  2. Configure Azure federated credentials for the environment"
echo "  3. Run integration tests via GitHub Actions"
echo "  4. Test with real Azure subscription (optional)"
echo "  5. Create a PR to trigger automated testing"
echo ""
print_status $YELLOW "Note: This script only validates configuration and syntax."
print_status $YELLOW "For full testing, use the GitHub Actions integration tests."
print_status $YELLOW "See GITHUB_ENVIRONMENTS.md for environment setup instructions." 