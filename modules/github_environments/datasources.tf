# -----------------------------------------------------------------------------
# datasources.tf
# Data sources and supporting locals for the stratus-tf-aca-gh-vending module.
# Handles remote state access and Azure client config.
# -----------------------------------------------------------------------------

locals {
  # Determine the remote state key for the container app environment.
  # Uses a different key if running in the stratus-tf-examples repo.
  container_app_environment_key = var.is_stratus_tf_examples == true ? "examples/corp/container_app.tfstate" : "${var.environment}.tfstate"
}

# Access the remote state to get container app environment configuration
# This is used to retrieve outputs from another Terraform deployment
# (e.g., container app environment ID, ACR name, etc.)
data "terraform_remote_state" "container_app_environment" {
  backend = "azurerm"

  config = {
    resource_group_name  = "${var.code_name}-state-rg-${var.environment}"
    storage_account_name = var.state_storage_account_name
    container_name       = "tfstate"                           # Azure Storage container name
    key                  = local.container_app_environment_key # Blob name/path within the container
  }
}

# Get current Azure client configuration (for role assignments, etc.)
data "azurerm_client_config" "current" {}
