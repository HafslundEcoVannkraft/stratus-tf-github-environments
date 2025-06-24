# Dependabot Configuration

This document explains how Dependabot is configured in the `stratus-tf-github-environments` repository to automatically manage dependency updates.

## Overview

Dependabot is configured to monitor and automatically update three types of dependencies:

- **Terraform providers** (primary focus)
- **GitHub Actions**
- **NPM packages** (if present)

All configuration is defined in [`.github/dependabot.yml`](.github/dependabot.yml).

## Update Schedule

| Ecosystem      | Schedule             | Time (Europe/Oslo) | Max PRs |
| -------------- | -------------------- | ------------------ | ------- |
| Terraform      | Weekly (Monday)      | 09:00              | 5       |
| GitHub Actions | Weekly (Monday)      | 10:00              | 3       |
| NPM            | Monthly (1st Monday) | 11:00              | 2       |

## Terraform Provider Updates

### Monitored Providers

Dependabot tracks all providers defined in [`version.tf`](version.tf):

```hcl
azurerm = "~> 4.0"           # Azure Resource Manager
azapi = "~> 2.4.0"           # Azure API Management
github = "~> 6.6.0"          # GitHub provider
random = "~> 3.5.1"          # Random provider
null = "~> 3.2.1"            # Null provider
time = "~> 0.9.1"            # Time provider
```

### Grouping Strategy

Related providers are grouped together to reduce PR noise:

- **azure-providers**: `azurerm` + `azapi`
- **github-providers**: `github` provider
- **utility-providers**: `random` + `null` + `time`

### Update Types

- ✅ **Minor updates** (e.g., 4.1.0 → 4.2.0)
- ✅ **Patch updates** (e.g., 4.1.0 → 4.1.1)
- ❌ **Major updates** (e.g., 4.x → 5.x) - excluded to prevent breaking changes

## GitHub Actions Updates

### Monitored Actions

Dependabot monitors all workflow files in [`.github/workflows/`](.github/workflows/):

- `commit-validation-flexible.yml`
- `pr-validation.yml`
- `welcome-contributors.yml`
- `dependabot-auto-merge.yml`
- `integration-test.yml`
- `github-environment-vending.yml`

### Grouping

All GitHub Actions are grouped together:

- `actions/*` (official GitHub actions)
- `hashicorp/setup-terraform`

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

This conservative approach ensures stability and prevents unexpected breaking changes.

### Review Process

1. **Dependabot creates PR** with dependency update
2. **Automated validation** runs (Terraform + examples)
3. **Auto-approval** if validation passes and update is safe
4. **Auto-merge** with squash commit
5. **Manual review** required for major updates or failures

## Review Process

### Automatic Assignment

All Dependabot PRs are automatically:

- **Assigned to**: `HafslundEcoVannkraft/stratus-az-platform-approvers`
- **Reviewed by**: `HafslundEcoVannkraft/stratus-az-platform-approvers`

### Labels

Each PR receives appropriate labels:

- `dependencies` (all PRs)
- `terraform` | `github-actions` | `npm` (ecosystem-specific)
- `automated` (indicates Dependabot origin)

## Commit Message Format

Dependabot uses consistent commit message prefixes:

```
terraform: update azurerm provider to v4.1.0
github-actions: update actions/checkout to v4.2.0
npm: update @types/node to v20.1.0
```

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

#### Grouped Updates

Related dependencies are bundled to reduce noise

### Manual Actions

To manually trigger Dependabot:

1. Go to the repository's **Insights** tab
2. Click **Dependency graph** → **Dependabot**
3. Click **Check for updates** on the desired ecosystem

### Manual Override

To manually merge a Dependabot PR:

```bash
# Approve the PR
gh pr review <PR_NUMBER> --approve

# Merge with squash
gh pr merge <PR_NUMBER> --squash --delete-branch
```

## Configuration Changes

To modify Dependabot behavior:

1. Edit [`.github/dependabot.yml`](.github/dependabot.yml)
2. Common changes:
   - Adjust schedule frequency
   - Modify grouping patterns
   - Change auto-merge settings
   - Update reviewer assignments

## Best Practices

### For Maintainers

- ✅ Review Dependabot PRs promptly (especially security updates)
- ✅ Test grouped updates thoroughly before merging
- ✅ Monitor for breaking changes in provider updates
- ✅ Keep the `dependabot.yml` configuration up-to-date

### For Contributors

- ✅ Don't manually update dependencies that Dependabot manages
- ✅ Let Dependabot handle routine updates
- ✅ Focus on feature development and bug fixes

## Related Documentation

- [GitHub Dependabot Documentation](https://docs.github.com/en/code-security/dependabot)
- [Terraform Provider Versioning](https://developer.hashicorp.com/terraform/language/providers/requirements)
- [GitHub Actions Versioning](https://docs.github.com/en/actions/creating-actions/about-custom-actions#using-release-management-for-actions)
- [Repository Contributing Guidelines](./CONTRIBUTING.md)

---

> **Note**: This configuration prioritizes stability over bleeding-edge updates. Security patches are prioritized while feature updates require manual review to ensure compatibility with the Stratus Azure Landing Zone architecture.
