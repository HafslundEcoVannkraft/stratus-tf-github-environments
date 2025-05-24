# Contributing Guide

Thank you for your interest in contributing! 🎉 This project welcomes contributions from everyone.

## 🚀 Quick Start

### For Small Changes (typos, docs, small fixes)
1. **Fork** the repository
2. **Make your changes** directly on GitHub or locally
3. **Submit a pull request** - that's it!

### For Larger Changes
1. **Open an issue first** to discuss your idea
2. **Fork** the repository  
3. **Create a branch**: `git checkout -b your-feature-name`
4. **Make your changes**
5. **Test locally** (see below)
6. **Submit a pull request**

## 🧪 Testing Your Changes

Before submitting, please run these commands locally:

```bash
# Format your code
terraform fmt -recursive

# Validate your changes
terraform init -backend=false
terraform validate
```

That's it! Our automated checks will handle the rest.

## 📝 Commit Messages

We prefer descriptive commit messages, but don't stress about the format. Examples:
- `Fix typo in README`
- `Add validation for new variable`
- `Update example configuration`

## 🤝 Pull Request Process

1. **Fill out the PR template** (it's short!)
2. **Wait for automated checks** to run
3. **Address any feedback** from maintainers
4. **Celebrate** when your PR is merged! 🎉

## 💡 Need Help?

- **Not sure about something?** Ask in your PR or open an issue
- **First time contributing?** We're here to help you learn!
- **Found a bug?** Please report it - even if you can't fix it yourself

## 🎯 What We're Looking For

- **Bug fixes** of any size
- **Documentation improvements** 
- **Example updates**
- **New features** (please discuss first)
- **Typo fixes** (seriously, these help!)

## 📋 Code Style

- **Terraform**: Use `terraform fmt` to format your code
- **YAML**: Keep it simple and readable
- **Documentation**: Clear and concise

## 🙏 Recognition

All contributors are recognized in our release notes and GitHub contributors list.

---

**Remember**: Every contribution matters, no matter how small. Thank you for helping make this project better! ✨ 