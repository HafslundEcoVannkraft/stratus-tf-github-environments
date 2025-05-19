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
  description = "GitHub token with permissions to create and manage environments and secrets. Should be stored securely (e.g., as a GitHub Actions secret)."
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub organization or user name for repository ownership. Defaults to the HafslundEcoVannkraft organization."
  type        = string
  default     = "HafslundEcoVannkraft"
}

variable "repositories_file" {
  description = "Path to the YAML file containing repository and environment configurations. Defaults to 'stratus-aca-github-environments.yaml' in the module directory."
  type        = string
  default     = "stratus-aca-github-environments.yaml"
}

variable "is_stratus_tf_examples" {
  description = "Set to true if calling this module from the stratus-tf-examples repo. Used for internal testing and examples. Defaults to false."
  type        = bool
  default     = false
}