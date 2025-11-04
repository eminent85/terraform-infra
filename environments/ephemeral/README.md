# Ephemeral Test Environment

This Terraform configuration creates an ephemeral GCP environment designed for running automated tests in CI/CD pipelines. The environment is optimized for cost-efficiency and can be quickly created and destroyed.

## Overview

The ephemeral environment includes:
- **VPC Network** with public and private subnets
- **GKE Cluster** with autoscaling and preemptible nodes (cost-optimized)
- **Cloud NAT** for private subnet outbound connectivity
- **Optional Bastion Host** for debugging test failures
- **Workload Identity** service account for test workloads

## Features

- **Cost-Optimized**: Uses preemptible nodes, minimal node pools, and standard disks
- **Fast Provisioning**: Zonal cluster by default for faster creation
- **Isolated**: Separate VPC for each ephemeral environment
- **Secure**: Private GKE nodes with optional public endpoint
- **Scalable**: Autoscaling enabled for dynamic test workloads
- **Pipeline-Ready**: Designed for integration with GitHub Actions, GitLab CI, or other CI/CD systems

## Quick Start

> **Note:** For automated CI/CD deployment using GitHub Actions, see [GITHUB_ACTIONS.md](./GITHUB_ACTIONS.md)

### 1. Configure Variables

Copy the example variables file and customize it:

```bash
cd environments/ephemeral
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your GCP project details:
```hcl
project_id       = "your-gcp-project-id"
environment_name = "test-pr-123"  # Or use dynamic naming in CI/CD
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Deploy the Environment

```bash
# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

This typically takes 5-10 minutes to provision.

### 4. Access the Cluster

Get the cluster credentials:
```bash
gcloud container clusters get-credentials ephemeral-test-cluster \
  --region us-central1 \
  --project your-gcp-project-id
```

Verify access:
```bash
kubectl get nodes
```

### 5. Run Your Tests

Deploy and test your application:
```bash
# Deploy your application
kubectl apply -f your-app-manifests/

# Run tests
kubectl run test-pod --image=your-test-image --restart=Never -- /run-tests.sh

# Check logs
kubectl logs test-pod
```

### 6. Clean Up

After tests complete, destroy the environment to avoid ongoing costs:
```bash
terraform destroy
```

## CI/CD Pipeline Integration

> **GitHub Actions Users:** See [GITHUB_ACTIONS.md](./GITHUB_ACTIONS.md) for complete GitHub Actions integration guide with reusable workflows.

### GitHub Actions Example (Basic)

```yaml
name: Integration Tests

on:
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2

      - name: Authenticate to GCP
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_CREDENTIALS }}

      - name: Create Ephemeral Environment
        working-directory: environments/ephemeral
        run: |
          terraform init
          terraform apply -auto-approve \
            -var="project_id=${{ secrets.GCP_PROJECT_ID }}" \
            -var="environment_name=test-pr-${{ github.event.pull_request.number }}"

      - name: Get Cluster Credentials
        run: |
          gcloud container clusters get-credentials \
            test-pr-${{ github.event.pull_request.number }}-cluster \
            --region us-central1 \
            --project ${{ secrets.GCP_PROJECT_ID }}

      - name: Run Tests
        run: |
          kubectl apply -f k8s/
          kubectl wait --for=condition=ready pod -l app=your-app --timeout=300s
          kubectl run tests --image=your-test-image --restart=Never -- /run-tests.sh
          kubectl wait --for=condition=completed pod/tests --timeout=600s
          kubectl logs tests

      - name: Cleanup
        if: always()
        working-directory: environments/ephemeral
        run: terraform destroy -auto-approve
```

### GitLab CI Example

```yaml
stages:
  - provision
  - test
  - cleanup

variables:
  ENVIRONMENT_NAME: "test-${CI_PIPELINE_ID}"
  TF_ROOT: environments/ephemeral

provision:
  stage: provision
  image: hashicorp/terraform:latest
  script:
    - cd $TF_ROOT
    - terraform init
    - terraform apply -auto-approve
      -var="project_id=${GCP_PROJECT_ID}"
      -var="environment_name=${ENVIRONMENT_NAME}"
  artifacts:
    paths:
      - $TF_ROOT/terraform.tfstate

test:
  stage: test
  image: google/cloud-sdk:alpine
  script:
    - gcloud container clusters get-credentials ${ENVIRONMENT_NAME}-cluster
      --region us-central1 --project ${GCP_PROJECT_ID}
    - kubectl apply -f k8s/
    - kubectl run tests --image=your-test-image --restart=Never -- /run-tests.sh
    - kubectl wait --for=condition=completed pod/tests --timeout=600s
    - kubectl logs tests

cleanup:
  stage: cleanup
  image: hashicorp/terraform:latest
  script:
    - cd $TF_ROOT
    - terraform destroy -auto-approve
  when: always
```

## Configuration

### Key Variables

| Variable | Description | Default | Notes |
|----------|-------------|---------|-------|
| `project_id` | GCP Project ID | - | Required |
| `environment_name` | Environment name prefix | `ephemeral` | Use dynamic names in CI/CD |
| `region` | GCP region | `us-central1` | - |
| `zone` | GCP zone | `us-central1-a` | - |
| `use_preemptible_nodes` | Use preemptible nodes | `true` | Save ~80% on compute costs |
| `machine_type` | GKE node machine type | `e2-medium` | Adjust based on test requirements |
| `min_node_count` | Minimum nodes | `1` | - |
| `max_node_count` | Maximum nodes | `3` | Increase for heavy workloads |
| `create_bastion` | Create bastion host | `false` | Enable for debugging |
| `regional_cluster` | Regional (HA) cluster | `false` | Set to `true` for production-like testing |

### Cost Optimization

This configuration is optimized for cost:

- **Preemptible Nodes**: ~80% cheaper than regular nodes
- **Zonal Cluster**: Lower control plane costs
- **Minimal Logging/Monitoring**: Reduces log ingestion costs
- **Auto-scaling**: Scales to zero when not in use
- **Small Machine Types**: e2-medium for most workloads

**Estimated Cost**: $0.50-$2.00 per test run (assuming 30-60 minute duration)

### Debugging Failed Tests

If tests fail and you need to debug:

1. **Enable the bastion host**:
   ```hcl
   create_bastion = true
   ```

2. **Re-apply**:
   ```bash
   terraform apply
   ```

3. **SSH to the bastion**:
   ```bash
   gcloud compute ssh ephemeral-test-bastion \
     --zone=us-central1-a \
     --tunnel-through-iap
   ```

4. **From the bastion, access the cluster**:
   ```bash
   gcloud container clusters get-credentials ephemeral-test-cluster --region us-central1
   kubectl get pods
   kubectl logs <pod-name>
   ```

## Best Practices

### Dynamic Environment Naming

Use dynamic environment names based on your CI/CD context:

```bash
# GitHub Actions
environment_name = "test-pr-${GITHUB_PR_NUMBER}"

# GitLab CI
environment_name = "test-${CI_PIPELINE_ID}"

# Jenkins
environment_name = "test-${BUILD_NUMBER}"

# Generic
environment_name = "test-$(git rev-parse --short HEAD)"
```

### Terraform State Management

For CI/CD pipelines, use remote state:

```hcl
terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "ephemeral/${ENVIRONMENT_NAME}"
  }
}
```

### Timeout and Retry

- Set appropriate timeouts for `terraform apply` (default: 20 minutes)
- Implement retry logic for transient GCP API errors
- Use `-parallelism` flag to control concurrent operations

### Resource Cleanup

Always ensure cleanup runs, even on test failure:

```yaml
# GitHub Actions
- name: Cleanup
  if: always()
  run: terraform destroy -auto-approve
```

### Cost Monitoring

Set up budget alerts:

```bash
gcloud billing budgets create \
  --billing-account=YOUR_BILLING_ACCOUNT \
  --display-name="Ephemeral Environment Budget" \
  --budget-amount=100USD \
  --threshold-rule=percent=50 \
  --threshold-rule=percent=90
```

## Advanced Configuration

### Using Workload Identity

The environment creates a GCP service account with Workload Identity binding:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: test-sa
  namespace: default
  annotations:
    iam.gke.io/gcp-service-account: ephemeral-test-sa@PROJECT_ID.iam.gserviceaccount.com
```

Use it in your pods:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  serviceAccountName: test-sa
  containers:
  - name: test
    image: your-test-image
```

### Custom IAM Roles

Add custom roles for your test service account:

```hcl
test_sa_roles = [
  "roles/logging.logWriter",
  "roles/monitoring.metricWriter",
  "roles/storage.objectViewer",
  "roles/cloudsql.client",
]
```

### Network Policies

Enable network policies for isolation testing:

```hcl
enable_network_policy = true
```

## Troubleshooting

### Quota Errors

If you hit quota limits:
```bash
gcloud compute project-info describe --project=PROJECT_ID
```

Request quota increases at: https://console.cloud.google.com/iam-admin/quotas

### Slow Provisioning

- Use zonal clusters (`regional_cluster = false`)
- Pre-pull container images to GCR/Artifact Registry
- Use smaller node pools initially

### Connection Issues

Verify master authorized networks:
```hcl
master_authorized_networks = [
  {
    cidr_block   = "0.0.0.0/0"
    display_name = "Allow all"
  }
]
```

## Outputs

After applying, Terraform outputs useful information:

- `cluster_name`: GKE cluster name
- `get_credentials_command`: Command to get cluster credentials
- `quick_start_commands`: Copy-paste commands to get started

View outputs:
```bash
terraform output
```

## Related Documentation

- [GKE Module](../../modules/gcp/gke/README.md)
- [Network Module](../../modules/gcp/network/README.md)
- [Compute Module](../../modules/gcp/compute/README.md)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

## License

See repository root for license information.
