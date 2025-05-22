# -----------------------------------------------------------------------------
# outputs.tf
# Output values for the stratus-tf-aca-gh-vending module.
# Exposes configured repositories, environments, identities, and debug info.
# -----------------------------------------------------------------------------

output "configured_repositories" {
  description = "List of repositories that were configured by this module."
  value = distinct([
    for repo in local.repositories : "${var.github_owner}/${repo.repo}"
  ])
}

output "configured_environments" {
  description = "Map of environments that were configured for each repository."
  value = {
    for repo in local.repositories : "${var.github_owner}/${repo.repo}" => [
      for env in repo.environments : env.name
    ]
  }
}

output "resource_group_name" {
  description = "Name of the resource group containing GitHub managed identities."
  value       = azurerm_resource_group.github_identities.name
}

output "managed_identities" {
  description = "Map of managed identities created for each repository environment."
  value = {
    for key, identity in module.managed_identity_app_repositories : key => {
      resource_name = identity.resource_name
      client_id     = identity.client_id
      principal_id  = identity.principal_id
      resource_id   = identity.resource_id
    }
  }
}

output "github_organization" {
  description = "GitHub organization configured for this module."
  value       = var.github_owner
}

output "github_repositories" {
  description = "List of GitHub repositories configured by this module."
  value       = distinct([for repo in local.repositories : repo.repo])
}

output "github_environments" {
  description = "List of all GitHub environments created by this module."
  value       = local.environments
}

output "github_managed_environments" {
  description = "List of all GitHub environments created and managed by Terraform."
  value       = keys(github_repository_environment.env)
}

# Debug outputs from remote state
output "remote_state_outputs" {
  description = "Outputs from remote state (for debugging and advanced use)."
  value       = local.remote_state_outputs
}

