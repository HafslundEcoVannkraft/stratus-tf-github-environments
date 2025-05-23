# GitHub Environment Vending for Azure Container Apps

> **Note:** This module is specifically tailored for developer teams building on the Stratus Corp Azure Landing Zone with Container App Environment. It is optimized for greenfield infrastructure-as-code (IaC) repositories created for each new system or team starting their journey in Stratus. Some input variables and design choices are opinionated for this workflow. **This module may not be the optimal choice for other use cases or non-Stratus environments.**

---

## Table of Contents

- [Quick Setup Guide](#quick-setup-guide)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Understanding Environment Types](#understanding-environment-types)
- [How This Module Fits in the Stratus Workflow](#how-this-module-fits-in-the-stratus-workflow)
- [Configuration Reference](#configuration-reference)
  - [YAML Structure](#yaml-structure)
  - [Reviewers Configuration](#reviewers-configuration)
  - [Branch Policies](#branch-policies)
  - [Tag Policies](#tag-policies)
  - [Environment Variables and Secrets](#environment-variables-and-secrets)
- [Azure Resources Created](#azure-resources-created)
- [GitHub Action Integration](#github-action-integration)
- [Common Issues and Troubleshooting](#common-issues-and-troubleshooting)
- [Understanding GitHub Environments and Deployments](#understanding-github-environments-and-deployments)
  - [What are GitHub Environments?](#what-are-github-environments)
  - [How Environments Work with GitHub Actions](#how-environments-work-with-github-actions)
  - [Best Practices for Environment Configuration](#best-practices-for-environment-configuration)
  - [Security Considerations with OIDC Federation](#security-considerations-with-oidc-federation)
  - [Common Troubleshooting](#common-troubleshooting)
  - [Recommended Workflow Configurations](#recommended-workflow-configurations)
- [GitHub Actions Workflow Example](#github-actions-workflow-example)

## Quick Setup Guide

Setting up GitHub Environment vending in your IaC repository is a simple process:

### 1. Copy Required Files

You need just two files in your IaC repository:

1. Download the GitHub workflow file to your existing `.github/workflows` directory:
   
   From your IaC repo root folder, run:
   ```bash
   # Create the workflows directory if it doesn't exist
   mkdir -p .github/workflows
   
   # Download the workflow file
   curl -o .github/workflows/vend-aca-github-environments.yml https://raw.githubusercontent.com/HafslundEcoVannkraft/stratus-tf-aca-gh-vending/main/.github/workflows/vend-aca-github-environments.yml
   ```

2. Create an environment configuration file in your repository - use the minimal configuragion

   ```bash
   # Create the deployments directory if it doesn't exist
   mkdir -p deployments
   
   curl -o deployments/github-envrionments.yaml https://raw.githubusercontent.com/HafslundEcoVannkraft/stratus-tf-aca-gh-vending/main/examples/minmal.yaml
   ```

3. Or use the complete configuration
   
   ```bash
   # Create the deployments directory if it doesn't exist
   mkdir -p deployments

   curl -o deployments/github-envrionments.yaml https://raw.githubusercontent.com/HafslundEcoVannkraft/stratus-tf-aca-gh-vending/main/test/complete.yaml
   ```

> **Note**: You can place the `github-envrionments.yaml` file anywhere in your repository. The workflow will search for it recursively from the repo root. You only need to specify the filename, not the full path.

### 2. Customize the Environment Configuration

Edit `deployments/github-envrionments.yaml` to specify:

1. The GitHub repository name(s) where you want to enable environments
2. The GitHub deployment environments to configure for each repository

> **Important**: The GitHub deployment environments defined here do not need to match the Azure infrastructure environments one-to-one. You can create multiple GitHub environments (like dev-plan, dev-apply, staging, production) that deploy to a smaller number of Azure environments.

Example (minimal):
```yaml
repositories:
  - repo: your-app-repo-name
    environments:
      - name: dev
        wait_timer: 0
        prevent_self_review: false
        reviewers:
          users: []
          teams: []
```

### 3. Commit, Push and Merge Changes

Follow your team's standard workflow to get your changes into the main branch:

1. Create a feature branch (if not already on one)
   ```bash
   git checkout -b feature/add-github-environments
   ```

2. Commit your changes
   ```bash
   git add .github/workflows/vend-aca-github-environments.yml deployments/github-envrionments.yaml
   git commit -m "Add GitHub environments configuration for ACA"
   ```

3. Push your changes and create a PR
   ```bash
   git push -u origin feature/add-github-environments
   ```

4. Create and merge the PR to the main branch through your Git provider's interface

### 4. Run the Workflow

Once your changes are merged to the main branch, run the workflow using GitHub CLI:

1. First, ensure you have a GitHub token with the proper permissions:
   ```bash
   # Using GitHub CLI on an authorized environment with network access
   gh auth login --web --scopes "repo,workflow,read:org,write:packages"
   ```

2. Verify you have a token with the required scopes
   ```bash   
   gh auth status
   ```

2. Run the workflow with your token:
   ```bash
   gh workflow run vend-aca-github-environments.yml -f github_token=$(gh auth token) -f tfvars_file=<environment>.tfvars -f operation=apply
   ```

   Where `<environment>` is your Azure infrastructure environment name (e.g., `dev`, `test`, `prod`). This tfvars file should contain:
   - Azure subscription details (`subscription_id`)
   - Resource group information (`resource_group_name`, optional)
   - Storage account configuration for Terraform state (`state_storage_account_name`)
   - Your application code name (`code_name`)
   - Environment name (`environment`)
   - Location (`location`)

> **How the Workflow Works**:
> 1. The workflow checks out your IaC repo to find your configuration files
> 2. It also checks out the public module repo directly into a `terraform-work` folder
> 3. It copies your tfvars and environment YAML files to the `terraform-work` folder
> 4. It runs Terraform in the context of the `terraform-work` folder
> 5. No need to create or maintain Terraform files in your IaC repo!

> **Note about Configuration File**: If you're using the default filename `github-envrionments.yaml`, you don't need to specify it when running the workflow. If you renamed the file, include the parameter `-f github_env_file=<your-filename>.yaml`.

> **Simplified File Parameters**: Both `github_env_file` and `tfvars_file` parameters accept just filenames without paths. The workflow will search for these files recursively from the repository root and use the first matching file found.

> **Environment Relationship**: The Azure infrastructure environment specified in your tfvars file provides the resources and identities that your GitHub deployment environments will use. A single Azure environment can be targeted by multiple GitHub environments with different approval gates and protections.

### 5. Verify the Results

Check the GitHub environments in your application repository and the federated credentials in Azure.

## Features

- **GitHub Environment Management**: Automatically create and configure environments in GitHub repositories
- **OIDC Federation**: Establish secure, token-based authentication between GitHub Actions and Azure
- **Azure Role Assignments**: Set up proper Azure RBAC for each environment
- **Deployment Branch Policies**: Control which branches can deploy to specific environments
- **Deployment Tag Policies**: Create tag-based deployment rules for environments
- **Required Approvals**: Establish approval requirements for deployments
- **Configuration as Code**: Define your entire setup using YAML

### What this module does NOT handle

- **Tag Protection**: This module doesn't configure tag protection rules (preventing tags from being deleted)
- **Branch Protection**: This module doesn't set up branch protection rules at the repository level
- **Repository Creation**: Repositories must already exist before using this module
- **Organization Management**: Organization settings are not managed by this module

This module is specifically focused on setting up the connection between GitHub Actions environments and Azure Container Apps, with appropriate security controls.

## Prerequisites

- GitHub repository with proper permissions
- GitHub token with `repo` and `workflow` permissions
- Azure subscription with contributor rights
- Terraform >= 1.3.0

## Understanding Environment Types

This module works with two distinct types of environments:

1. **Azure Infrastructure Environments** (specified by `tfvars_file`):
   - Represent physical Azure environments like dev, test, or production
   - Each has its own subscription, resource group, and Container App Environment
   - Defined by Terraform variables in tfvars files (e.g., `dev.tfvars`, `prod.tfvars`)
   - Usually correspond to isolated Azure subscriptions or resource groups

2. **GitHub Deployment Environments** (defined in `github_env_file`):
   - Logical environments within GitHub for deployment workflows
   - Can be more numerous and granular than Azure environments
   - Define approval processes, branch policies, and deployment protections
   - Each gets its own managed identity and federated credentials

These environments can have a one-to-one relationship, but often you'll have multiple GitHub deployment environments targeting the same Azure infrastructure (e.g., dev-plan, dev-apply, staging-plan, staging-apply all working with dev and staging Azure environments).

**Why More GitHub Environments Than Azure Environments?**

Typical application lifecycles require different levels of protection and controls for different types of operations against the same infrastructure:

1. **Operation-based separation**: 
   - **plan environments**: For read-only preview operations with minimal approvals
   - **apply environments**: For actual deployments that make changes, requiring stricter approvals

2. **Security and governance benefits**:
   - **Different approval requirements** for each operation type
   - **Granular access control** - some team members can plan but not apply
   - **Separate branch policies** - feature branches can plan but only main can apply 
   - **Distinct audit trails** for who performed which operation types

3. **Practical example**:
   A single "dev" Azure subscription might have multiple GitHub environments:
   - `dev-plan` - No approvals, any branch, read-only operations
   - `dev-apply` - Requires approvals, protected branches only, write operations 
   - `dev-hotfix` - Special approval path for emergency fixes

This approach lets you implement sophisticated deployment controls without duplicating Azure infrastructure for each operational scenario.

4. **Cost optimization**:
   - **Share Azure resources** between different stages (e.g., dev and test) while maintaining separate deployment controls
   - **Reduce infrastructure costs** by not creating separate Azure environments for each deployment scenario
   - **Test against production-like infrastructure** without duplicating expensive resources
   - **Link different code branches** to the same underlying Azure resources with different protection rules

For example, your organization might use a single Azure subscription with one Container App Environment for both development and testing activities, but have separate GitHub environments with different branch policies, approval requirements, and team permissions controlling access to those resources.

### Environment Mapping Visualization

```mermaid
flowchart LR
    %% Define Azure environments
    AzureDev["Azure Dev Environment<br>Subscription A"]
    AzureProd["Azure Prod Environment<br>Subscription B"]
    style AzureDev fill:#d0e8ff,stroke:#0078d4,color:#0078d4
    style AzureProd fill:#d0e8ff,stroke:#0078d4,color:#0078d4

    %% Define GitHub environments 
    GHDev["GitHub Dev Environment<br>(Frontend & Backend)"]
    GHTest["GitHub Test Environment<br>(Frontend & Backend)"]
    GHProd["GitHub Prod Environment<br>(Frontend & Backend)"]
    
    %% Style GitHub environments
    style GHDev fill:#e8f5e9,stroke:#2e7d32,color:#2e7d32
    style GHTest fill:#e8f5e9,stroke:#2e7d32,color:#2e7d32
    style GHProd fill:#e8f5e9,stroke:#2e7d32,color:#2e7d32
    
    %% Define operations
    PlanOp["Plan Operation<br>(Read-only)"]
    ApplyOp["Apply Operation<br>(Deployment)"]
    style PlanOp fill:#fff9c4,stroke:#fbc02d,color:#3e2723
    style ApplyOp fill:#ffccbc,stroke:#e64a19,color:#3e2723
    
    %% Connection lines
    GHDev --> PlanOp -.-> AzureDev
    GHDev --> ApplyOp --> AzureDev
    
    GHTest --> PlanOp -.-> AzureDev
    
    GHProd --> PlanOp -.-> AzureProd  
    GHProd --> ApplyOp --> AzureProd
```

**Understanding Plan and Apply Operations:**
- Each GitHub environment supports **both plan and apply operations**
- **Plan operations** (yellow) are read-only, preview-only actions that show what would change
- **Apply operations** (orange) are actual deployments that make changes to Azure resources
- The same GitHub environment can perform both operations, with different approval requirements for each

**GitHub Environment Access Controls:**
- Dev environments often allow plans with no approvals, but require approvals for apply operations
- Test environments usually perform read-only operations against dev infrastructure 
- Prod environments typically require strict approval processes for both plan and apply operations
- A single GitHub environment can be configured with different protection rules for different operations

**Key points about environment relationships:**
* GitHub environments (green) define the security boundaries and approval processes
* Operations (plan/apply) define what actions can be taken within those environments
* Multiple GitHub environments from different repos can target the same Azure infrastructure
* Azure environments (blue) are the actual infrastructure that operations act upon
* The separation of environments from operations provides a flexible security model

## How This Module Fits in the Stratus Workflow

This module is **not a standalone solution**. It is designed to be used as part of a larger, connected deployment process:

> **Note**: In the diagram below, "GitHub Env Vending Module" refers to **this repository** (stratus-tf-aca-gh-vending).

```mermaid
graph LR
    B["GitHub Env Vending Module<br>THIS REPO"] -.->|"1 Copy workflow file"| A[IaC Repo]
    B -.-> |"2 Provide terraform<br>module code"| A
    A --> |"3 Create new identities"| D[Azure Subscription]
    A --> |"4 Configure GitHub<br>environments"| C[App Source Repos]
    C --> |"5 Deploy Azure<br>Container Apps"| D
    
    style B fill:#e8f5e9,stroke:#2e7d32,color:#2e7d32
    
    subgraph "Why use IaC Repo?"
        E["Azure Identity (OIDC)<br>for Subscription Access"]
        F["VNet Connectivity<br>to Private Terraform Backend"]
    end
    
    A --- E
    A --- F
```

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
   Application developers can now use the configured environments to deploy to Azure Container Apps without managing credentials, using secure OIDC federation.

> **Simplified File Requirements:** You only need two files in your IaC repo:
> 1. The workflow file (`.github/workflows/vend-aca-github-environments.yml`)
> 2. The GitHub environments configuration YAML file

> **No Terraform Files Needed:** The workflow checks out the module code directly from this repository. You don't need to create any Terraform files in your IaC repo.

> **Simplified File Parameters**: Both `github_env_file` and `tfvars_file` parameters accept just filenames without paths. The workflow will search for these files recursively from the repository root and use the first matching file found.

### End-to-End Example Flow

1. **Provision Infra:**  
   Run Terraform in your IaC repo to create ACE, ACR, etc. We recommend using the [Stratus Terraform Examples](https://github.com/HafslundEcoVannkraft/stratus-tf-examples/tree/main/examples/corp/container_app) for corporate Container Apps deployments. These examples provide tested, production-ready infrastructure patterns aligned with Stratus best practices.

2. **Configure GitHub Environments:**  
   - Edit `github-envrionments.yaml` in the IaC repo to describe which app repos/environments to configure.
   - Run the provided workflow (via GitHub CLI) with the required inputs (`github_token`, `tfvars_file`).

3. **App Source Repo Usage:**  
   - Developers in the app repo can now use the configured environments for secure, OIDC-based deployments to Azure.
   - **Why vend the source repos?** Each source repo (e.g., frontend, backend, APIs) needs its own OIDC identity and GitHub environment to:
     - Push container images securely to the Azure Container Registry (ACR) using federated credentials (no static secrets).
     - Deploy new container apps or update existing apps in the Azure Container App Environment.
   - In larger systems, you may have multiple source repos (e.g., frontend, backend, microservices) that each require their own environment configuration and permissions. This module enables you to vend and manage these environments centrally and securely from your IaC repo.

> **Note:**  
> This module is a **building block** in a larger Stratus deployment. It does not provision Azure infra or manage app source code. It configures GitHub environments and permissions so that remote app repos can deploy to the infra you provisioned.

---

## Configuration Reference

### YAML Structure

The `github-envrionments.yaml` file defines GitHub deployment environments for your application repositories:

```yaml
repositories:
  - repo: "repository-name"  # GitHub repository name
    environments:
      - name: "environment-name"  # GitHub Environment name (e.g., dev, staging, prod)
        # Environment settings follow
```

### Environment Options

| Property | Type | Description | Default | Required |
|----------|------|-------------|---------|----------|
| `name` | string | Name of the GitHub deployment environment | - | Yes |
| `wait_timer` | integer | Wait time (minutes) before allowing deployments | 0 | No |
| `prevent_self_review` | boolean | Prevents people from approving their own deployments | false | No |
| `reviewers` | object | Users and teams who must approve deployments | null | No |
| `deployment_branch_policy` | object | Branch restriction rules | null | No |
| `deployment_tag_policy` | object | Tag-based deployment rules | null | No |
| `variables` | object | Environment variables to create | {} | No |
| `secrets` | array | Secrets to create | [] | No |

> **Note**: Each GitHub environment defined here will get its own Azure User-Assigned Managed Identity and federated credential. This allows for granular access control and deployment permissions targeting the same underlying Azure resources.

### Reviewers Configuration

GitHub requires either users or teams (or both) as reviewers for environments:

```yaml
reviewers:
  users:
    - username: "johndoe"      # GitHub username
    - username: "janedoe"      # Multiple users allowed
  teams:
    - name: "devops-team"      # GitHub team name
    - slug: "security-team"    # OR team slug (not both)
```

**Important Notes:**
- Each user must be specified with the `username` field
- Teams can be specified with either `name` OR `slug` (not both for the same team)
- You must use proper GitHub usernames and team names/slugs
- Teams must exist in the organization before running this module

### Branch Policies

GitHub environments can restrict which branches can deploy to them:

#### 1. No Branch Restrictions

Omit the `deployment_branch_policy` section entirely to allow any branch to deploy.

#### 2. Protected Branches Only

```yaml
deployment_branch_policy:
  protected_branches: true
  custom_branch_policies: false
```

This only allows branches with branch protection rules to deploy to the environment.

#### 3. Custom Branch Patterns

```yaml
deployment_branch_policy:
  protected_branches: false
  custom_branch_policies: true
  custom_branches:
    - "main"
    - "release/*"
    - "feature/**"
```

This allows branches matching specific patterns to deploy. Patterns support:
- Exact matches (`main`)
- Wildcards (`release/*`)
- Complex patterns (`feature/**`)

### Tag Policies

Tag-based deployment rules limit which tags can deploy to an environment:

```yaml
deployment_tag_policy:
  enabled: true
  tag_patterns:
    - "v*"           # All version tags
    - "release-*"    # All release tags
```

When enabled, only tags matching the specified patterns can be deployed to the environment. This controls which tags can trigger deployments via GitHub Actions workflows, but does not provide tag protection (preventing tag deletion) which should be configured separately using GitHub repository settings or other modules.

### Key Configuration Constraints

**GitHub Environment Configuration Limitations:**

1. **Branch Policy Constraints:**
   - You cannot set both `protected_branches` and `custom_branch_policies` to `false`
   - If using `custom_branch_policies: true`, you must provide at least one pattern
   - If using `protected_branches: true`, leave `custom_branches` empty or omit it

2. **Tag Policy Constraints:**
   - Tag policies do not protect tags from deletion (configure tag protection separately)

3. **Critical API Limitations:**
   - You cannot use `protected_branches: true` in the same environment as tag policies
   - These settings are mutually exclusive in GitHub's API
   - If you need both protected branches and tag-based deployments, create separate environments for each purpose

4. **GitHub API Behavior:**
   - GitHub's API enforces only one deployment branch pattern per environment
   - The module prioritizes tag patterns if tag deployments are provided
   - Multiple patterns defined in your YAML remain as documentation, but only one can be enforced

This module works around these limitations as much as possible, but some combinations of settings may not be supported due to GitHub API constraints.

### Environment Variables and Secrets

The module automatically provides essential Azure infrastructure variables for all environments, plus you can define additional custom variables and secrets:

#### Automatically Provided Azure Variables

**The module automatically injects these variables into every GitHub environment** (no manual configuration required):

| Variable Name | Description | Source |
|---------------|-------------|---------|
| `AZURE_CLIENT_ID` | Managed identity client ID (unique per environment) | Per-environment managed identity |
| `AZURE_TENANT_ID` | Azure tenant ID | Current Azure client config |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | Current Azure client config |
| `ACR_NAME` | Container registry name | Remote state from infrastructure deployment |
| `CONTAINER_APP_ENVIRONMENT_ID` | Target environment for deployments | Remote state from infrastructure deployment |
| `CONTAINER_APP_ENVIRONMENT_CLIENT_ID` | Client ID for ACR authentication | Per-environment managed identity |
| `BACKEND_AZURE_RESOURCE_GROUP_NAME` | Resource group for Terraform state | Module configuration |
| `BACKEND_AZURE_STORAGE_ACCOUNT_NAME` | Storage account for Terraform state | Module configuration |
| `BACKEND_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME` | Container for state files | Module configuration |

> **Key Benefits**: These variables provide everything needed for Azure OIDC authentication, container operations, and CI/CD state access without any manual configuration.

#### Custom Variables and Secrets (Optional)

You can define additional custom variables and secrets for each environment in your YAML configuration:

```yaml
variables:
  API_URL: "https://api.example.com"
  DEBUG_MODE: "false"
  # Custom variables are merged with automatic Azure variables
  # Custom variables take precedence if names conflict

secrets:
  - name: API_KEY
    value: "secret-value"
  - name: DATABASE_PASSWORD
    value: "another-secret-value"
```

**Variable Precedence**: Custom variables override automatic Azure variables if there are naming conflicts.

**Note**: This version of the module only supports static secrets defined directly in the YAML file. 

> **Important**: Container App deployments using Azure OIDC federation typically don't need GitHub Environment secrets for Azure authentication since all Azure variables are automatically provided. Use secrets for build steps or third-party services only.

Future versions will support secret substitution from GitHub workflow environment variables, GitHub secrets, and references to Azure Key Vault for even greater security and flexibility in production environments.

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

3. **Role Assignments**:
   - **AcrPush**: Allows pushing container images to Azure Container Registry
   - **Container Apps Contributor**: Allows deploying to Azure Container Apps
   - **Container Apps Jobs Contributor**: Allows deploying jobs to Container Apps
   - **Storage Blob Data Contributor**: Provides access to Terraform state for CI/CD

## GitHub Action Integration

Once this module has been applied, your GitHub workflows can use the automatically configured environments and federated credentials to deploy to Azure Container Apps.

**The module automatically configures these environment variables** for use in GitHub Actions (no manual setup required):

| Variable | Description | Usage |
|----------|-------------|-------|
| `AZURE_CLIENT_ID` | The managed identity client ID for GitHub OIDC federation | Azure authentication |
| `AZURE_TENANT_ID` | The Azure tenant ID | Azure authentication |
| `AZURE_SUBSCRIPTION_ID` | The Azure subscription ID | Azure authentication |
| `ACR_NAME` | Container registry name | Image operations |
| `CONTAINER_APP_ENVIRONMENT_ID` | Target environment for deployments | Container app deployments |
| `CONTAINER_APP_ENVIRONMENT_CLIENT_ID` | Client ID of the managed identity for ACR authentication | ACR operations |
| `BACKEND_AZURE_RESOURCE_GROUP_NAME` | Resource group for Terraform state | CI/CD state access |
| `BACKEND_AZURE_STORAGE_ACCOUNT_NAME` | Storage account for Terraform state | CI/CD state access |
| `BACKEND_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME` | Container for state files | CI/CD state access |

> **Ready to Use**: These variables are automatically available in your GitHub Actions workflows immediately after running this module. No additional configuration needed!

### Example Workflow for Container App Deployment

Here's how to use these environments in your application repository's GitHub workflow:

```yaml
name: Deploy to Azure Container Apps

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    # Reference the environment name exactly as configured in github-envrionments.yaml
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

      - name: Log in to Azure Container Registry
        run: |
          az acr login --name ${{ vars.ACR_NAME }}

      - name: Build and push Docker image
        run: |
          docker build -t ${{ vars.ACR_NAME }}.azurecr.io/myapp:${{ github.sha }} .
          docker push ${{ vars.ACR_NAME }}.azurecr.io/myapp:${{ github.sha }}

      - name: Update Azure Container App
        run: |
          az containerapp update \
            --name my-container-app \
            --resource-group my-resource-group \
            --image ${{ vars.ACR_NAME }}.azurecr.io/myapp:${{ github.sha }}
```

For more advanced deployment patterns, you may want to:

1. **Separate plan and apply jobs** with different environments and protection levels
2. **Use different environments** for dev, staging, and production
3. **Add approval gates** for production deployments

Refer to the "Understanding GitHub Environments and Deployments" section for best practices.

## Common Issues and Troubleshooting

### Branch Policy Conflicts

**Error**: `"custom_branch_policies" and "protected_branches" cannot have the same value []`

**Solution**: You cannot set both `protected_branches` and `custom_branch_policies` to `false`. Either omit the entire `deployment_branch_policy` section or set one of them to `true`.

### GitHub Token Permissions

**Error**: `Resource not accessible by integration`

**Solution**: Ensure your GitHub token has the following required permissions for this module:
- `repo` (full control of private repositories)
- `workflow` (update GitHub Action workflows)
- `read:org` (read organization membership, teams, and users)
- `write:packages` (if you use GitHub Packages)

For organization-level operations, the token must have `read:org` scope to read teams and users in the organization. Without these permissions, the module will not be able to configure environments, reviewers, or deployment policies correctly.

#### Token Management in Corporate Environments

In this corporate archetype environment, the module is designed to be executed through GitHub Actions workflows. Key considerations:

1. **Execution Environment**:
   - Primary method: GitHub Actions workflows
   - Local execution: Only possible from an environment with proper network access to private endpoints

2. **Network Restrictions**:
   - Storage accounts are typically restricted to private endpoints only
   - Direct internet access to these resources is not allowed

3. **Required Permissions**:
   - GitHub permissions: Token needs repo, workflow, and read:org scopes
   - Azure permissions: Service principal or managed identity needs contributor access

If you need to create a token for workflow dispatch from the portal:

```bash
# Using GitHub CLI on an authorized environment with network access
gh auth login --web --scopes "repo,workflow,read:org,write:packages"

# Copy the token for use in the workflow
gh auth token
```

For CI/CD pipelines, configure secrets in your GitHub repository or organization settings rather than exporting as environment variables.

If you need to manage environments in organization repositories, ensure your token has the necessary organization-level permissions.

### Team Not Found

**Error**: `Could not resolve to a Team with the name '...'`

**Solution**: Verify the team exists in your GitHub organization and that you're using the correct name or slug.

### Reviewers Required

**Error**: `Inappropriate reviewers: ["user1", "user2"]`

**Solution**: Ensure all users specified as reviewers exist in GitHub with the exact usernames provided.

### Federated Credential Issues

**Error**: `Failed to create federated credential`

**Solution**: Check that the repository exists and that the subject format is correct. Ensure your Azure credentials have proper permissions.

### Common Troubleshooting

#### GitHub API Limitations with Deployment Policies

GitHub has limitations on how deployment policies can be configured:

1. **One pattern type per environment:** You can only have branch patterns OR tag patterns active
2. **Mutually exclusive settings:** Protected branches and tag policies cannot be used together
3. **Multiple patterns as documentation:** While you can define multiple patterns in your configuration, GitHub enforces only one pattern type

These limitations are inherent to GitHub's API implementation, not the module itself.

#### GitHub API Inconsistencies

GitHub's API can also be inconsistent when managing deployment policies:

- Some environments may trigger 404 errors when adding deployment policies
- The module includes a 45-second wait time to mitigate these issues
- Environments with conflicting configurations are especially problematic
- The module excludes known problematic combinations to prevent failures

If you encounter persistent errors with specific environments, consider these workarounds:
1. Avoid mixing protected branch policies and tag policies in the same environment
2. Create dedicated environments for tag-based deployments without branch policies
3. Manually create the deployment policies in the GitHub UI
4. Use the GitHub CLI to manage these policies outside of Terraform

These issues appear to be related to GitHub's API implementation, not with the module itself.

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `code_name` | Project/Application code name | `string` | n/a | yes |
| `environment` | Azure environment name (dev, test, prod) | `string` | n/a | yes |
| `github_token` | GitHub token for API access | `string` | n/a | yes |
| `github_owner` | GitHub organization or user name | `string` | `HafslundEcoVannkraft` | no |
| `location` | Azure region for resources | `string` | n/a | yes |
| `github_env_file` | Filename of GitHub environments configuration file | `string` | `"github-envrionments.yaml"` | no |
| `state_storage_account_name` | Storage account for Terraform state | `string` | n/a | yes |

## Notes for Single Organization Support

This module is designed to work with repositories within a single GitHub organization. If you need to manage repositories across multiple organizations, create separate deployments with different configurations.

## Understanding GitHub Environments and Deployments

> **Note:** While GitHub's official documentation is comprehensive, it's often scattered across multiple pages and not focused on specific use cases. This section provides a distilled set of best practices specifically tailored for Azure Container Apps deployments. We've consolidated the most relevant information based on real-world experience with the Stratus platform to help you implement a secure and effective deployment strategy.

### What are GitHub Environments?

GitHub environments are named deployment targets that provide protection rules, secrets, and variables for deployments. They allow you to:

1. **Control deployment workflows** through approval requirements and wait timers
2. **Separate deployment concerns** across different stages (development, staging, production)
3. **Secure sensitive data** by making secrets and variables available only to specific environments
4. **Restrict who can deploy** and which branches or tags can be deployed

### How Environments Work with GitHub Actions

When a GitHub Actions workflow deploys to an environment, it:

1. **Must explicitly reference** the environment by name (e.g., `environment: production`)
2. **Waits for any protection rules** to pass before running
3. **Can access environment secrets and variables** only after passing protection rules
4. **Creates a deployment record** visible on the repository's deployments page
5. **Uses the environment's OIDC identity** to authenticate with Azure

Here's a simplified view of how environments fit into a typical Container Apps deployment flow:

```
GitHub Repository
  │
  ├── Code Changes (PR or push)
  │     │
  │     ▼
  ├── GitHub Actions Workflow
  │     │
  │     ▼
  ├── Environment Protection Rules
  │     │ (wait timers, approvals, branch restrictions)
  │     ▼
  ├── Access to Environment Secrets & Variables
  │     │
  │     ▼
  ├── OIDC Authentication with Azure
  │     │
  │     ▼  
  └── Deployment to Azure Container Apps
```

### Best Practices for Environment Configuration

#### 1. Separate Plan and Apply Environments

For Azure Container Apps deployments, we recommend creating separate environments for planning and applying changes:

- **`*-plan` environments**: Low restrictions, no wait time, allow viewing what will change
- **`*-apply` environments**: Stronger protections, wait timers, approvals required, restricted to specific branches

This separation helps prevent accidental deployments while still allowing team members to preview changes.

#### 2. Progressive Protection Levels

For ACA deployments, increase protection as you move from development to production:

| Environment | Wait Timer | Approvals | Branch Restrictions | Tag Restrictions |
|-------------|------------|-----------|---------------------|------------------|
| Development | None       | Optional  | Minimal             | None             |
| Staging     | Short      | Required  | Protected branches   | None             |
| Production  | Longer     | Required  | Protected branches   | Release tags only |

#### 3. Use Proper Approval Workflows

- **Prevent self-review** to ensure changes are verified by another team member
- **Assign reviewers** who understand the system and deployment impacts
- **Use teams as reviewers** rather than individuals when possible for better coverage
- **Document deployment criteria** so reviewers know what to look for

#### 4. Branch and Tag Deployment Policies

For Container Apps, we recommend the following pattern:

- **Development**: Allow feature branches for testing new container images
- **Staging**: Restrict to main branch or release branches for integration testing
- **Production**: Restrict to version tags for controlled, versioned deployments

### Security Considerations with OIDC Federation

This module uses OpenID Connect (OIDC) federation to securely connect GitHub Actions with Azure Container Apps. This approach:

1. **Eliminates static credentials** in your GitHub repository 
2. **Provides temporary, scoped access** to Azure resources
3. **Leverages Azure RBAC** to limit what each environment can access
4. **Prevents credential leaks** by using token-based authentication
5. **Simplifies auditing** by tying actions directly to GitHub identities

This eliminates the need for long-lived service principal secrets and provides a more secure method for authenticating your container deployments.

### Recommended Workflow Configurations

For a practical implementation using the environments created by this module, consider this pattern:

```yaml
name: Deploy Container App

on:
  push:
    branches: [main]
    tags: ['v*']
  workflow_dispatch:

jobs:
  plan:
    runs-on: ubuntu-latest
    environment: app-dev-plan  # Lower restrictions for planning
    permissions:
      id-token: write
      contents: read
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      
      - name: Plan Deployment
        run: |
          echo "Planning deployment..."
          # Planning steps here
  
  deploy:
    needs: plan
    runs-on: ubuntu-latest
    environment: app-dev-apply  # Higher restrictions for applying changes
    permissions:
      id-token: write
      contents: read
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      
      - name: Deploy
        run: |
          # Deployment steps here
```