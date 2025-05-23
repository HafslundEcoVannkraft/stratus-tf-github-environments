# -----------------------------------------------------------------------------
# locals.tf
# Local values for the stratus-tf-aca-gh-vending module.
# Used for file paths, YAML parsing, backend config, and validation.
# -----------------------------------------------------------------------------
locals {
  # =============================================================================
  # FILE PROCESSING AND YAML PARSING
  # =============================================================================

  # Path to the GitHub environment configuration file
  # Falls back to minimal example if the specified file doesn't exist
  github_env_file = var.github_env_file

  # Read and parse the YAML configuration file
  # This contains the repository and environment definitions
  # If the specified file doesn't exist, fall back to the minimal example
  yaml_content = fileexists(local.github_env_file) ? file(local.github_env_file) : file("${path.module}/examples/minmal.yaml")

  # Parse the YAML content into a Terraform object
  # This is the single source of truth for all configuration data
  config = yamldecode(local.yaml_content)

  # Extract the repositories array from the parsed configuration
  # Each repository contains:
  # - repo: GitHub repository name
  # - environments: Array of environment configurations
  repositories = local.config.repositories

  # =============================================================================
  # REMOTE STATE AND AZURE RESOURCE REFERENCES
  # =============================================================================

  # Outputs from the remote Terraform state (Container App Environment deployment)
  # This links to infrastructure provisioned by another Terraform configuration
  # Contains references to ACR, Container App Environment, and other shared resources
  remote_state_outputs = try(data.terraform_remote_state.container_app_environment.outputs, {})

  # Azure Container App Environment ID where applications will be deployed
  # Retrieved from remote state to ensure consistency across deployments
  container_app_environment_id = try(local.remote_state_outputs.container_app_environment_id, "")

  # Azure Container Registry name for container image storage
  # Used for role assignments to allow GitHub Actions to push images
  acr_name = try(local.remote_state_outputs.acr_name, "")

  # Azure Container Registry resource ID for RBAC assignments
  # Full ARM resource path needed for role assignment scope
  acr_resource_id = try(local.remote_state_outputs.acr_resource_id, "")


  # =============================================================================
  # ENVIRONMENT PROCESSING AND FLATTENING
  # =============================================================================

  # Flatten the nested repository/environment structure for easier processing
  # Creates a list where each item represents one repository-environment combination
  # Used for creating managed identities and federated credentials
  # Structure: [{ repo, environment, key, azure_resource_key }, ...]
  flattened_repo_environments = flatten([
    for repo in local.repositories : [
      for env in repo.environments : {
        repo               = repo.repo                  # GitHub repository name
        environment        = env.name                   # Environment name (dev, staging, prod, etc.)
        key                = "${repo.repo}:${env.name}" # Standard GitHub format (colon-separated)
        azure_resource_key = "${repo.repo}-${env.name}" # Azure-compatible format (dash-separated, only for resource naming)
      }
    ]
  ])

  # =============================================================================
  # TERRAFORM BACKEND CONFIGURATION
  # =============================================================================

  # Backend configuration information used for role assignments
  # GitHub Actions need access to the Terraform state storage account
  # This allows CI/CD pipelines to read/write Terraform state
  terraform_backend = {
    resource_group_name  = "${var.code_name}-state-rg-${var.environment}" # Resource group containing state storage
    storage_account_name = var.state_storage_account_name                 # Storage account for Terraform state
    container_name       = "tfstate"                                      # Blob container for state files
  }

  # =============================================================================
  # VALIDATION
  # =============================================================================

  # Basic validation to ensure the YAML configuration is valid
  # Checks that at least one repository is defined in the configuration
  # Additional validation rules can be added here as needed
  valid_yaml = alltrue([
    length(local.config.repositories) > 0,
    # Future validation rules can be added here:
    # - Check required fields are present
    # - Validate environment names follow naming conventions
    # - Ensure no duplicate repository/environment combinations
  ])

  # =============================================================================
  # ENVIRONMENT PROCESSING AND ORGANIZATION
  # =============================================================================

  # Create a flattened list of all environments with their complete properties
  # This processes the YAML configuration into a standardized format for resource creation
  # Each environment gets extracted from the nested repo -> environments structure
  # into a flat list with all necessary configuration properties
  environments = flatten([
    for repo in local.repositories : [
      for env in repo.environments : {
        repository         = repo.repo                       # GitHub repository name
        environment        = env.name                        # Environment name (dev, staging, prod, etc.)
        key                = "${repo.repo}:${env.name}"      # Standard GitHub format (colon-separated)
        azure_resource_key = "${repo.repo}-${env.name}"      # Azure-compatible format (only for resource naming)
        prevent_destroy    = try(env.prevent_destroy, false) # Lifecycle protection setting

        # Reviewer configuration for deployment approvals
        reviewers = {
          users = try(env.reviewers.users, []) # GitHub users who can approve deployments
          teams = try(env.reviewers.teams, []) # GitHub teams who can approve deployments
        }

        # Branch and tag deployment policies
        branch_policy = try(env.deployment_branch_policy, null) # Which branches can deploy
        tag_policy    = try(env.deployment_tag_policy, null)    # Which tags can deploy

        # Environment-specific configuration
        variables = try(env.variables, {}) # Environment variables to set
        secrets   = try(env.secrets, [])   # Secrets to create
      }
    ]
  ])

  # Map environments by their GitHub API key format for resource creation
  # Uses standard GitHub colon format consistently throughout
  environments_map = {
    for env in flatten([
      for repo in local.repositories : [
        for env_item in repo.environments : {
          repository          = repo.repo
          environment         = env_item.name
          key                 = "${repo.repo}:${env_item.name}" # Standard GitHub format (colon-separated)
          azure_resource_key  = "${repo.repo}-${env_item.name}" # Azure-compatible format (only for resource naming)
          prevent_destroy     = try(env_item.prevent_destroy, false)
          wait_timer          = try(env_item.wait_timer, 0)              # Minutes to wait before allowing deployment
          prevent_self_review = try(env_item.prevent_self_review, false) # Prevent self-approval of deployments

          # Reviewer configuration
          reviewers = {
            users = try(env_item.reviewers.users, [])
            teams = try(env_item.reviewers.teams, [])
          }

          # Deployment policies
          branch_policy = try(env_item.deployment_branch_policy, null)
          tag_policy    = try(env_item.deployment_tag_policy, null)

          # Environment data
          variables = try(env_item.variables, {})
          secrets   = try(env_item.secrets, [])
        }
      ]
    ]) : env.key => env
  }

  # =============================================================================
  # ENVIRONMENT VARIABLES PROCESSING AND AZURE INTEGRATION
  # =============================================================================

  # Define standard Azure infrastructure variables that should be automatically 
  # available in all GitHub environments. These are derived from remote state
  # and module configuration to provide seamless Azure integration.
  # These variables enable GitHub Actions workflows to:
  # - Authenticate with Azure using OIDC federation
  # - Access Azure Container Registry for image operations  
  # - Deploy to Azure Container App Environment
  # - Access Terraform state for CI/CD operations
  standard_azure_variables = {
    # Azure authentication and subscription details
    AZURE_TENANT_ID       = data.azurerm_client_config.current.tenant_id
    AZURE_SUBSCRIPTION_ID = data.azurerm_client_config.current.subscription_id

    # Azure Container Registry details for image operations
    ACR_NAME = local.acr_name

    # Azure Container App Environment for deployments
    CONTAINER_APP_ENVIRONMENT_ID = local.container_app_environment_id

    # Terraform backend configuration for CI/CD state access
    BACKEND_AZURE_RESOURCE_GROUP_NAME            = local.terraform_backend.resource_group_name
    BACKEND_AZURE_STORAGE_ACCOUNT_NAME           = local.terraform_backend.storage_account_name
    BACKEND_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME = local.terraform_backend.container_name
  }

  # Create a comprehensive map of environment variables for each environment
  # This automatically provides a complete set of Azure integration variables:
  # 1. Standard Azure variables (same for all environments)
  # 2. Per-environment managed identity variables (unique per environment)  
  # 3. Manual variables from YAML configuration (user-defined)
  # 
  # Variable precedence (last wins): Standard -> Per-Environment -> Manual
  # This allows users to override any automatically generated variable if needed
  environment_variables = {
    for env in local.environments :
    env.key => merge(
      local.standard_azure_variables, # Standard Azure variables (applied to all environments)
      {
        # Per-environment variables derived from the managed identity for this specific environment
        # These provide the unique identity for each environment's GitHub Actions workflows
        AZURE_CLIENT_ID                     = module.managed_identity_app_repositories[env.key].client_id
        CONTAINER_APP_ENVIRONMENT_CLIENT_ID = module.managed_identity_app_repositories[env.key].client_id
      },
      try(env.variables, {}) # Manual variables from YAML configuration (can override standards)
    )
  }

  # =============================================================================
  # SECRETS PROCESSING
  # =============================================================================

  # Process and flatten secrets from all environments
  # Creates individual secret objects with proper key structure for resource creation
  # Each secret gets its own entry with repository, environment, and secret details
  # TODO: Add GitHub Action runtime processing of secret values, we dont want secrets in the yaml files
  environment_secrets = flatten([
    for env in local.environments : [
      for secret in try(env.secrets, []) : {
        key         = "${env.repository}:${env.environment}-${secret.name}" # Unique key for this secret
        full_key    = "${env.key}-${secret.name}"                           # Resource naming key
        repository  = env.repository                                        # GitHub repository
        environment = env.environment                                       # Environment name
        name        = secret.name                                           # Secret name
        value       = secret.value                                          # Secret value
      }
    ]
  ])

  # Map secrets by their unique keys for easier resource lookup
  # Converts the flattened list into a map for use in for_each loops
  secrets_map = {
    for secret in local.environment_secrets :
    secret.key => secret
  }

  # =============================================================================
  # IMPORT HANDLING
  # =============================================================================

  # Create a list of existing environments that need to be imported into Terraform state
  # This allows the module to take over management of pre-existing GitHub environments
  # Compares environments defined in YAML with those found in the GitHub API
  environments_to_import = flatten([
    for repo_name, repo_data in data.github_repository_environments.existing : [
      for env in repo_data.environments : "${repo_name}:${env.name}"
      if contains([for env in local.environments : "${env.repository}:${env.environment}"], "${repo_name}:${env.name}")
    ]
  ])
}