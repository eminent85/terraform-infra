# STAGING Environment Configuration
# Balanced settings - production-like but smaller scale

# Project Configuration
region = "us-central1"
zone   = "us-central1-a"

# Labels to apply to all resources
labels = {
  environment = "staging"
  managed_by  = "terraform"
  project     = "gke-infrastructure"
  cost_center = "staging"
}

# Network Configuration
network_name        = "gke-vpc-staging"
public_subnet_cidr  = "10.20.1.0/24"
private_subnet_cidr = "10.20.2.0/24"

# GKE Pod and Service IP Ranges
public_pods_cidr      = "10.21.0.0/16"
public_services_cidr  = "10.22.0.0/16"
private_pods_cidr     = "10.23.0.0/16"
private_services_cidr = "10.24.0.0/16"

# Bastion Configuration
bastion_name               = "gke-bastion-staging"
bastion_machine_type       = "e2-small"
bastion_assign_external_ip = false # Use IAP for SSH access
bastion_create_static_ip   = false

# Istio Configuration
istio_version = "1.20.2"

# GKE Cluster Configuration - Regional for higher availability
cluster_name                = "gke-cluster-staging"
gke_regional                = true # Regional cluster for better availability
gke_master_ipv4_cidr_block  = "172.17.0.0/28"
gke_enable_private_endpoint = false

# GKE Node Pool Configuration - Standard nodes, moderate size
gke_node_count        = 1
gke_min_node_count    = 1
gke_max_node_count    = 5
gke_machine_type      = "e2-standard-2" # Mid-size instance
gke_disk_size_gb      = 75              # Medium disk size
gke_preemptible_nodes = false           # Regular nodes for stability

# GKE Features
gke_enable_network_policy     = true
gke_release_channel           = "REGULAR" # Balanced release channel
gke_enable_managed_prometheus = false     # Can enable if monitoring needed
