# -----------------------------------------------------------------------------
# version.tf
# Terraform version and provider requirements for the stratus-tf-aca-gh-vending module.
# -----------------------------------------------------------------------------

terraform {
  backend "azurerm" {}
  required_providers {
    # Azure Resource Manager provider (for Azure resources)
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    # Azure API Management provider (for federated credentials)
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4.0"
    }
    # GitHub provider (for repository/environment management)
    github = {
      source  = "integrations/github"
      version = "~> 6.6.0"
    }
    # Random provider (for resource names)
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
    # Null provider (for validation checks)
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.1"
    }
    # Time provider (for wait operations)
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9.1"
    }
  }
  required_version = ">= 1.9.0"
}

# Configure the Azure providers
provider "azurerm" {
  features {}
}

provider "azapi" {
  # No additional configuration required
}

# Configure the GitHub provider for repository/environment management
provider "github" {
  token = var.github_token
  owner = var.github_owner
}
