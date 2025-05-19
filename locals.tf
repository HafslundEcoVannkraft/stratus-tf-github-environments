# -----------------------------------------------------------------------------
# locals.tf
# Local values for the stratus-tf-aca-gh-vending module.
# Used for file paths, YAML parsing, backend config, and validation.
# -----------------------------------------------------------------------------
locals {
  # Path to the stratus-aca-github-environments.yaml config file (overridable by var.repositories_file)
  repositories_file = coalesce(var.repositories_file, "${path.module}/stratus-aca-github-environments.yaml")

  # Path to the JSON schema for validating the YAML config
  schema_file = "${path.module}/schema.json"

  # Outputs from remote state (used for cross-module references)
  remote_state_outputs                = try(data.terraform_remote_state.container_app_environment.outputs, {})
  container_app_environment_id        = try(local.remote_state_outputs.container_app_environment_id, "")
  container_app_environment_client_id = try(local.remote_state_outputs.container_app_environment_client_id, "")
  acr_name                            = try(local.remote_state_outputs.acr_name, "")
  acr_resource_id                     = try(local.remote_state_outputs.acr_resource_id, "")


  # Read YAML file directly and parse with yamldecode
  yaml_content = file("${path.module}/stratus-aca-github-environments.yaml")
  yaml_data    = yamldecode(local.yaml_content)

  # Extract repositories from parsed YAML - expects all repos to be in the same organization
  repositories = try(local.yaml_data.repositories, [])

  # Flatten repositories and environments for identity creation
  flattened_repo_environments = flatten([
    for repo in local.repositories : [
      for env in repo.environments : {
        repo        = repo.repo
        environment = env.name
        key         = "${repo.repo}:${env.name}"
        full_key    = "${repo.repo}-${env.name}"
      }
    ]
  ])

  # Backend information for GitHub environments (used for state and role assignments)
  terraform_backend = {
    resource_group_name  = "${var.code_name}-state-rg-${var.environment}"
    storage_account_name = var.state_storage_account_name
    container_name       = "tfstate"
  }

  # Basic validation using terraform built-in conditions
  valid_yaml = alltrue([
    length(local.yaml_data.repositories) > 0,
    # Add more validation rules as needed
  ])

  # List of all environment keys in the format "repo:environment"
  environments_import_keys = flatten([
    for repo in local.repositories : [
      for env in repo.environments : "${repo.repo}:${env.name}"
    ]
  ])
}
