# 🤝 **Contributing to stratus-tf-aca-gh-vending**

> **🚧 WORK IN PROGRESS** 🚧  
> This project is currently under active development. Contribution guidelines and processes may evolve as the project matures.

Welcome! We're excited that you want to contribute to the **stratus-tf-aca-gh-vending** project. This guide will help you get started with contributing effectively.

Thank you for your interest in contributing! 🎉 This project welcomes contributions from everyone.

## 🚀 **Quick Start**

### **For Small Changes** (typos, docs, small fixes)
1. **Fork** the repository
2. **Make your changes** directly on GitHub or locally
3. **Submit a pull request** - that's it!

### **For Larger Changes**
1. **Open an issue first** to discuss your idea
2. **Fork** the repository  
3. **Create a branch**: `git checkout -b your-feature-name`
4. **Make your changes**
5. **Test locally** (see below)
6. **Submit a pull request**

## 🧪 **Testing Your Changes**

Before submitting, please run these commands locally:

```bash
# Format your code
terraform fmt -recursive

# Validate your changes
terraform init -backend=false
terraform validate
```

That's it! Our automated checks will handle the rest.

## 📝 **Commit Messages**

We prefer descriptive commit messages, but don't stress about the format. Examples:
- `Fix typo in README`
- `Add validation for new variable`
- `Update example configuration`

## 🤝 **Pull Request Process**

1. **Fill out the PR template** (it's short!)
2. **Wait for automated checks** to run
3. **Address any feedback** from maintainers
4. **Celebrate** when your PR is merged! 🎉

## 💡 **Need Help?**

- **Not sure about something?** Ask in your PR or open an issue
- **First time contributing?** We're here to help you learn!
- **Found a bug?** Please report it - even if you can't fix it yourself

## 🎯 **What We're Looking For**

- **Bug fixes** of any size
- **Documentation improvements** 
- **Example updates**
- **New features** (please discuss first)
- **Typo fixes** (seriously, these help!)

## 📋 **Code Style**

- **Terraform**: Use `terraform fmt` to format your code
- **YAML**: Keep it simple and readable
- **Documentation**: Clear and concise

---

## 🔧 **Advanced Development** (for complex contributions)

### **Development Environment Setup**

For major features or complex bug fixes, you'll need:

- **Terraform** >= 1.3.0
- **GitHub CLI** (for testing workflows)
- **Azure CLI** (for testing Azure integration)
- Access to a test Azure subscription

### **Branch Strategy**

```bash
# Create a feature branch from main
git checkout main
git pull origin main
git checkout -b feature/your-feature-name
```

**Branch naming conventions**:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates

### **Advanced Testing**

For complex changes:

```bash
# Validate YAML examples
yq . examples/*.yaml

# Test example configurations
terraform plan -var-file=test/test.tfvars
```

### **Documentation Updates**

When adding features:
- Update README if adding new functionality
- Update examples if changing configuration
- Update variable documentation

### **Conventional Commits** (optional but appreciated)

For better change tracking:
```bash
git commit -m "feat(validation): add Azure naming constraint validation"
git commit -m "fix(github): resolve API rate limiting issues"
git commit -m "docs(readme): update configuration examples"
```

## 🙏 **Recognition**

All contributors are recognized in our release notes and GitHub contributors list.

## 🤖 **AI-Assisted Development**

If you're using AI tools to help with contributions:

- **Read the AI Context**: Check [AI_CONTEXT.md](AI_CONTEXT.md) for essential project context
- **Understand Constraints**: Be aware of GitHub API limitations and Stratus-specific requirements
- **Follow Patterns**: Maintain existing naming conventions and architectural patterns
- **Test Thoroughly**: AI-generated code should be validated locally before submission

The AI context file provides comprehensive background that helps AI assistants understand the project's architecture, constraints, and best practices.

---

**Remember**: Every contribution matters, no matter how small. Thank you for helping make this project better! ✨ 