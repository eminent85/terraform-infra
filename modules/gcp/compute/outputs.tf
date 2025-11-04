output "bastion_instance_id" {
  description = "The ID of the bastion instance"
  value       = google_compute_instance.bastion.instance_id
}

output "bastion_instance_name" {
  description = "The name of the bastion instance"
  value       = google_compute_instance.bastion.name
}

output "bastion_internal_ip" {
  description = "The internal IP address of the bastion instance"
  value       = google_compute_instance.bastion.network_interface[0].network_ip
}

output "bastion_external_ip" {
  description = "The external IP address of the bastion instance (if assigned)"
  value       = var.assign_external_ip ? google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip : null
}

output "bastion_static_ip" {
  description = "The static IP address of the bastion instance (if created)"
  value       = var.assign_external_ip && var.create_static_ip ? google_compute_address.bastion_ip[0].address : null
}

output "bastion_service_account_email" {
  description = "The email of the bastion service account"
  value       = google_service_account.bastion.email
}

output "bastion_zone" {
  description = "The zone of the bastion instance"
  value       = google_compute_instance.bastion.zone
}

output "bastion_self_link" {
  description = "The self-link of the bastion instance"
  value       = google_compute_instance.bastion.self_link
}
