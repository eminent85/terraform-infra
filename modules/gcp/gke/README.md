# GCP GKE Module

This module creates a Google Kubernetes Engine (GKE) cluster with support for Istio ingress gateway and private cluster configuration.

## Features

- VPC-native cluster with private nodes
- Configurable regional or zonal deployment
- Separate node pool with autoscaling
- Workload Identity enabled
- Gateway API support for Istio
- Static IP for Istio ingress gateway
- Private cluster with optional authorized networks
- Cloud NAT for outbound connectivity from private nodes
- Security features: Secure Boot, Integrity Monitoring
- Managed logging and monitoring

## Usage

```hcl
module "gke" {
  source = "./modules/gcp/gke"

  project_id                = "my-gcp-project"
  cluster_name              = "my-gke-cluster"
  region                    = "us-central1"
  network_name              = module.network.network_name
  subnetwork_name           = module.network.private_subnet_name
  pods_ip_range_name        = module.network.pods_ip_range_name
  services_ip_range_name    = module.network.services_ip_range_name

  master_ipv4_cidr_block    = "172.16.0.0/28"
  enable_private_endpoint   = false

  master_authorized_networks = [
    {
      cidr_block   = "10.0.1.0/24"  # Bastion subnet
      display_name = "bastion-subnet"
    }
  ]

  # Node pool configuration
  machine_type    = "e2-standard-4"
  min_node_count  = 1
  max_node_count  = 5

  # Enable Gateway API for Istio
  enable_gateway_api = true
  create_ingress_ip  = true
}
```

## Connecting to the Cluster

### From Bastion Host
```bash
gcloud container clusters get-credentials CLUSTER_NAME --region REGION --project PROJECT_ID
```

### Installing Istio
After cluster creation, install Istio with the Ingress Gateway:

```bash
# Install Istio
istioctl install --set profile=default -y

# Create Istio Ingress Gateway with static IP
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: istio-ingressgateway
  namespace: istio-system
spec:
  type: LoadBalancer
  loadBalancerIP: <ISTIO_INGRESS_IP>  # From module output
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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_id | GCP Project ID | string | n/a | yes |
| cluster_name | Name of the GKE cluster | string | n/a | yes |
| region | GCP region for the cluster | string | n/a | yes |
| network_name | Name of the VPC network | string | n/a | yes |
| subnetwork_name | Name of the subnetwork | string | n/a | yes |
| pods_ip_range_name | Name of the secondary IP range for pods | string | n/a | yes |
| services_ip_range_name | Name of the secondary IP range for services | string | n/a | yes |
| master_ipv4_cidr_block | The IP range in CIDR notation for the GKE master | string | "172.16.0.0/28" | no |
| enable_private_endpoint | Whether the master's internal IP address is used as the cluster endpoint | bool | false | no |
| master_authorized_networks | List of master authorized networks | list(object) | [] | no |
| machine_type | Machine type for the node pool | string | "e2-medium" | no |
| min_node_count | Minimum number of nodes per zone | number | 1 | no |
| max_node_count | Maximum number of nodes per zone | number | 3 | no |
| enable_gateway_api | Enable Gateway API for Istio | bool | true | no |
| create_ingress_ip | Whether to create a static IP for Istio ingress gateway | bool | true | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | The name of the GKE cluster |
| cluster_endpoint | The IP address of the cluster master |
| cluster_ca_certificate | The public certificate for the cluster |
| istio_ingress_ip | Static IP address for Istio ingress gateway |
