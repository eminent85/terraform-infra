# Network Outputs
output "network_name" {
  description = "Name of the VPC network"
  value       = module.network.network_name
}

output "network_id" {
  description = "ID of the VPC network"
  value       = module.network.network_id
}

output "public_subnet_name" {
  description = "Name of the public subnet"
  value       = module.network.public_subnet_name
}

output "private_subnet_name" {
  description = "Name of the private subnet"
  value       = module.network.private_subnet_name
}

# GKE Cluster Outputs
output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the GKE cluster"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate for the GKE cluster"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "Location (region or zone) of the GKE cluster"
  value       = module.gke.cluster_location
}

output "get_credentials_command" {
  description = "Command to get GKE credentials"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.project_id}"
}

# Bastion Outputs
output "bastion_name" {
  description = "Name of the bastion instance"
  value       = var.create_bastion ? module.bastion[0].bastion_instance_name : null
}

output "bastion_internal_ip" {
  description = "Internal IP of the bastion instance"
  value       = var.create_bastion ? module.bastion[0].bastion_internal_ip : null
}

output "bastion_external_ip" {
  description = "External IP of the bastion instance"
  value       = var.create_bastion ? module.bastion[0].bastion_external_ip : null
}

output "bastion_ssh_command" {
  description = "Command to SSH to the bastion via IAP"
  value       = var.create_bastion ? "gcloud compute ssh ${module.bastion[0].bastion_instance_name} --zone=${var.zone} --tunnel-through-iap --project=${var.project_id}" : null
}

# Service Account Outputs
output "test_service_account_email" {
  description = "Email of the test workload service account"
  value       = var.create_test_service_account ? google_service_account.test_workload_sa[0].email : null
}

output "test_service_account_name" {
  description = "Name of the test workload service account"
  value       = var.create_test_service_account ? google_service_account.test_workload_sa[0].name : null
}

# Quick Start Commands
output "quick_start_commands" {
  description = "Quick start commands for using this environment"
  value = <<-EOT
    # Get GKE credentials:
    ${module.gke.cluster_location != "" ? "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.project_id}" : ""}

    # Verify cluster access:
    kubectl get nodes

    # Create test namespace and service account (if using Workload Identity):
    kubectl create namespace ${var.test_k8s_namespace}
    kubectl create serviceaccount ${var.test_k8s_sa_name} -n ${var.test_k8s_namespace}
    kubectl annotate serviceaccount ${var.test_k8s_sa_name} -n ${var.test_k8s_namespace} iam.gke.io/gcp-service-account=${var.create_test_service_account ? google_service_account.test_workload_sa[0].email : "SERVICE_ACCOUNT_EMAIL"}
    ${var.create_bastion ? "\n    # SSH to bastion (for debugging):\n    gcloud compute ssh ${module.bastion[0].bastion_instance_name} --zone=${var.zone} --tunnel-through-iap --project=${var.project_id}" : ""}
  EOT
}
