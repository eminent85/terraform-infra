terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Backend configuration for dev environment
  backend "gcs" {
    bucket = "eminent-dev-terraform-state"
    prefix = "terraform/dev/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Network Module - VPC, Subnets, NAT, Firewall Rules
module "network" {
  source = "../../modules/gcp/network"

  project_id   = var.project_id
  network_name = var.network_name
  region       = var.region

  public_subnet_cidr    = var.public_subnet_cidr
  private_subnet_cidr   = var.private_subnet_cidr
  public_pods_cidr      = var.public_pods_cidr
  public_services_cidr  = var.public_services_cidr
  private_pods_cidr     = var.private_pods_cidr
  private_services_cidr = var.private_services_cidr
}

# Bastion Host Module
module "bastion" {
  source = "../../modules/gcp/compute"

  project_id      = var.project_id
  bastion_name    = var.bastion_name
  region          = var.region
  zone            = var.zone
  network_name    = module.network.network_name
  subnetwork_name = module.network.public_subnet_name

  machine_type       = var.bastion_machine_type
  assign_external_ip = var.bastion_assign_external_ip
  create_static_ip   = var.bastion_create_static_ip
  allowed_ssh_cidrs  = var.bastion_allowed_ssh_cidrs
  istio_version      = var.istio_version

  labels = var.labels

  depends_on = [module.network]
}

# GKE Cluster Module
module "gke" {
  source = "../../modules/gcp/gke"

  project_id             = var.project_id
  cluster_name           = var.cluster_name
  region                 = var.region
  regional               = var.gke_regional
  zone                   = var.gke_regional ? null : var.zone
  network_name           = module.network.network_name
  subnetwork_name        = module.network.private_subnet_name
  pods_ip_range_name     = module.network.pods_ip_range_name
  services_ip_range_name = module.network.services_ip_range_name

  master_ipv4_cidr_block  = var.gke_master_ipv4_cidr_block
  enable_private_endpoint = var.gke_enable_private_endpoint

  # Allow bastion to access the cluster
  master_authorized_networks = [
    {
      cidr_block   = "${module.bastion.bastion_internal_ip}/32"
      display_name = "bastion-host"
    },
    {
      cidr_block   = var.public_subnet_cidr
      display_name = "public-subnet"
    }
  ]

  # Node pool configuration
  node_count        = var.gke_node_count
  min_node_count    = var.gke_min_node_count
  max_node_count    = var.gke_max_node_count
  machine_type      = var.gke_machine_type
  disk_size_gb      = var.gke_disk_size_gb
  preemptible_nodes = var.gke_preemptible_nodes

  # Features
  enable_network_policy     = var.gke_enable_network_policy
  enable_gateway_api        = true
  create_ingress_ip         = true
  release_channel           = var.gke_release_channel
  enable_managed_prometheus = var.gke_enable_managed_prometheus

  # Registry service account for pulling containers and Helm charts
  create_registry_sa    = var.gke_create_registry_sa
  registry_sa_namespace = var.gke_registry_sa_namespace
  registry_sa_k8s_name  = var.gke_registry_sa_k8s_name

  cluster_labels = var.labels

  depends_on = [module.network]
}

# Workload Identity Service Account for GKE workloads
# Provides access to Artifact Registry, Cloud SQL, and Redis
module "workload_identity_sa" {
  source = "../../modules/gcp/service-accounts"

  project_id   = var.project_id
  account_id   = var.workload_identity_sa_id
  display_name = "GKE Workload Identity Service Account"
  description  = "Service account for GKE workloads with access to Artifact Registry, Cloud SQL, and Redis"

  # IAM roles for required GCP services
  roles = [
    "roles/artifactregistry.reader", # Pull Docker images and Helm charts
    "roles/artifactregistry.writer", # Push Docker images (if needed)
    "roles/cloudsql.client",         # Connect to Cloud SQL instances
    "roles/redis.editor",            # Access to Cloud Memorystore Redis
  ]

  # Workload Identity configuration
  enable_workload_identity   = true
  workload_identity_bindings = var.workload_identity_bindings

  depends_on = [module.gke]
}
