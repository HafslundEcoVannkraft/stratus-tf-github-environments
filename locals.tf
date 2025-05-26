# -----------------------------------------------------------------------------
# locals.tf
# Local values and data sources for the stratus-tf-aca-gh-vending module.
# Handles YAML parsing, environment processing, remote state access, 
# role assignments, and GitHub API data lookups.
# -----------------------------------------------------------------------------

# =============================================================================
# DATA SOURCES
# =============================================================================

# Access the remote state to get container app environment configuration
# This is used to retrieve outputs from another Terraform deployment
# (e.g., container app environment ID, ACR name, etc.)
data "terraform_remote_state" "container_app_environment" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.remote_state_resource_group_name != null ? var.remote_state_resource_group_name : "${var.code_name}-state-rg-${var.environment}"
    storage_account_name = var.remote_state_storage_account_name != null ? var.remote_state_storage_account_name : var.state_storage_account_name
    container_name       = var.remote_state_container != null ? var.remote_state_container : "tfstate"        # Azure Storage container name
    key                  = var.remote_state_key != null ? var.remote_state_key : "${var.environment}.tfstate" # Blob name/path for the Container App Environment deployment (e.g., dev.tfstate)
  }
}

# Get current Azure client configuration (for role assignments, etc.)
data "azurerm_client_config" "current" {}

# Look up team IDs for teams referenced by name or slug
data "github_team" "environment_teams" {
  for_each = local.referenced_teams

  slug = each.key
}

# Look up user IDs for users referenced by username
data "github_user" "environment_users" {
  for_each = local.referenced_users

  username = each.key
}

# Look up existing environments to handle imports
data "github_repository_environments" "existing" {
  for_each = toset([
    for env in local.environments : env.repository
  ])

  repository = each.key
}

# =============================================================================
# KEY VAULT DATA SOURCES FOR SECRETS
# =============================================================================

# Data source to get Key Vault information for referenced vaults
data "azurerm_key_vault" "referenced_vaults" {
  for_each = toset([
    for ref in local.key_vault_references : ref.key_vault_name
  ])

  name = each.key
  resource_group_name = try(
    # Try to get resource group from environment config
    [
      for env_name, env_config in try(local.github_environment_config.environments, {}) :
      try(env_config.key_vault.resource_group_name, null)
      if try(env_config.key_vault.name, null) == each.key
    ][0],
    # Fallback: try to find it in current subscription (this may fail if KV is in different RG)
    null
  )
}

# Data source to read Key Vault secrets referenced in remote state
data "azurerm_key_vault_secret" "remote_state_secrets" {
  for_each = local.unique_kv_secrets

  name         = each.value.secret_name
  key_vault_id = data.azurerm_key_vault.referenced_vaults[each.value.key_vault_name].id
}

# =============================================================================
# LOCAL VALUES
# =============================================================================

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
  yaml_content = fileexists(local.github_env_file) ? file(local.github_env_file) : file("${path.module}/examples/minimal.yaml")

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

  # GitHub environment configuration from remote state
  # The remote state should output github_environment_config with environments map
  # Each environment can have its own variables, secrets, role assignments, and settings
  github_environment_config = try(local.remote_state_outputs.github_environment_config, {
    environments = {}
  })

  # =============================================================================
  # KEY VAULT SECRETS PROCESSING
  # =============================================================================

  # Extract all Key Vault references from remote state secrets
  key_vault_references = flatten([
    for env_name, env_config in try(local.github_environment_config.environments, {}) : [
      for secret_name, secret_config in try(env_config.secrets, {}) : {
        key_vault_name     = try(secret_config.key_vault_name, null)
        secret_name        = try(secret_config.secret_name, null)
        env_name           = env_name
        github_secret_name = secret_name
      }
      if can(secret_config.key_vault_name) && can(secret_config.secret_name)
    ]
  ])

  # Create unique Key Vault + secret combinations for data source lookups
  unique_kv_secrets = {
    for ref in local.key_vault_references :
    "${ref.key_vault_name}:${ref.secret_name}" => {
      key_vault_name = ref.key_vault_name
      secret_name    = ref.secret_name
    }
  }

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
          key                   = "${env.key}-global-${role.role}-${md5(role.scope)}"
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
          key                   = "${env.key}-${endswith(env.environment, "-plan") ? "plan" : "apply"}-${role.role}-${md5(role.scope)}"
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
  # NAMING CONVENTIONS AND TAGGING
  # =============================================================================

  # Consistent naming patterns for all resources
  naming = {
    # Base naming components
    prefix = "${var.code_name}-${var.environment}"
    suffix = var.resource_group_suffix != null ? var.resource_group_suffix : random_string.name_suffix.result

    # Resource-specific naming
    resource_group_name     = "${var.code_name}-rg-${var.environment}-github-identities-${var.resource_group_suffix != null ? var.resource_group_suffix : random_string.name_suffix.result}"
    managed_identity_prefix = "${var.code_name}-id-github"
  }

  # Common tags applied to all resources
  common_tags = merge(var.tags, {
    Environment    = var.environment
    CodeName       = var.code_name
    ManagedBy      = "terraform"
    Module         = "stratus-tf-aca-gh-vending"
    DeploymentDate = timestamp()
  })

  # =============================================================================
  # VALIDATION AND DEPLOYMENT READINESS
  # =============================================================================

  # Validation checks for configuration integrity
  validation_checks = {
    has_repositories = length(local.repositories) > 0
    has_environments = length(flatten([for repo in local.repositories : repo.environments])) > 0
    yaml_is_valid    = can(yamldecode(local.yaml_content))
  }

  # Collect all environment keys (repo:env) for duplicate check
  all_environment_keys = flatten([
    for repo in local.repositories : [
      for env in repo.environments : "${repo.repo}:${env.name}"
    ]
  ])

  # True if there are no duplicate environments
  no_duplicate_environments = length(local.all_environment_keys) == length(toset(local.all_environment_keys))

  # Overall validation status
  validation_passed = alltrue(values(local.validation_checks))

  # Validation errors for configuration integrity
  validation_errors = [
    !local.validation_checks.has_repositories ? "YAML configuration must contain at least one repository." : null,
    !local.validation_checks.has_environments ? "At least one environment must be defined in YAML." : null,
    !local.validation_checks.yaml_is_valid ? "YAML file is not valid or cannot be parsed." : null,
    !local.no_duplicate_environments ? "Duplicate environment names found (repo:name must be unique)." : null
  ]

  # Filtered validation errors (no nulls)
  validation_errors_filtered = [for e in local.validation_errors : e if e != null]

  # Minimum deployment requirements check
  minimum_deployment_requirements = {
    has_environments       = length(local.environments) > 0
    has_valid_github_owner = length(var.github_owner) > 0
    has_github_token       = length(var.github_token) > 0
    has_azure_config       = length(var.subscription_id) > 0 && length(var.location) > 0
    has_naming_config      = length(var.code_name) > 0 && length(var.environment) > 0
  }

  # Check if minimum requirements are met for deployment
  can_deploy = alltrue([
    local.validation_passed,
    local.minimum_deployment_requirements.has_environments,
    local.minimum_deployment_requirements.has_valid_github_owner,
    local.minimum_deployment_requirements.has_github_token,
    local.minimum_deployment_requirements.has_azure_config,
    local.minimum_deployment_requirements.has_naming_config
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
  # SECRETS PROCESSING WITH KEY VAULT ONLY
  # =============================================================================

  # Process and flatten secrets from all environments
  # Each secret must be a map with key_vault_name and secret_name
  environment_secrets = flatten([
    for env in local.environments : [
      for secret_name, secret_config in try(local.github_environment_config.environments[env.container_environment].secrets, {}) : (
        can(secret_config.key_vault_name) && can(secret_config.secret_name)
        ? {
          key         = "${env.repository}:${env.environment}-${secret_name}"
          full_key    = "${env.key}-${secret_name}"
          repository  = env.repository
          environment = env.environment
          name        = secret_name
          value       = data.azurerm_key_vault_secret.remote_state_secrets["${secret_config.key_vault_name}:${secret_config.secret_name}"].value
        }
        : (throw("All secrets must be a map with key_vault_name and secret_name. Secret '${secret_name}' in environment '${env.environment}' is invalid."))
      )
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

  # Extract only unique users/teams that are actually referenced
  referenced_users = toset(flatten([
    for env in local.environments : [
      for user in try(env.reviewers.users, []) : user.username
    ]
  ]))

  referenced_teams = toset(flatten([
    for env in local.environments : [
      for team in try(env.reviewers.teams, []) :
      team.name != null ? team.name : team.slug
    ]
  ]))

  # True if all referenced container_environments exist in remote state
  container_environments_valid = alltrue([
    for env in local.environments :
    contains(keys(local.github_environment_config.environments), env.container_environment)
  ])

  validation_results = {
    remote_state_accessible           = can(data.terraform_remote_state.container_app_environment.outputs.github_environment_config)
    github_environment_config_present = length(try(local.github_environment_config.environments, {})) > 0
    yaml_has_repositories             = length(local.repositories) > 0
    yaml_repositories_valid           = length(local.repositories) > 0
    yaml_environments_valid           = length(flatten([for repo in local.repositories : repo.environments])) > 0
    no_duplicate_environments         = local.no_duplicate_environments
    container_environments_valid      = local.container_environments_valid
  }
}
