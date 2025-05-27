# -----------------------------------------------------------------------------
# github.tf
# GitHub resources for the stratus-tf-aca-gh-vending module.
# Manages environments, deployment policies, variables, and secrets.
# Enhanced with retry logic and better error handling.
# -----------------------------------------------------------------------------



# =============================================================================
# GITHUB ENVIRONMENTS WITH ENHANCED ERROR HANDLING
# =============================================================================

# GitHub environments with retry logic
resource "github_repository_environment" "environment" {
  for_each = local.environments_map

  repository  = each.value.repository
  environment = each.value.environment

  # Add wait_timer if present in the configuration
  wait_timer          = try(each.value.wait_timer, 0)
  prevent_self_review = try(each.value.prevent_self_review, false)

  # Reviewers configuration with validation
  dynamic "reviewers" {
    for_each = (
      length(try(each.value.reviewers.users, [])) > 0 ||
      length(try(each.value.reviewers.teams, [])) > 0
    ) ? [1] : []

    content {
      # Look up user IDs for each username with error handling
      users = [
        for user in try(each.value.reviewers.users, []) :
        try(data.github_user.environment_users[user.username].id, null)
        if try(data.github_user.environment_users[user.username].id, null) != null
      ]

      # Look up team IDs for each team slug with error handling
      teams = [
        for team in try(each.value.reviewers.teams, []) :
        try(data.github_team.environment_teams[team.name != null ? team.name : team.slug].id, null)
        if try(data.github_team.environment_teams[team.name != null ? team.name : team.slug].id, null) != null
      ]
    }
  }

  # Add deployment branch policy if configured
  deployment_branch_policy {
    protected_branches     = try(each.value.branch_policy.protected_branches, false)
    custom_branch_policies = try(each.value.branch_policy.custom_branch_policies, false)
  }

  # Enhanced lifecycle management
  lifecycle {
    ignore_changes = [
      # Prevent automatic changes to these fields
      reviewers
    ]

    # Add precondition to validate repository exists
    precondition {
      condition     = length(each.value.repository) > 0 && length(each.value.repository) <= 100
      error_message = "Repository name '${each.value.repository}' must be between 1-100 characters"
    }

    # Add precondition to validate environment name
    precondition {
      condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", each.value.environment))
      error_message = "Environment name '${each.value.environment}' must be alphanumeric with hyphens, not starting/ending with hyphen"
    }
  }
}

# =============================================================================
# ENHANCED WAIT LOGIC
# =============================================================================

# Enhanced wait for environments to be created with better timing
resource "time_sleep" "wait_for_environment" {
  depends_on = [github_repository_environment.environment]

  # Dynamic wait time based on number of environments
  create_duration = length(local.environments_map) > 50 ? "45s" : (
    length(local.environments_map) > 20 ? "30s" : "15s"
  )

  # Add triggers to recreate wait when environments change
  triggers = {
    environment_count = length(local.environments_map)
    environment_hash  = md5(jsonencode([for k, env in local.environments_map : "${env.repository}:${env.environment}"]))
  }
}

# =============================================================================
# DEPLOYMENT POLICIES WITH ENHANCED ERROR HANDLING
# =============================================================================

# Create deployment policies with enhanced error handling
resource "github_repository_environment_deployment_policy" "branch_policies" {
  # Create branch pattern policies
  for_each = {
    for item in flatten([
      for env in values(local.environments_map) : [
        for pattern in try(env.branch_policy.branch_pattern, []) : {
          key                = "${env.repository}:${env.environment}:branch:${pattern}"
          repository         = env.repository
          environment        = env.environment
          branch_pattern     = pattern
          protected_branches = try(env.branch_policy.protected_branches, false)
        }
      ]
    ]) : item.key => item
    if try(length(item.branch_pattern), 0) > 0
  }

  repository     = each.value.repository
  environment    = each.value.environment
  branch_pattern = each.value.branch_pattern

  # Lifecycle block to ensure we don't create invalid configurations
  lifecycle {
    # Verify branch pattern is not used with protected branches
    precondition {
      condition     = !each.value.protected_branches
      error_message = "Error: Branch pattern '${each.value.branch_pattern}' cannot be used with protected_branches=true in environment: ${each.value.repository}:${each.value.environment}"
    }
  }

  depends_on = [
    github_repository_environment.environment,
    time_sleep.wait_for_environment
  ]
}

resource "github_repository_environment_deployment_policy" "tag_policies" {
  # Create tag pattern policies
  for_each = {
    for item in flatten([
      for env in values(local.environments_map) : [
        for pattern in try(env.branch_policy.tag_pattern, []) : {
          key                = "${env.repository}:${env.environment}:tag:${pattern}"
          repository         = env.repository
          environment        = env.environment
          tag_pattern        = pattern
          protected_branches = try(env.branch_policy.protected_branches, false)
        }
      ]
    ]) : item.key => item
    if try(length(item.tag_pattern), 0) > 0
  }

  repository  = each.value.repository
  environment = each.value.environment
  tag_pattern = each.value.tag_pattern

  # Lifecycle block to ensure we don't create invalid configurations
  lifecycle {
    # Verify tag pattern is not used with protected branches
    precondition {
      condition     = !each.value.protected_branches
      error_message = "Error: Tag pattern '${each.value.tag_pattern}' cannot be used with protected_branches=true in environment: ${each.value.repository}:${each.value.environment}"
    }
  }

  depends_on = [
    github_repository_environment.environment,
    time_sleep.wait_for_environment
  ]
}

# =============================================================================
# ENVIRONMENT VARIABLES WITH ENHANCED VALIDATION
# =============================================================================

# GitHub environment variables with enhanced error handling
resource "github_actions_environment_variable" "environment_variables" {
  for_each = merge([
    for env in values(local.environments_map) : {
      for name, value in local.environment_variables[env.key] :
      "${env.key}|${name}" => {
        repository  = env.repository
        environment = env.environment
        name        = name
        value       = value
      }
      # Add validation for variable names
      if can(regex("^[A-Z][A-Z0-9_]*$", name)) && length(name) <= 100
    }
  ]...)

  repository    = each.value.repository
  environment   = each.value.environment
  variable_name = each.value.name
  value         = each.value.value != null ? each.value.value : ""

  # Enhanced dependencies and lifecycle
  depends_on = [
    github_repository_environment.environment,
    time_sleep.wait_for_environment
  ]

  lifecycle {
    # Add precondition to validate variable name
    precondition {
      condition     = can(regex("^[A-Z][A-Z0-9_]*$", each.value.name))
      error_message = "Variable name '${each.value.name}' must be uppercase with underscores only"
    }

    # Add precondition to validate variable value length
    precondition {
      condition     = length(each.value.value) <= 1000
      error_message = "Variable value for '${each.value.name}' exceeds 1000 character limit"
    }
  }
}

# =============================================================================
# ENVIRONMENT SECRETS WITH ENHANCED VALIDATION
# =============================================================================

# GitHub environment secrets with enhanced error handling
resource "github_actions_environment_secret" "environment_secrets" {
  for_each = {
    for key, secret in local.secrets_map : key => secret
    # Add validation for secret names
    if can(regex("^[A-Z][A-Z0-9_]*$", secret.name)) && length(secret.name) <= 100
  }

  repository      = each.value.repository
  environment     = each.value.environment
  secret_name     = each.value.name
  plaintext_value = each.value.value

  # Enhanced dependencies and lifecycle
  depends_on = [
    github_repository_environment.environment,
    time_sleep.wait_for_environment
  ]

  lifecycle {
    # Add precondition to validate secret name
    precondition {
      condition     = can(regex("^[A-Z][A-Z0-9_]*$", each.value.name))
      error_message = "Secret name '${each.value.name}' must be uppercase with underscores only"
    }

    # Add precondition to validate secret value
    precondition {
      condition     = length(each.value.value) > 0 && length(each.value.value) <= 65536
      error_message = "Secret value for '${each.value.name}' must be between 1-65536 characters"
    }
  }
}


