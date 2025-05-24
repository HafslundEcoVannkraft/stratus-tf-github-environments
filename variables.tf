# -----------------------------------------------------------------------------
# variables.tf
# Input variables for the stratus-tf-aca-gh-vending module.
# Configure Azure, GitHub, and module-specific settings here.
# -----------------------------------------------------------------------------
variable "subscription_id" {
  description = "Azure Subscription ID used for resource deployment."
  type        = string
}

variable "location" {
  description = "Azure region for resource deployment (e.g., 'norwayeast')."
  type        = string
  default     = "norwayeast"
}

variable "code_name" {
  description = "Code name for the product team or application. Used for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, test, prod). Used for resource naming."
  type        = string
}

variable "state_storage_account_name" {
  description = "Name of the Azure Storage Account for Terraform state."
  type        = string
}

variable "github_token" {
  description = "GitHub token with permissions to create and manage environments and secrets."
  type        = string
  ephemeral   = true
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub organization or user name for repository ownership."
  type        = string
  default     = "HafslundEcoVannkraft"
}

variable "github_env_file" {
  description = "Filename of the GitHub environments configuration file. The workflow will search for this file recursively from the repository root."
  type        = string
  default     = "github-envrionments.yaml"
}

variable "remote_state_resource_group_name" {
  description = "Optional: Override the default terraform remote state resource group name, the default resource group will be <code_name>-state-rg-<environment>"
  type        = string
  default     = null
}

variable "remote_state_storage_account_name" {
  description = "Optional: Override the default terraform remote state storage account name, the default storage_account_name will be var.state_storage_account_name"
  type        = string
  default     = null
}

variable "remote_state_container" {
  description = "Optional: Override the default terraform remote state container, the default container will be tfstate"
  type        = string
  default     = null
}

variable "remote_state_key" {
  description = "Optional: Override the default terraform remote state key, the default key will be <environment>.tfstate"
  type        = string
  default     = null
}
