# GitHub Actions for Ephemeral Environments

This guide explains how to use the ephemeral environment GitHub Actions workflows, both within this repository and from external application repositories.

## Overview

Four workflows are available:

1. **ephemeral-deploy.yml** - Manual deployment within this repo
2. **ephemeral-destroy.yml** - Manual destruction within this repo
3. **reusable-ephemeral-deploy.yml** - Reusable workflow for external repos
4. **reusable-ephemeral-destroy.yml** - Reusable workflow for external repos

## Using Workflows in This Repository

### Manual Deployment

Navigate to Actions → "Ephemeral Environment - Deploy" → "Run workflow"

**Inputs:**
- `environment_name` (required): Unique name (e.g., `test-pr-123`)
- `create_bastion`: Create bastion host for debugging (default: false)
- `machine_type`: GKE node machine type (default: `e2-medium`)
- `max_node_count`: Maximum nodes (default: `3`)

### Manual Destruction

Navigate to Actions → "Ephemeral Environment - Destroy" → "Run workflow"

**Inputs:**
- `environment_name` (required): Name of environment to destroy
- `skip_approval`: Skip manual approval (default: false)

## Using Workflows from External Repositories

External repositories can call these workflows to provision ephemeral test environments for CI/CD.

### Prerequisites

1. **Repository Access**: Your external repo needs access to this terraform-infra repository
2. **Secrets Configuration**: Set up the following secrets in your application repository:
   - `GCP_PROJECT_ID`: Your GCP project ID
   - `GCP_SA_KEY`: GCP service account key with permissions to create resources
   - `GITHUB_TOKEN`: Automatically provided by GitHub Actions

3. **Repository Settings**:
   - Make this terraform-infra repository accessible (public or grant access)
   - Or fork it to your organization

### Example 1: PR-Based Testing

Create `.github/workflows/pr-test.yml` in your application repository:

```yaml
name: PR Integration Tests

on:
  pull_request:
    branches: [main]

jobs:
  deploy-test-env:
    name: Deploy Test Environment
    uses: YOUR-ORG/terraform-infra/.github/workflows/reusable-ephemeral-deploy.yml@main
    with:
      environment_name: test-pr-${{ github.event.pull_request.number }}
      machine_type: e2-medium
      max_node_count: 3
      use_preemptible_nodes: true
    secrets:
      GCP_PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
      GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}

  run-tests:
    name: Run Integration Tests
    needs: deploy-test-env
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup gcloud
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}

      - name: Get Cluster Credentials
        run: |
          ${{ needs.deploy-test-env.outputs.get_credentials_command }}

      - name: Deploy Application
        run: |
          kubectl apply -f k8s/

      - name: Wait for Deployment
        run: |
          kubectl wait --for=condition=available --timeout=300s \
            deployment/my-app -n default

      - name: Run Tests
        run: |
          kubectl run test-runner \
            --image=my-org/test-runner:latest \
            --restart=Never \
            --rm \
            --attach \
            -- pytest /tests

      - name: Check Application Health
        run: |
          kubectl get pods -n default
          kubectl logs -l app=my-app -n default --tail=50

  cleanup:
    name: Cleanup Test Environment
    needs: [deploy-test-env, run-tests]
    if: always()
    uses: YOUR-ORG/terraform-infra/.github/workflows/reusable-ephemeral-destroy.yml@main
    with:
      environment_name: test-pr-${{ github.event.pull_request.number }}
      skip_approval: true
    secrets:
      GCP_PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
      GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
```

### Example 2: Commit-Based Testing

```yaml
name: Commit Integration Tests

on:
  push:
    branches:
      - develop
      - feature/*

jobs:
  test:
    name: Integration Tests
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Generate Environment Name
        id: env-name
        run: |
          SHORT_SHA=$(git rev-parse --short HEAD)
          echo "name=test-${SHORT_SHA}" >> $GITHUB_OUTPUT

      - name: Deploy Environment
        uses: YOUR-ORG/terraform-infra/.github/workflows/reusable-ephemeral-deploy.yml@main
        with:
          environment_name: ${{ steps.env-name.outputs.name }}
          machine_type: e2-small
          max_node_count: 2
        secrets:
          GCP_PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
          GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}

      - name: Run Tests
        run: |
          # Your test commands here
          echo "Running tests..."

      - name: Cleanup
        if: always()
        uses: YOUR-ORG/terraform-infra/.github/workflows/reusable-ephemeral-destroy.yml@main
        with:
          environment_name: ${{ steps.env-name.outputs.name }}
          skip_approval: true
        secrets:
          GCP_PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
          GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
```

### Example 3: On-Demand Testing with Manual Trigger

```yaml
name: On-Demand Integration Test

on:
  workflow_dispatch:
    inputs:
      test_tag:
        description: 'Docker image tag to test'
        required: true
      keep_environment:
        description: 'Keep environment after tests'
        required: false
        type: boolean
        default: false

jobs:
  deploy-and-test:
    name: Deploy and Test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Deploy Environment
        id: deploy
        uses: YOUR-ORG/terraform-infra/.github/workflows/reusable-ephemeral-deploy.yml@main
        with:
          environment_name: test-manual-${{ github.run_number }}
          create_bastion: true
          machine_type: e2-standard-2
          max_node_count: 5
        secrets:
          GCP_PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
          GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}

      - name: Deploy and Test Application
        run: |
          ${{ steps.deploy.outputs.get_credentials_command }}
          kubectl apply -f k8s/
          kubectl set image deployment/my-app my-app=my-org/my-app:${{ github.event.inputs.test_tag }}
          kubectl wait --for=condition=available --timeout=300s deployment/my-app
          # Run tests
          ./run-integration-tests.sh

      - name: Output Access Info
        if: github.event.inputs.keep_environment == 'true'
        run: |
          echo "Environment: test-manual-${{ github.run_number }}"
          echo "Cluster: ${{ steps.deploy.outputs.cluster_name }}"
          echo "Connect: ${{ steps.deploy.outputs.get_credentials_command }}"

      - name: Cleanup
        if: github.event.inputs.keep_environment != 'true'
        uses: YOUR-ORG/terraform-infra/.github/workflows/reusable-ephemeral-destroy.yml@main
        with:
          environment_name: test-manual-${{ github.run_number }}
          skip_approval: true
        secrets:
          GCP_PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
          GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
```

### Example 4: Nightly Full Integration Tests

```yaml
name: Nightly Integration Tests

on:
  schedule:
    - cron: '0 2 * * *'  # Run at 2 AM UTC
  workflow_dispatch:

jobs:
  deploy:
    name: Deploy Nightly Test Environment
    uses: YOUR-ORG/terraform-infra/.github/workflows/reusable-ephemeral-deploy.yml@main
    with:
      environment_name: test-nightly-${{ github.run_number }}
      machine_type: e2-standard-4
      max_node_count: 10
      use_preemptible_nodes: false  # Use standard nodes for reliability
    secrets:
      GCP_PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
      GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}

  test-suite:
    name: Run Full Test Suite
    needs: deploy
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup kubectl
        run: |
          ${{ needs.deploy.outputs.get_credentials_command }}

      - name: Deploy Full Stack
        run: |
          kubectl apply -f k8s/db/
          kubectl apply -f k8s/cache/
          kubectl apply -f k8s/app/
          kubectl apply -f k8s/workers/

      - name: Wait for Services
        run: |
          kubectl wait --for=condition=ready pod -l tier=database --timeout=600s
          kubectl wait --for=condition=ready pod -l tier=cache --timeout=300s
          kubectl wait --for=condition=ready pod -l tier=app --timeout=300s

      - name: Run Integration Tests
        run: |
          ./scripts/run-full-test-suite.sh

      - name: Run Load Tests
        run: |
          ./scripts/run-load-tests.sh

      - name: Generate Test Report
        if: always()
        run: |
          ./scripts/generate-test-report.sh

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results-${{ github.run_number }}
          path: test-results/

  cleanup:
    name: Cleanup Nightly Environment
    needs: [deploy, test-suite]
    if: always()
    uses: YOUR-ORG/terraform-infra/.github/workflows/reusable-ephemeral-destroy.yml@main
    with:
      environment_name: test-nightly-${{ github.run_number }}
      skip_approval: true
    secrets:
      GCP_PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
      GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
```

## Workflow Inputs Reference

### Deploy Workflow Inputs

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `environment_name` | string | Yes | - | Unique environment identifier |
| `create_bastion` | boolean | No | false | Create bastion for debugging |
| `machine_type` | string | No | e2-medium | GKE node machine type |
| `min_node_count` | string | No | 1 | Minimum nodes per zone |
| `max_node_count` | string | No | 3 | Maximum nodes per zone |
| `use_preemptible_nodes` | boolean | No | true | Use preemptible nodes |
| `region` | string | No | us-central1 | GCP region |
| `zone` | string | No | us-central1-a | GCP zone |
| `terraform_version` | string | No | 1.5.0 | Terraform version |

### Deploy Workflow Outputs

| Output | Description |
|--------|-------------|
| `cluster_name` | Name of the created GKE cluster |
| `cluster_endpoint` | Cluster API endpoint |
| `cluster_region` | Region where cluster is deployed |
| `environment_name` | Environment name used |
| `get_credentials_command` | Command to get cluster credentials |

### Destroy Workflow Inputs

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `environment_name` | string | Yes | - | Environment name to destroy |
| `region` | string | No | us-central1 | GCP region |
| `terraform_version` | string | No | 1.5.0 | Terraform version |
| `skip_approval` | boolean | No | false | Skip manual approval |

## Best Practices

### 1. Environment Naming

Use consistent, descriptive naming:

```yaml
# Good
environment_name: test-pr-${{ github.event.pull_request.number }}
environment_name: test-${{ github.sha }}
environment_name: test-branch-${{ github.ref_name }}

# Bad (too generic or conflicts possible)
environment_name: test
environment_name: my-env
```

### 2. Always Cleanup

Always use `if: always()` for cleanup jobs:

```yaml
cleanup:
  if: always()
  needs: [deploy, test]
  uses: .../reusable-ephemeral-destroy.yml@main
```

### 3. Cost Optimization

For PR tests, use:
- `use_preemptible_nodes: true`
- `machine_type: e2-medium` or `e2-small`
- `max_node_count: 3` or less

### 4. Timeout Protection

Set timeouts to prevent runaway costs:

```yaml
jobs:
  test:
    timeout-minutes: 60  # Maximum 1 hour
```

### 5. Artifact Management

Terraform state is automatically saved as artifacts for 7 days. For longer-running environments, consider using remote state:

```hcl
# In environments/ephemeral/main.tf
terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "ephemeral/${var.environment_name}"
  }
}
```

### 6. Secret Management

Never hardcode secrets. Use GitHub Secrets:

```yaml
secrets:
  GCP_PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
  GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
```

### 7. Parallel Testing

Run multiple test suites in parallel:

```yaml
jobs:
  deploy:
    uses: .../reusable-ephemeral-deploy.yml@main

  unit-tests:
    needs: deploy
    runs-on: ubuntu-latest
    steps: [...]

  integration-tests:
    needs: deploy
    runs-on: ubuntu-latest
    steps: [...]

  e2e-tests:
    needs: deploy
    runs-on: ubuntu-latest
    steps: [...]

  cleanup:
    needs: [deploy, unit-tests, integration-tests, e2e-tests]
    if: always()
    uses: .../reusable-ephemeral-destroy.yml@main
```

## Troubleshooting

### Issue: Workflow can't find reusable workflow

**Solution:** Ensure the repository path is correct:
```yaml
uses: YOUR-ORG/terraform-infra/.github/workflows/reusable-ephemeral-deploy.yml@main
```

### Issue: Permission denied accessing terraform-infra repo

**Solution:** Make terraform-infra public or grant access to your application repo.

### Issue: Terraform state not found during destroy

**Solution:** The workflow will attempt manual cleanup using gcloud commands if state is missing.

### Issue: Quota exceeded

**Solution:** Check your GCP quotas:
```bash
gcloud compute project-info describe --project=PROJECT_ID
```

Request increases at: https://console.cloud.google.com/iam-admin/quotas

### Issue: Cleanup fails, resources still exist

**Solution:** Manually destroy via Actions UI or gcloud:
```bash
gcloud container clusters delete CLUSTER_NAME --region REGION
gcloud compute networks delete VPC_NAME
```

## Monitoring Costs

Set up budget alerts for ephemeral environments:

```bash
gcloud billing budgets create \
  --billing-account=BILLING_ACCOUNT_ID \
  --display-name="Ephemeral Environments" \
  --budget-amount=500USD \
  --threshold-rule=percent=50 \
  --threshold-rule=percent=90 \
  --filter-labels=environment=ephemeral
```

## Related Documentation

- [Ephemeral Environment README](./README.md)
- [Terraform GCP Modules](../../modules/gcp/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## Support

For issues or questions:
1. Check this documentation
2. Review workflow run logs in GitHub Actions
3. Check GCP Console for resource status
4. Open an issue in the terraform-infra repository
