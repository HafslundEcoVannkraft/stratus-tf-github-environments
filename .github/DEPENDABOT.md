# Dependabot Configuration

This repository uses [Dependabot](https://docs.github.com/en/code-security/dependabot) to automatically keep dependencies up-to-date, including Terraform providers and GitHub Actions.

## 🤖 What Dependabot Does

### Terraform Providers
- **Monitors**: All Terraform providers in `version.tf`
- **Schedule**: Weekly updates every Monday at 09:00 CET
- **Grouping**: Related providers are grouped together:
  - **Azure providers**: `azurerm`, `azapi`
  - **GitHub providers**: `github`
  - **Utility providers**: `random`, `null`, `time`

### GitHub Actions
- **Monitors**: All GitHub Actions in workflow files
- **Schedule**: Weekly updates every Monday at 10:00 CET
- **Grouping**: All GitHub Actions updates are grouped together

## 🔄 Auto-Merge Process

### Automatic Approval & Merge
Dependabot PRs are **automatically merged** if they meet these criteria:

✅ **Safe Updates** (auto-merged):
- Patch version updates (e.g., `4.8.1` → `4.8.2`)
- Security updates
- GitHub Actions updates

✅ **Validation Passes**:
- Terraform format check
- Terraform validation
- Example YAML file validation
- No breaking changes detected

### Manual Review Required
🔍 **Manual review needed** for:
- Major version updates (e.g., `4.x` → `5.x`)
- Minor version updates with potential breaking changes
- Failed validation tests

## 📋 PR Labels and Organization

### Labels Applied
- `dependencies` - All dependency updates
- `terraform` - Terraform provider updates
- `github-actions` - GitHub Actions updates
- `automated` - Automated updates

### Commit Message Format
- **Terraform**: `terraform: update provider azurerm to v4.8.2`
- **GitHub Actions**: `github-actions: update actions/checkout to v4.2.0`

## 🛡️ Security Features

### Auto-Merge Safety
- **Validation Required**: All PRs must pass validation before auto-merge
- **Breaking Change Detection**: Major version updates require manual review
- **Team Notification**: Platform team is automatically assigned and notified

### Review Process
1. **Dependabot creates PR** with dependency update
2. **Automated validation** runs (Terraform + examples)
3. **Auto-approval** if validation passes and update is safe
4. **Auto-merge** with squash commit
5. **Manual review** required for major updates or failures

## 🔧 Configuration Files

### `.github/dependabot.yml`
Main configuration file defining:
- Update schedules
- Package ecosystems
- Grouping rules
- Auto-merge policies

### `.github/workflows/dependabot-auto-merge.yml`
Workflow that handles:
- Terraform validation
- Example file testing
- Auto-approval and merge
- Manual review notifications

## 📊 Monitoring and Maintenance

### Weekly Schedule
- **Monday 09:00**: Terraform provider updates
- **Monday 10:00**: GitHub Actions updates
- **First Monday of month**: NPM dependencies (if applicable)

### Limits
- **Terraform**: Max 5 open PRs
- **GitHub Actions**: Max 3 open PRs
- **NPM**: Max 2 open PRs

### Team Assignment
- **Reviewers**: `HafslundEcoVannkraft/platform-team`
- **Assignees**: `HafslundEcoVannkraft/platform-team`

## 🚨 Troubleshooting

### Common Issues

#### Validation Failures
If Dependabot PRs fail validation:
1. Check the workflow logs for specific errors
2. Verify Terraform syntax and formatting
3. Ensure example files are valid YAML
4. Review for breaking changes in provider updates

#### Auto-Merge Not Working
Possible causes:
1. Branch protection rules preventing auto-merge
2. Required status checks not configured
3. Insufficient permissions for GitHub token
4. Manual review required due to major version update

#### Too Many Open PRs
If hitting PR limits:
1. Review and merge pending PRs manually
2. Adjust `open-pull-requests-limit` in `dependabot.yml`
3. Consider more frequent update schedules

### Manual Override
To manually merge a Dependabot PR:
```bash
# Approve the PR
gh pr review <PR_NUMBER> --approve

# Merge with squash
gh pr merge <PR_NUMBER> --squash --delete-branch
```

## 🔗 Useful Links

- [Dependabot Documentation](https://docs.github.com/en/code-security/dependabot)
- [Terraform Provider Versioning](https://developer.hashicorp.com/terraform/language/providers/requirements)
- [GitHub Actions Versioning](https://docs.github.com/en/actions/creating-actions/about-custom-actions#using-release-management-for-actions) 