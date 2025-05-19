# -----------------------------------------------------------------------------
# roles.tf
# Azure role assignments for managed identities used by GitHub environments.
# -----------------------------------------------------------------------------

# Assign AcrPush role to managed identities for all GitHub environments
resource "azurerm_role_assignment" "github_federated_credentials_acrpush" {
  for_each = local.container_app_environment_id != "" && local.acr_name != "" ? { for item in local.flattened_repo_environments : item.full_key => item } : {}

  scope                = local.acr_resource_id
  role_definition_name = "AcrPush"
  principal_id         = module.managed_identity_app_repositories[each.key].principal_id
  principal_type       = "ServicePrincipal"
}

# Assign Container Apps Contributor role to managed identities for all environments
resource "azurerm_role_assignment" "github_federated_credentials_container_apps_contributor" {
  for_each = local.container_app_environment_id != "" ? { for item in local.flattened_repo_environments : item.full_key => item } : {}

  scope                = local.container_app_environment_id
  role_definition_name = "Container Apps Contributor"
  principal_id         = module.managed_identity_app_repositories[each.key].principal_id
  principal_type       = "ServicePrincipal"
}

# Assign Container Apps Jobs Contributor role to managed identities for all environments
resource "azurerm_role_assignment" "github_federated_credentials_container_apps_jobs_contributor" {
  for_each = local.container_app_environment_id != "" ? { for item in local.flattened_repo_environments : item.full_key => item } : {}

  scope                = local.container_app_environment_id
  role_definition_name = "Container Apps Jobs Contributor"
  principal_id         = module.managed_identity_app_repositories[each.key].principal_id
  principal_type       = "ServicePrincipal"
}

# Assign Storage Blob Data Contributor role to managed identities for all environments
resource "azurerm_role_assignment" "github_federated_credentials_storage_blob_data_contributor" {
  for_each = length(local.terraform_backend.resource_group_name) > 0 && length(local.terraform_backend.storage_account_name) > 0 ? { for item in local.flattened_repo_environments : item.full_key => item } : {}

  # Use the storage account for Terraform state
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.terraform_backend.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${local.terraform_backend.storage_account_name}"
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.managed_identity_app_repositories[each.key].principal_id
  principal_type       = "ServicePrincipal"
}
