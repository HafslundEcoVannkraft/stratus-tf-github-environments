# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Comprehensive Input Validation**: All variables now include validation rules that catch errors early
  - Azure naming constraints enforcement
  - GitHub format validation for usernames and file formats
  - Reserved prefix protection to prevent conflicts with Azure reserved names
  - Length constraints validation for all inputs
- **Consistent Resource Naming**: Standardized naming convention with customizable suffixes
  - Pattern: `{code_name}-{resource_type}-{environment}-{purpose}-{suffix}`
  - Optional `resource_group_suffix` for predictable naming
- **Comprehensive Resource Tagging**: Rich metadata tagging for all Azure resources
  - Core identification tags (Environment, CodeName, Purpose, ManagedBy)
  - Repository tracking (ModuleRepository, ModuleVersion, IaCRepository)
  - Deployment metadata (DeploymentDate, TerraformWorkspace)
  - GitHub integration tags (GitHubOrganization, TotalEnvironments, TotalRepositories)
  - Azure integration tags (AzureSubscription, AzureTenant, AzureRegion)
  - Resource-specific tags (ResourceType, GitHubRepository, GitHubEnvironment)
- **Data Source Optimization**: Improved GitHub API efficiency
  - Pre-computed sets for unique users and teams
  - Eliminated duplicate API calls using `toset()`
  - Reduced plan time and API rate limiting
- **Modern Error Handling**: Replaced null_resource hacks with proper check blocks
  - Clear error messages for common configuration issues
  - Early validation of GitHub repository existence
  - Comprehensive YAML file validation
- **Enhanced Provider Support**: Updated all providers to latest stable versions
  - Azure RM provider with latest features
  - GitHub provider with improved API support
  - Random and Time providers for better resource management
- **Lifecycle Management**: Production-ready resource protection
  - Prevent accidental deletion of critical resources
  - Tag optimization to reduce unnecessary updates
  - Proper resource dependencies and ordering
- **Automated Dependency Management**: Comprehensive Dependabot configuration
  - Weekly automated updates for Terraform providers
  - GitHub Actions updates with validation
  - Grouped updates for related providers
  - Auto-merge for safe updates with validation
  - Manual review requirements for major version updates
- **Enhanced Documentation**: Comprehensive guides and examples
  - Detailed setup instructions with multiple scenarios
  - Complete configuration reference with validation rules
  - Troubleshooting guides for common issues
  - Best practices for GitHub environment management
  - Architecture diagrams and workflow explanations

### Enhanced
- **Remote State Integration**: Improved support for flexible remote state configurations
  - Support for multiple Azure Container App Environments
  - Environment-specific variables, secrets, and role assignments
  - Settings override behavior (Remote State → YAML precedence)
  - Backward compatibility with legacy configurations
- **GitHub Workflow Integration**: Enhanced workflow file with better parameter handling
  - Combined remote state configuration parameter
  - Support for IaC and module repository references
  - Intelligent parsing of partial configuration overrides
  - Reduced input parameter count (8 instead of 10)
- **Role Assignment Management**: Flexible and centralized permission management
  - Global, plan, and apply role assignment categories
  - Support for any Azure resource scope and role combination
  - Environment-specific permission patterns
  - No hardcoded permission logic in the module
- **Example Configurations**: Updated examples with latest features
  - Complete example showing all available options
  - Minimal example for quick setup
  - Multi-environment and multi-repository patterns
  - Container App Environment mapping examples

### Fixed
- **Circular Reference Issues**: Resolved remote state circular dependencies
- **Duplicate Key Errors**: Fixed role assignment key generation with scope-based uniqueness
- **GitHub API Limitations**: Improved handling of GitHub API constraints
  - Better error handling for deployment policy conflicts
  - Proper wait times for API consistency
  - Exclusion of problematic configuration combinations
- **Terraform Validation**: Fixed local variable circular references
- **File Organization**: Consolidated and cleaned up module structure
  - Merged related files for better maintainability
  - Removed duplicate headers and improved organization
  - Consistent section headers and documentation

### Security
- **Enhanced OIDC Federation**: Improved security for GitHub-Azure integration
  - Unique managed identities per environment
  - Proper federated credential configuration
  - Principle of least privilege role assignments
- **Token Security**: Better GitHub token management
  - Clear scope requirements documentation
  - Corporate environment considerations
  - Secure token handling in workflows

### Performance
- **Optimized API Calls**: Reduced GitHub API usage
  - Pre-computed user and team sets
  - Eliminated redundant data source calls
  - Improved plan and apply performance
- **Efficient Resource Management**: Better Terraform state management
  - Optimized resource dependencies
  - Reduced unnecessary resource updates
  - Improved lifecycle management

### Documentation
- **Comprehensive README**: Complete rewrite with enhanced content
  - Step-by-step setup guide
  - Architecture explanations with diagrams
  - Configuration reference with validation rules
  - Troubleshooting guides
  - Best practices and security considerations
- **Dependabot Documentation**: Detailed dependency management guide
  - Configuration explanations
  - Auto-merge process documentation
  - Troubleshooting for dependency updates
- **Example Files**: Updated and enhanced example configurations
  - Real-world scenarios and use cases
  - Multi-file configuration strategies
  - Container App Environment mapping examples

## [Previous Versions]

### Initial Release
- Basic GitHub environment creation
- Azure managed identity and federated credential setup
- Simple role assignment management
- Basic YAML configuration support
- GitHub workflow integration 