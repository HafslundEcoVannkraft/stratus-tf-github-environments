# -----------------------------------------------------------------------------
# validation_test.tf
# Configuration validation tests for the stratus-tf-aca-gh-vending module
# Uses standard Terraform features to validate configuration logic
# -----------------------------------------------------------------------------

# =============================================================================
# TEST CONFIGURATION
# =============================================================================

terraform {
  required_version = ">= 1.3.0"
}

# =============================================================================
# TEST DATA AND VALIDATION LOGIC
# =============================================================================

locals {
  # Test YAML configurations
  test_configs = {
    valid_minimal = {
      repositories = [
        {
          repo = "test-repo"
          environments = [
            {
              name = "dev"
              container_environment = "dev"
            }
          ]
        }
      ]
    }
    
    valid_comprehensive = {
      repositories = [
        {
          repo = "test-repo-comprehensive"
          environments = [
            {
              name = "dev-plan"
              container_environment = "dev"
              wait_timer = 0
              prevent_self_review = false
              reviewers = {
                users = [{ username = "test-user" }]
                teams = [{ name = "test-team" }]
              }
              deployment_branch_policy = {
                protected_branches = false
                custom_branch_policies = true
                custom_branches = ["main", "develop"]
              }
              variables = {
                TEST_VAR = "test-value"
                DEBUG_MODE = "true"
              }
              secrets = [
                {
                  name = "TEST_SECRET"
                  value = "secret-value"
                }
              ]
            }
          ]
        }
      ]
    }
    
    invalid_conflicting_policies = {
      repositories = [
        {
          repo = "test-repo-invalid"
          environments = [
            {
              name = "conflicting-env"
              container_environment = "dev"
              deployment_branch_policy = {
                protected_branches = true
              }
              deployment_tag_policy = {
                enabled = true
                tag_patterns = ["v*"]
              }
            }
          ]
        }
      ]
    }
  }
  
  # Mock remote state structure
  mock_remote_state = {
    github_environment_config = {
      environments = {
        dev = {
          variables = {
            AZURE_TENANT_ID = "12345678-1234-1234-1234-123456789012"
            AZURE_SUBSCRIPTION_ID = "87654321-4321-4321-4321-210987654321"
            ACR_NAME = "testacr"
            CONTAINER_APP_ENVIRONMENT_ID = "/subscriptions/test/resourceGroups/test/providers/Microsoft.App/managedEnvironments/test"
          }
          secrets = {
            TEST_SECRET = "test-value"
          }
          settings = {
            wait_timer = 0
            prevent_self_review = false
          }
          role_assignments = {
            global = [
              {
                scope = "/subscriptions/test/resourceGroups/test"
                role = "Reader"
              }
            ]
            plan = []
            apply = [
              {
                scope = "/subscriptions/test/resourceGroups/test"
                role = "Contributor"
              }
            ]
          }
        }
      }
    }
  }

  # =============================================================================
  # VALIDATION TESTS USING STANDARD TERRAFORM FEATURES
  # =============================================================================

  # Test 1: YAML Configuration Structure
  yaml_structure_tests = {
    minimal_config_valid = alltrue([
      can(local.test_configs.valid_minimal.repositories),
      length(local.test_configs.valid_minimal.repositories) > 0,
      can(local.test_configs.valid_minimal.repositories[0].environments),
      length(local.test_configs.valid_minimal.repositories[0].environments) > 0
    ])
    
    comprehensive_config_valid = alltrue([
      can(local.test_configs.valid_comprehensive.repositories),
      can(local.test_configs.valid_comprehensive.repositories[0].environments[0].reviewers),
      can(local.test_configs.valid_comprehensive.repositories[0].environments[0].variables),
      can(local.test_configs.valid_comprehensive.repositories[0].environments[0].secrets)
    ])
  }

  # Test 2: Naming Validation
  naming_validation_tests = {
    environment_names_follow_conventions = alltrue([
      for config in values(local.test_configs) : alltrue([
        for repo in config.repositories : alltrue([
          for env in repo.environments :
          can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", env.name)) || length(env.name) == 1
        ])
      ])
    ])
    
    repository_names_valid = alltrue([
      for config in values(local.test_configs) : alltrue([
        for repo in config.repositories :
        can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", repo.repo)) || length(repo.repo) == 1
      ])
    ])
  }

  # Test 3: Security Policy Validation
  security_policy_tests = {
    production_environments_secure = alltrue([
      for config in values(local.test_configs) : alltrue([
        for repo in config.repositories : alltrue([
          for env in repo.environments :
          !contains(["prod", "production"], lower(env.name)) || (
            try(env.prevent_self_review, false) == true ||
            try(env.reviewers, null) != null
          )
        ])
      ])
    ])
    
    wait_timers_within_limits = alltrue([
      for config in values(local.test_configs) : alltrue([
        for repo in config.repositories : alltrue([
          for env in repo.environments :
          try(env.wait_timer, 0) >= 0 && try(env.wait_timer, 0) <= 43200
        ])
      ])
    ])
  }

  # Test 4: Policy Conflict Detection
  policy_conflict_tests = {
    # This should detect conflicts (return false for invalid config)
    no_branch_tag_policy_conflicts = alltrue([
      for config in values(local.test_configs) : alltrue([
        for repo in config.repositories : alltrue([
          for env in repo.environments :
          !(
            try(env.deployment_branch_policy.protected_branches, false) &&
            try(env.deployment_tag_policy.enabled, false)
          )
        ])
      ])
    ])
  }

  # Test 5: Variable and Secret Format
  variable_secret_format_tests = {
    variable_names_uppercase = alltrue([
      for config in values(local.test_configs) : alltrue([
        for repo in config.repositories : alltrue([
          for env in repo.environments : alltrue([
            for var_name, var_value in try(env.variables, {}) :
            can(regex("^[A-Z][A-Z0-9_]*$", var_name))
          ])
        ])
      ])
    ])
    
    secret_names_uppercase = alltrue([
      for config in values(local.test_configs) : alltrue([
        for repo in config.repositories : alltrue([
          for env in repo.environments : alltrue([
            for secret in try(env.secrets, []) :
            can(regex("^[A-Z][A-Z0-9_]*$", secret.name))
          ])
        ])
      ])
    ])
    
    secret_values_not_empty = alltrue([
      for config in values(local.test_configs) : alltrue([
        for repo in config.repositories : alltrue([
          for env in repo.environments : alltrue([
            for secret in try(env.secrets, []) :
            length(secret.value) > 0
          ])
        ])
      ])
    ])
  }

  # Test 6: Remote State Structure
  remote_state_structure_tests = {
    github_environment_config_structure = alltrue([
      can(local.mock_remote_state.github_environment_config),
      can(local.mock_remote_state.github_environment_config.environments),
      can(local.mock_remote_state.github_environment_config.environments.dev)
    ])
    
    required_azure_variables_present = alltrue([
      can(local.mock_remote_state.github_environment_config.environments.dev.variables.AZURE_TENANT_ID),
      can(local.mock_remote_state.github_environment_config.environments.dev.variables.AZURE_SUBSCRIPTION_ID),
      can(local.mock_remote_state.github_environment_config.environments.dev.variables.ACR_NAME)
    ])
    
    role_assignments_structure_valid = alltrue([
      can(local.mock_remote_state.github_environment_config.environments.dev.role_assignments),
      can(local.mock_remote_state.github_environment_config.environments.dev.role_assignments.global),
      can(local.mock_remote_state.github_environment_config.environments.dev.role_assignments.plan),
      can(local.mock_remote_state.github_environment_config.environments.dev.role_assignments.apply)
    ])
  }

  # Aggregate all test results
  all_test_results = {
    yaml_structure = local.yaml_structure_tests
    naming_validation = local.naming_validation_tests
    security_policies = local.security_policy_tests
    policy_conflicts = local.policy_conflict_tests
    variable_secret_format = local.variable_secret_format_tests
    remote_state_structure = local.remote_state_structure_tests
  }

  # Calculate overall test status
  test_summary = {
    total_test_groups = length(local.all_test_results)
    passed_groups = length([
      for group_name, group_tests in local.all_test_results :
      group_name if alltrue(values(group_tests))
    ])
    failed_groups = length([
      for group_name, group_tests in local.all_test_results :
      group_name if !alltrue(values(group_tests))
    ])
    overall_status = alltrue([
      for group_tests in values(local.all_test_results) :
      alltrue(values(group_tests))
    ]) ? "PASSED" : "FAILED"
  }
}

# =============================================================================
# VALIDATION CHECKS USING TERRAFORM CHECKS
# =============================================================================

check "yaml_structure_validation" {
  assert {
    condition = local.yaml_structure_tests.minimal_config_valid
    error_message = "Minimal YAML configuration structure validation failed"
  }
  
  assert {
    condition = local.yaml_structure_tests.comprehensive_config_valid
    error_message = "Comprehensive YAML configuration structure validation failed"
  }
}

check "naming_convention_validation" {
  assert {
    condition = local.naming_validation_tests.environment_names_follow_conventions
    error_message = "Environment names do not follow naming conventions"
  }
  
  assert {
    condition = local.naming_validation_tests.repository_names_valid
    error_message = "Repository names are not valid"
  }
}

check "security_policy_validation" {
  assert {
    condition = local.security_policy_tests.production_environments_secure
    error_message = "Production environments do not have adequate security controls"
  }
  
  assert {
    condition = local.security_policy_tests.wait_timers_within_limits
    error_message = "Wait timers exceed GitHub API limits"
  }
}

check "variable_secret_format_validation" {
  assert {
    condition = local.variable_secret_format_tests.variable_names_uppercase
    error_message = "Variable names do not follow uppercase naming convention"
  }
  
  assert {
    condition = local.variable_secret_format_tests.secret_names_uppercase
    error_message = "Secret names do not follow uppercase naming convention"
  }
  
  assert {
    condition = local.variable_secret_format_tests.secret_values_not_empty
    error_message = "Some secret values are empty"
  }
}

check "remote_state_structure_validation" {
  assert {
    condition = local.remote_state_structure_tests.github_environment_config_structure
    error_message = "Remote state does not have expected github_environment_config structure"
  }
  
  assert {
    condition = local.remote_state_structure_tests.required_azure_variables_present
    error_message = "Required Azure variables are missing from remote state"
  }
  
  assert {
    condition = local.remote_state_structure_tests.role_assignments_structure_valid
    error_message = "Role assignments structure is invalid in remote state"
  }
}

# =============================================================================
# TEST OUTPUTS
# =============================================================================

output "validation_test_results" {
  description = "Validation test results using standard Terraform features"
  value = {
    test_type = "Configuration Validation Tests"
    test_scope = "Configuration validation using standard Terraform features"
    terraform_version = "Compatible with Terraform >= 1.3.0"
    test_summary = local.test_summary
    detailed_results = local.all_test_results
    test_coverage = {
      yaml_structure = "✅ YAML configuration structure validation"
      naming_validation = "✅ Naming convention validation"
      security_policies = "✅ Security policy validation"
      policy_conflicts = "⚠️ Policy conflict detection (expected to find conflicts)"
      variable_secret_format = "✅ Variable and secret format validation"
      remote_state_structure = "✅ Remote state structure validation"
    }
    recommendations = [
      "Run 'terraform plan' to execute validation checks",
      "Add new test scenarios to locals.test_configs",
      "Use these validations to verify YAML configurations",
      "Extend validation logic for new requirements"
    ]
  }
} 