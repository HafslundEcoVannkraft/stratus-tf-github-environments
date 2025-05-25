# Automated Workflows

This repository uses GitHub Actions to automate quality assurance, dependency management, and validation processes.

## 🔄 **Pull Request Validation** (`pr-validation.yml`)

**File**: [`.github/workflows/pr-validation.yml`](workflows/pr-validation.yml)

**Purpose**: Community-friendly validation that ensures essential quality standards while being welcoming to new contributors.

**Triggers**:
- Pull requests to `main` or `develop` branches
- On opened, synchronize, or reopened events

**Key Features**:
- **Essential validation only**: Focuses on must-have checks (Terraform syntax, YAML validation)
- **Helpful feedback**: Provides clear guidance instead of cryptic error messages
- **Community-friendly**: Warnings instead of failures where appropriate
- **Auto-labeling**: Automatically suggests helpful labels for organization

**Jobs**:

| Job | Purpose | Failure Impact |
|-----|---------|----------------|
| **Essential Checks** | Terraform format, init, validate + YAML syntax | ❌ Blocks merge |
| **Auto Label** | Suggests helpful labels based on changed files | ⚠️ Advisory only |

**What it validates**:
- ✅ **Terraform syntax**: Format, initialization, validation
- ✅ **YAML structure**: Syntax and basic schema validation  
- ✅ **Security awareness**: Scans for obvious sensitive information (advisory)
- ✅ **Examples**: Validates YAML examples if changed

**Community Benefits**:
- **Beginner-friendly**: Clear error messages with actionable guidance
- **Fast feedback**: Essential checks only, no overwhelming validation
- **Helpful automation**: Auto-suggests labels and provides guidance
- **Encouraging**: Celebrates successes and guides improvements

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

## �� Customization

### **Adding New Validation Checks**

To add new validation to the PR workflow:

1. **Add step** to the `essential-validation` job in `pr-validation.yml`
2. **Keep it simple**: Focus on essential checks that help contributors
3. **Provide guidance**: Include helpful error messages and next steps
4. **Test thoroughly**: Ensure new checks don't create barriers for beginners

### **Key Principles**:
- **Community-first**: Prioritize contributor experience over comprehensive validation
- **Essential only**: Only validate what's truly necessary for code quality
- **Helpful feedback**: Every error should include actionable guidance
- **Graceful degradation**: Prefer warnings over failures where possible

### **Example: Adding a New Check**

```yaml
- name: Check for common issues
  run: |
    echo "Checking for common configuration issues..."
    # Your validation logic here
    if [ "$issue_found" = true ]; then
      echo "⚠️ Issue found: [description]"
      echo "💡 To fix: [specific guidance]"
      echo "📚 More info: [link to documentation]"
    else
      echo "✅ No issues found"
    fi
```

### Modifying Auto-Merge

To change auto-merge behavior:

1. **Edit criteria** in `dependabot-auto-merge.yml`
2. **Update validation steps** as needed
3. **Test with Dependabot PR**
4. **Document changes** in this file

## 📚 Related Documentation

- [Contributing Guide](../CONTRIBUTING.md) - Development workflow and quick start
- [Support Guide](SUPPORT.md) - Getting help
- [Good First Issues](../GOOD_FIRST_ISSUES.md) - Beginner-friendly tasks
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