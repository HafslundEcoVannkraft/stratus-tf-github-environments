# -----------------------------------------------------------------------------
# locals.tf
# Local values for the stratus-tf-aca-gh-vending module.
# Used for file paths, YAML parsing, backend config, and validation.
# -----------------------------------------------------------------------------
locals {
  # =============================================================================
  # FILE PROCESSING AND YAML PARSING
  # =============================================================================
  
  # Path to the GitHub environment configuration file
  # Falls back to minimal example if the specified file doesn't exist
  github_env_file = var.github_env_file
  
  # Read and parse the YAML configuration file
  # This contains the repository and environment definitions
  # If the specified file doesn't exist, fall back to the minimal example
  yaml_content = fileexists(local.github_env_file) ? file(local.github_env_file) : file("${path.module}/examples/minmal.yaml")
  
  # Parse the YAML content into a Terraform object
  # This is the single source of truth for all configuration data
  config = yamldecode(local.yaml_content)
  
  # Extract the repositories array from the parsed configuration
  # Each repository contains:
  # - repo: GitHub repository name
  # - environments: Array of environment configurations
  repositories = local.config.repositories

  # =============================================================================
  # REMOTE STATE AND AZURE RESOURCE REFERENCES
  # =============================================================================
  
  # Outputs from the remote Terraform state (Container App Environment deployment)
  # This links to infrastructure provisioned by another Terraform configuration
  # Contains references to ACR, Container App Environment, and other shared resources
  remote_state_outputs = try(data.terraform_remote_state.container_app_environment.outputs, {})
  
  # Azure Container App Environment ID where applications will be deployed
  # Retrieved from remote state to ensure consistency across deployments
  container_app_environment_id = try(local.remote_state_outputs.container_app_environment_id, "")
  
  # Azure Container Registry name for container image storage
  # Used for role assignments to allow GitHub Actions to push images
  acr_name = try(local.remote_state_outputs.acr_name, "")
  
  # Azure Container Registry resource ID for RBAC assignments
  # Full ARM resource path needed for role assignment scope
  acr_resource_id = try(local.remote_state_outputs.acr_resource_id, "")

  # =============================================================================
  # ENVIRONMENT PROCESSING AND FLATTENING
  # =============================================================================
  
  # Flatten the nested repository/environment structure for easier processing
  # Creates a list where each item represents one repository-environment combination
  # Used for creating managed identities and federated credentials
  # Structure: [{ repo, environment, key, full_key }, ...]
  flattened_repo_environments = flatten([
    for repo in local.repositories : [
      for env in repo.environments : {
        repo        = repo.repo                           # GitHub repository name
        environment = env.name                            # Environment name (dev, staging, prod, etc.)
        key         = "${repo.repo}:${env.name}"         # Colon-separated key for GitHub references
        full_key    = "${repo.repo}-${env.name}"         # Dash-separated key for Azure resource naming
      }
    ]
  ])

  # =============================================================================
  # TERRAFORM BACKEND CONFIGURATION
  # =============================================================================
  
  # Backend configuration information used for role assignments
  # GitHub Actions need access to the Terraform state storage account
  # This allows CI/CD pipelines to read/write Terraform state
  terraform_backend = {
    resource_group_name  = "${var.code_name}-state-rg-${var.environment}"   # Resource group containing state storage
    storage_account_name = var.state_storage_account_name                    # Storage account for Terraform state
    container_name       = "tfstate"                                         # Blob container for state files
  }

  # =============================================================================
  # VALIDATION
  # =============================================================================
  
  # Basic validation to ensure the YAML configuration is valid
  # Checks that at least one repository is defined in the configuration
  # Additional validation rules can be added here as needed
  valid_yaml = alltrue([
    length(local.config.repositories) > 0,
    # Future validation rules can be added here:
    # - Check required fields are present
    # - Validate environment names follow naming conventions
    # - Ensure no duplicate repository/environment combinations
  ])
}
