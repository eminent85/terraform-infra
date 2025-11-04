terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC Network for ephemeral environment
module "network" {
  source = "../../modules/gcp/network"

  project_id   = var.project_id
  network_name = "${var.environment_name}-vpc"
  region       = var.region

  # Smaller CIDR ranges for ephemeral environment
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr

  # Secondary ranges for GKE pods and services
  public_pods_cidr     = var.public_pods_cidr
  public_services_cidr = var.public_services_cidr

  private_pods_cidr     = var.private_pods_cidr
  private_services_cidr = var.private_services_cidr
}

# GKE Cluster for running tests
module "gke" {
  source = "../../modules/gcp/gke"

  project_id   = var.project_id
  cluster_name = "${var.environment_name}-cluster"
  region       = var.region
  zone         = var.zone
  regional     = var.regional_cluster

  network_name    = module.network.network_name
  subnetwork_name = module.network.private_subnet_name

  # Secondary IP ranges for pods and services
  pods_ip_range_name     = "gke-pods-private"
  services_ip_range_name = "gke-services-private"

  # Master configuration
  master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  enable_private_endpoint = var.enable_private_endpoint

  # Cost optimization: use preemptible nodes for ephemeral testing
  preemptible_nodes = var.use_preemptible_nodes
  machine_type      = var.machine_type
  disk_size_gb      = var.disk_size_gb
  disk_type         = "pd-standard"

  # Autoscaling for dynamic workloads
  node_count     = var.initial_node_count
  min_node_count = var.min_node_count
  max_node_count = var.max_node_count

  # Release channel
  release_channel = var.release_channel

  # Logging and monitoring (minimal for ephemeral)
  logging_components    = var.logging_components
  monitoring_components = var.monitoring_components

  # Enable features as needed
  enable_network_policy     = var.enable_network_policy
  enable_managed_prometheus = var.enable_managed_prometheus
  enable_gateway_api        = var.enable_gateway_api
  enable_backup_agent       = false

  # Labels for resource management
  cluster_labels = merge(
    var.additional_labels,
    {
      environment = "ephemeral"
      purpose     = "testing"
      managed-by  = "terraform"
    }
  )

  # Master authorized networks - allow access from CI/CD and bastion
  master_authorized_networks = var.master_authorized_networks

  depends_on = [module.network]
}

# Optional: Bastion host for debugging test failures
module "bastion" {
  count  = var.create_bastion ? 1 : 0
  source = "../../modules/gcp/compute"

  project_id      = var.project_id
  bastion_name    = "${var.environment_name}-bastion"
  region          = var.region
  zone            = var.zone
  network_name    = module.network.network_name
  subnetwork_name = module.network.public_subnet_name

  # Use IAP for SSH access (no external IP needed)
  assign_external_ip = var.bastion_external_ip
  allowed_ssh_cidrs  = var.bastion_allowed_cidrs

  # Small machine type for cost savings
  machine_type = var.bastion_machine_type

  depends_on = [module.network]
}

# Workload Identity binding for test service accounts
resource "google_service_account" "test_workload_sa" {
  count = var.create_test_service_account ? 1 : 0

  account_id   = "${var.environment_name}-test-sa"
  display_name = "Service Account for ${var.environment_name} test workloads"
  project      = var.project_id
}

resource "google_project_iam_member" "test_workload_permissions" {
  for_each = var.create_test_service_account ? toset(var.test_sa_roles) : toset([])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.test_workload_sa[0].email}"
}

resource "google_service_account_iam_member" "workload_identity_binding" {
  count = var.create_test_service_account ? 1 : 0

  service_account_id = google_service_account.test_workload_sa[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.test_k8s_namespace}/${var.test_k8s_sa_name}]"
}
