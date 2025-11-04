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

variable "environment_name" {
  description = "Name prefix for ephemeral environment (e.g., test-pr-123, test-commit-abc)"
  type        = string
  default     = "ephemeral"
}

# Network Configuration
variable "public_subnet_cidr" {
  description = "CIDR range for public subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR range for private subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_pods_cidr" {
  description = "CIDR range for GKE pods in public subnet"
  type        = string
  default     = "10.4.0.0/16"
}

variable "public_services_cidr" {
  description = "CIDR range for GKE services in public subnet"
  type        = string
  default     = "10.8.0.0/20"
}

variable "private_pods_cidr" {
  description = "CIDR range for GKE pods in private subnet"
  type        = string
  default     = "10.12.0.0/16"
}

variable "private_services_cidr" {
  description = "CIDR range for GKE services in private subnet"
  type        = string
  default     = "10.16.0.0/20"
}

# GKE Configuration
variable "regional_cluster" {
  description = "Create a regional cluster (true) or zonal cluster (false)"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for GKE master nodes"
  type        = string
  default     = "172.16.0.0/28"
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for GKE master"
  type        = bool
  default     = false
}

variable "use_preemptible_nodes" {
  description = "Use preemptible nodes for cost savings (recommended for ephemeral environments)"
  type        = bool
  default     = true
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "disk_size_gb" {
  description = "Disk size in GB for GKE nodes"
  type        = number
  default     = 50
}

variable "initial_node_count" {
  description = "Initial number of nodes per zone"
  type        = number
  default     = 1
}

variable "min_node_count" {
  description = "Minimum number of nodes per zone for autoscaling"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes per zone for autoscaling"
  type        = number
  default     = 3
}

variable "release_channel" {
  description = "GKE release channel (RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "logging_components" {
  description = "GKE logging components to enable"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

variable "monitoring_components" {
  description = "GKE monitoring components to enable"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS"]
}

variable "enable_network_policy" {
  description = "Enable Kubernetes Network Policy"
  type        = bool
  default     = false
}

variable "enable_managed_prometheus" {
  description = "Enable GKE managed Prometheus"
  type        = bool
  default     = false
}

variable "enable_gateway_api" {
  description = "Enable Gateway API for Istio"
  type        = bool
  default     = false
}

variable "master_authorized_networks" {
  description = "List of CIDR blocks allowed to access the GKE master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "additional_labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}

# Bastion Configuration
variable "create_bastion" {
  description = "Create a bastion host for debugging"
  type        = bool
  default     = false
}

variable "bastion_external_ip" {
  description = "Assign external IP to bastion"
  type        = bool
  default     = false
}

variable "bastion_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to bastion"
  type        = list(string)
  default     = []
}

variable "bastion_machine_type" {
  description = "Machine type for bastion host"
  type        = string
  default     = "e2-micro"
}

# Workload Identity Configuration
variable "create_test_service_account" {
  description = "Create a service account for test workloads"
  type        = bool
  default     = true
}

variable "test_sa_roles" {
  description = "IAM roles to grant to test service account"
  type        = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ]
}

variable "test_k8s_namespace" {
  description = "Kubernetes namespace for test workloads"
  type        = string
  default     = "default"
}

variable "test_k8s_sa_name" {
  description = "Kubernetes service account name for test workloads"
  type        = string
  default     = "test-sa"
}
