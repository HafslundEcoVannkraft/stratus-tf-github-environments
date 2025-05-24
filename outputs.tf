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
          container_environment       = try(env.container_environment, "default")
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
  description = "Summary of environment variables provided to each environment."
  value = {
    variable_sources = [
      "Container App Environment-specific remote state (github_environment_config.environments[container_environment].variables)",
      "Per-environment managed identity (AZURE_CLIENT_ID, CONTAINER_APP_ENVIRONMENT_CLIENT_ID)",
      "YAML configuration (user-defined overrides)"
    ]
    variable_precedence = "Container App Environment Remote State -> Per-Environment -> YAML (highest precedence)"
    per_environment_variables = [
      "AZURE_CLIENT_ID (unique per environment)",
      "CONTAINER_APP_ENVIRONMENT_CLIENT_ID (unique per environment)"
    ]
    container_environment_mapping = {
      for env in local.environments : env.key => env.container_environment
    }
    note = "Variables come from the specific Container App Environment configuration in remote state. Multiple GitHub environments can map to the same Container App Environment."
  }
}

output "role_assignments_summary" {
  description = "Summary of role assignment configuration and sources."
  value = {
    role_assignment_sources = [
      "Container App Environment-specific remote state (github_environment_config.environments[container_environment].role_assignments)"
    ]
    remote_state_role_types = [
      "global - Applied to all environments",
      "plan - Applied only to environments ending with '-plan'", 
      "apply - Applied only to environments NOT ending with '-plan'"
    ]
    total_assignments = length(local.environment_role_assignments)
    environments_with_roles = length(distinct([for assignment in local.environment_role_assignments : assignment.environment_key]))
    container_environments_used = length(distinct([for assignment in local.environment_role_assignments : assignment.container_environment]))
    container_environment_mapping = {
      for env in local.environments : env.key => env.container_environment
    }
    note = "Role assignments come from the specific Container App Environment configuration in remote state. Multiple GitHub environments can share the same Container App Environment's role assignments."
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
    ace_storage_account = local.ace_storage_account_id != "" ? {
      id   = local.ace_storage_account_id
      name = local.ace_storage_account_name
      note = "Used for persistent storage, file shares, and Dapr components"
    } : null
    private_dns_zone = local.private_dns_zone_id != "" ? {
      id   = local.private_dns_zone_id
      name = local.private_dns_zone_name
      note = "Used for creating CNAME records for container apps"
    } : null
    public_dns_zone = local.public_dns_zone_id != "" ? {
      id   = local.public_dns_zone_id
      name = local.public_dns_zone_name
      note = "Used for creating DNS records for internet-accessible container apps via Application Gateway"
    } : null
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
        "$${{ vars.PRIVATE_DNS_ZONE_NAME }}",
        "$${{ vars.PUBLIC_DNS_ZONE_NAME }}",
        "$${{ vars.BACKEND_AZURE_RESOURCE_GROUP_NAME }}",
        "$${{ vars.BACKEND_AZURE_STORAGE_ACCOUNT_NAME }}",
        "$${{ vars.BACKEND_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME }}"
      ]
    }
  }
}

output "environment_to_identity_mapping" {
  description = "Quick reference mapping of GitHub environments to their Azure managed identity client IDs and target Container App Environments."
  value = [
    for env in local.environments : {
      github_environment    = env.key
      container_environment = env.container_environment
      azure_client_id       = module.managed_identity_app_repositories[env.key].client_id
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
    azure_role_assignments = {
      plan_environments = [
        "Reader on Container App Environment (read-only access)",
        "Storage Blob Data Reader on Terraform state storage (read-only)"
      ]
      apply_environments = concat([
        "AcrPush on ${local.acr_name}",
        "Container Apps Contributor on Container App Environment",
        "Container Apps Jobs Contributor on Container App Environment",
        "Reader on Container App Environment",
        "Storage Blob Data Contributor on Terraform state storage (read/write)"
        ], local.ace_storage_account_id != "" ? [
        "Storage Blob Data Contributor on ACE storage account (${local.ace_storage_account_name})",
        "Storage File Data SMB Share Contributor on ACE storage account (${local.ace_storage_account_name})",
        "Storage Queue Data Contributor on ACE storage account (${local.ace_storage_account_name})",
        "Storage Table Data Contributor on ACE storage account (${local.ace_storage_account_name})"
        ] : [], local.private_dns_zone_id != "" ? [
        "DNS Zone Contributor on private DNS zone (${local.private_dns_zone_name})"
        ] : [], local.public_dns_zone_id != "" ? [
        "DNS Zone Contributor on public DNS zone (${local.public_dns_zone_name})"
      ] : [])
      security_note = "Plan environments (ending with '-plan') get read-only permissions, apply environments get full deployment permissions including ACE storage access and DNS management"
    }
    common_issues = {
      github_token_permissions = "Ensure token has repo, workflow, read:org scopes"
      azure_permissions        = "Ensure Azure identity has Contributor access to subscription"
      network_access           = "Module requires access to private Terraform backend storage"
      plan_permissions         = "Plan environments have read-only access - use apply environments for deployments"
      ace_storage_access       = local.ace_storage_account_id != "" ? "ACE storage account permissions automatically granted to apply environments" : "No ACE storage account detected - storage permissions not assigned"
      dns_zone_access          = local.private_dns_zone_id != "" ? "DNS zone permissions automatically granted to apply environments for CNAME record creation" : "No private DNS zone detected - DNS permissions not assigned"
      public_dns_zone_access   = local.public_dns_zone_id != "" ? "Public DNS zone permissions automatically granted to apply environments for internet-accessible apps" : "No public DNS zone detected - public DNS permissions not assigned"
    }
  }
}

# =============================================================================
# RAW DATA (for advanced users)
# =============================================================================

output "raw_configuration" {
  description = "Raw configuration data for advanced troubleshooting (use only if you know what you're doing)."
  value = {
    parsed_repositories         = local.repositories
    remote_state_outputs        = local.remote_state_outputs
    terraform_backend_config    = local.terraform_backend
    github_environment_config   = local.github_environment_config
    processed_role_assignments  = local.environment_role_assignments
  }
  sensitive = false
}

