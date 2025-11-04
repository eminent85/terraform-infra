# GCP Kubernetes Infrastructure

Multi-environment Terraform infrastructure for deploying production-ready GKE clusters on Google Cloud Platform with Istio service mesh support.

## Repository Structure

```
terraform-infra/
├── modules/gcp/              # Reusable Terraform modules
│   ├── network/             # VPC, subnets, NAT, firewall rules
│   ├── gke/                 # GKE cluster and node pools
│   └── compute/             # Bastion VM
│
├── environments/            # Environment-specific configurations
│   ├── dev/                # Development environment (cost-optimized)
│   ├── staging/            # Staging environment (production-like)
│   └── prod/               # Production environment (HA, full monitoring)
│
└── CLAUDE.md               # Claude Code guidance
```

## Architecture

Each environment creates:

- **VPC Network** with public and private subnets
- **GKE Cluster** in private subnet with private nodes
- **Bastion Host** in public subnet for secure cluster access
- **Cloud NAT** for outbound connectivity from private resources
- **Static IP** for Istio Ingress Gateway
- **IAM Service Accounts** with least-privilege permissions

### Network Architecture

```
┌─────────────────────────────────────────────────────┐
│                    VPC Network                       │
│                                                      │
│  ┌──────────────────┐    ┌───────────────────────┐ │
│  │  Public Subnet   │    │   Private Subnet      │ │
│  │  (Bastion)       │    │   (GKE Cluster)       │ │
│  │                  │    │                       │ │
│  │  ┌────────────┐  │    │  ┌─────────────────┐ │ │
│  │  │  Bastion   │  │    │  │   GKE Cluster   │ │ │
│  │  │    VM      │──┼────┼─>│   Private Nodes │ │ │
│  │  └────────────┘  │    │  │   Workload ID   │ │ │
│  │                  │    │  └─────────────────┘ │ │
│  │  (IAP Access)    │    │         │            │ │
│  └──────────────────┘    │  ┌──────▼──────────┐ │ │
│                          │  │   Cloud NAT     │ │ │
│                          │  └─────────────────┘ │ │
│                          └───────────────────────┘ │
│                                   │                 │
│  ┌────────────────────────────────▼──────────────┐ │
│  │    Istio Ingress Gateway (LoadBalancer)       │ │
│  │    Static IP: <Provisioned per environment>   │ │
│  └────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

## Environment Comparison

| Feature | Dev | Staging | Production |
|---------|-----|---------|------------|
| **Cluster Type** | Zonal | Regional | Regional |
| **Node Type** | Preemptible | Standard | Standard |
| **Machine Type** | e2-medium | e2-standard-2 | e2-standard-4 |
| **Min Nodes** | 1 | 3 (1/zone) | 6 (2/zone) |
| **Max Nodes** | 3 | 5 (total) | 30 (10/zone) |
| **Disk Size** | 50GB | 75GB | 100GB |
| **Monitoring** | Basic | Basic | Managed Prometheus |
| **Release Channel** | RAPID | REGULAR | REGULAR |
| **Estimated Cost** | ~$15/mo | ~$245/mo | ~$743/mo |
| **SLA** | None | 99.5% | 99.95% |

## Prerequisites

1. **GCP Project(s)** with billing enabled (one per environment recommended)
2. **Terraform** >= 1.5.0
3. **gcloud CLI** configured with appropriate credentials
4. **Required GCP APIs enabled**:
   ```bash
   gcloud services enable compute.googleapis.com \
     container.googleapis.com \
     servicenetworking.googleapis.com \
     cloudresourcemanager.googleapis.com \
     --project=YOUR_PROJECT_ID
   ```

## Quick Start

### 1. Choose Your Environment

```bash
# For development
cd environments/dev

# For staging
cd environments/staging

# For production
cd environments/prod
```

### 2. Configure Variables

Edit `terraform.tfvars` in your chosen environment:

```hcl
project_id = "your-gcp-project-id"
region     = "us-central1"
zone       = "us-central1-a"
```

### 3. Configure Remote State (Recommended)

Create a GCS bucket for Terraform state:

```bash
gsutil mb -p YOUR_PROJECT_ID -l us-central1 gs://YOUR_TERRAFORM_STATE_BUCKET
gsutil versioning set on gs://YOUR_TERRAFORM_STATE_BUCKET
```

Update the backend configuration in `main.tf`:

```hcl
backend "gcs" {
  bucket = "YOUR_TERRAFORM_STATE_BUCKET"
  prefix = "terraform/ENV/state"  # dev, staging, or prod
}
```

### 4. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 5. Access Your Cluster

```bash
# Get outputs
terraform output

# Connect to bastion via IAP
terraform output -raw bastion_connection_command | bash

# From bastion, get GKE credentials
terraform output -raw get_credentials_command | bash

# Verify cluster access
kubectl get nodes
```

## Environment-Specific Guides

- **[Dev Environment](environments/dev/README.md)** - Cost-optimized for development
- **[Staging Environment](environments/staging/README.md)** - Production-like for testing
- **[Production Environment](environments/prod/README.md)** - HA and fully monitored

## Module Documentation

Each module has comprehensive documentation:

- **[Network Module](modules/gcp/network/README.md)** - VPC, subnets, NAT, firewall
- **[GKE Module](modules/gcp/gke/README.md)** - Kubernetes cluster configuration
- **[Compute Module](modules/gcp/compute/README.md)** - Bastion host setup

## Common Operations

### Installing Istio

After cluster creation, install Istio with the pre-allocated static IP:

```bash
# SSH to bastion
gcloud compute ssh BASTION_NAME --zone=ZONE --tunnel-through-iap

# Install Istio
istioctl install --set profile=default -y

# Get the static IP from terraform outputs
INGRESS_IP=$(terraform output -raw istio_ingress_ip)

# Create Istio Ingress Gateway
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: istio-ingressgateway
  namespace: istio-system
spec:
  type: LoadBalancer
  loadBalancerIP: ${INGRESS_IP}
  selector:
    istio: ingressgateway
  ports:
  - name: http
    port: 80
    targetPort: 8080
  - name: https
    port: 443
    targetPort: 8443
EOF
```

### Switching Between Environments

```bash
# Work with dev
cd environments/dev
terraform workspace select dev  # if using workspaces
terraform plan

# Work with staging
cd ../staging
terraform workspace select staging
terraform plan

# Work with prod
cd ../prod
terraform workspace select prod
terraform plan
```

### Scaling Nodes

Edit the environment's `terraform.tfvars`:

```hcl
gke_min_node_count = 3
gke_max_node_count = 10
```

Apply the changes:

```bash
terraform apply
```

### Upgrading Kubernetes Version

GKE clusters in release channels auto-upgrade during maintenance windows. To change the release channel:

```hcl
gke_release_channel = "STABLE"  # or REGULAR, RAPID
```

## Security Features

- ✅ Private GKE cluster with no public nodes
- ✅ Cloud NAT for outbound traffic (no node external IPs)
- ✅ IAP for bastion SSH access (no external IPs)
- ✅ Workload Identity for pod authentication
- ✅ Shielded VMs with Secure Boot
- ✅ Network policies enabled (Calico)
- ✅ Master authorized networks
- ✅ Least-privilege service accounts
- ✅ OS Login enabled on bastion

## Cost Optimization

### Development

The dev environment is optimized for cost:
- Zonal cluster (free control plane)
- Preemptible nodes (80% cheaper)
- Smaller machine types
- Lower node count

### Staging/Production

To reduce costs without compromising too much:

1. **Scale down during off-hours**:
   ```bash
   # Scale to minimum
   kubectl scale deployment --all --replicas=1 -n your-namespace

   # Scale node pool
   gcloud container clusters resize CLUSTER_NAME --num-nodes=1
   ```

2. **Use committed use discounts** for production
3. **Enable cluster autoscaling** to scale down when idle
4. **Review and delete unused resources** regularly

## Disaster Recovery

### Backup Strategy

1. **Infrastructure**: Version-controlled in git
2. **Terraform state**: Stored in GCS with versioning
3. **Application config**: GitOps with ArgoCD/Flux
4. **Persistent data**: Regular PV snapshots or Velero backups

### Recovery Procedures

1. Checkout infrastructure code from git
2. Run `terraform init` and `terraform apply`
3. Restore application configuration via GitOps
4. Restore data from backups

## Troubleshooting

### Cannot SSH to Bastion

```bash
# Enable IAP API
gcloud services enable iap.googleapis.com

# Check IAP firewall rule
gcloud compute firewall-rules list --filter="name~iap"

# Verify you have IAP permissions
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:YOUR_EMAIL"
```

### Cannot Access GKE Master

1. Verify bastion IP is in master authorized networks
2. Check Cloud NAT is operational
3. Verify firewall rules allow traffic

### Pods Cannot Access Internet

1. Verify Cloud NAT is configured for private subnet
2. Check firewall rules allow egress
3. Verify DNS resolution works

### Terraform State Locked

```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

## Maintenance

### Updating Modules

When updating module versions:

1. Test in dev environment first
2. Run `terraform plan` carefully
3. Apply to staging for validation
4. Apply to production during maintenance window

### Updating Node Pools

Node pools auto-update based on release channel. To manually upgrade:

```bash
gcloud container clusters upgrade CLUSTER_NAME --region=REGION
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy to GKE
on:
  push:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: hashicorp/setup-terraform@v1
      - name: Terraform Init
        run: terraform init
        working-directory: environments/prod
      - name: Terraform Plan
        run: terraform plan
        working-directory: environments/prod
```

## Support

For issues or questions:
1. Check environment-specific README files
2. Review module documentation
3. Check GCP documentation
4. Open an issue in this repository

## License

MIT

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test changes in dev environment
4. Submit a pull request

## Cleanup

To destroy an environment:

```bash
cd environments/ENV
terraform destroy
```

⚠️ **Warning**: This will permanently delete all resources in that environment.
