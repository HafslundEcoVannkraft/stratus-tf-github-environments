# -----------------------------------------------------------------------------
# main.tf
# Core resources for the stratus-tf-aca-gh-vending module.
# Handles validation, random naming, and resource group creation.
# -----------------------------------------------------------------------------

# Fail if YAML validation doesn't pass
resource "null_resource" "validation_check" {
  count = local.valid_yaml ? 0 : "YAML validation failed - check your configuration"
}

# Random string for unique resource naming
resource "random_string" "name_suffix" {
  length  = 4
  special = false
  upper   = false
}

# Create resource group for managed identities
resource "azurerm_resource_group" "github_identities" {
  name     = "${var.code_name}-rg-${var.environment}-github-identities-${random_string.name_suffix.result}"
  location = var.location
}