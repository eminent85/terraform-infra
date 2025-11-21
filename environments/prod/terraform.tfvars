# PRODUCTION Environment Configuration
# Production-grade settings with high availability and reliability

# Project Configuration
region = "us-central1"
zone   = "us-central1-a"

# Labels to apply to all resources
labels = {
  environment = "production"
  managed_by  = "terraform"
  project     = "gke-infrastructure"
  cost_center = "production"
}

# Network Configuration
network_name        = "gke-vpc-prod"
public_subnet_cidr  = "10.30.1.0/24"
private_subnet_cidr = "10.30.2.0/24"

# GKE Pod and Service IP Ranges
public_pods_cidr      = "10.31.0.0/16"
public_services_cidr  = "10.32.0.0/16"
private_pods_cidr     = "10.33.0.0/16"
private_services_cidr = "10.34.0.0/16"

# Bastion Configuration
bastion_name               = "gke-bastion-prod"
bastion_machine_type       = "e2-small"
bastion_assign_external_ip = false # Use IAP for SSH access
bastion_create_static_ip   = false

# Istio Configuration
istio_version = "1.20.2"

# GKE Cluster Configuration - Production grade
cluster_name                = "gke-cluster-prod"
gke_regional                = true # Regional cluster for HA
gke_master_ipv4_cidr_block  = "172.18.0.0/28"
gke_enable_private_endpoint = false

# GKE Node Pool Configuration - Production sized
gke_node_count        = 2               # Start with 2 nodes per zone (6 total)
gke_min_node_count    = 2               # Minimum 2 per zone for HA
gke_max_node_count    = 10              # Allow scaling up to 10 per zone
gke_machine_type      = "e2-standard-4" # Production-grade instance
gke_disk_size_gb      = 100             # Full disk size
gke_preemptible_nodes = false           # Standard nodes for reliability

# GKE Features
gke_enable_network_policy     = true
gke_release_channel           = "REGULAR" # Stable releases
gke_enable_managed_prometheus = true      # Full monitoring for production
