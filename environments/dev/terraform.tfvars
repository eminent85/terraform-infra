# DEV Environment Configuration
# Cost-optimized settings for development

# Project Configuration
region     = "us-central1"
zone       = "us-central1-a"

# Labels to apply to all resources
labels = {
  environment = "dev"
  managed_by  = "terraform"
  project     = "gke-infrastructure"
  cost_center = "development"
}

# Network Configuration
network_name        = "gke-vpc-dev"
public_subnet_cidr  = "10.10.1.0/24"
private_subnet_cidr = "10.10.2.0/24"

# GKE Pod and Service IP Ranges
public_pods_cidr      = "10.11.0.0/16"
public_services_cidr  = "10.12.0.0/16"
private_pods_cidr     = "10.13.0.0/16"
private_services_cidr = "10.14.0.0/16"

# Bastion Configuration - Small instance for dev
bastion_name               = "gke-bastion-dev"
bastion_machine_type       = "e2-micro" # Smallest instance for cost savings
bastion_assign_external_ip = false      # Use IAP for SSH access
bastion_create_static_ip   = false

# Istio Configuration
istio_version = "1.20.2"

# GKE Cluster Configuration - Cost optimized
cluster_name                = "gke-cluster-dev"
gke_regional                = false # Zonal cluster for cost savings
gke_master_ipv4_cidr_block  = "172.16.0.0/28"
gke_enable_private_endpoint = false

# GKE Node Pool Configuration - Small, preemptible nodes
gke_node_count        = 1
gke_min_node_count    = 1
gke_max_node_count    = 3           # Lower max for dev
gke_machine_type      = "e2-medium" # Smaller instance type
gke_disk_size_gb      = 50          # Smaller disk
gke_preemptible_nodes = true        # Use preemptible nodes for cost savings

# GKE Features
gke_enable_network_policy     = true
gke_release_channel           = "RAPID" # Get latest features faster in dev
gke_enable_managed_prometheus = false   # Disabled to save costs
