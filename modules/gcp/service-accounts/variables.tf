variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "account_id" {
  description = "The service account ID (will be used as the account_id in GCP)"
  type        = string
}

variable "display_name" {
  description = "Display name for the service account"
  type        = string
  default     = ""
}

variable "description" {
  description = "Description for the service account"
  type        = string
  default     = ""
}

variable "roles" {
  description = "List of IAM roles to grant to the service account at the project level"
  type        = list(string)
  default     = []
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity binding for GKE"
  type        = bool
  default     = false
}

variable "workload_identity_namespace" {
  description = "Kubernetes namespace for Workload Identity binding"
  type        = string
  default     = "default"
}

variable "workload_identity_sa_name" {
  description = "Kubernetes service account name for Workload Identity binding"
  type        = string
  default     = ""
}
