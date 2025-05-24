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



  # =============================================================================
  # ROLE ASSIGNMENTS PROCESSING
  # =============================================================================

  # Create flattened role assignment objects for all environments
  # This combines global roles with environment-specific roles based on environment type
  # Role assignments come from the Azure environment-specific configuration
  environment_role_assignments = flatten([
    for env in local.environments :
    concat(
      # Global roles (apply to all environments)
      [
        for role in try(local.github_environment_config.environments[env.container_environment].role_assignments.global, []) : {
          key                   = "${env.key}-global-${role.role}"
          environment_key       = env.key
          container_environment = env.container_environment
          environment_type      = endswith(env.environment, "-plan") ? "plan" : "apply"
          managed_identity_id   = module.managed_identity_app_repositories[env.key].principal_id
          scope                 = role.scope
          role_definition_name  = role.role
        }
      ],
      # Environment-specific roles (plan or apply)
      [
        for role in try(
          endswith(env.environment, "-plan") ?
          local.github_environment_config.environments[env.container_environment].role_assignments.plan :
          local.github_environment_config.environments[env.container_environment].role_assignments.apply,
          []
          ) : {
          key                   = "${env.key}-${endswith(env.environment, "-plan") ? "plan" : "apply"}-${role.role}"
          environment_key       = env.key
          container_environment = env.container_environment
          environment_type      = endswith(env.environment, "-plan") ? "plan" : "apply"
          managed_identity_id   = module.managed_identity_app_repositories[env.key].principal_id
          scope                 = role.scope
          role_definition_name  = role.role
        }
      ]
    )
  ])

  # Map role assignments by their unique keys for resource creation
  role_assignments_map = {
    for assignment in local.environment_role_assignments :
    assignment.key => assignment
  }

  # Legacy remote state references - kept for backward compatibility with existing role assignments
  # These will be removed once all role assignment logic is updated to use the new convention
  container_app_environment_id = try(local.remote_state_outputs.container_app_environment_id, "")
  acr_name                     = try(local.remote_state_outputs.acr_name, "")
  acr_resource_id              = try(local.remote_state_outputs.acr_resource_id, "")
  ace_storage_account_id       = try(local.remote_state_outputs.ace_storage_account_id, "")
  ace_storage_account_name     = try(local.remote_state_outputs.ace_storage_account_name, "")
  private_dns_zone_id          = try(local.remote_state_outputs.private_dns_zone_id, "")
  private_dns_zone_name        = try(local.remote_state_outputs.private_dns_zone_name, "")
  public_dns_zone_id           = try(local.remote_state_outputs.public_dns_zone_id, "")
  public_dns_zone_name         = try(local.remote_state_outputs.public_dns_zone_name, "")

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
        repository            = repo.repo                                 # GitHub repository name
        environment           = env.name                                  # Environment name (dev, staging, prod, etc.)
        key                   = "${repo.repo}:${env.name}"                # Standard GitHub format (colon-separated)
        azure_resource_key    = "${repo.repo}-${env.name}"                # Azure-compatible format (only for resource naming)
        container_environment = try(env.container_environment, "default") # Maps to remote state environments key
        prevent_destroy       = try(env.prevent_destroy, false)           # Lifecycle protection setting

        # Settings with precedence: Remote State → YAML (YAML wins)
        # Get settings from the specific Container App Environment configuration
        wait_timer          = try(env.wait_timer, try(local.github_environment_config.environments[try(env.container_environment, "default")].settings.wait_timer, 0))
        prevent_self_review = try(env.prevent_self_review, try(local.github_environment_config.environments[try(env.container_environment, "default")].settings.prevent_self_review, false))

        # Reviewer configuration for deployment approvals
        reviewers = try(env.reviewers, try(local.github_environment_config.environments[try(env.container_environment, "default")].settings.reviewers, {
          users = [] # Default empty if nothing specified
          teams = []
        }))

        # Branch and tag deployment policies
        branch_policy = try(env.deployment_branch_policy, try(local.github_environment_config.environments[try(env.container_environment, "default")].settings.deployment_branch_policy, null))
        tag_policy    = try(env.deployment_tag_policy, try(local.github_environment_config.environments[try(env.container_environment, "default")].settings.deployment_tag_policy, null))

        # Environment-specific configuration
        variables = try(env.variables, {}) # Environment variables to set (YAML only, merged later)
        secrets   = try(env.secrets, [])   # Secrets to create (YAML only, merged later)
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

  # GitHub environment configuration from remote state
  # The remote state should output github_environment_config with environments map
  # Each environment can have its own variables, secrets, role assignments, and settings
  github_environment_config = try(local.remote_state_outputs.github_environment_config, {
    environments = {}
  })

  # Create a comprehensive map of environment variables for each environment
  # This provides environment variables from multiple sources:
  # 1. Remote state variables (from Azure environment-specific configuration)
  # 2. Per-environment managed identity variables (unique per environment)  
  # 3. Manual variables from YAML configuration (user-defined)
  # 
  # Variable precedence (last wins): Remote State -> Per-Environment -> Manual
  # This allows users to override any automatically generated variable if needed
  environment_variables = {
    for env in local.environments :
    env.key => merge(
      # Get variables from the specific Container App Environment configuration
      try(local.github_environment_config.environments[env.container_environment].variables, {}),
      {
        # Per-environment variables derived from the managed identity for this specific environment
        # These provide the unique identity for each environment's GitHub Actions workflows
        AZURE_CLIENT_ID                     = module.managed_identity_app_repositories[env.key].client_id
        CONTAINER_APP_ENVIRONMENT_CLIENT_ID = module.managed_identity_app_repositories[env.key].client_id
      },
      try(env.variables, {}) # From YAML (highest precedence)
    )
  }

  # =============================================================================
  # SECRETS PROCESSING
  # =============================================================================

  # Process and flatten secrets from all environments
  # Creates individual secret objects with proper key structure for resource creation
  # Each secret gets its own entry with repository, environment, and secret details
  # Secrets come from two sources: Azure environment-specific remote state and YAML configuration
  # TODO: Add GitHub Action runtime processing of secret values, we dont want secrets in the yaml files
  environment_secrets = flatten([
    for env in local.environments : concat(
      # Secrets from Container App Environment-specific remote state (convert map to list of objects)
      [
        for secret_name, secret_value in try(local.github_environment_config.environments[env.container_environment].secrets, {}) : {
          key         = "${env.repository}:${env.environment}-${secret_name}"
          full_key    = "${env.key}-${secret_name}"
          repository  = env.repository
          environment = env.environment
          name        = secret_name
          value       = secret_value
        }
      ],
      # Secrets from YAML (already in correct format)
      [
        for secret in try(env.secrets, []) : {
          key         = "${env.repository}:${env.environment}-${secret.name}" # Unique key for this secret
          full_key    = "${env.key}-${secret.name}"                           # Resource naming key
          repository  = env.repository                                        # GitHub repository
          environment = env.environment                                       # Environment name
          name        = secret.name                                           # Secret name
          value       = secret.value                                          # Secret value
        }
      ]
    )
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