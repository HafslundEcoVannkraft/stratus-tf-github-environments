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
    total_environments    = length(local.flattened_repo_environments)
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
        for env in repo.environments : env.name => {
          name                        = env.name
          managed_by_terraform        = true
          azure_client_id             = module.managed_identity_app_repositories["${repo.repo}:${env.name}"].client_id
          azure_managed_identity_name = module.managed_identity_app_repositories["${repo.repo}:${env.name}"].resource_name
          github_environment_url      = "https://github.com/${var.github_owner}/${repo.repo}/settings/environments/${env.name}"
        }
      }
    }
  }
}

output "environment_variables_summary" {
  description = "Summary of automatic Azure variables provided to each environment."
  value = {
    automatic_variables_count = 9 # 7 standard Azure variables + 2 per-environment variables
    automatic_variables_provided = [
      "AZURE_CLIENT_ID (unique per environment)",
      "AZURE_TENANT_ID",
      "AZURE_SUBSCRIPTION_ID",
      "ACR_NAME",
      "CONTAINER_APP_ENVIRONMENT_ID",
      "CONTAINER_APP_ENVIRONMENT_CLIENT_ID (unique per environment)",
      "BACKEND_AZURE_RESOURCE_GROUP_NAME",
      "BACKEND_AZURE_STORAGE_ACCOUNT_NAME",
      "BACKEND_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME"
    ]
    note = "These variables are automatically available in GitHub Actions workflows for all environments"
  }
}

# =============================================================================
# AZURE RESOURCE DETAILS
# =============================================================================

output "azure_managed_identities" {
  description = "Azure managed identities created for GitHub OIDC federation, organized by environment."
  value = {
    for key, identity in module.managed_identity_app_repositories : key => {
      name         = identity.resource_name
      client_id    = identity.client_id
      principal_id = identity.principal_id
      resource_id  = identity.resource_id
    }
  }
}

output "azure_infrastructure" {
  description = "Azure infrastructure resources that GitHub environments will deploy to."
  value = {
    container_app_environment = {
      id = local.container_app_environment_id
    }
    container_registry = {
      name = local.acr_name
    }
    terraform_backend = {
      resource_group_name  = local.terraform_backend.resource_group_name
      storage_account_name = local.terraform_backend.storage_account_name
      container_name       = local.terraform_backend.container_name
    }
    managed_identities_resource_group = {
      name = azurerm_resource_group.github_identities.name
    }
  }
}

# =============================================================================
# INTEGRATION AND USAGE INFORMATION
# =============================================================================

output "next_steps" {
  description = "Guidance on how to use the created GitHub environments in your workflows."
  value = {
    workflow_integration = {
      description              = "Use these environment names in your GitHub Actions workflows"
      environment_names        = [for env in local.flattened_repo_environments : env.key]
      example_workflow_snippet = "environment: your-environment-name  # Replace with your desired environment from environment_names"
    }
    required_permissions = {
      description = "Required permissions for GitHub Actions workflows"
      permissions = [
        "id-token: write  # For OIDC authentication",
        "contents: read   # For repository access"
      ]
    }
    github_environment_variables = {
      description = "This variables become available for use in the GitHub Actions workflow"
      variables = [
        "$${{ vars.AZURE_CLIENT_ID }}",
        "$${{ vars.AZURE_TENANT_ID }}",
        "$${{ vars.AZURE_SUBSCRIPTION_ID }}",
        "$${{ vars.ACR_NAME }}",
        "$${{ vars.CONTAINER_APP_ENVIRONMENT_ID }}",
        "$${{ vars.CONTAINER_APP_ENVIRONMENT_CLIENT_ID }}",
        "$${{ vars.BACKEND_AZURE_RESOURCE_GROUP_NAME }}",
        "$${{ vars.BACKEND_AZURE_STORAGE_ACCOUNT_NAME }}",
        "$${{ vars.BACKEND_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME }}"
      ]
    }
  }
}

output "environment_to_identity_mapping" {
  description = "Quick reference mapping of GitHub environments to their Azure managed identity client IDs."
  value = [
    for env in local.flattened_repo_environments : {
      environment     = env.key
      azure_client_id = module.managed_identity_app_repositories[env.key].client_id
    }
  ]
}

# =============================================================================
# TROUBLESHOOTING AND DEBUG INFORMATION
# =============================================================================

output "troubleshooting_info" {
  description = "Information useful for troubleshooting and debugging."
  value = {
    module_version        = "Latest"
    terraform_workspace   = terraform.workspace
    github_api_calls_made = "GitHub environments, variables, secrets, and policies configured"
    azure_role_assignments = [
      "AcrPush on ${local.acr_name}",
      "Container Apps Contributor on Container App Environment",
      "Container Apps Jobs Contributor on Container App Environment",
      "Storage Blob Data Contributor on Terraform state storage"
    ]
    common_issues = {
      github_token_permissions = "Ensure token has repo, workflow, read:org scopes"
      azure_permissions        = "Ensure Azure identity has Contributor access to subscription"
      network_access           = "Module requires access to private Terraform backend storage"
    }
  }
}

# =============================================================================
# RAW DATA (for advanced users)
# =============================================================================

output "raw_configuration" {
  description = "Raw configuration data for advanced troubleshooting (use only if you know what you're doing)."
  value = {
    parsed_repositories      = local.repositories
    remote_state_outputs     = local.remote_state_outputs
    terraform_backend_config = local.terraform_backend
  }
  sensitive = false
}

