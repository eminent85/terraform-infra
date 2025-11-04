# GCP Compute Module (Bastion)

This module creates a bastion host (jump box) for accessing GKE clusters and other private resources.

## Features

- Bastion VM with IAM service account
- OS Login enabled for SSH access
- Pre-installed tools: kubectl, gcloud, helm, istioctl, fluxcdcli
- Optional external IP with firewall rules
- IAP (Identity-Aware Proxy) SSH support by default
- Shielded VM with Secure Boot and Integrity Monitoring
- Automated startup script for tool installation

## Usage

### With IAP (Recommended - No External IP)
```hcl
module "bastion" {
  source = "./modules/gcp/compute"

  project_id      = "my-gcp-project"
  bastion_name    = "bastion"
  region          = "us-central1"
  zone            = "us-central1-a"
  network_name    = module.network.network_name
  subnetwork_name = module.network.public_subnet_name

  # No external IP - use IAP for SSH
  assign_external_ip = false

  machine_type = "e2-small"
}
```

### With External IP
```hcl
module "bastion" {
  source = "./modules/gcp/compute"

  project_id      = "my-gcp-project"
  bastion_name    = "bastion"
  region          = "us-central1"
  zone            = "us-central1-a"
  network_name    = module.network.network_name
  subnetwork_name = module.network.public_subnet_name

  assign_external_ip = true
  create_static_ip   = true
  allowed_ssh_cidrs  = ["YOUR_IP/32"]

  machine_type = "e2-small"
}
```

## Connecting to the Bastion

### Using IAP (No External IP Required)
```bash
# SSH via IAP
gcloud compute ssh bastion --zone=us-central1-a --tunnel-through-iap

# Port forwarding via IAP
gcloud compute start-iap-tunnel bastion 22 --local-host-port=localhost:2222 --zone=us-central1-a
```

### Using External IP
```bash
# Direct SSH (if external IP is assigned and your IP is whitelisted)
ssh USERNAME@EXTERNAL_IP
```

## Pre-installed Tools

The bastion comes with the following tools pre-installed:
- `kubectl` - Kubernetes command-line tool
- `gcloud` - Google Cloud SDK
- `helm` - Kubernetes package manager
- `istioctl` - Istio service mesh CLI
- `git` - Version control
- `jq` - JSON processor
- `vim` - Text editor

## Connecting to GKE from Bastion

```bash
# SSH to bastion
gcloud compute ssh bastion --zone=us-central1-a --tunnel-through-iap

# Get GKE credentials
gcloud container clusters get-credentials CLUSTER_NAME --region REGION

# Verify connection
kubectl get nodes
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_id | GCP Project ID | string | n/a | yes |
| bastion_name | Name of the bastion instance | string | "bastion" | no |
| region | GCP region | string | n/a | yes |
| zone | GCP zone for the bastion instance | string | n/a | yes |
| network_name | Name of the VPC network | string | n/a | yes |
| subnetwork_name | Name of the subnetwork | string | n/a | yes |
| machine_type | Machine type for the bastion instance | string | "e2-small" | no |
| assign_external_ip | Whether to assign an external IP | bool | false | no |
| allowed_ssh_cidrs | List of CIDR blocks allowed to SSH (if external IP) | list(string) | [] | no |
| istio_version | Version of Istio to install | string | "1.20.2" | no |

## Outputs

| Name | Description |
|------|-------------|
| bastion_instance_name | The name of the bastion instance |
| bastion_internal_ip | The internal IP address of the bastion |
| bastion_external_ip | The external IP address (if assigned) |
| bastion_service_account_email | The email of the bastion service account |
