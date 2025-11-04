variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "region" {
  description = "GCP region for the cluster"
  type        = string
}

variable "zone" {
  description = "GCP zone for the cluster (used if regional is false)"
  type        = string
  default     = ""
}

variable "regional" {
  description = "Whether to create a regional cluster (true) or zonal cluster (false)"
  type        = bool
  default     = true
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnetwork_name" {
  description = "Name of the subnetwork"
  type        = string
}

variable "pods_ip_range_name" {
  description = "Name of the secondary IP range for pods"
  type        = string
}

variable "services_ip_range_name" {
  description = "Name of the secondary IP range for services"
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation for the GKE master"
  type        = string
  default     = "172.16.0.0/28"
}

variable "enable_private_endpoint" {
  description = "Whether the master's internal IP address is used as the cluster endpoint"
  type        = bool
  default     = false
}

variable "master_authorized_networks" {
  description = "List of master authorized networks"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "enable_autopilot" {
  description = "Enable Autopilot mode for GKE cluster"
  type        = bool
  default     = false
}

variable "enable_cluster_autoscaling" {
  description = "Enable cluster autoscaling"
  type        = bool
  default     = false
}

variable "enable_network_policy" {
  description = "Enable network policy addon"
  type        = bool
  default     = true
}

variable "enable_backup_agent" {
  description = "Enable GKE backup agent"
  type        = bool
  default     = false
}

variable "release_channel" {
  description = "Release channel for GKE cluster (RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "maintenance_start_time" {
  description = "Start time for daily maintenance window (HH:MM format)"
  type        = string
  default     = "03:00"
}

variable "enable_binary_authorization" {
  description = "Enable binary authorization"
  type        = bool
  default     = false
}

variable "logging_components" {
  description = "List of logging components to enable"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

variable "monitoring_components" {
  description = "List of monitoring components to enable"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS"]
}

variable "enable_managed_prometheus" {
  description = "Enable managed Prometheus monitoring"
  type        = bool
  default     = false
}

variable "enable_gateway_api" {
  description = "Enable Gateway API for Istio"
  type        = bool
  default     = true
}

variable "cluster_labels" {
  description = "Labels to apply to the cluster"
  type        = map(string)
  default     = {}
}

# Node pool variables
variable "node_count" {
  description = "Initial number of nodes per zone in the node pool"
  type        = number
  default     = 1
}

variable "min_node_count" {
  description = "Minimum number of nodes per zone in the node pool"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes per zone in the node pool"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Machine type for the node pool"
  type        = string
  default     = "e2-medium"
}

variable "disk_size_gb" {
  description = "Disk size in GB for node pool nodes"
  type        = number
  default     = 100
}

variable "disk_type" {
  description = "Disk type for node pool nodes (pd-standard, pd-ssd, pd-balanced)"
  type        = string
  default     = "pd-balanced"
}

variable "preemptible_nodes" {
  description = "Whether to use preemptible nodes"
  type        = bool
  default     = false
}

variable "service_account_email" {
  description = "Service account email for the node pool (uses default if not specified)"
  type        = string
  default     = ""
}

variable "node_labels" {
  description = "Labels to apply to nodes in the node pool"
  type        = map(string)
  default     = {}
}

variable "node_tags" {
  description = "Network tags to apply to nodes in the node pool"
  type        = list(string)
  default     = ["gke-node"]
}

variable "enable_secure_boot" {
  description = "Enable secure boot for nodes"
  type        = bool
  default     = true
}

variable "enable_integrity_monitoring" {
  description = "Enable integrity monitoring for nodes"
  type        = bool
  default     = true
}

variable "max_surge" {
  description = "Maximum number of nodes that can be created beyond current size during upgrade"
  type        = number
  default     = 1
}

variable "max_unavailable" {
  description = "Maximum number of nodes that can be unavailable during upgrade"
  type        = number
  default     = 0
}

variable "create_ingress_ip" {
  description = "Whether to create a static IP for Istio ingress gateway"
  type        = bool
  default     = true
}
