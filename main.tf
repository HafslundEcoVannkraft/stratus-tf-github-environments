module "github_environments" {
  source = "github.com/HafslundEcoVannkraft/stratus-tf-aca-gh-vending/modules/github_environments"

  # Variables from tfvars file
  subscription_id            = var.subscription_id
  location                   = var.location
  code_name                  = var.code_name
  environment                = var.environment
  state_storage_account_name = var.state_storage_account_name

  # Variables from workflow inputs
  github_token           = var.github_token
  github_owner           = var.github_owner
  github_env_file        = "${path.module}/${var.github_env_file}"
  is_stratus_tf_examples = var.is_stratus_tf_examples
} 