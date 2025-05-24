# -----------------------------------------------------------------------------
# azure_roles.tf
# Azure role assignments for managed identities used by GitHub environments.
# Implements least-privilege access: plan environments get read-only access,
# apply environments get full deployment permissions.
# -----------------------------------------------------------------------------

# =============================================================================
# ROLE ASSIGNMENTS FROM REMOTE STATE (NEW CONVENTION)
# =============================================================================

# Role assignments defined in remote state github_environment_config
# This replaces the hardcoded role assignments below with a flexible approach
# where the upstream infrastructure defines exactly what permissions each environment needs
resource "azurerm_role_assignment" "github_environment_roles_from_remote_state" {
  for_each = local.role_assignments_map

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.managed_identity_id
  principal_type       = "ServicePrincipal"

  depends_on = [
    module.managed_identity_app_repositories
  ]
}

# =============================================================================
# LEGACY ROLE ASSIGNMENTS (BACKWARD COMPATIBILITY)
# =============================================================================
# The following role assignments are kept for backward compatibility
# They will be removed once all upstream modules migrate to the new convention

# =============================================================================
# SHARED PERMISSIONS (both plan and apply environments)
# =============================================================================

# All environments need read access to Container App Environment for planning
resource "azurerm_role_assignment" "github_federated_credentials_container_apps_reader" {
  for_each = local.container_app_environment_id != "" ? { for item in local.flattened_repo_environments : item.key => item } : {}

  scope                = local.container_app_environment_id
  role_definition_name = "Reader"
  principal_id         = module.managed_identity_app_repositories[each.key].principal_id
  principal_type       = "ServicePrincipal"
}

# =============================================================================
# PLAN-ONLY PERMISSIONS (read-only environments)
# =============================================================================

# Plan environments only need read access to Terraform state
resource "azurerm_role_assignment" "github_federated_credentials_storage_blob_data_reader" {
  for_each = length(local.terraform_backend.resource_group_name) > 0 && length(local.terraform_backend.storage_account_name) > 0 ? {
    for item in local.flattened_repo_environments : item.key => item
    if can(regex(".*-plan$", item.environment)) # Include only environments ending with "-plan"
  } : {}

  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.terraform_backend.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${local.terraform_backend.storage_account_name}"
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = module.managed_identity_app_repositories[each.key].principal_id
  principal_type       = "ServicePrincipal"
}

# =============================================================================
# APPLY-ONLY PERMISSIONS (deployment environments only)
# =============================================================================

# Apply environments need write access to Terraform state for state updates
resource "azurerm_role_assignment" "github_federated_credentials_storage_blob_data_contributor" {
  for_each = length(local.terraform_backend.resource_group_name) > 0 && length(local.terraform_backend.storage_account_name) > 0 ? {
    for item in local.flattened_repo_environments : item.key => item
    if !can(regex(".*-plan$", item.environment)) # Exclude environments ending with "-plan"
  } : {}

  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.terraform_backend.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${local.terraform_backend.storage_account_name}"
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.managed_identity_app_repositories[each.key].principal_id
  principal_type       = "ServicePrincipal"
}

# Only apply environments can push container images to ACR
resource "azurerm_role_assignment" "github_federated_credentials_acrpush" {
  for_each = local.container_app_environment_id != "" && local.acr_name != "" ? {
    for item in local.flattened_repo_environments : item.key => item
    if !can(regex(".*-plan$", item.environment)) # Exclude environments ending with "-plan"
  } : {}

  scope                = local.acr_resource_id
  role_definition_name = "AcrPush"
  principal_id         = module.managed_identity_app_repositories[each.key].principal_id
  principal_type       = "ServicePrincipal"
}

# Only apply environments can deploy to Azure Container Apps
resource "azurerm_role_assignment" "github_federated_credentials_container_apps_contributor" {
  for_each = local.container_app_environment_id != "" ? {
    for item in local.flattened_repo_environments : item.key => item
    if !can(regex(".*-plan$", item.environment)) # Exclude environments ending with "-plan"
  } : {}

  scope                = local.container_app_environment_id
  role_definition_name = "Container Apps Contributor"
  principal_id         = module.managed_identity_app_repositories[each.key].principal_id
  principal_type       = "ServicePrincipal"
}

# Only apply environments can deploy jobs to Container Apps
resource "azurerm_role_assignment" "github_federated_credentials_container_apps_jobs_contributor" {
  for_each = local.container_app_environment_id != "" ? {
    for item in local.flattened_repo_environments : item.key => item
    if !can(regex(".*-plan$", item.environment)) # Exclude environments ending with "-plan"
  } : {}

  scope                = local.container_app_environment_id
  role_definition_name = "Container Apps Jobs Contributor"
  principal_id         = module.managed_identity_app_repositories[each.key].principal_id
  principal_type       = "ServicePrincipal"
}

# =============================================================================
# ACE STORAGE ACCOUNT PERMISSIONS (apply environments only)
# =============================================================================

# Only apply environments can access ACE storage account for persistent storage
resource "azurerm_role_assignment" "github_federated_credentials_ace_storage_blob_data_contributor" {
  for_each = local.ace_storage_account_id != "" ? {
    for item in local.flattened_repo_environments : item.key => item
    if !can(regex(".*-plan$", item.environment)) # Exclude environments ending with "-plan"
  } : {}

  scope                = local.ace_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.managed_identity_app_repositories[each.key].principal_id
  principal_type       = "ServicePrincipal"
}

# Only apply environments can access ACE file shares
resource "azurerm_role_assignment" "github_federated_credentials_ace_storage_file_data_smb_share_contributor" {
  for_each = local.ace_storage_account_id != "" ? {
    for item in local.flattened_repo_environments : item.key => item
    if !can(regex(".*-plan$", item.environment)) # Exclude environments ending with "-plan"
  } : {}

  scope                = local.ace_storage_account_id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = module.managed_identity_app_repositories[each.key].principal_id
  principal_type       = "ServicePrincipal"
}

# Only apply environments can access ACE storage queues (for Dapr components)
resource "azurerm_role_assignment" "github_federated_credentials_ace_storage_queue_data_contributor" {
  for_each = local.ace_storage_account_id != "" ? {
    for item in local.flattened_repo_environments : item.key => item
    if !can(regex(".*-plan$", item.environment)) # Exclude environments ending with "-plan"
  } : {}

  scope                = local.ace_storage_account_id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = module.managed_identity_app_repositories[each.key].principal_id
  principal_type       = "ServicePrincipal"
}

# Only apply environments can access ACE storage tables (for Dapr components)
resource "azurerm_role_assignment" "github_federated_credentials_ace_storage_table_data_contributor" {
  for_each = local.ace_storage_account_id != "" ? {
    for item in local.flattened_repo_environments : item.key => item
    if !can(regex(".*-plan$", item.environment)) # Exclude environments ending with "-plan"
  } : {}

  scope                = local.ace_storage_account_id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = module.managed_identity_app_repositories[each.key].principal_id
  principal_type       = "ServicePrincipal"
}

# =============================================================================
# DNS ZONE PERMISSIONS (apply environments only)
# =============================================================================

# Only apply environments can create DNS records for container apps
resource "azurerm_role_assignment" "github_federated_credentials_dns_zone_contributor" {
  for_each = local.private_dns_zone_id != "" ? {
    for item in local.flattened_repo_environments : item.key => item
    if !can(regex(".*-plan$", item.environment)) # Exclude environments ending with "-plan"
  } : {}

  scope                = local.private_dns_zone_id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = module.managed_identity_app_repositories[each.key].principal_id
  principal_type       = "ServicePrincipal"
}

# Only apply environments can create public DNS records for internet-accessible container apps
resource "azurerm_role_assignment" "github_federated_credentials_public_dns_zone_contributor" {
  for_each = local.public_dns_zone_id != "" ? {
    for item in local.flattened_repo_environments : item.key => item
    if !can(regex(".*-plan$", item.environment)) # Exclude environments ending with "-plan"
  } : {}

  scope                = local.public_dns_zone_id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = module.managed_identity_app_repositories[each.key].principal_id
  principal_type       = "ServicePrincipal"
}