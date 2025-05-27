# -----------------------------------------------------------------------------
# locals.tf
# Local values and data sources for the stratus-tf-aca-gh-vending module.
# Handles YAML parsing, environment processing, remote state access,
# role assignments, and GitHub API data lookups.
# -----------------------------------------------------------------------------

# =============================================================================
# DATA SOURCES
# =============================================================================

# Access the remote state to get infrastructure configuration
# This is used to retrieve outputs from another Terraform deployment
# (e.g., infrastructure resources, shared services, etc.)
data "terraform_remote_state" "infrastructure" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.remote_state_resource_group_name != null ? var.remote_state_resource_group_name : "${var.code_name}-state-rg-${var.environment}"
    storage_account_name = var.remote_state_storage_account_name != null ? var.remote_state_storage_account_name : var.state_storage_account_name
    container_name       = var.remote_state_container != null ? var.remote_state_container : "tfstate"        # Azure Storage container name
    key                  = var.remote_state_key != null ? var.remote_state_key : "${var.environment}.tfstate" # Blob name/path for the infrastructure deployment (e.g., dev.tfstate)
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
      for env_config in local.github_environment_config :
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
  github_env_file = var.github_env_file
  yaml_content    = fileexists(local.github_env_file) ? file(local.github_env_file) : file("${path.module}/examples/minimal.yaml")
  config          = yamldecode(local.yaml_content)
  repositories    = local.config.repositories

  remote_state_outputs      = try(data.terraform_remote_state.infrastructure.outputs, {})
  github_environment_config = try(local.remote_state_outputs.github_environments, [])

  # Flatten environments
  environments = flatten([
    for repo in local.repositories : [
      for env in repo.environments : {
        repository          = repo.repo
        environment         = env.name
        key                 = "${repo.repo}:${env.name}"
        azure_resource_key  = "${repo.repo}-${env.name}"
        metadata            = try(env.metadata, {})
        prevent_destroy     = try(env.prevent_destroy, false)
        wait_timer          = try(env.wait_timer, 0)
        prevent_self_review = try(env.prevent_self_review, false)
        reviewers = try(env.reviewers, {
          users = []
          teams = []
        })
        branch_policy = try(env.deployment_branch_policy, {
          protected_branches     = false
          custom_branch_policies = false
          branch_pattern         = []
          tag_pattern            = []
        })
        variables = try(env.variables, {})
        secrets   = try(env.secrets, [])
      }
    ]
  ])

  environments_map = { for env in local.environments : env.key => env }

  referenced_users = toset(flatten([
    for env in local.environments : [
      for user in try(env.reviewers.users, []) : user.username
    ]
  ]))
  referenced_teams = toset(flatten([
    for env in local.environments : [
      for team in try(env.reviewers.teams, []) : team.name != null ? team.name : team.slug
    ]
  ]))

  key_vault_references = flatten([
    for env in local.environments : [
      for secret_name, secret_config in try(env.secrets, {}) : {
        key_vault_name     = try(secret_config.key_vault, null)
        secret_name        = try(secret_config.secret_ref, null)
        env_name           = env.environment
        github_secret_name = secret_name
      }
      if can(secret_config.key_vault) && can(secret_config.secret_ref)
    ]
  ])
  unique_kv_secrets = {
    for ref in local.key_vault_references :
    "${ref.key_vault_name}:${ref.secret_name}" => {
      key_vault_name = ref.key_vault_name
      secret_name    = ref.secret_name
    }
  }

  # Create a map of deployment targets for role assignment lookup
  deployment_targets_map = {
    for remote in local.github_environment_config :
    try(remote.metadata.deployment_target, "default") => remote
    if can(remote.metadata.deployment_target)
  }

  environment_role_assignments = flatten([
    for env in local.environments :
    try(env.metadata.deployment_target, null) != null ? concat(
      # Global/All role assignments (always applied)
      [
        for role in try(local.deployment_targets_map[env.metadata.deployment_target].role_assignments.global, []) : {
          key                  = "${env.key}-global-${role.role}-${md5(role.scope)}"
          environment_key      = env.key
          deployment_target    = env.metadata.deployment_target
          environment_type     = "global"
          managed_identity_id  = module.github_environment_identity[env.key].principal_id
          scope                = role.scope
          role_definition_name = role.role
        }
      ],
      # Dynamic suffix-based role assignments
      flatten([
        for role_type, roles in try(local.deployment_targets_map[env.metadata.deployment_target].role_assignments, {}) :
        role_type != "global" && endswith(env.environment, "-${role_type}") ? [
          for role in roles : {
            key                  = "${env.key}-${role_type}-${role.role}-${md5(role.scope)}"
            environment_key      = env.key
            deployment_target    = env.metadata.deployment_target
            environment_type     = role_type
            managed_identity_id  = module.github_environment_identity[env.key].principal_id
            scope                = role.scope
            role_definition_name = role.role
          }
        ] : []
      ])
    ) : []
  ])
  role_assignments_map = { for assignment in local.environment_role_assignments : assignment.key => assignment }

  # Legacy remote state references - these can be accessed directly from remote_state_outputs if needed
  # Removed hardcoded references to make module generic

  naming = {
    prefix                  = "${var.code_name}-${var.environment}"
    suffix                  = var.resource_group_suffix != null ? var.resource_group_suffix : random_string.name_suffix.result
    resource_group_name     = "${var.code_name}-rg-${var.environment}-github-identities-${var.resource_group_suffix != null ? var.resource_group_suffix : random_string.name_suffix.result}"
    managed_identity_prefix = "${var.code_name}-id-github"
  }
  common_tags = merge(var.tags, {
    Environment    = var.environment
    CodeName       = var.code_name
    ManagedBy      = "terraform"
    Module         = "stratus-tf-aca-gh-vending"
    DeploymentDate = timestamp()
  })

  validation_checks = {
    has_repositories = length(local.repositories) > 0
    has_environments = length(flatten([for repo in local.repositories : repo.environments])) > 0
    yaml_is_valid    = can(yamldecode(local.yaml_content))
  }
  all_environment_keys = [
    for env in local.environments : "${env.repository}:${env.environment}"
  ]
  no_duplicate_environments = length(local.all_environment_keys) == length(toset(local.all_environment_keys))
  validation_passed         = alltrue(values(local.validation_checks))
  validation_errors = [
    !local.validation_checks.has_repositories ? "YAML configuration must contain at least one repository." : null,
    !local.validation_checks.has_environments ? "At least one environment must be defined in YAML." : null,
    !local.validation_checks.yaml_is_valid ? "YAML file is not valid or cannot be parsed." : null,
    !local.no_duplicate_environments ? "Duplicate environment names found (repo:name must be unique)." : null
  ]
  validation_errors_filtered = [for e in local.validation_errors : e if e != null]
  minimum_deployment_requirements = {
    has_environments       = length(local.environments) > 0
    has_valid_github_owner = length(var.github_owner) > 0
    has_github_token       = length(var.github_token) > 0
    has_azure_config       = length(var.subscription_id) > 0 && length(var.location) > 0
    has_naming_config      = length(var.code_name) > 0 && length(var.environment) > 0
  }
  can_deploy = alltrue([
    local.validation_passed,
    local.minimum_deployment_requirements.has_environments,
    local.minimum_deployment_requirements.has_valid_github_owner,
    local.minimum_deployment_requirements.has_github_token,
    local.minimum_deployment_requirements.has_azure_config,
    local.minimum_deployment_requirements.has_naming_config
  ])

  environment_variables = {
    for env in local.environments :
    env.key => merge(
      # Variables from remote state (if deployment target is specified)
      try(env.metadata.deployment_target, null) != null ? try(local.deployment_targets_map[env.metadata.deployment_target].variables, {}) : {},
      # Auto-generated Azure identity variables (always provided)
      {
        AZURE_CLIENT_ID = module.github_environment_identity[env.key].client_id
      },
      # Variables from YAML (highest precedence)
      try(env.variables, {})
    )
  }

  environment_secrets = flatten([
    for env in local.environments : [
      # Secrets from remote state (deployment target level, if specified)
      for secret_name, secret_config in try(env.metadata.deployment_target, null) != null ? try(local.deployment_targets_map[env.metadata.deployment_target].secrets, {}) : {} : (
        can(secret_config.key_vault) && can(secret_config.secret_ref)
        ? {
          key         = "${env.repository}:${env.environment}-${secret_name}"
          full_key    = "${env.key}-${secret_name}"
          repository  = env.repository
          environment = env.environment
          name        = secret_name
          value       = data.azurerm_key_vault_secret.remote_state_secrets["${secret_config.key_vault}:${secret_config.secret_ref}"].value
        }
        : (throw("All secrets must be a map with key_vault and secret_ref. Secret '${secret_name}' in environment '${env.environment}' is invalid."))
      )
    ]
    ] + [
    # Secrets from YAML (environment level)
    for env in local.environments : [
      for secret_name, secret_config in try(env.secrets, {}) : (
        can(secret_config.key_vault) && can(secret_config.secret_ref)
        ? {
          key         = "${env.repository}:${env.environment}-${secret_name}"
          full_key    = "${env.key}-${secret_name}"
          repository  = env.repository
          environment = env.environment
          name        = secret_name
          value       = data.azurerm_key_vault_secret.remote_state_secrets["${secret_config.key_vault}:${secret_config.secret_ref}"].value
        }
        : (throw("All secrets must be a map with key_vault and secret_ref. Secret '${secret_name}' in environment '${env.environment}' is invalid."))
      )
    ]
  ])
  secrets_map = { for secret in local.environment_secrets : secret.key => secret }

  environments_to_import = [
    for env in local.environments : "${env.repository}:${env.environment}"
    if contains(flatten([
      for repo_name, repo_data in data.github_repository_environments.existing : [
        for existing_env in repo_data.environments : "${repo_name}:${existing_env.name}"
      ]
    ]), "${env.repository}:${env.environment}")
  ]
  deployment_targets_valid = alltrue([
    for env in local.environments :
    try(env.metadata.deployment_target, null) == null || contains(keys(local.deployment_targets_map), env.metadata.deployment_target)
  ])
  validation_results = {
    remote_state_accessible           = can(data.terraform_remote_state.infrastructure.outputs.github_environments)
    github_environment_config_present = length(local.github_environment_config) > 0
    yaml_has_repositories             = length(local.repositories) > 0
    yaml_repositories_valid           = length(local.repositories) > 0
    yaml_environments_valid           = length(flatten([for repo in local.repositories : repo.environments])) > 0
    no_duplicate_environments         = local.no_duplicate_environments
    deployment_targets_valid          = local.deployment_targets_valid
  }
  yaml_github_environment_config = yamldecode(local.yaml_content)
}

# =============================================================================
# END OF LOCALS BLOCK - All local variables are now consolidated above
# =============================================================================

data "github_actions_environment_variables" "env_vars" {
  for_each = local.environments_map

  name        = each.value.repository
  environment = each.value.environment
}

