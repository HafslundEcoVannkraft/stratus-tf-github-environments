# -----------------------------------------------------------------------------
# azure.tf
# Azure resources for the stratus-tf-aca-gh-vending module.
# Handles resource group creation, managed identities, federated credentials,
# role assignments, validation, and random naming.
# -----------------------------------------------------------------------------

# =============================================================================
# VALIDATION AND CORE RESOURCES
# =============================================================================

# Comprehensive validation using modern Terraform check blocks
# These run during plan phase and provide clear error messages
check "yaml_configuration_valid" {
  assert {
    condition     = local.validation_passed
    error_message = "YAML configuration validation failed:\n${join("\n", local.validation_errors_filtered)}"
  }
}

check "minimum_deployment_requirements" {
  assert {
    condition     = local.can_deploy
    error_message = <<-EOT
      Minimum deployment requirements not met. Please ensure:
      - YAML configuration is valid
      - At least one environment is defined
      - GitHub owner and token are provided
      - Azure subscription ID and location are set
      - Code name and environment are specified
      
      Current validation errors:
      ${join("\n", local.validation_errors_filtered)}
    EOT
  }
}

check "remote_state_configuration" {
  assert {
    condition     = local.validation_results.remote_state_accessible
    error_message = <<-EOT
      Remote state is not accessible. This may indicate:
      - Incorrect remote state configuration
      - Missing permissions to access the storage account
      - The referenced state file does not exist
      
      Please verify your remote state configuration:
      - Resource Group: ${var.remote_state_resource_group_name != null ? var.remote_state_resource_group_name : "${var.code_name}-state-rg-${var.environment}"}
      - Storage Account: ${var.remote_state_storage_account_name != null ? var.remote_state_storage_account_name : var.state_storage_account_name}
      - Container: ${var.remote_state_container != null ? var.remote_state_container : "tfstate"}
      - Key: ${var.remote_state_key != null ? var.remote_state_key : "${var.environment}.tfstate"}
    EOT
  }
}

check "github_environment_config_available" {
  assert {
    condition     = local.validation_results.github_environment_config_present || length(local.validation_errors) == 0
    error_message = <<-EOT
      GitHub environment configuration not found in remote state.
      
      The module expects a 'github_environment_config' output from your infrastructure module.
      This output should contain environment variables, secrets, and role assignments.
      
      If you're using the new remote state convention, ensure your infrastructure module
      outputs the github_environment_config structure as documented.
      
      If you're migrating from legacy role assignments, this warning can be ignored
      until you update your infrastructure module.
    EOT
  }
}

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

# Creates managed identities for application repositories
module "managed_identity_app_repositories" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.3.3"

  for_each = { for item in local.flattened_repo_environments : item.key => item }

  name                = "${local.naming.managed_identity_prefix}-${each.value.azure_resource_key}"
  location            = var.location
  resource_group_name = azurerm_resource_group.github_identities.name
  enable_telemetry    = true

  # Add tags to managed identities
  tags = merge(local.common_tags, {
    ResourceType      = "managed-identity"
    GitHubRepository  = each.value.repo
    GitHubEnvironment = each.value.environment
    EnvironmentKey    = each.key
  })
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

# =============================================================================
# ROLE ASSIGNMENTS FROM REMOTE STATE
# =============================================================================

# Role assignments defined in remote state github_environment_config
# This replaces all hardcoded role assignments with a flexible approach
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