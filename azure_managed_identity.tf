# -----------------------------------------------------------------------------
# azure_managed_identities.tf
# Managed identities and federated credentials for GitHub environments.
# -----------------------------------------------------------------------------

# Creates managed identities for application repositories
module "managed_identity_app_repositories" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.3.3"

  for_each = { for item in local.flattened_repo_environments : item.key => item }

  name                = "${var.code_name}-id-github-${each.value.azure_resource_key}"
  location            = var.location
  resource_group_name = azurerm_resource_group.github_identities.name
  enable_telemetry    = true
}

# Create Federated identity credential for GitHub environments
resource "azapi_resource" "github_federated_credential" {
  for_each = { for item in local.flattened_repo_environments : item.key => item }

  type      = "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31"
  name      = "${each.value.repo}-${each.value.environment}"
  parent_id = module.managed_identity_app_repositories[each.key].resource_id
  body = {
    properties = {
      audiences = ["api://AzureADTokenExchange"]
      issuer    = "https://token.actions.githubusercontent.com"
      subject   = "repo:${var.github_owner}/${each.value.repo}:environment:${each.value.environment}"
    }
  }
  response_export_values    = ["*"]
  schema_validation_enabled = true
}