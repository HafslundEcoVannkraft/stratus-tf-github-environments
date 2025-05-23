# -----------------------------------------------------------------------------
# datasources.tf
# Data sources and supporting locals for the stratus-tf-aca-gh-vending module.
# Handles remote state access and Azure client config.
# -----------------------------------------------------------------------------

# Access the remote state to get container app environment configuration
# This is used to retrieve outputs from another Terraform deployment
# (e.g., container app environment ID, ACR name, etc.)
data "terraform_remote_state" "container_app_environment" {
  backend = "azurerm"

  config = {
    resource_group_name  = "${var.code_name}-state-rg-${var.environment}"
    storage_account_name = var.state_storage_account_name
    container_name       = "tfstate"                                                                # Azure Storage container name
    key                  = try("${var.environment}.tfstate", "examples/corp/container_app.tfstate") # Blob name/path within the container, fallback to examples/corp/container_app.tfstate to support stratus-tf-examples usage
  }
}

# Get current Azure client configuration (for role assignments, etc.)
data "azurerm_client_config" "current" {}
