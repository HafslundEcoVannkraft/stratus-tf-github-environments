# -----------------------------------------------------------------------------
# outputs.tf
# Output values for the stratus-tf-github-environments module.
# Provides organized information about created resources and integration details.
# -----------------------------------------------------------------------------

# =============================================================================
# DEPLOYMENT SUMMARY
# =============================================================================

output "deployment_summary" {
  description = "High-level summary of what was deployed by this module."
  value = {
    total_repositories    = length(distinct([for repo in local.repositories : repo.repo]))
    total_environments    = length(local.environments_map)
    github_organization   = var.github_owner
    azure_subscription_id = data.azurerm_client_config.current.subscription_id
    azure_tenant_id       = data.azurerm_client_config.current.tenant_id
    deployment_region     = var.location
  }
}

# =============================================================================
# GITHUB ENVIRONMENT DETAILS
# =============================================================================

output "github_environments" {
  description = "Detailed information about each GitHub environment created, organized by repository."
  value = {
    for repo in local.repositories : repo.repo => {
      repository_full_name = "${var.github_owner}/${repo.repo}"
      environments = {
        for env in repo.environments :
        # Use the new key format to look up the environment in environments_map
        env.name => {
          name                        = env.name
          deployment_target           = try(env.metadata.deployment_target, "generic")
          managed_by_terraform        = true
          azure_client_id             = module.github_environment_identity["${repo.repo}:${env.name}"].client_id
          azure_managed_identity_name = module.github_environment_identity["${repo.repo}:${env.name}"].resource_name
          github_environment_url      = "https://github.com/${var.github_owner}/${repo.repo}/settings/environments/${env.name}"
        }
      }
    }
  }
}

# =============================================================================
# VALIDATION STATUS
# =============================================================================

output "validation_results" {
  description = "Simple validation results for deployment readiness."
  value = {
    no_duplicate_environments = local.validation_results.no_duplicate_environments
    deployment_targets_valid  = local.validation_results.deployment_targets_valid
  }
}
