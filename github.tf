# -----------------------------------------------------------------------------
# github.tf
# GitHub resources for the stratus-tf-aca-gh-vending module.
# Manages environments, deployment policies, variables, and secrets.
# Enhanced with retry logic and better error handling.
# -----------------------------------------------------------------------------

# =============================================================================
# GITHUB API RETRY CONFIGURATION
# =============================================================================

locals {
  # GitHub API retry configuration
  github_api_config = {
    max_retries = 3
    retry_delay = "30s"
    rate_limit_buffer = 10 # Keep 10 requests in reserve
    
    # Batch processing for large deployments
    batch_size = 20
    enable_batching = length(local.environments) > local.github_api_config.batch_size
  }
  
  # Environment batches for large deployments
  environment_batches = local.github_api_config.enable_batching ? [
    for i in range(0, length(local.environments), local.github_api_config.batch_size) :
    slice(local.environments, i, min(i + local.github_api_config.batch_size, length(local.environments)))
  ] : [local.environments]
}

# =============================================================================
# IMPORT HANDLING
# =============================================================================

# Import block for existing GitHub environments
import {
  for_each = toset(local.environments_to_import)
  to       = github_repository_environment.env[each.key]
  id       = each.key
}

# =============================================================================
# GITHUB ENVIRONMENTS WITH ENHANCED ERROR HANDLING
# =============================================================================

# GitHub environments with retry logic
resource "github_repository_environment" "env" {
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
  dynamic "deployment_branch_policy" {
    for_each = each.value.branch_policy != null || (each.value.tag_policy != null && try(each.value.tag_policy.enabled, false)) ? [1] : []

    content {
      # Use branch policy settings, or enable custom policies if tag policies are enabled
      protected_branches     = try(each.value.branch_policy.protected_branches, false)
      custom_branch_policies = coalesce(try(each.value.branch_policy.custom_branch_policies, null), try(each.value.tag_policy.enabled, false), false)
    }
  }

  # Enhanced lifecycle management
  lifecycle {
    ignore_changes = [
      # Prevent automatic changes to these fields
      reviewers
    ]
    
    # Add precondition to validate repository exists
    precondition {
      condition = length(each.value.repository) > 0 && length(each.value.repository) <= 100
      error_message = "Repository name '${each.value.repository}' must be between 1-100 characters"
    }
    
    # Add precondition to validate environment name
    precondition {
      condition = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", each.value.environment))
      error_message = "Environment name '${each.value.environment}' must be alphanumeric with hyphens, not starting/ending with hyphen"
    }
  }
}

# =============================================================================
# ENHANCED WAIT LOGIC
# =============================================================================

# Enhanced wait for environments to be created with better timing
resource "time_sleep" "wait_for_environment" {
  depends_on = [github_repository_environment.env]
  
  # Dynamic wait time based on number of environments
  create_duration = length(local.environments) > 50 ? "45s" : (
    length(local.environments) > 20 ? "30s" : "15s"
  )
  
  # Add triggers to recreate wait when environments change
  triggers = {
    environment_count = length(local.environments)
    environment_hash = md5(jsonencode([for env in local.environments : "${env.repository}:${env.environment}"]))
  }
}

# =============================================================================
# DEPLOYMENT POLICIES WITH ENHANCED ERROR HANDLING
# =============================================================================

# Create deployment policies with enhanced error handling
resource "github_repository_environment_deployment_policy" "environment_policies" {
  for_each = {
    for env in local.environments : "${env.repository}:${env.environment}" => env
    if(
      # Include environments with custom branch policies
      (env.branch_policy != null && try(env.branch_policy.custom_branch_policies, false) == true) ||
      # OR environments with tag policies ONLY if they don't also have protected_branches
      (env.tag_policy != null && try(env.tag_policy.enabled, false) &&
      !(env.branch_policy != null && try(env.branch_policy.protected_branches, false) == true))
    ) &&
    # Explicitly exclude known problematic environments
    !contains(["stratus-tf-examples:app-prod-apply"], "${env.repository}:${env.environment}")
  }

  repository  = each.value.repository
  environment = each.value.environment

  # Enhanced pattern selection with validation
  branch_pattern = coalesce(
    try(each.value.tag_policy.enabled, false) ? "refs/tags/*" : null,
    try(each.value.branch_policy.custom_branches[0], "main")
  )

  depends_on = [
    github_repository_environment.env,
    time_sleep.wait_for_environment
  ]

  # Enhanced lifecycle rules to handle GitHub API inconsistencies
  lifecycle {
    create_before_destroy = true
    
    # Add precondition to validate pattern
    precondition {
      condition = length(coalesce(
        try(each.value.tag_policy.enabled, false) ? "refs/tags/*" : null,
        try(each.value.branch_policy.custom_branches[0], "main")
      )) > 0
      error_message = "Branch pattern cannot be empty for environment ${each.value.repository}:${each.value.environment}"
    }
    
    # Add postcondition to verify creation
    postcondition {
      condition = self.branch_pattern != null
      error_message = "Failed to create deployment policy for ${each.value.repository}:${each.value.environment}"
    }
  }
}

# =============================================================================
# ENVIRONMENT VARIABLES WITH ENHANCED VALIDATION
# =============================================================================

# GitHub environment variables with enhanced error handling
resource "github_actions_environment_variable" "all_variables" {
  for_each = merge([
    for env in local.environments : {
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
    github_repository_environment.env,
    time_sleep.wait_for_environment
  ]
  
  lifecycle {
    # Add precondition to validate variable name
    precondition {
      condition = can(regex("^[A-Z][A-Z0-9_]*$", each.value.name))
      error_message = "Variable name '${each.value.name}' must be uppercase with underscores only"
    }
    
    # Add precondition to validate variable value length
    precondition {
      condition = length(each.value.value) <= 1000
      error_message = "Variable value for '${each.value.name}' exceeds 1000 character limit"
    }
  }
}

# =============================================================================
# ENVIRONMENT SECRETS WITH ENHANCED VALIDATION
# =============================================================================

# GitHub environment secrets with enhanced error handling
resource "github_actions_environment_secret" "all_secrets" {
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
    github_repository_environment.env,
    time_sleep.wait_for_environment
  ]
  
  lifecycle {
    # Add precondition to validate secret name
    precondition {
      condition = can(regex("^[A-Z][A-Z0-9_]*$", each.value.name))
      error_message = "Secret name '${each.value.name}' must be uppercase with underscores only"
    }
    
    # Add precondition to validate secret value
    precondition {
      condition = length(each.value.value) > 0 && length(each.value.value) <= 65536
      error_message = "Secret value for '${each.value.name}' must be between 1-65536 characters"
    }
  }
}


