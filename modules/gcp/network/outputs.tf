output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "network_self_link" {
  description = "The self-link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = google_compute_subnetwork.public_subnet.id
}

output "public_subnet_name" {
  description = "The name of the public subnet"
  value       = google_compute_subnetwork.public_subnet.name
}

output "public_subnet_self_link" {
  description = "The self-link of the public subnet"
  value       = google_compute_subnetwork.public_subnet.self_link
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = google_compute_subnetwork.private_subnet.id
}

output "private_subnet_name" {
  description = "The name of the private subnet"
  value       = google_compute_subnetwork.private_subnet.name
}

output "private_subnet_self_link" {
  description = "The self-link of the private subnet"
  value       = google_compute_subnetwork.private_subnet.self_link
}

output "pods_ip_range_name" {
  description = "The name of the secondary IP range for pods"
  value       = "gke-pods-private"
}

output "services_ip_range_name" {
  description = "The name of the secondary IP range for services"
  value       = "gke-services-private"
}

output "router_id" {
  description = "The ID of the Cloud Router"
  value       = google_compute_router.router.id
}

output "nat_id" {
  description = "The ID of the Cloud NAT"
  value       = google_compute_router_nat.nat.id
}
