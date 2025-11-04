# GitHub Actions Workflows for Terraform Infrastructure

This directory contains GitHub Actions workflows for managing long-lived GCP infrastructure across multiple environments (dev, staging, prod).

## Overview

The workflow structure uses reusable workflows to ensure consistency across environments while maintaining environment-specific configurations and safety measures.

### Workflow Architecture

```
Reusable Workflows (Core Logic):
├── terraform-deploy.yml    # Handles terraform plan and apply
└── terraform-destroy.yml   # Handles terraform destroy operations

Environment-Specific Workflows (Triggers):
├── dev-deploy.yml          # Deploy to dev environment
├── dev-destroy.yml         # Destroy dev environment
├── staging-deploy.yml      # Deploy to staging environment
├── staging-destroy.yml     # Destroy staging environment
├── prod-deploy.yml         # Deploy to production environment
└── prod-destroy.yml        # Destroy production environment
```

## Deployment Workflows

### Automatic Deployments

Deployments are automatically triggered when:
- Changes are pushed to the `main` branch that affect:
  - Environment-specific configuration (`environments/{env}/**`)
  - Shared modules (`modules/gcp/**`)
  - Workflow files themselves

### Manual Deployments

All environments support manual deployment via the GitHub Actions UI:
1. Navigate to **Actions** → **[Environment] - Deploy**
2. Click **Run workflow**
3. Optionally provide a reason for the deployment
4. Click **Run workflow**

### Pull Request Planning

When a PR is opened that affects an environment:
- Terraform plan is automatically generated
- Plan output is posted as a PR comment
- No infrastructure changes are applied until PR is merged

## Destroy Workflows

All destroy workflows are **manual only** and include safety confirmations.

### Dev Environment Destroy

**Trigger:** Manual workflow dispatch only

**Confirmation required:** Type `destroy-dev`

**Steps:**
1. Navigate to **Actions** → **Dev Environment - Destroy**
2. Click **Run workflow**
3. Enter `destroy-dev` in the confirmation field
4. Provide a reason for destruction
5. Click **Run workflow**
6. Approve the deployment in the **dev-destroy** environment

### Staging Environment Destroy

**Trigger:** Manual workflow dispatch only

**Confirmation required:** Type `destroy-staging`

**Steps:**
1. Navigate to **Actions** → **Staging Environment - Destroy**
2. Click **Run workflow**
3. Enter `destroy-staging` in the confirmation field
4. Provide a reason for destruction
5. Click **Run workflow**
6. Approve the deployment in the **staging-destroy** environment

### Production Environment Destroy

**Trigger:** Manual workflow dispatch only

**Confirmation required:**
- Type `destroy-production-permanently`
- Enter the production GCP project ID

**Steps:**
1. Navigate to **Actions** → **Production Environment - Destroy**
2. Click **Run workflow**
3. Enter `destroy-production-permanently` in the confirmation field
4. Enter the production GCP project ID in the secondary confirmation field
5. Provide a reason for destruction
6. Click **Run workflow**
7. Approve the deployment in the **prod-destroy** environment

## Required GitHub Secrets

Configure the following secrets in your GitHub repository settings:

### Development Environment
- `DEV_GCP_PROJECT_ID` - GCP Project ID for dev environment
- `DEV_GCP_SA_KEY` - Service Account JSON key for dev (with appropriate permissions)

### Staging Environment
- `STAGING_GCP_PROJECT_ID` - GCP Project ID for staging environment
- `STAGING_GCP_SA_KEY` - Service Account JSON key for staging (with appropriate permissions)

### Production Environment
- `PROD_GCP_PROJECT_ID` - GCP Project ID for production environment
- `PROD_GCP_SA_KEY` - Service Account JSON key for production (with appropriate permissions)

## Required GitHub Environments

Create the following environments in your GitHub repository settings with appropriate protection rules:

### Standard Environments (for deployments)
- `dev` - Development environment
  - Recommended: No required reviewers for faster iteration
  - Optional: Limit to main branch only

- `staging` - Staging environment
  - Recommended: At least 1 required reviewer
  - Recommended: Limit to main branch only

- `prod` - Production environment
  - **Required:** At least 2 required reviewers
  - **Required:** Limit to main branch only
  - Recommended: Add deployment branch protection

### Destroy Environments (for destroy operations)
- `dev-destroy`
  - Recommended: At least 1 required reviewer

- `staging-destroy`
  - Recommended: At least 2 required reviewers

- `prod-destroy`
  - **Required:** At least 3 required reviewers
  - **Required:** Additional wait timer (e.g., 5 minutes)

## Service Account Permissions

The GCP service accounts used in the workflows require the following IAM roles:

### Minimum Required Roles
- `roles/compute.admin` - Compute Engine management
- `roles/container.admin` - GKE cluster management
- `roles/iam.serviceAccountUser` - Service account usage
- `roles/storage.admin` - GCS bucket management (for Terraform state)

### Additional Recommended Roles
- `roles/compute.networkAdmin` - VPC and network management
- `roles/iam.serviceAccountAdmin` - Service account creation/management (if needed)

### State Bucket Permissions
Ensure the service account has read/write access to the Terraform state bucket:
- `eminent-dev-terraform-state` (for dev)
- Corresponding buckets for staging and prod

## Workflow Features

### Terraform Deploy Workflow
- ✅ Automatic formatting check
- ✅ Terraform validation
- ✅ Plan generation with artifact upload
- ✅ PR comment with plan output
- ✅ Automatic apply on main branch
- ✅ JSON output capture for downstream usage

### Terraform Destroy Workflow
- ✅ Two-stage process (plan → destroy)
- ✅ Manual approval required
- ✅ Destroy plan artifact preservation
- ✅ Environment-specific confirmations
- ✅ Additional safety for production

## Best Practices

### For Long-Lived Clusters

1. **State Management**
   - Terraform state is stored in GCS buckets
   - State is locked during operations
   - Each environment has its own state file

2. **Environment Isolation**
   - Each environment uses a separate GCP project
   - Separate service accounts per environment
   - Independent state buckets

3. **Change Management**
   - Use pull requests for all infrastructure changes
   - Review Terraform plans before merging
   - Test changes in dev before promoting to staging/prod

4. **Disaster Recovery**
   - Terraform state is version-enabled in GCS
   - Regular backups of state files
   - Keep configuration in version control

5. **Security**
   - Use environment protection rules
   - Require reviews for sensitive environments
   - Rotate service account keys regularly
   - Use least privilege for service accounts

## Troubleshooting

### Workflow Fails on "Terraform Init"
- Check that the state bucket exists
- Verify service account has access to the state bucket
- Ensure the backend configuration in `main.tf` is correct

### Workflow Fails on "Terraform Plan"
- Verify all required secrets are configured
- Check service account permissions
- Review Terraform configuration for syntax errors

### Destroy Workflow Fails
- Ensure you've entered the correct confirmation text
- Verify you have approval from environment reviewers
- Check for resources with deletion protection enabled

### State Lock Errors
- Previous workflow may have been interrupted
- Manually release the lock in GCS if safe to do so
- Check for concurrent workflow runs

## Monitoring and Alerts

Consider setting up:
- Slack/email notifications for workflow failures
- GitHub Actions status badges in README
- Monitoring for GCP quota limits
- Cost alerts for unexpected infrastructure growth

## Maintenance

### Updating Terraform Version
Update the `terraform_version` parameter in environment-specific workflow files:

```yaml
with:
  terraform_version: '1.6.0'  # Update to desired version
```

### Updating Workflow Logic
Modify the reusable workflows (`terraform-deploy.yml`, `terraform-destroy.yml`) to apply changes across all environments.

## Support

For issues or questions:
1. Check the workflow run logs in GitHub Actions
2. Review Terraform state in GCS buckets
3. Consult the main repository documentation
4. Create an issue in the repository
