# GitHub Environment Vending for Azure Infrastructure

> **🚧 WORK IN PROGRESS** 🚧
> This project is currently under active development. Features, APIs, and documentation may change without notice. Use at your own risk in production environments.

[![Terraform Validation](https://github.com/HafslundEcoVannkraft/stratus-tf-github-environments/actions/workflows/pr-validation.yml/badge.svg)](https://github.com/HafslundEcoVannkraft/stratus-tf-github-environments/actions/workflows/pr-validation.yml)
[![Dependabot Auto-Merge](https://github.com/HafslundEcoVannkraft/stratus-tf-github-environments/actions/workflows/dependabot-auto-merge.yml/badge.svg)](https://github.com/HafslundEcoVannkraft/stratus-tf-github-environments/actions/workflows/dependabot-auto-merge.yml)
[![Community Friendly](https://img.shields.io/badge/Community-Friendly-brightgreen?style=flat&logo=github)](./CONTRIBUTING.md)
[![Good First Issues](https://img.shields.io/github/issues/HafslundEcoVannkraft/stratus-tf-github-environments/good%20first%20issue?color=7057ff&logo=github)](https://github.com/HafslundEcoVannkraft/stratus-tf-github-environments/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
[![Work in Progress](https://img.shields.io/badge/Status-Work%20in%20Progress-yellow?style=flat&logo=github)](https://github.com/HafslundEcoVannkraft/stratus-tf-github-environments)



> **Note:** This module is specifically tailored for developer teams building on the Stratus Azure Landing Zone architecture. It is optimized for the IaC Repositories created for each new system or team starting their journey in Stratus. Some input variables and design choices are opinionated for this workflow. **This module may not be the optimal choice for other use cases or non-Stratus environments.**

---

## Table of Contents

- [GitHub Environment Vending for Azure Infrastructure](#github-environment-vending-for-azure-infrastructure)
  - [Table of Contents](#table-of-contents)
  - [What This Module Does](#what-this-module-does)
  - [Quick Setup Guide](#quick-setup-guide)
    - [1. Copy Required Files](#1-copy-required-files)
    - [2. Customize the Environment Configuration](#2-customize-the-environment-configuration)
    - [3. Commit, Push and Merge Changes](#3-commit-push-and-merge-changes)
    - [4. Run the Workflow](#4-run-the-workflow)
    - [5. Workflow Parameters Reference](#5-workflow-parameters-reference)
    - [6. Organizing Files in Your IaC Repository](#6-organizing-files-in-your-iac-repository)
    - [7. Verify the Results](#7-verify-the-results)
  - [Understanding Environment Architecture](#understanding-environment-architecture)
    - [1. **Stratus Landing Zone (Subscription Level)**](#1-stratus-landing-zone-subscription-level)
    - [2. **Deployment Targets (Application Level)**](#2-deployment-targets-application-level)
    - [3. **GitHub Deployment Environments (Workflow Level)**](#3-github-deployment-environments-workflow-level)
    - [Environment Relationship Example](#environment-relationship-example)
    - [Dynamic Role Assignment Convention](#dynamic-role-assignment-convention)
  - [Why This Architecture Pattern Works](#why-this-architecture-pattern-works)
    - [**Many-to-One Deployment Target Mapping** 🎯](#many-to-one-deployment-target-mapping-)
    - [**Clean Separation of Concerns** 🏗️](#clean-separation-of-concerns-️)
    - [**Scalability Without Duplication** 📈](#scalability-without-duplication-)
  - [How This Module Fits in the Stratus Workflow](#how-this-module-fits-in-the-stratus-workflow)
    - [Actual Workflow Process](#actual-workflow-process)
    - [End-to-End Example Flow](#end-to-end-example-flow)
  - [Configuration Reference](#configuration-reference)
    - [YAML Structure](#yaml-structure)
    - [Environment Options](#environment-options)
    - [Secrets Configuration](#secrets-configuration)
    - [Deployment Target Mapping](#deployment-target-mapping)
    - [Settings Override Behavior](#settings-override-behavior)
    - [Reviewers Configuration](#reviewers-configuration)
    - [Branch Policies](#branch-policies)
    - [Environment Variables and Secrets](#environment-variables-and-secrets)
  - [Azure Resources Created](#azure-resources-created)
  - [GitHub Action Integration](#github-action-integration)
    - [Example Workflow for Azure Deployment](#example-workflow-for-azure-deployment)
  - [Validation and Error Handling](#validation-and-error-handling)
    - [Validation Framework](#validation-framework)
    - [Common Validation Errors](#common-validation-errors)
    - [Validation Outputs](#validation-outputs)
    - [Best Practices for Validation](#best-practices-for-validation)
  - [Common Issues and Troubleshooting](#common-issues-and-troubleshooting)
  - [🌟 **Welcome Contributors!**](#-welcome-contributors)
    - [🎯 **Quick Ways to Contribute**](#-quick-ways-to-contribute)
  - [Variables](#variables)

## What This Module Does

This Terraform module creates a **secure bridge** between GitHub Actions and Azure infrastructure by:

🔐 **Establishing OIDC Federation**: Eliminates static credentials by creating secure, token-based authentication between GitHub Actions and Azure using managed identities and federated credentials.

🎯 **Managing GitHub Environments**: Automatically creates and configures GitHub deployment environments with appropriate protection rules, approval requirements, and deployment policies.

🏗️ **Enabling Infrastructure Deployment**: Provides the foundation for secure CI/CD pipelines that can deploy any type of Azure infrastructure - from Container Apps to Virtual Machines, AKS clusters, or serverless functions.

📋 **Centralizing Configuration**: Uses a simple YAML configuration to define multiple GitHub environments across multiple repositories, with centralized management from your IaC repository.

### **Generic Infrastructure Support**

While originally designed for Azure Container Apps, this module now supports **any Azure infrastructure pattern**:

- **Container Apps** - Containerized applications with auto-scaling
- **Azure Kubernetes Service (AKS)** - Kubernetes clusters and workloads  
- **Virtual Machines** - Traditional VM-based applications
- **Azure Functions** - Serverless compute
- **Static Web Apps** - Frontend applications
- **App Service** - Web applications and APIs
- **Custom Infrastructure** - Any Azure resources you define

The module creates the secure authentication foundation, while your infrastructure defines the specific deployment targets and permissions.

## Quick Setup Guide

Setting up GitHub Environment vending in your IaC repository is a simple process:

### 1. Copy Required Files

You need just two files in your IaC repository:

1. **Check and update the GitHub workflow file:**

   > **📋 Note for New Stratus Teams**: If you received a new IaC repository from the Stratus team, it likely already contains the workflow file. However, it's always good practice to check for updates and copy the latest version from the source repository to ensure you have the most recent features and bug fixes.

   From your IaC repo root folder, run:

   ```bash
   # Create the workflows directory if it doesn't exist
   mkdir -p .github/workflows

   # Download the latest workflow file (overwrites existing if present)
   curl -o .github/workflows/github-environment-vending.yml https://raw.githubusercontent.com/HafslundEcoVannkraft/stratus-tf-github-environments/main/.github/workflows/github-environment-vending.yml
   ```

2. Create an environment configuration file in your repository - use the minimal configuration

   ```bash
   # Create the deployments/github directory if it doesn't exist
   mkdir -p deployments/github

   curl -o deployments/github/github-environments.yaml https://raw.githubusercontent.com/HafslundEcoVannkraft/stratus-tf-github-environments/main/examples/minimal.yaml
   ```

3. Or use the complete configuration

   ```bash
   # Create the deployments/github directory if it doesn't exist
   mkdir -p deployments/github

   curl -o deployments/github/github-environments.yaml https://raw.githubusercontent.com/HafslundEcoVannkraft/stratus-tf-github-environments/main/examples/complete.yaml
   ```

> **Note**: You can place the `github-environments.yaml` file anywhere in your repository. The workflow will search for it recursively from the repo root. You only need to specify the filename, not the full path.

### 2. Customize the Environment Configuration

Edit `deployments/github/github-environments.yaml` to specify:

1. The GitHub repository name(s) where you want to enable environments
2. The GitHub deployment environments to configure for each repository

> **Important**: The GitHub deployment environments defined here do not need to match the Azure infrastructure environments one-to-one. You can create multiple GitHub environments (like dev-ci, dev-cd, staging, production) that deploy to a smaller number of Azure deployment targets.

Example (minimal):

```yaml
repositories:
  - repo: your-app-repo-name
    environments:
      - name: dev-ci
        wait_timer: 0
        prevent_self_review: false
        reviewers:
          users: []
          teams: []
        metadata:
          deployment_target: dev # Maps to "dev" key in remote state environments
```

### 3. Commit, Push and Merge Changes

Follow your team's standard workflow to get your changes into the main branch:

1. Create a feature branch (if not already on one)

   ```bash
   git checkout -b feature/add-github-environments
   ```

2. Commit your changes

   ```bash
   git add .github/workflows/github-environment-vending.yml deployments/github/github-environments.yaml
   git commit -m "Add GitHub environments configuration"
   ```

3. Push your changes and create a PR

   ```bash
   git push -u origin feature/add-github-environments
   ```

4. Create and merge the PR to the main branch through your Git provider's interface

### 4. Run the Workflow

Once your changes are merged to the main branch, run the workflow using GitHub CLI:

1. **Setup GitHub CLI Authentication** (one-time setup):

   ```bash
   # Install and authenticate with GitHub CLI
   gh auth login

   # Verify authentication
   gh auth status
   ```

   > **💡 Why GitHub CLI?** GitHub CLI provides secure OAuth-based authentication with automatic scope management. See our [Authentication Guide](./AUTHENTICATION.md) for detailed setup instructions, security comparison, and alternative methods.

2. Run the workflow with your token:

   **Standard Stratus IaC Repository Pattern** (recommended):

   ```bash
   gh workflow run github-environment-vending.yml \
     -f github_token=$(gh auth token) \
     -f tfvars_file=<environment>.tfvars
   ```

   **Custom Setup with Remote State Overrides** (advanced):

   ```bash
   gh workflow run github-environment-vending.yml \
     -f github_token=$(gh auth token) \
     -f tfvars_file=<environment>.tfvars \
     -f remote_state_config="rg=custom-state-rg,sa=customstateaccount,container=tfstate,key=custom-environment.tfstate"
   ```

   Where `<environment>` is your Stratus Azure environment name (e.g., `dev`, `test`, `prod`).

### 5. Workflow Parameters Reference

| Parameter             | Required | Default                    | Description                                                                                                                                                      |
| --------------------- | -------- | -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `github_token`        | Yes      | -                          | **GitHub CLI token (recommended)**: Use `$(gh auth token)` for secure, never-expiring authentication. See [Authentication Guide](./AUTHENTICATION.md) for setup. |
| `tfvars_file`         | Yes      | -                          | Filename of tfvars file (searched recursively)                                                                                                                   |
| `operation`           | No       | `apply`                    | Operation to perform (`apply` or `destroy`)                                                                                                                      |
| `github_env_file`     | No       | `github-environments.yaml` | Filename of GitHub environment config                                                                                                                            |
| `github_owner`        | No       | `HafslundEcoVannkraft`     | GitHub organization or user name                                                                                                                                 |
| `iac_repo_ref`        | No       | `main`                     | Git reference (branch, tag, or commit SHA) of IaC repository                                                                                                     |
| `remote_state_config` | No       | -                          | Combined remote state override (e.g., "key=custom.tfstate" or "rg=custom-rg,key=custom.tfstate")                                                                 |
| `module_repo_ref`     | No       | `main`                     | Git reference (branch, tag, or commit SHA) of module repository                                                                                                  |

### 6. Organizing Files in Your IaC Repository

For teams with multiple Stratus environments and deployment targets, we recommend organizing your files like this:

```
your-iac-repo/
├── .github/workflows/
│   └── github-environment-vending.yml
├── deployments/
│   ├── *.tf                                 # Terraform infrastructure files
│   ├── tfvars/                              # Environment-specific tfvars
│   │   ├── dev.tfvars                       # Stratus dev Landing Zone
│   │   ├── test.tfvars                      # Stratus test Landing Zone
│   │   └── prod.tfvars                      # Stratus prod Landing Zone
│   └── github/                              # GitHub environment configurations
│       ├── github-environments.yaml                           # Default (simple setups)
│       ├── github-environments-dev-web.yaml                   # Web apps in dev
│       ├── github-environments-dev-api.yaml                   # APIs in dev
│       ├── github-environments-test-web.yaml                  # Web apps in test
│       ├── github-environments-prod-web.yaml                  # Web apps in prod
│       └── github-environments-prod-api.yaml                  # APIs in prod
└── README.md
```

### 7. Verify the Results

Check the GitHub environments in your application repository and the federated credentials in Azure.

## Understanding Environment Architecture

This module works with **three distinct layers** of environments in the Stratus architecture:

### 1. **Stratus Landing Zone (Subscription Level)**

- **What it is**: A complete Azure subscription created by the Stratus Landing Zone vending process
- **Naming**: Combination of `code_name` + `environment` (e.g., "myapp-dev", "myapp-prod")
- **Scope**: One subscription per Stratus Landing Zone
- **Contains**: Multiple deployment targets, shared resources (networking, DNS, monitoring)
- **Defined by**: Your tfvars file (e.g., `dev.tfvars`, `prod.tfvars`)

### 2. **Deployment Targets (Application Level)**

- **What it is**: Specific infrastructure environments within a Stratus Landing Zone subscription
- **Purpose**: Logical separation of different applications or deployment stages within the same subscription
- **Examples**:
  - `web-apps` - For frontend applications and static sites
  - `api-services` - For backend APIs and microservices
  - `data-processing` - For batch jobs and analytics workloads
  - `container-apps` - For containerized applications (Container Apps example)
  - `kubernetes` - For AKS-based workloads
  - `functions` - For serverless applications
- **Mapping**: The `deployment_target` property in your YAML maps to these
- **Flexibility**: One Stratus LZ can host multiple deployment targets

### 3. **GitHub Deployment Environments (Workflow Level)**

- **What it is**: GitHub environments that define deployment workflows and security policies
- **Purpose**: Control who can deploy, when, and with what approvals
- **Examples**: `web-dev-ci`, `web-dev-cd`, `api-prod-cd`
- **Mapping**: Each GitHub environment targets a specific deployment target
- **Security**: Each gets its own managed identity and federated credentials

### Environment Relationship Example

```
Stratus Landing Zone: "codename-dev" (Azure Subscription)
├── Deployment Target: "web-apps"
│   ├── GitHub Environment: "web-dev-ci" (validation/testing)
│   └── GitHub Environment: "web-dev-cd" (deployment)
├── Deployment Target: "api-services"
│   ├── GitHub Environment: "api-dev-ci"
│   └── GitHub Environment: "api-dev-cd"
└── Deployment Target: "data-processing"
    ├── GitHub Environment: "data-ci"
    └── GitHub Environment: "data-cd"
```

**Key Benefits of This Architecture**:

- **Cost Optimization**: Multiple applications share the same Stratus Landing Zone subscription
- **Workload Isolation**: Each deployment target has independent scaling and resource allocation
- **Performance Independence**: Different deployment targets don't affect each other
- **Flexible Deployment**: Different GitHub environments with different approval processes
- **Technology Agnostic**: Supports any Azure infrastructure pattern

### Dynamic Role Assignment Convention

The module uses a **dynamic, convention-based approach** for role assignments that automatically maps GitHub environment suffixes to role assignment types:

**How it works:**
- Environment names ending with `-{suffix}` automatically get `role_assignments.{suffix}`
- Examples: `prod-ci` gets `role_assignments.ci`, `dev-deploy` gets `role_assignments.deploy`
- `global` role assignments are always applied regardless of suffix

**Supported Conventions:**

**Standard CI/CD:**
- `my-app-prod-ci` → gets `role_assignments.ci` (read-only permissions)
- `my-app-prod-cd` → gets `role_assignments.cd` (deployment permissions)

**Custom Workflows:**
- `my-app-prod-validate` → gets `role_assignments.validate`
- `my-app-prod-deploy` → gets `role_assignments.deploy`
- `my-app-prod-test` → gets `role_assignments.test`

**Any Convention:**
- `my-app-prod-backup` → gets `role_assignments.backup`
- `my-app-prod-migrate` → gets `role_assignments.migrate`

This approach provides **infinite flexibility** while maintaining **simple configuration** - infrastructure teams define what role assignment types they support, and application teams create environments with matching suffixes.

## Why This Architecture Pattern Works

The module uses a **YAML + Remote State** pattern that provides powerful benefits for enterprise environments:

### **Many-to-One Deployment Target Mapping** 🎯

Multiple application repositories can share the same deployment target, enabling efficient resource utilization:

```yaml
# Multiple apps → Same deployment target
repositories:
  - repo: frontend-app
    environments:
      - name: prod-cd
        metadata:
          deployment_target: web-apps  # Shared target
  
  - repo: marketing-site  
    environments:
      - name: prod-cd
        metadata:
          deployment_target: web-apps  # Same target
```

**Benefits:**
- ✅ **Resource Efficiency**: Shared Azure infrastructure (CDN, storage, networking)
- ✅ **Consistent Configuration**: All apps get identical Azure settings automatically
- ✅ **Simplified Management**: Infrastructure defined once, used by many applications
- ✅ **Team Autonomy**: Application teams control GitHub settings while sharing infrastructure

### **Clean Separation of Concerns** 🏗️

```
Infrastructure Teams (Remote State):
├── Define deployment targets and Azure resources
├── Manage variables, secrets, and role assignments
└── Control infrastructure-level configuration

Application Teams (YAML):
├── Choose which repositories need environments
├── Set GitHub-specific policies (approvals, branch rules)
└── Map to appropriate deployment targets
```

### **Scalability Without Duplication** 📈

Adding new applications requires only YAML changes - no infrastructure modifications needed. This prevents configuration drift and reduces maintenance overhead compared to alternatives where each application would need separate infrastructure definitions.

## How This Module Fits in the Stratus Workflow

This module is **not a standalone solution**. It is designed to be used as part of a larger, connected deployment process:

### Actual Workflow Process

1. **Copy Workflow to IaC Repo:**
   Developer teams only need to copy the workflow file and YAML config template from this repo to their IaC repo. The workflow must run in the context of the team's IaC repo for two critical reasons:

   - **Azure Identity**: The IaC repo has the required OIDC credentials to access Azure resources and Terraform state
   - **Network Access**: The IaC repo has VNet connectivity to the private Terraform backend storage account

2. **No Need for Local Terraform Files:**
   The workflow automatically checks out the latest version of this module directly from GitHub. You do not need to create or maintain any Terraform files in your IaC repo - just the workflow and configuration files.

3. **Execute with IaC Permissions:**
   The team's IaC repo has the necessary OIDC federation with Azure to:

   - Access the Azure Storage backend for Terraform state (often behind private endpoints)
   - Deploy resources (managed identities) to the team's Azure subscription

4. **Configure App Repos:**
   The workflow creates and configures GitHub Environments in the team's application source repositories and sets up OIDC federation between GitHub and Azure for each environment.

5. **Deploy Apps:**
   Application developers can now use the configured environments to deploy to Azure infrastructure without managing credentials, using secure OIDC federation.

### End-to-End Example Flow

1. **Provision Infrastructure:**
   Run Terraform in your IaC repo to create your Azure infrastructure (Container Apps, AKS, VMs, etc.). We recommend using the [Stratus Terraform Examples](https://github.com/HafslundEcoVannkraft/stratus-tf-examples) for tested, production-ready infrastructure patterns.

2. **Configure GitHub Environments:**
   - Edit `github-environments.yaml` in the IaC repo to describe which app repos/environments to configure.
   - Run the provided workflow (via GitHub CLI) with the required inputs (`github_token`, `tfvars_file`).

3. **App Source Repo Usage:**
   - Developers in the app repo can now use the configured environments for secure, OIDC-based deployments to Azure.
   - Each source repo (e.g., frontend, backend, APIs) gets its own OIDC identity and GitHub environment to securely deploy to the appropriate Azure infrastructure.

## Configuration Reference

### YAML Structure

The `github-environments.yaml` file defines GitHub deployment environments for your application repositories:

```yaml
repositories:
  - repo: "repository-name" # GitHub repository name
    environments:
      - name: "environment-name" # GitHub Environment name (e.g., web-dev-ci, api-prod-cd)
        # Environment settings follow
```

### Environment Options

| Property                                         | Type    | Description                                           | Default   | Required |
| ------------------------------------------------ | ------- | ----------------------------------------------------- | --------- | -------- |
| `name`                                           | string  | Name of the GitHub deployment environment             | -         | Yes      |
| `metadata.deployment_target`                     | string  | Maps to deployment target key in remote state        | -         | No       |
| `wait_timer`                                     | integer | Wait time (minutes) before allowing deployments       | 0         | No       |
| `prevent_self_review`                            | boolean | Prevents people from approving their own deployments  | false     | No       |
| `prevent_destroy`                                | boolean | Prevents accidental destruction of the environment    | false     | No       |
| `reviewers`                                      | object  | Users and teams who must approve deployments          | null      | No       |
| `deployment_branch_policy`                       | object  | Branch restriction rules                              | null      | No       |
| `deployment_branch_policy.protected_branches`    | boolean | Only allow deployments from protected branches       | true      | No       |
| `deployment_branch_policy.custom_branch_policies` | boolean | Allow deployments from specific branches or tags     | false     | No       |
| `deployment_branch_policy.branch_pattern`        | array   | Branch patterns for custom branch policy             | []        | No       |
| `deployment_branch_policy.tag_pattern`           | array   | Tag-based deployment rules                            | []        | No       |
| `variables`                                      | object  | Environment variables to create                       | {}        | No       |
| `secrets`                                        | object  | Secrets to create from Azure Key Vault               | {}        | No       |

### Secrets Configuration

The `secrets` property allows you to reference secrets stored in Azure Key Vault:

```yaml
secrets:
  # Latest version (versionless)
  DATABASE_PASSWORD:
    key_vault: "my-key-vault-name"
    secret_ref: "database-password"
  
  # Specific version
  API_KEY:
    key_vault: "shared-vault"
    secret_ref: "api-key/a1b2c3d4e5f6"
  
  # Version with semantic naming
  TLS_CERTIFICATE:
    key_vault: "security-vault"
    secret_ref: "tls-cert-v2"
```

Each secret requires:
- **`key_vault`**: Name of the Azure Key Vault containing the secret
- **`secret_ref`**: Name of the secret within the Key Vault. Supports both versionless (latest) and versioned references:
  - `"secret-name"` - Uses the latest version
  - `"secret-name/version-id"` - Uses a specific version (e.g., `"api-key/a1b2c3d4e5f6....."`)

### Deployment Target Mapping

The `metadata.deployment_target` property maps your GitHub environments to specific **deployment targets** within your Stratus Landing Zone. This enables flexible deployment patterns within a single subscription:

```yaml
# Example: Stratus Landing Zone "codename-dev" contains multiple deployment targets
repositories:
  - repo: my-web-frontend
    environments:
      - name: web-dev-ci
        metadata:
          deployment_target: web-apps # Maps to "web-apps" deployment target
      - name: web-dev-cd
        metadata:
          deployment_target: web-apps # Same deployment target, different protections

  - repo: my-user-service
    environments:
      - name: api-dev-ci
        metadata:
          deployment_target: api-services # Maps to "api-services" deployment target
      - name: api-dev-cd
        metadata:
          deployment_target: api-services

  - repo: my-data-processor
    environments:
      - name: data-cd
        metadata:
          deployment_target: data-processing # Maps to "data-processing" deployment target
```

**Real-World Stratus Example**:

```
Stratus Landing Zone: "codename-dev" (Subscription)
├── Deployment Target: "web-apps" (Static Web Apps + CDN)
│   └── GitHub Environments: web-dev-ci, web-dev-cd
│   └── Services: frontend-app, marketing-site
├── Deployment Target: "api-services" (Container Apps for APIs)
│   └── GitHub Environments: api-dev-ci, api-dev-cd
│   └── Services: user-api, inventory-api
└── Deployment Target: "data-processing" (Azure Functions + Storage)
    └── GitHub Environments: data-ci, data-cd
    └── Services: analytics-functions, report-generator
```

### Settings Override Behavior

When both remote state and YAML provide settings for the same environment, the precedence is:

**Remote State → YAML (YAML wins)**

This allows the remote state to provide sensible defaults while giving YAML the final say.

### Reviewers Configuration

GitHub requires either users or teams (or both) as reviewers for environments:

```yaml
reviewers:
  users:
    - username: "johndoe" # GitHub username
    - username: "janedoe" # Multiple users allowed
  teams:
    - name: "devops-team" # GitHub team name
    - slug: "security-team" # OR team slug (not both)
```

### Branch Policies

GitHub environments can restrict which branches can deploy to them. 

**Default Behavior:**
When no `deployment_branch_policy` is specified in your YAML configuration, the module applies secure defaults:
- `protected_branches: true` - Only protected branches can deploy
- `custom_branch_policies: false` - No custom branch patterns allowed

This ensures that environments are secure by default, requiring branches to be protected in GitHub before they can trigger deployments.

**Custom Configuration:**
You can override these defaults by specifying a `deployment_branch_policy` in your environment configuration. See the [complete example](./examples/complete.yaml) for detailed branch policy configurations.

**Important:** GitHub API requires that `protected_branches` and `custom_branch_policies` cannot have the same value. The module handles this automatically with the secure defaults above.

### Environment Variables and Secrets

The module automatically provides essential Azure infrastructure variables for all environments, plus you can define additional custom variables and secrets. Variables come from three sources with this precedence:

1. **Remote state variables** (from infrastructure)
2. **Per-environment managed identity variables** (AZURE_CLIENT_ID)
3. **YAML configuration variables** (highest precedence)

## Azure Resources Created

For each environment, the following Azure resources are created:

1. **User-Assigned Managed Identity**:
   - Located in a shared resource group
   - Named `{codename}-id-github-{repo}-{environment}`
   - Used by GitHub Actions workflows for secure access to Azure

2. **Federated Credential**:
   - Links GitHub Actions to the managed identity
   - Subject format: `repo:{owner}/{repo}:environment:{environment}`
   - Enables passwordless authentication from GitHub to Azure

3. **Dynamic Role Assignments**:
   Role assignments are defined in the remote state and automatically applied based on environment naming conventions.

## GitHub Action Integration

Once this module has been applied, your GitHub workflows can use the automatically configured environments and federated credentials to deploy to any Azure infrastructure.

### Example Workflow for Azure Deployment

Here's how to use these environments in your application repository's GitHub workflow:

```yaml
name: Deploy to Azure Infrastructure

on:
  push:
    branches: [main]
    tags: ["v*"]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    # Reference the environment name exactly as configured in github-environments.yaml
    environment: production

    # Required permissions for OIDC token
    permissions:
      id-token: write
      contents: read

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Log in to Azure using OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}

      # Example: Deploy to Container Apps
      - name: Deploy Container App
        run: |
          az containerapp update \
            --name my-container-app \
            --resource-group my-resource-group \
            --image myregistry.azurecr.io/myapp:${{ github.sha }}

      # Example: Deploy to AKS
      - name: Deploy to AKS
        run: |
          az aks get-credentials --resource-group my-rg --name my-aks-cluster
          kubectl set image deployment/my-app my-app=myregistry.azurecr.io/myapp:${{ github.sha }}

      # Example: Deploy Azure Functions
      - name: Deploy Azure Functions
        run: |
          func azure functionapp publish my-function-app
```

## Validation and Error Handling

The module includes comprehensive validation to catch configuration errors early and provide clear guidance for fixes.

### Validation Framework

The module validates your configuration at multiple levels:

#### **1. YAML Structure Validation**
- Validates YAML syntax and required fields
- Ensures repository and environment names follow GitHub conventions
- Checks for duplicate environment configurations

#### **2. Deployment Target Validation**
- Validates that `deployment_target` values exist in your remote state
- Optional validation - environments without deployment targets are allowed
- Provides clear error messages when targets are missing

#### **3. GitHub API Validation**
- Validates GitHub token permissions and scopes
- Checks repository accessibility
- Validates user and team references in reviewers

#### **4. Azure Prerequisites Validation**
- Validates Azure subscription ID format
- Checks remote state accessibility
- Validates Azure resource naming conventions

### Common Validation Errors

#### **Invalid deployment_target**
```
Error: Invalid deployment_target in environment metadata
```
**Fix**: Ensure the deployment_target exists in your remote state outputs, or omit it for generic environments.

#### **Remote state access error**
```
Error: Cannot access remote state 'github_environments' output
```
**Fix**: Verify remote state configuration and ensure your infrastructure module outputs 'github_environments'.

#### **Duplicate environments**
```
Error: Duplicate repository:environment combinations detected
```
**Fix**: Ensure each repository:environment combination is unique across your configuration.

### Validation Outputs

Check validation status using Terraform outputs:

```bash
# Check validation results
terraform output validation_results

# Example output:
# {
#   "deployment_targets_valid" = true
#   "no_duplicate_environments" = true
# }
```

### Best Practices for Validation

1. **Test Configuration Changes**: Always run `terraform plan` to validate changes before applying
2. **Use Descriptive Names**: Choose clear, consistent naming for repositories and environments
3. **Validate YAML Syntax**: Use a YAML validator or editor with syntax highlighting
4. **Check Remote State**: Ensure your infrastructure outputs are up-to-date before running this module

## Common Issues and Troubleshooting

For comprehensive troubleshooting, see our [Troubleshooting Guide](./TROUBLESHOOTING.md).

**Most Common Issues:**
- **Authentication**: Use GitHub CLI authentication instead of Personal Access Tokens
- **Permissions**: Ensure proper Azure subscription access
- **Configuration**: Validate YAML syntax and environment names
- **GitHub API**: Some deployment policy combinations are not supported

## 🌟 **Welcome Contributors!**

**We love community contributions!** 🎉 This project is designed to be **contributor-friendly** with:

- 🚀 **Simple setup** - Get started in minutes
- 🤖 **Helpful automation** - Our bots guide you through the process
- 📚 **Clear documentation** - Everything you need to know
- 🤝 **Welcoming community** - We're here to help you succeed

### 🎯 **Quick Ways to Contribute**

- 🐛 **Found a bug?** [Open an issue](https://github.com/HafslundEcoVannkraft/stratus-tf-github-environments/issues/new?template=bug-report.yml)
- 📚 **Improve docs** - Fix typos, add examples, clarify instructions
- ✨ **Add features** - Check our [good first issues](https://github.com/HafslundEcoVannkraft/stratus-tf-github-environments/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
- 🧪 **Test examples** - Try our configurations and share feedback

**New to open source?** Perfect! Check our [Contributing Guide](./CONTRIBUTING.md) for a gentle introduction.

---

## Variables

| Name                                | Description                                                                                              | Type     | Default                      | Required |
| ----------------------------------- | -------------------------------------------------------------------------------------------------------- | -------- | ---------------------------- | :------: |
| `code_name`                         | Project/Application code name (3-63 chars, lowercase alphanumeric + hyphens, no reserved Azure prefixes) | `string` | n/a                          |   yes    |
| `environment`                       | Azure environment name (dev, test, prod, staging, uat, preprod) - max 10 chars                           | `string` | n/a                          |   yes    |
| `github_token`                      | GitHub token for API access (requires repo, workflow, read:org scopes)                                   | `string` | n/a                          |   yes    |
| `github_owner`                      | GitHub organization or user name (max 39 chars, valid GitHub format)                                     | `string` | `HafslundEcoVannkraft`       |    no    |
| `location`                          | Azure region for resources (validated against common regions)                                            | `string` | `norwayeast`                 |    no    |
| `github_env_file`                   | Filename of GitHub environments configuration file (must be .yaml/.yml)                                  | `string` | `"github-environments.yaml"` |    no    |
| `state_storage_account_name`        | Storage account for Terraform state (3-24 chars, lowercase alphanumeric)                                 | `string` | n/a                          |   yes    |
| `subscription_id`                   | Azure Subscription ID (valid UUID format)                                                                | `string` | n/a                          |   yes    |
| `resource_group_suffix`             | Optional custom suffix for resource group name (max 10 chars, lowercase alphanumeric)                    | `string` | `null`                       |    no    |
| `module_repo_ref`                   | Git reference of module repository for deployment tracking (1-100 chars)                                 | `string` | `"main"`                     |    no    |
| `iac_repo_url`                      | Optional URL of IaC repository for tracking (must start with https://)                                   | `string` | `null`                       |    no    |
| `remote_state_resource_group_name`  | Optional override for remote state resource group name                                                   | `string` | `null`                       |    no    |
| `remote_state_storage_account_name` | Optional override for remote state storage account name                                                  | `string` | `null`                       |    no    |
| `remote_state_container`            | Optional override for remote state container name                                                        | `string` | `null`                       |    no    |
| `remote_state_key`                  | Optional override for remote state key                                                                   | `string` | `null`                       |    no    |

---

**Ready to get started?** Follow the [Quick Setup Guide](#quick-setup-guide) or check out our [examples](./examples/) for common configuration patterns.
