# -----------------------------------------------------------------------------
# github.tf
# GitHub resources for the stratus-tf-aca-gh-vending module.
# Manages environments, deployment policies, variables, and secrets.
# -----------------------------------------------------------------------------

# Look up team IDs for teams referenced by name or slug
data "github_team" "environment_teams" {
  for_each = toset(flatten([
    for repo in local.repositories : [
      for env in repo.environments : [
        for team in try(env.reviewers.teams, []) :
        team.name != null ? team.name : team.slug
      ]
    ]
  ]))

  slug = each.key
}

# Look up user IDs for users referenced by username
data "github_user" "environment_users" {
  for_each = toset(flatten([
    for repo in local.repositories : [
      for env in repo.environments : [
        for user in try(env.reviewers.users, []) : user.username
      ]
    ]
  ]))

  username = each.key
}

# Process each environment for better organization
locals {
  # Create a flattened list of all environments with their properties
  environments = flatten([
    for repo in local.repositories : [
      for env in repo.environments : {
        repository      = repo.repo
        environment     = env.name
        key             = "${repo.repo}-${env.name}"
        full_key        = "${repo.repo}-${env.name}"
        prevent_destroy = try(env.prevent_destroy, false)
        reviewers = {
          users = try(env.reviewers.users, [])
          teams = try(env.reviewers.teams, [])
        }
        branch_policy = try(env.deployment_branch_policy, null)
        tag_policy    = try(env.deployment_tag_policy, null)
        variables     = try(env.variables, {})
        secrets       = try(env.secrets, [])
      }
    ]
  ])

  # Map environments by key for easier lookup
  environments_map = {
    for env in flatten([
      for repo in local.repositories : [
        for env_item in repo.environments : {
          repository          = repo.repo
          environment         = env_item.name
          key                 = "${repo.repo}:${env_item.name}"
          full_key            = "${repo.repo}-${env_item.name}"
          prevent_destroy     = try(env_item.prevent_destroy, false)
          wait_timer          = try(env_item.wait_timer, 0)
          prevent_self_review = try(env_item.prevent_self_review, false)
          reviewers = {
            users = try(env_item.reviewers.users, [])
            teams = try(env_item.reviewers.teams, [])
          }
          branch_policy = try(env_item.deployment_branch_policy, null)
          tag_policy    = try(env_item.deployment_tag_policy, null)
          variables     = try(env_item.variables, {})
          secrets       = try(env_item.secrets, [])
        }
      ]
    ]) : env.key => env
  }

  # Create a map of environment variables for each environment
  environment_variables = {
    for env in local.environments :
    env.full_key => try(env.variables, {})
  }

  # Process secrets from each environment
  # TODO: Add GitHub Action runtime processing of secret values, we dont want secrets in the yaml files
  environment_secrets = flatten([
    for env in local.environments : [
      for secret in try(env.secrets, []) : {
        key         = "${env.repository}:${env.environment}-${secret.name}"
        full_key    = "${env.full_key}-${secret.name}"
        repository  = env.repository
        environment = env.environment
        name        = secret.name
        value       = secret.value
      }
    ]
  ])

  # Map secrets by key for easier lookup
  secrets_map = {
    for secret in local.environment_secrets :
    secret.key => secret
  }

  # Create a list of existing environments that need to be imported
  environments_to_import = flatten([
    for repo_name, repo_data in data.github_repository_environments.existing : [
      for env in repo_data.environments : "${repo_name}:${env.name}"
      if contains([for env in local.environments : "${env.repository}:${env.environment}"], "${repo_name}:${env.name}")
    ]
  ])
}

# Look up existing environments to handle imports
data "github_repository_environments" "existing" {
  for_each = toset([
    for env in local.environments : env.repository
  ])

  repository = each.key
}

# Import block for existing GitHub environments
import {
  for_each = toset(local.environments_to_import)
  to       = github_repository_environment.env[each.key]
  id       = each.key
}

# GitHub environments
resource "github_repository_environment" "env" {
  for_each = local.environments_map

  repository  = each.value.repository
  environment = each.value.environment
  # Add wait_timer if present in the configuration
  wait_timer          = try(each.value.wait_timer, 0)
  prevent_self_review = try(each.value.prevent_self_review, false)

  # Reviewers configuration
  dynamic "reviewers" {
    for_each = (
      length(try(each.value.reviewers.users, [])) > 0 ||
      length(try(each.value.reviewers.teams, [])) > 0
    ) ? [1] : []

    content {
      # Look up user IDs for each username
      users = [
        for user in try(each.value.reviewers.users, []) :
        data.github_user.environment_users[user.username].id
      ]

      # Look up team IDs for each team slug
      teams = [
        for team in try(each.value.reviewers.teams, []) :
        data.github_team.environment_teams[team.name != null ? team.name : team.slug].id
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

  # Prevent automatic deletions if specified
  lifecycle {
    ignore_changes = [
      # Prevent automatic changes to these fields
      reviewers
    ]
  }
}

# Wait for environments to be created
# Longer wait time to help mitigate GitHub API inconsistencies
resource "time_sleep" "wait_for_environment" {
  depends_on      = [github_repository_environment.env]
  create_duration = "15s"
}

# Create a single deployment policy per environment
# GitHub only allows one deployment policy per environment
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

  # Choose the pattern based on whether this is a tag-based deployment or branch-based
  # If tag policy is enabled, use refs/tags/* pattern as that takes precedence
  # Otherwise use the first branch pattern (GitHub only allows one pattern per API call)
  branch_pattern = coalesce(
    try(each.value.tag_policy.enabled, false) ? "refs/tags/*" : null,
    try(each.value.branch_policy.custom_branches[0], "main")
  )

  depends_on = [
    github_repository_environment.env,
    time_sleep.wait_for_environment
  ]

  # Add explicit lifecycle rules to handle GitHub API inconsistencies
  lifecycle {
    create_before_destroy = true
  }
}

# GitHub environment variables 
resource "github_actions_environment_variable" "all_variables" {
  for_each = merge([
    for env in local.environments : {
      for name, value in local.environment_variables[env.full_key] :
      "${env.full_key}|${name}" => {
        repository  = env.repository
        environment = env.environment
        name        = name
        value       = value
      }
    }
  ]...)

  repository    = each.value.repository
  environment   = each.value.environment
  variable_name = each.value.name
  value         = each.value.value != null ? each.value.value : ""

  # Explicit dependency to ensure environments are created before variables
  depends_on = [
    github_repository_environment.env,
    time_sleep.wait_for_environment
  ]
}

# GitHub environment secrets
resource "github_actions_environment_secret" "all_secrets" {
  for_each = local.secrets_map

  repository      = each.value.repository
  environment     = each.value.environment
  secret_name     = each.value.name
  plaintext_value = each.value.value

  # Explicit dependency to ensure environments are created before secrets
  depends_on = [
    github_repository_environment.env,
    time_sleep.wait_for_environment
  ]
}

# Outputs for GitHub resources
output "environment_keys" {
  description = "Environment keys for GitHub environments"
  value       = [for env in local.environments : env.key]
}
