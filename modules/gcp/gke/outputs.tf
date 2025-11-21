output "cluster_id" {
  description = "The ID of the GKE cluster"
  value       = google_container_cluster.primary.id
}

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "The IP address of the cluster master"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The public certificate that is the root of trust for the cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "The location (region or zone) of the cluster"
  value       = google_container_cluster.primary.location
}

output "node_pool_name" {
  description = "The name of the node pool"
  value       = google_container_node_pool.primary_nodes.name
}

output "istio_ingress_ip" {
  description = "Static IP address for Istio ingress gateway"
  value       = var.create_ingress_ip ? google_compute_address.istio_ingress_ip[0].address : null
}

output "istio_ingress_ip_name" {
  description = "Name of the static IP resource for Istio ingress gateway"
  value       = var.create_ingress_ip ? google_compute_address.istio_ingress_ip[0].name : null
}

output "workload_identity_pool" {
  description = "The workload identity pool for the cluster"
  value       = "${var.project_id}.svc.id.goog"
}

output "registry_sa_email" {
  description = "Email of the registry service account"
  value       = var.create_registry_sa ? google_service_account.registry_sa[0].email : null
}

output "registry_sa_annotation" {
  description = "Annotation value to add to Kubernetes service account for Workload Identity"
  value       = var.create_registry_sa ? google_service_account.registry_sa[0].email : null
}

output "registry_sa_k8s_namespace" {
  description = "Kubernetes namespace for the registry service account"
  value       = var.create_registry_sa ? var.registry_sa_namespace : null
}

output "registry_sa_k8s_name" {
  description = "Kubernetes service account name for registry access"
  value       = var.create_registry_sa ? var.registry_sa_k8s_name : null
}
