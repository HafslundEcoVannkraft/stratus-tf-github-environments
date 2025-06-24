# -----------------------------------------------------------------------------
# azure.tf
# Azure resources for the stratus-tf-github-environments module.
# Handles resource group creation, managed identities, federated credentials,
# role assignments, validation, and random naming.
# -----------------------------------------------------------------------------

# =============================================================================
# CORE RESOURCES
# =============================================================================

# Random string for unique resource naming
resource "random_string" "name_suffix" {
  length  = 4
  special = false
  upper   = false
}

# Create resource group for managed identities
resource "azurerm_resource_group" "github_identities" {
  name     = local.naming.resource_group_name
  location = var.location
  tags     = local.common_tags

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags["DeploymentDate"] # Ignore deployment date changes on updates
    ]
  }
}

# =============================================================================
# MANAGED IDENTITIES AND FEDERATED CREDENTIALS
# =============================================================================

# Creates managed identities for GitHub environments
module "github_environment_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.3.3"

  for_each = local.environments_map

  name                = "${local.naming.managed_identity_prefix}-${each.value.repository}-${each.value.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.github_identities.name
  enable_telemetry    = true

  # Add tags to managed identities
  tags = merge(local.common_tags, {
    ResourceType      = "managed-identity"
    GitHubRepository  = each.value.repository
    GitHubEnvironment = each.value.environment
    DeploymentTarget  = try(each.value.metadata.deployment_target, "generic")
    EnvironmentKey    = each.key
  })
}

# Create Federated identity credential for GitHub environments
resource "azapi_resource" "github_environment_federated_credential" {
  for_each = local.environments_map

  type      = "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31"
  name      = "${each.value.repository}-${each.value.environment}"
  parent_id = module.github_environment_identity[each.key].resource_id
  body = {
    properties = {
      audiences = ["api://AzureADTokenExchange"]
      issuer    = "https://token.actions.githubusercontent.com"
      subject   = "repo:${var.github_owner}/${each.value.repository}:environment:${each.value.environment}"
    }
  }
  response_export_values    = ["*"]
  schema_validation_enabled = true
}

# =============================================================================
# ROLE ASSIGNMENTS FROM REMOTE STATE
# =============================================================================

# Role assignments defined in remote state github_environment_config
# This replaces all hardcoded role assignments with a flexible approach
# where the upstream infrastructure defines exactly what permissions each environment needs
resource "azurerm_role_assignment" "github_environment_role_assignment" {
  for_each = local.role_assignments_map

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.managed_identity_id
  principal_type       = "ServicePrincipal"

  depends_on = [
    module.github_environment_identity
  ]
}
