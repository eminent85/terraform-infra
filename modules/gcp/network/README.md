# GCP Network Module

This module creates a VPC network with public and private subnets, Cloud NAT, and firewall rules for a GKE cluster deployment.

## Features

- VPC network with custom subnets
- Public and private subnets with secondary IP ranges for GKE pods and services
- Cloud Router and Cloud NAT for private subnet outbound connectivity
- Firewall rules for:
  - IAP SSH access to bastion hosts
  - Internal communication between subnets and pods
  - GCP load balancer health checks

## Usage

```hcl
module "network" {
  source = "./modules/gcp/network"

  project_id   = "my-gcp-project"
  network_name = "my-vpc"
  region       = "us-central1"

  public_subnet_cidr     = "10.0.1.0/24"
  private_subnet_cidr    = "10.0.2.0/24"
  public_pods_cidr       = "10.1.0.0/16"
  public_services_cidr   = "10.2.0.0/16"
  private_pods_cidr      = "10.3.0.0/16"
  private_services_cidr  = "10.4.0.0/16"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_id | GCP Project ID | string | n/a | yes |
| network_name | Name of the VPC network | string | n/a | yes |
| region | GCP region for the network resources | string | n/a | yes |
| public_subnet_cidr | CIDR range for the public subnet | string | "10.0.1.0/24" | no |
| private_subnet_cidr | CIDR range for the private subnet | string | "10.0.2.0/24" | no |
| public_pods_cidr | Secondary CIDR range for GKE pods in public subnet | string | "10.1.0.0/16" | no |
| public_services_cidr | Secondary CIDR range for GKE services in public subnet | string | "10.2.0.0/16" | no |
| private_pods_cidr | Secondary CIDR range for GKE pods in private subnet | string | "10.3.0.0/16" | no |
| private_services_cidr | Secondary CIDR range for GKE services in private subnet | string | "10.4.0.0/16" | no |

## Outputs

| Name | Description |
|------|-------------|
| network_id | The ID of the VPC network |
| network_name | The name of the VPC network |
| public_subnet_id | The ID of the public subnet |
| private_subnet_id | The ID of the private subnet |
| pods_ip_range_name | The name of the secondary IP range for pods |
| services_ip_range_name | The name of the secondary IP range for services |
