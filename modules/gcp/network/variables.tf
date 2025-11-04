variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "region" {
  description = "GCP region for the network resources"
  type        = string
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
