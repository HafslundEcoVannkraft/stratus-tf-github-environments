# Contributing to GitHub Environment Vending for Azure Container Apps

Thank you for your interest in contributing to this project! This guide will help you understand how to contribute effectively.

## 🚀 Quick Start for Contributors

### Prerequisites

- **Terraform** >= 1.3.0
- **GitHub CLI** (for testing workflows)
- **Azure CLI** (for testing Azure integration)
- **Git** with proper configuration
- Access to a test Azure subscription
- GitHub organization with appropriate permissions

### Development Environment Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/HafslundEcoVannkraft/stratus-tf-aca-gh-vending.git
   cd stratus-tf-aca-gh-vending
   ```

2. **Install development tools**:
   ```bash
   # Install Terraform (if not already installed)
   # macOS
   brew install terraform
   
   # Install GitHub CLI
   brew install gh
   
   # Install Azure CLI
   brew install azure-cli
   ```

3. **Set up authentication**:
   ```bash
   # Azure authentication
   az login
   
   # GitHub authentication
   gh auth login --scopes "repo,workflow,read:org"
   ```

## 📋 Development Workflow

### 1. Issue Creation

Before starting work:
- **Search existing issues** to avoid duplicates
- **Create a detailed issue** describing the problem or enhancement
- **Use issue templates** when available
- **Add appropriate labels** (bug, enhancement, documentation, etc.)

### 2. Branch Strategy

We use a **feature branch workflow**:

```bash
# Create a feature branch from main
git checkout main
git pull origin main
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/issue-description

# Or for documentation
git checkout -b docs/documentation-update
```

**Branch naming conventions**:
- `feature/` - New features or enhancements
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test improvements

### 3. Development Guidelines

#### **Code Style and Standards**

- **Terraform formatting**: Always run `terraform fmt -recursive`
- **Variable naming**: Use descriptive names with proper prefixes
- **Resource naming**: Follow the established naming convention
- **Comments**: Add meaningful comments for complex logic
- **Validation**: Include proper variable validation rules

#### **File Organization**

- **Keep files focused**: Each file should have a clear purpose
- **Use consistent headers**: Include proper file descriptions
- **Group related resources**: Logical organization within files
- **Maintain alphabetical ordering**: For variables, outputs, etc.

#### **Testing Requirements**

Before submitting a PR, our automated validation workflow will check most requirements, but you should still run these locally:

1. **Terraform validation** (automated in PR):
   ```bash
   terraform fmt -check -recursive
   terraform init -backend=false
   terraform validate
   ```

2. **Example validation** (automated in PR):
   ```bash
   # Validate YAML examples
   yamllint examples/*.yaml
   
   # Test example configurations
   terraform plan -var-file=test/test.tfvars
   ```

3. **Documentation checks** (automated in PR):
   ```bash
   # Check for broken links
   # Verify all examples are up-to-date
   # Ensure README reflects changes
   ```

> **🤖 Automated Validation**: When you open a PR, our [automated validation workflow](.github/workflows/pr-validation.yml) will automatically check:
> - Terraform formatting and validation
> - YAML file syntax and structure
> - Documentation consistency and broken links
> - Code quality (TODO comments, debugging code, file naming)
> - Security patterns (sensitive information detection)
> - Conventional commit message format
> - Auto-labeling based on changed files
> 
> The workflow will comment on your PR with detailed results and actionable feedback.

### 4. Commit Guidelines

We follow **Conventional Commits** specification:

```bash
# Format: type(scope): description
git commit -m "feat(validation): add Azure naming constraint validation"
git commit -m "fix(github): resolve API rate limiting issues"
git commit -m "docs(readme): update configuration examples"
git commit -m "refactor(locals): optimize variable processing logic"
```

**Commit types**:
- `feat` - New features
- `fix` - Bug fixes
- `docs` - Documentation changes
- `style` - Code style changes (formatting, etc.)
- `refactor` - Code refactoring
- `test` - Test additions or modifications
- `chore` - Maintenance tasks

**Scope examples**:
- `validation` - Input validation
- `github` - GitHub integration
- `azure` - Azure resources
- `workflow` - GitHub Actions workflow
- `examples` - Example configurations
- `deps` - Dependencies

### 5. Pull Request Process

#### **Automated Validation Workflow**

Our repository includes comprehensive automated validation that runs on every PR:

**🔧 What Gets Checked Automatically:**
- **Terraform**: Formatting, initialization, and validation
- **YAML**: Syntax validation and schema structure
- **Documentation**: Broken links, missing updates, example references
- **Code Quality**: TODO comments, debugging code, file naming conventions
- **Security**: Sensitive information patterns, provider version constraints
- **Commits**: Conventional commit message format validation

**📊 PR Status Dashboard:**
Each PR gets a comprehensive status comment showing:
- ✅/❌ Status for each validation check
- 📋 Summary of what passed/failed
- 🔗 Links to contributing guidelines
- 🏷️ Automatic labels based on changed files

**⚡ Benefits:**
- **Faster feedback**: Immediate validation without waiting for human review
- **Consistent quality**: Automated enforcement of coding standards
- **Learning tool**: Clear explanations of what needs to be fixed
- **Reduced reviewer burden**: Focus on logic and design, not formatting

#### **Before Creating a PR**

1. **Ensure your branch is up-to-date**:
   ```bash
   git checkout main
   git pull origin main
   git checkout your-feature-branch
   git rebase main
   ```

2. **Run all validations**:
   ```bash
   terraform fmt -recursive
   terraform validate
   # Test examples if applicable
   ```

3. **Update documentation**:
   - Update README if adding new features
   - Update examples if changing configuration
   - Add entries to CHANGELOG.md
   - Update variable documentation

#### **PR Creation**

1. **Use descriptive titles**: Clear, concise description of changes
2. **Fill out PR template**: Provide all requested information
3. **Link related issues**: Use "Fixes #123" or "Closes #123"
4. **Add appropriate labels**: enhancement, bug, documentation, etc. (or let automation handle it)
5. **Request reviews**: Tag relevant team members

> **🔄 Automated Process**: After creating your PR:
> 1. **Automated validation** runs immediately with 6 comprehensive checks
> 2. **Auto-labeling** applies relevant labels based on changed files
> 3. **PR summary comment** provides detailed status and next steps
> 4. **Status checks** must pass before merge is allowed
> 5. **Human review** required after automated checks pass

#### **PR Description Template**

```markdown
## Description
Brief description of changes and motivation.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Terraform fmt and validate pass
- [ ] Examples validate successfully
- [ ] Manual testing completed (describe)

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Examples updated (if applicable)

## Related Issues
Fixes #(issue number)
```

## 🧪 Testing Guidelines

### Local Testing

1. **Basic validation**:
   ```bash
   terraform fmt -check -recursive
   terraform init -backend=false
   terraform validate
   ```

2. **Example testing**:
   ```bash
   # Test with minimal example
   terraform plan -var-file=examples/minimal.tfvars
   
   # Test with complete example
   terraform plan -var-file=examples/complete.tfvars
   ```

3. **YAML validation**:
   ```bash
   # Install yq if not available
   brew install yq
   
   # Validate YAML syntax
   for file in examples/*.yaml; do
     echo "Validating $file"
     yq eval '.' "$file" > /dev/null
   done
   ```

### Integration Testing

For testing actual deployments:

1. **Use test environment**: Never test against production
2. **Clean up resources**: Always destroy test resources after testing
3. **Document test scenarios**: Include test cases in PR description

## 📚 Documentation Standards

### README Updates

When adding features:
- Update the configuration reference
- Add examples demonstrating new functionality
- Update the variables table
- Add troubleshooting information if needed

### Code Documentation

- **Variable descriptions**: Clear, concise descriptions with constraints
- **Output descriptions**: Explain what the output provides
- **Resource comments**: Document complex resource configurations
- **Local variable comments**: Explain complex logic

### Example Files

- **Keep examples current**: Update when adding new features
- **Provide realistic scenarios**: Use practical, real-world examples
- **Include comments**: Explain configuration choices
- **Test examples**: Ensure all examples validate

## 🔧 Common Development Tasks

### Adding a New Variable

1. **Add to variables.tf**:
   ```hcl
   variable "new_variable" {
     description = "Clear description of the variable's purpose"
     type        = string
     default     = null
     
     validation {
       condition     = var.new_variable == null || can(regex("^[a-z0-9-]+$", var.new_variable))
       error_message = "Variable must contain only lowercase letters, numbers, and hyphens."
     }
   }
   ```

2. **Update documentation**:
   - Add to README variables table
   - Update examples if relevant
   - Add to CHANGELOG.md

3. **Test the validation**:
   ```bash
   terraform plan -var="new_variable=invalid-VALUE"  # Should fail
   terraform plan -var="new_variable=valid-value"    # Should succeed
   ```

### Adding a New Feature

1. **Plan the implementation**:
   - Consider backward compatibility
   - Plan validation requirements
   - Consider documentation needs

2. **Implement incrementally**:
   - Start with basic functionality
   - Add validation and error handling
   - Add comprehensive testing

3. **Update all relevant files**:
   - Core Terraform files
   - Examples
   - Documentation
   - Tests

## 🐛 Bug Reports

### Creating Effective Bug Reports

Include:
- **Clear description** of the issue
- **Steps to reproduce** the problem
- **Expected behavior** vs actual behavior
- **Environment details** (Terraform version, provider versions)
- **Configuration snippets** (sanitized)
- **Error messages** (full output)

### Bug Report Template

```markdown
## Bug Description
Clear and concise description of the bug.

## Steps to Reproduce
1. Step one
2. Step two
3. Step three

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Environment
- Terraform version: 
- Provider versions:
- Operating system:

## Configuration
```hcl
# Sanitized configuration that reproduces the issue
```

## Error Output
```
Full error message or output
```

## Additional Context
Any other context about the problem.
```

## 🚀 Release Process

### Version Numbering

We follow [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Checklist

1. **Update CHANGELOG.md**: Move unreleased changes to new version
2. **Update version references**: In documentation and examples
3. **Create release PR**: For final review
4. **Tag release**: After merging to main
5. **Update documentation**: Ensure all docs reflect new version

## 💬 Getting Help

### Communication Channels

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Team Slack**: For internal team communication (if applicable)

### Code Review Process

- **All PRs require review**: At least one approval required
- **Platform team review**: For significant changes
- **Automated checks**: Must pass before merge
- **Documentation review**: Ensure docs are updated

## 📜 Code of Conduct

### Our Standards

- **Be respectful**: Treat all contributors with respect
- **Be inclusive**: Welcome contributors from all backgrounds
- **Be constructive**: Provide helpful feedback
- **Be patient**: Help newcomers learn and contribute

### Reporting Issues

If you experience or witness unacceptable behavior, please report it to the project maintainers.

## 🙏 Recognition

Contributors are recognized through:
- **GitHub contributors list**: Automatic recognition
- **CHANGELOG mentions**: For significant contributions
- **Release notes**: For major features or fixes

Thank you for contributing to make this project better! 🎉 