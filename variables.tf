# -----------------------------------------------------------------------------
# variables.tf
# Input variables for the stratus-tf-aca-gh-vending module.
# Configure Azure, GitHub, and module-specific settings here.
# -----------------------------------------------------------------------------
variable "subscription_id" {
  description = "Azure Subscription ID used for resource deployment."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = "Subscription ID must be a valid UUID format (e.g., 12345678-1234-1234-1234-123456789012)."
  }
}

variable "location" {
  description = "Azure region for resource deployment (e.g., 'norwayeast')."
  type        = string
  default     = "norwayeast"

  validation {
    condition = contains([
      "norwayeast", "norwaywest", "westeurope", "northeurope", "eastus", "eastus2",
      "westus", "westus2", "centralus", "southcentralus", "northcentralus", "westcentralus"
    ], var.location)
    error_message = "Location must be a valid Azure region. Common options: norwayeast, norwaywest, westeurope, northeurope."
  }
}

variable "code_name" {
  description = "Code name for the product team or application. Used for resource naming."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.code_name))
    error_message = "Code name must be 3-63 characters, start and end with alphanumeric, contain only lowercase letters, numbers, and hyphens."
  }

  validation {
    condition     = !can(regex("^(microsoft|azure|windows|login)", var.code_name))
    error_message = "Code name cannot start with reserved Azure prefixes: microsoft, azure, windows, login."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, test, prod). Used for resource naming."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod", "staging", "uat", "preprod"], var.environment)
    error_message = "Environment must be one of: dev, test, prod, staging, uat, preprod."
  }

  validation {
    condition     = length(var.environment) <= 10
    error_message = "Environment name must be 10 characters or less for Azure resource naming constraints."
  }
}

variable "state_storage_account_name" {
  description = "Name of the Azure Storage Account for Terraform state."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.state_storage_account_name))
    error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only."
  }
}

variable "github_token" {
  description = "GitHub token with permissions to create and manage environments and secrets."
  type        = string
  ephemeral   = true
  sensitive   = true

  validation {
    condition     = length(var.github_token) > 10
    error_message = "GitHub token must be provided and cannot be empty."
  }
}

variable "github_owner" {
  description = "GitHub organization or user name for repository ownership."
  type        = string
  default     = "HafslundEcoVannkraft"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-])*[a-zA-Z0-9]$", var.github_owner)) && length(var.github_owner) <= 39
    error_message = "GitHub owner must be a valid GitHub username or organization name (max 39 characters)."
  }

  validation {
    condition     = !can(regex("^-|--|-$", var.github_owner))
    error_message = "GitHub owner cannot start/end with hyphens or contain consecutive hyphens."
  }
}

variable "github_env_file" {
  description = "Filename of the GitHub environments configuration file. The workflow will search for this file recursively from the repository root."
  type        = string
  default     = "github-environments.yaml"

  validation {
    condition     = can(regex("\\.(yaml|yml)$", var.github_env_file))
    error_message = "GitHub environment file must have .yaml or .yml extension."
  }

  validation {
    condition     = length(var.github_env_file) <= 255 && !can(regex("[<>:\"|?*]", var.github_env_file))
    error_message = "File name must be valid (max 255 chars, no special characters: < > : \" | ? *)."
  }
}

variable "remote_state_resource_group_name" {
  description = "Optional: Override the default terraform remote state resource group name, the default resource group will be <code_name>-state-rg-<environment>"
  type        = string
  default     = null

  validation {
    condition     = var.remote_state_resource_group_name == null || can(regex("^[a-zA-Z0-9._-]+$", var.remote_state_resource_group_name))
    error_message = "Resource group name must contain only alphanumeric characters, periods, underscores, and hyphens."
  }
}

variable "remote_state_storage_account_name" {
  description = "Optional: Override the default terraform remote state storage account name, the default storage_account_name will be var.state_storage_account_name"
  type        = string
  default     = null

  validation {
    condition     = var.remote_state_storage_account_name == null || can(regex("^[a-z0-9]{3,24}$", var.remote_state_storage_account_name))
    error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only."
  }
}

variable "remote_state_container" {
  description = "Optional: Override the default terraform remote state container, the default container will be tfstate"
  type        = string
  default     = null

  validation {
    condition     = var.remote_state_container == null || can(regex("^[a-z0-9-]{3,63}$", var.remote_state_container))
    error_message = "Container name must be 3-63 characters, lowercase letters, numbers, and hyphens only."
  }
}

variable "remote_state_key" {
  description = "Optional: Override the default terraform remote state key, the default key will be <environment>.tfstate"
  type        = string
  default     = null

  validation {
    condition     = var.remote_state_key == null || can(regex("\\.tfstate$", var.remote_state_key))
    error_message = "Remote state key must end with .tfstate extension."
  }
}

variable "resource_group_suffix" {
  description = "Optional: Custom suffix for the resource group name. If not provided, a random suffix will be generated."
  type        = string
  default     = null

  validation {
    condition     = var.resource_group_suffix == null || (length(var.resource_group_suffix) <= 10 && can(regex("^[a-z0-9]+$", var.resource_group_suffix)))
    error_message = "Resource group suffix must be 10 characters or less, lowercase letters and numbers only."
  }
}

variable "module_repo_ref" {
  description = "Git reference (branch, tag, or commit SHA) of the module repository used for deployment tracking."
  type        = string
  default     = "main"

  validation {
    condition     = length(var.module_repo_ref) > 0 && length(var.module_repo_ref) <= 100
    error_message = "Module repository reference must be 1-100 characters."
  }
}

variable "iac_repo_url" {
  description = "Optional: URL of the IaC repository that deployed these resources for tracking purposes."
  type        = string
  default     = null

  validation {
    condition     = var.iac_repo_url == null || can(regex("^https://", var.iac_repo_url))
    error_message = "IaC repository URL must start with https:// if provided."
  }
}
