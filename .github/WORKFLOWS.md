# Automated Workflows

This repository uses GitHub Actions to automate quality assurance, dependency management, and validation processes.

## 🔄 Pull Request Validation

**File**: [`.github/workflows/pr-validation.yml`](workflows/pr-validation.yml)

**Triggers**: Pull requests to `main` or `develop` branches

**Purpose**: Comprehensive validation of all changes before they can be merged.

### Validation Jobs

| Job | Purpose | What It Checks |
|-----|---------|----------------|
| **Terraform Validation** | Code quality | Format, initialization, validation |
| **YAML Validation** | Configuration files | Syntax, schema structure |
| **Documentation Validation** | Content consistency | Broken links, missing updates |
| **Code Quality** | Standards compliance | TODO comments, debugging code, naming |
| **Security Validation** | Security patterns | Sensitive data, version constraints |
| **Commit Validation** | Message format | Conventional commits compliance |

### Automated Features

- **📊 Status Comments**: Detailed results posted to PR
- **🏷️ Auto-Labeling**: Labels applied based on changed files
- **📋 Summary Dashboard**: Overall status and next steps
- **🔗 Helpful Links**: Direct links to contributing guidelines

### Example PR Comment

```markdown
## 📋 Pull Request Validation Summary

🎉 All checks passed!

| Check | Status |
|-------|--------|
| Terraform Validation | ✅ success |
| YAML Validation | ✅ success |
| Documentation Validation | ✅ success |
| Code Quality | ✅ success |
| Security Validation | ✅ success |
| Commit Validation | ✅ success |

### ✅ Ready for Review
All automated checks have passed. This PR is ready for human review.
```

## 🤖 Dependabot Auto-Merge

**File**: [`.github/workflows/dependabot-auto-merge.yml`](workflows/dependabot-auto-merge.yml)

**Triggers**: Dependabot pull requests

**Purpose**: Automatically validate and merge safe dependency updates.

### Auto-Merge Criteria

**✅ Automatically Merged:**
- Patch version updates (e.g., `4.8.1` → `4.8.2`)
- Security updates
- GitHub Actions updates
- All validation tests pass

**🔍 Manual Review Required:**
- Major version updates (e.g., `4.x` → `5.x`)
- Failed validation tests
- Breaking changes detected

### Validation Steps

1. **Terraform Validation**: Format, init, validate
2. **Example Testing**: YAML syntax validation
3. **Breaking Change Detection**: Major version analysis
4. **Auto-Approval**: If all checks pass
5. **Auto-Merge**: Squash and delete branch

## 📊 Workflow Status

You can monitor workflow status through:

- **Repository badges** in README.md
- **Actions tab** in GitHub repository
- **PR status checks** on individual pull requests
- **Email notifications** (if configured)

## 🛠️ Workflow Configuration

### Required Permissions

```yaml
permissions:
  contents: read
  pull-requests: write
  checks: write
```

### Environment Variables

No sensitive environment variables are required. All workflows use:
- GitHub token (automatically provided)
- Repository context (automatically available)

### Secrets

No additional secrets required beyond GitHub's default `GITHUB_TOKEN`.

## 🔧 Customization

### Adding New Validation

To add new validation steps:

1. **Add job** to `pr-validation.yml`
2. **Update summary** in `pr-summary` job
3. **Update documentation** in this file
4. **Test thoroughly** with sample PR

### Modifying Auto-Merge

To change auto-merge behavior:

1. **Edit criteria** in `dependabot-auto-merge.yml`
2. **Update validation steps** as needed
3. **Test with Dependabot PR**
4. **Document changes** in this file

## 📚 Related Documentation

- [Community Contributing Guide](../CONTRIBUTING_COMMUNITY.md) - Quick start for new contributors
- [Detailed Contributing Guide](../CONTRIBUTING.md) - Full development workflow
- [Dependabot Configuration](DEPENDABOT.md) - Dependency management
- [Pull Request Template](PULL_REQUEST_TEMPLATE.md) - PR requirements

## 🐛 Troubleshooting

### Common Issues

**Workflow fails on fork PRs:**
- External forks have limited permissions
- Some checks may be skipped for security

**Auto-merge not working:**
- Check branch protection rules
- Verify required status checks
- Ensure proper permissions

**False positive security warnings:**
- Review patterns in security validation
- Add exceptions if needed
- Update documentation examples

### Getting Help

- **GitHub Issues**: Report workflow problems
- **Actions Logs**: Check detailed execution logs
- **Team Discussion**: Ask in team channels 