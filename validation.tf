# -----------------------------------------------------------------------------
# validation.tf
# Enhanced validation framework for comprehensive error handling and user guidance
# -----------------------------------------------------------------------------

# =============================================================================
# ENHANCED VALIDATION FRAMEWORK
# =============================================================================

locals {
  # Enhanced validation with detailed error context
  enhanced_validation = {
    # GitHub API connectivity validation
    github_connectivity = {
      valid         = length(var.github_token) > 10
      error_message = "GitHub token must be provided and valid. Ensure token has 'repo', 'workflow', and 'read:org' scopes."
      remediation   = "Generate a new token at https://github.com/settings/tokens with required scopes"
    }

    # Repository accessibility validation
    repository_accessibility = {
      valid = alltrue([
        for repo in distinct([for env in local.environments : env.repository]) :
        length(repo) > 0 && length(repo) <= 100
      ])
      error_message = "All repository names must be valid GitHub repository names (1-100 characters)"
      remediation   = "Check repository names in your YAML configuration"
    }

    # Environment naming validation with Azure constraints
    environment_naming = {
      valid = alltrue([
        for env in local.environments :
        can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", env.environment)) &&
        length(env.environment) <= 50 &&
        !contains(["CON", "PRN", "AUX", "NUL"], upper(env.environment))
      ])
      error_message = "Environment names must be valid Azure resource names and not reserved words"
      remediation   = "Use alphanumeric characters and hyphens only, avoid Windows reserved names"
    }

    # Container environment mapping validation
    container_environment_mapping = {
      valid = alltrue([
        for env in local.environments :
        env.container_environment != null && length(env.container_environment) > 0
      ])
      error_message = "All environments must have valid container_environment mapping"
      remediation   = "Ensure each environment specifies a container_environment that exists in your remote state"
    }

    # Reviewer configuration validation
    reviewer_configuration = {
      valid = alltrue([
        for env in local.environments :
        env.reviewers == null || (
          length(try(env.reviewers.users, [])) > 0 ||
          length(try(env.reviewers.teams, [])) > 0
        )
      ])
      error_message = "Environments with reviewers must specify at least one user or team"
      remediation   = "Add valid GitHub usernames or team names to reviewer configuration"
    }

    # Branch policy validation
    branch_policy_validation = {
      valid = alltrue([
        for env in local.environments :
        env.branch_policy == null || (
          # Cannot have both protected_branches and tag_policy enabled
          !(try(env.branch_policy.protected_branches, false) && try(env.tag_policy.enabled, false))
        )
      ])
      error_message = "Cannot use protected_branches with tag policies due to GitHub API limitations"
      remediation   = "Use either protected branches OR tag policies, not both"
    }

    # Resource naming collision detection
    resource_naming_collision = {
      valid = length(local.environments) == length(distinct([
        for env in local.environments : "${env.repository}-${env.environment}"
      ]))
      error_message = "Duplicate repository:environment combinations detected"
      remediation   = "Ensure each repository:environment combination is unique"
    }

    # Azure subscription validation
    azure_subscription = {
      valid         = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
      error_message = "Azure subscription ID must be a valid UUID"
      remediation   = "Verify your Azure subscription ID format"
    }

    # Remote state accessibility
    remote_state_access = {
      valid         = try(local.remote_state_outputs != null, false)
      error_message = "Cannot access remote state - check configuration and permissions"
      remediation   = "Verify remote state configuration and ensure proper Azure permissions"
    }
  }

  # Collect all validation failures
  validation_failures = [
    for key, validation in local.enhanced_validation :
    {
      check       = key
      error       = validation.error_message
      remediation = validation.remediation
    } if !validation.valid
  ]

  # Overall validation status
  enhanced_validation_passed = length(local.validation_failures) == 0

  # Generate user-friendly error report
  validation_error_report = length(local.validation_failures) > 0 ? formatlist(
    "❌ %s\n   Error: %s\n   Fix: %s\n",
    [for failure in local.validation_failures : failure.check],
    [for failure in local.validation_failures : failure.error],
    [for failure in local.validation_failures : failure.remediation]
  ) : []
}

# =============================================================================
# ENHANCED CHECK BLOCKS WITH BETTER ERROR MESSAGES
# =============================================================================

# check "enhanced_configuration_validation" {
#   assert {
#     condition     = local.enhanced_validation_passed
#     error_message = <<-EOT
#       Configuration validation failed. Please fix the following issues:
      
#       ${join("\n", nonsensitive(local.validation_error_report))}
      
#       For more help, see: https://github.com/HafslundEcoVannkraft/stratus-tf-aca-gh-vending/blob/main/README.md#troubleshooting
#     EOT
#   }
# }

check "github_api_prerequisites" {
  assert {
    condition = length(var.github_token) > 10 && length(var.github_owner) > 0
    // We use nonsensitive for the github token to avoid terraform errors, we only output the length of the token not the token itself
    error_message = <<-EOT
      GitHub API prerequisites not met:
      
      Required:
      - GitHub token with 'repo', 'workflow', 'read:org' scopes
      - Valid GitHub organization or user name
      
      Current status:
      - Token provided: ${length(nonsensitive(var.github_token)) > 10 ? "✅" : "❌"}
      - Owner specified: ${length(var.github_owner) > 0 ? "✅" : "❌"}
      
      Generate token at: https://github.com/settings/tokens
    EOT
  }
}

check "azure_prerequisites" {
  assert {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = <<-EOT
      Azure prerequisites not met:
      
      Issues found:
      - Subscription ID format: ${can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id)) ? "✅" : "❌ Invalid UUID format"}
      
      Verify your Azure subscription ID in the Azure portal.
    EOT
  }
}

# =============================================================================
# DEPLOYMENT READINESS ASSESSMENT
# =============================================================================

locals {
  deployment_readiness = {
    configuration_valid = local.enhanced_validation_passed
    prerequisites_met = alltrue([
      length(var.github_token) > 10,
      length(var.github_owner) > 0,
      can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id)),
      length(var.code_name) > 0,
      length(var.environment) > 0
    ])
    environments_configured = length(local.environments) > 0
    remote_state_accessible = try(local.remote_state_outputs != null, false)

    # Calculate readiness score
    readiness_score = (
      (local.enhanced_validation_passed ? 25 : 0) +
      (length(var.github_token) > 10 ? 25 : 0) +
      (length(local.environments) > 0 ? 25 : 0) +
      (try(local.remote_state_outputs != null, false) ? 25 : 0)
    )
  }

  # Determine readiness status based on score
  deployment_readiness_status = local.deployment_readiness.readiness_score == 100 ? "READY" : (
    local.deployment_readiness.readiness_score >= 75 ? "MOSTLY_READY" : (
      local.deployment_readiness.readiness_score >= 50 ? "NEEDS_WORK" : "NOT_READY"
    )
  )
} 