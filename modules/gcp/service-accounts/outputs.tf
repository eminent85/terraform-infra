output "email" {
  description = "Email address of the service account"
  value       = google_service_account.service_account.email
}

output "name" {
  description = "Fully qualified name of the service account"
  value       = google_service_account.service_account.name
}

output "id" {
  description = "ID of the service account"
  value       = google_service_account.service_account.id
}

output "unique_id" {
  description = "Unique ID of the service account"
  value       = google_service_account.service_account.unique_id
}

output "member" {
  description = "IAM member string for the service account (serviceAccount:email)"
  value       = "serviceAccount:${google_service_account.service_account.email}"
}
