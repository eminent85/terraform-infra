# GCP Project Configuration
project_id = "your-gcp-project-id"
region     = "us-central1"
zone       = "us-central1-a"

# Environment Naming
# Use dynamic names for CI/CD pipelines:
# - environment_name = "test-pr-${PR_NUMBER}"
# - environment_name = "test-commit-${SHORT_SHA}"
# - environment_name = "test-branch-${BRANCH_NAME}"
environment_name = "ephemeral-test"

# Network Configuration (defaults are usually fine)
# public_subnet_cidr  = "10.0.0.0/24"
# private_subnet_cidr = "10.0.1.0/24"
# public_pods_cidr     = "10.4.0.0/16"
# public_services_cidr = "10.8.0.0/20"
# private_pods_cidr     = "10.12.0.0/16"
# private_services_cidr = "10.16.0.0/20"

# GKE Configuration
regional_cluster = false # Set to true for HA, false for cost savings
# master_ipv4_cidr_block = "172.16.0.0/28"
enable_private_endpoint = false # Set to true if accessing only from within GCP

# Cost Optimization
use_preemptible_nodes = true # Recommended for ephemeral environments
machine_type          = "e2-medium"
disk_size_gb          = 50

# Autoscaling
initial_node_count = 1
min_node_count     = 1
max_node_count     = 3

# Release Channel
release_channel = "REGULAR" # RAPID, REGULAR, or STABLE

# Features (minimal for cost savings)
enable_network_policy     = false
enable_managed_prometheus = false
enable_gateway_api        = false

# Master Authorized Networks
# Uncomment and configure to restrict access to GKE master
# master_authorized_networks = [
#   {
#     cidr_block   = "0.0.0.0/0"
#     display_name = "Allow all (for CI/CD testing)"
#   }
# ]

# Additional Labels
additional_labels = {
  team        = "platform"
  cost-center = "engineering"
  automated   = "true"
}

# Bastion Configuration (for debugging failed tests)
create_bastion       = false # Set to true if you need to debug
bastion_external_ip  = false # Use IAP instead
bastion_machine_type = "e2-micro"
# bastion_allowed_cidrs = ["YOUR_IP/32"] # Only needed if bastion_external_ip = true

# Workload Identity
create_test_service_account = true
test_k8s_namespace          = "default"
test_k8s_sa_name            = "test-sa"

# IAM Roles for Test Service Account
test_sa_roles = [
  "roles/logging.logWriter",
  "roles/monitoring.metricWriter",
  # Add additional roles as needed for your tests
  # "roles/storage.objectViewer",
  # "roles/cloudsql.client",
]
