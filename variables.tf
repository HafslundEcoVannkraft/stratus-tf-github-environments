# -----------------------------------------------------------------------------
# variables.tf
# Input variables for the stratus-tf-aca-gh-vending module.
# Configure Azure, GitHub, and module-specific settings here.
# -----------------------------------------------------------------------------

# Variables provided by the tfvars file
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

# Variables provided as workflow inputs
variable "github_token" {
  description = "GitHub token with permissions to create and manage environments and secrets."
  type        = string
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

variable "is_stratus_tf_examples" {
  description = "Set to true if calling this module from the stratus-tf-examples repo."
  type        = bool
  default     = false
} 