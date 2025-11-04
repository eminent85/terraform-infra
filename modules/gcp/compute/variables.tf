variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "bastion_name" {
  description = "Name of the bastion instance"
  type        = string
  default     = "bastion"
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone for the bastion instance"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnetwork_name" {
  description = "Name of the subnetwork"
  type        = string
}

variable "machine_type" {
  description = "Machine type for the bastion instance"
  type        = string
  default     = "e2-small"
}

variable "image" {
  description = "Boot disk image for the bastion instance"
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Boot disk type (pd-standard, pd-ssd, pd-balanced)"
  type        = string
  default     = "pd-balanced"
}

variable "assign_external_ip" {
  description = "Whether to assign an external IP to the bastion"
  type        = bool
  default     = false
}

variable "create_static_ip" {
  description = "Whether to create a static external IP (only if assign_external_ip is true)"
  type        = bool
  default     = false
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH to the bastion (only used if assign_external_ip is true)"
  type        = list(string)
  default     = []
}

variable "additional_tags" {
  description = "Additional network tags for the bastion instance"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to the bastion instance"
  type        = map(string)
  default     = {}
}

variable "additional_metadata" {
  description = "Additional metadata for the bastion instance"
  type        = map(string)
  default     = {}
}

variable "enable_secure_boot" {
  description = "Enable secure boot for the bastion instance"
  type        = bool
  default     = true
}

variable "enable_integrity_monitoring" {
  description = "Enable integrity monitoring for the bastion instance"
  type        = bool
  default     = true
}

variable "istio_version" {
  description = "Version of Istio to install on bastion"
  type        = string
  default     = "1.20.2"
}
