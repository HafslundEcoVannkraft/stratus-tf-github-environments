# -----------------------------------------------------------------------------
# outputs.tf
# Output values for the stratus-tf-aca-gh-vending module.
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

output "validation_status" {
  description = "Comprehensive validation status and any issues found during configuration processing."
  sensitive   = true
  value = {
    overall_status = local.validation_passed ? "PASSED" : "FAILED"
    can_deploy     = local.can_deploy

    validation_results = {
      yaml_structure = {
        has_repositories         = local.validation_results.yaml_has_repositories
        repositories_valid       = local.validation_results.yaml_repositories_valid
        environments_valid       = local.validation_results.yaml_environments_valid
        no_duplicates            = local.validation_results.no_duplicate_environments
        deployment_targets_valid = local.validation_results.deployment_targets_valid
      }
      remote_state = {
        accessible                        = local.validation_results.remote_state_accessible
        github_environment_config_present = local.validation_results.github_environment_config_present
      }
      minimum_requirements = local.minimum_deployment_requirements
    }

    validation_errors = local.validation_errors

    recommendations = length(local.validation_errors) > 0 ? [
      "Review validation errors above and fix configuration issues",
      "Ensure YAML structure follows the documented format",
      "Verify remote state configuration is correct",
      "Check that all required variables are provided"
      ] : [
      "Configuration is valid and ready for deployment",
      "All validation checks passed successfully"
    ]

    help = {
      documentation_url = "https://github.com/HafslundEcoVannkraft/stratus-tf-aca-gh-vending/blob/main/README.md"
      common_fixes = {
        yaml_issues            = "Check YAML syntax and ensure all required fields are present"
        remote_state_issues    = "Verify remote state configuration and permissions"
        duplicate_environments = "Ensure each repository:environment combination is unique"
        reviewer_issues        = "Check that users have 'username' field and teams have 'name' or 'slug'"
      }
    }
  }
}