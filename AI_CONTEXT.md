# AI Context for stratus-tf-github-environments

> **🚧 WORK IN PROGRESS** 🚧  
> This project is currently under active development. Features, APIs, and documentation may change without notice.

This document provides essential context for AI assistants working on the `stratus-tf-github-environments` project. It helps maintain consistency across AI sessions and ensures new AI interactions understand the project's purpose, architecture, and constraints.

## 🎯 Project Overview

### Purpose
This Terraform module automates the creation of GitHub deployment environments for Azure infrastructure within the **Stratus Corp Azure Landing Zone** architecture. It establishes secure OIDC federation between GitHub Actions and Azure, eliminating the need for static credentials.

### Key Value Proposition
- **Generic Infrastructure Support**: Works with any Azure infrastructure (Container Apps, AKS, VMs, Functions, etc.)
- **Secure Authentication**: OIDC federation replaces static secrets
- **Centralized Management**: IaC repository controls all environment creation
- **Dynamic Role Assignment**: Convention-based role mapping for infinite flexibility
- **Enterprise Ready**: Designed for corporate environments with strict security requirements

## 🏗️ Architecture Context

### Three-Layer Environment Model

1. **Stratus Landing Zone** (Azure Subscription Level)
   - Complete Azure subscription with shared resources
   - Named: `{code_name}-{environment}` (e.g., "myapp-dev")
   - Contains: Multiple deployment targets, shared networking, DNS, monitoring

2. **Deployment Targets** (Application Level)
   - Logical separation within a subscription
   - Examples: `web-apps`, `api-services`, `data-processing`, `container-apps`, `kubernetes`
   - Independent scaling and resource allocation
   - Technology agnostic (any Azure infrastructure)

3. **GitHub Deployment Environments** (Workflow Level)
   - Control deployment workflows and security policies
   - Examples: `web-dev-ci`, `api-prod-cd`, `data-validate`
   - Each gets unique managed identity and federated credentials

### Dynamic Role Assignment Convention
- Environment names ending with `-{suffix}` automatically get `role_assignments.{suffix}`
- Examples: `prod-ci` → `role_assignments.ci`, `dev-deploy` → `role_assignments.deploy`
- `global` role assignments always applied
- Supports any custom convention (ci/cd, validate/deploy, test/backup, etc.)

### Execution Model
- **NOT a standalone module** - part of larger Stratus workflow
- **Runs in IaC repository context** for Azure access and VNet connectivity
- **Workflow copies module code** - no local Terraform files needed
- **Remote state integration** - reads configuration from upstream infrastructure

## 🔧 Technical Architecture

### Core Components
- **Terraform Module**: Creates Azure managed identities and GitHub environments
- **GitHub Workflow**: `github-environment-vending.yml` for execution
- **YAML Configuration**: `github-environments.yaml` for environment definitions
- **Remote State Integration**: Reads from upstream infrastructure outputs

### Key Files Structure
```
stratus-tf-github-environments/
├── .github/
│   ├── dependabot.yml           # Dependency management configuration
│   └── workflows/               # CI/CD workflows
│       ├── github-environment-vending.yml  # Main vending workflow
│       └── integration-test.yml # End-to-end testing
├── examples/                    # Configuration examples
├── tests/                       # Testing infrastructure
├── *.tf                        # Terraform module files
├── README.md                   # Primary documentation
├── DEPENDABOT.md              # Dependency management docs
├── AI_CONTEXT.md              # This file
├── AUTHENTICATION.md          # GitHub CLI setup guide
├── CONTRIBUTING.md            # Contributor guidelines
└── TROUBLESHOOTING.md         # Common issues and solutions
```

## 🎨 Design Principles

### Generic Infrastructure Support
- **Technology Agnostic**: Supports any Azure infrastructure pattern
- **Convention-Based**: Dynamic role assignment based on naming patterns
- **Flexible Mapping**: Deployment targets can be any infrastructure type
- **Future-Proof**: Easy to extend for new Azure services

### Security First
- **OIDC Federation**: No static credentials stored
- **Least Privilege**: Role assignments based on environment type and naming convention
- **Conservative Auto-merge**: Only security updates auto-merge
- **Environment Isolation**: Each environment gets unique identity

### Enterprise Patterns
- **Opinionated for Stratus**: Designed for specific corporate architecture
- **Centralized Control**: IaC repository manages all environments
- **Standardized Naming**: Consistent resource naming conventions
- **Comprehensive Tagging**: Full resource metadata for governance

### Developer Experience
- **Simple Setup**: Two files to get started
- **Clear Documentation**: Extensive examples and troubleshooting
- **Automated Testing**: Comprehensive CI/CD validation
- **Community Friendly**: Welcoming to contributors

## 🔍 Key Constraints & Limitations

### GitHub API Limitations
- **One deployment pattern per environment**: Branch OR tag policies, not both
- **Protected branches vs tag policies**: Mutually exclusive
- **API inconsistencies**: 45-second wait times to handle GitHub API issues

### Stratus-Specific Constraints
- **Corporate network requirements**: Private endpoints for storage accounts
- **OIDC federation requirements**: Specific subject format for federated credentials
- **Naming conventions**: Azure reserved prefixes must be avoided
- **Team structure**: `HafslundEcoVannkraft/stratus-az-platform-approvers` team

### Technical Constraints
- **Root module only**: Cannot be used as child module (import blocks, provider configs)
- **GitHub CLI preferred**: Better security than Personal Access Tokens
- **Remote state dependency**: Requires upstream infrastructure outputs

## 📋 Common Patterns & Conventions

### Naming Conventions
- **Resources**: `{code_name}-{resource_type}-{environment}-{purpose/identifier}-{suffix}`
- **Environments**: `{deployment_target}-{azure_environment}-{operation}`
- **Examples**: `myapp-rg-dev-github-identities-a1b2`, `web-dev-ci`, `api-prod-cd`

### Configuration Patterns
- **Minimal setup**: Single environment, basic configuration
- **Multi-environment**: Separate files per Stratus Landing Zone
- **Multi-target**: Different deployment targets in same subscription
- **Complex**: Multiple Stratus LZ + multiple deployment targets

### Dynamic Role Assignment Patterns
```hcl
role_assignments = {
  global = [...]     # Always applied
  ci = [...]         # Applied to environments ending with '-ci'
  cd = [...]         # Applied to environments ending with '-cd'
  validate = [...]   # Applied to environments ending with '-validate'
  deploy = [...]     # Applied to environments ending with '-deploy'
  # Any custom suffix supported
}
```

## 🛠️ Development Guidelines

### Code Style
- **Terraform**: Use `terraform fmt` for formatting
- **YAML**: Keep simple and readable
- **Documentation**: Clear, comprehensive, with examples
- **Validation**: Comprehensive input validation with helpful error messages

### Testing Approach
- **Local validation**: `terraform fmt`, `terraform validate`
- **Integration testing**: Real GitHub/Azure API testing via GitHub Actions
- **Example validation**: YAML syntax and structure validation
- **Security testing**: Terraform security scanning

### Documentation Standards
- **README-first**: Comprehensive main documentation
- **Specialized docs**: Separate files for specific topics
- **Examples**: Working examples for all use cases
- **Troubleshooting**: Common issues with solutions

## 🔄 Dependency Management

### Dependabot Configuration
- **Weekly updates**: Terraform providers and GitHub Actions
- **Security priority**: Auto-merge security updates only
- **Grouped updates**: Related providers bundled together
- **Conservative approach**: Manual review for feature updates

### Provider Versions
- **azurerm**: `~> 4.0` (Azure Resource Manager)
- **azapi**: `~> 2.4.0` (Azure API Management)
- **github**: `~> 6.6.0` (GitHub provider)
- **Utility providers**: random, null, time

## 🎯 Common AI Tasks

### When Working on This Project

1. **Understanding Context**
   - Always consider the three-layer environment model
   - Remember this is part of larger Stratus workflow
   - Consider GitHub API limitations in solutions
   - Focus on generic infrastructure support, not just Container Apps

2. **Code Changes**
   - Maintain input validation patterns
   - Follow naming conventions
   - Update documentation for any changes
   - Consider impact on existing configurations
   - Ensure dynamic role assignment flexibility

3. **Documentation Updates**
   - Keep README.md as primary reference
   - Update specialized docs for specific changes
   - Maintain example configurations
   - Update troubleshooting for new issues
   - Emphasize generic nature while maintaining Stratus context

4. **Testing Considerations**
   - Local validation must pass
   - Consider integration test impact
   - Update examples if needed
   - Validate YAML configurations

### Helpful Context for AI Sessions

- **Target Audience**: DevOps engineers in corporate environment
- **Skill Level**: Intermediate to advanced Terraform and Azure knowledge
- **Environment**: Corporate network with security restrictions
- **Use Case**: Secure CI/CD for any Azure infrastructure
- **Scale**: Enterprise-level with multiple teams and environments

## 🔗 Related Resources

### Internal Documentation
- [README.md](README.md) - Primary documentation
- [DEPENDABOT.md](DEPENDABOT.md) - Dependency management
- [AUTHENTICATION.md](AUTHENTICATION.md) - GitHub CLI setup
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues

### External References
- [Stratus Terraform Examples](https://github.com/HafslundEcoVannkraft/stratus-tf-examples)
- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Azure Container Apps Documentation](https://docs.microsoft.com/en-us/azure/container-apps/)
- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## 🚨 Important Notes for AI

### What NOT to Suggest
- **Breaking changes** without clear migration path
- **Hardcoded values** that should be configurable
- **Security compromises** (static credentials, overly broad permissions)
- **GitHub API workarounds** that violate platform constraints
- **Container App specific solutions** when generic approaches exist

### What TO Prioritize
- **Generic infrastructure support** that works with any Azure service
- **Security best practices** and least privilege
- **Clear documentation** with working examples
- **Backward compatibility** when possible
- **Enterprise-ready solutions** that scale
- **Dynamic, convention-based approaches** over hardcoded logic

### Common Gotchas
- GitHub API limitations are real and must be worked around
- Stratus naming conventions are mandatory, not suggestions
- Remote state integration is critical for the architecture
- Corporate network restrictions affect testing and deployment
- Module is generic but workflows are still Stratus-opinionated

### Testing Strategy
- **Unit Tests**: Terraform validation and formatting
- **Integration Tests**: End-to-end workflow testing with GitHub App authentication
  - Creates GitHub App token for secure authentication
  - Dispatches actual `github-environment-vending.yml` workflow
  - Monitors workflow execution and verifies completion
  - Validates GitHub environments and configurations were created
  - Automatically cleans up resources via destroy workflow
- **Manual Testing**: Local development with GitHub CLI authentication
- **Security Testing**: OIDC federation and permission validation

---

> **For AI Assistants**: This project is production-ready and used by multiple teams. The module is now generic for any Azure infrastructure while maintaining Stratus workflow patterns. Changes should be conservative, well-documented, and maintain backward compatibility. When in doubt, ask for clarification about Stratus-specific requirements or corporate constraints. 