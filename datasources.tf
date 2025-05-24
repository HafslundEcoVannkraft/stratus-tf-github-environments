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
    resource_group_name  = var.remote_state_resource_group_name != null ? var.remote_state_resource_group_name : "${var.code_name}-state-rg-${var.environment}"
    storage_account_name = var.remote_state_storage_account_name != null ? var.remote_state_storage_account_name : var.state_storage_account_name
    container_name       = var.remote_state_container != null ? var.remote_state_container : "tfstate"        # Azure Storage container name
    key                  = var.remote_state_key != null ? var.remote_state_key : "${var.environment}.tfstate" # Blob name/path for the Container App Environment deployment (e.g., dev.tfstate)
  }
}

# Get current Azure client configuration (for role assignments, etc.)
data "azurerm_client_config" "current" {}

# Look up team IDs for teams referenced by name or slug
data "github_team" "environment_teams" {
  for_each = toset(flatten([
    for repo in local.repositories : [
      for env in repo.environments : [
        for team in try(env.reviewers.teams, []) :
        team.name != null ? team.name : team.slug
      ]
    ]
  ]))

  slug = each.key
}

# Look up user IDs for users referenced by username
data "github_user" "environment_users" {
  for_each = toset(flatten([
    for repo in local.repositories : [
      for env in repo.environments : [
        for user in try(env.reviewers.users, []) : user.username
      ]
    ]
  ]))

  username = each.key
}

# Look up existing environments to handle imports
data "github_repository_environments" "existing" {
  for_each = toset([
    for env in local.environments : env.repository
  ])

  repository = each.key
}
