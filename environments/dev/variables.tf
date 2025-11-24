# Project Configuration
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for zonal resources"
  type        = string
  default     = "us-central1-a"
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

# Network Configuration
variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "gke-vpc"
}

variable "public_subnet_cidr" {
  description = "CIDR range for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR range for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "public_pods_cidr" {
  description = "Secondary CIDR range for GKE pods in public subnet"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_services_cidr" {
  description = "Secondary CIDR range for GKE services in public subnet"
  type        = string
  default     = "10.2.0.0/16"
}

variable "private_pods_cidr" {
  description = "Secondary CIDR range for GKE pods in private subnet"
  type        = string
  default     = "10.3.0.0/16"
}

variable "private_services_cidr" {
  description = "Secondary CIDR range for GKE services in private subnet"
  type        = string
  default     = "10.4.0.0/16"
}

# Bastion Configuration
variable "bastion_name" {
  description = "Name of the bastion instance"
  type        = string
  default     = "gke-bastion"
}

variable "bastion_machine_type" {
  description = "Machine type for the bastion instance"
  type        = string
  default     = "e2-small"
}

variable "bastion_assign_external_ip" {
  description = "Whether to assign an external IP to the bastion"
  type        = bool
  default     = false
}

variable "bastion_create_static_ip" {
  description = "Whether to create a static external IP for bastion"
  type        = bool
  default     = false
}

variable "bastion_allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH to the bastion"
  type        = list(string)
  default     = []
}

variable "istio_version" {
  description = "Version of Istio to install on bastion"
  type        = string
  default     = "1.20.2"
}

# GKE Configuration
variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "gke-cluster"
}

variable "gke_regional" {
  description = "Whether to create a regional cluster"
  type        = bool
  default     = true
}

variable "gke_master_ipv4_cidr_block" {
  description = "CIDR block for GKE master"
  type        = string
  default     = "172.16.0.0/28"
}

variable "gke_enable_private_endpoint" {
  description = "Whether the master's internal IP is used as cluster endpoint"
  type        = bool
  default     = false
}

variable "gke_node_count" {
  description = "Initial number of nodes per zone"
  type        = number
  default     = 1
}

variable "gke_min_node_count" {
  description = "Minimum number of nodes per zone"
  type        = number
  default     = 1
}

variable "gke_max_node_count" {
  description = "Maximum number of nodes per zone"
  type        = number
  default     = 5
}

variable "gke_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "gke_disk_size_gb" {
  description = "Disk size in GB for GKE nodes"
  type        = number
  default     = 100
}

variable "gke_preemptible_nodes" {
  description = "Whether to use preemptible nodes"
  type        = bool
  default     = false
}

variable "gke_enable_network_policy" {
  description = "Enable network policy for GKE"
  type        = bool
  default     = true
}

variable "gke_release_channel" {
  description = "Release channel for GKE (RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "gke_enable_managed_prometheus" {
  description = "Enable managed Prometheus monitoring"
  type        = bool
  default     = false
}

# Registry Service Account Configuration
variable "gke_create_registry_sa" {
  description = "Create a service account for pulling from Artifact Registry"
  type        = bool
  default     = false
}

variable "gke_registry_sa_namespace" {
  description = "Kubernetes namespace for the registry service account"
  type        = string
  default     = "default"
}

variable "gke_registry_sa_k8s_name" {
  description = "Kubernetes service account name that will use the GCP registry service account"
  type        = string
  default     = "registry-sa"
}

# Workload Identity Service Account Configuration
variable "workload_identity_sa_id" {
  description = "Service account ID for GKE workload identity"
  type        = string
  default     = "gke-workload-identity"
}

variable "workload_identity_bindings" {
  description = "List of Kubernetes namespace/service account pairs for workload identity bindings"
  type = list(object({
    namespace            = string
    service_account_name = string
  }))
  default = []
}
