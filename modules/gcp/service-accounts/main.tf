# Service Account
resource "google_service_account" "service_account" {
  account_id   = var.account_id
  display_name = var.display_name != "" ? var.display_name : var.account_id
  description  = var.description
  project      = var.project_id
}

# IAM Role Bindings
resource "google_project_iam_member" "roles" {
  for_each = toset(var.roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

# Workload Identity Bindings (multiple namespaces)
locals {
  # Use the new bindings list if provided, otherwise fall back to single namespace/sa config
  workload_identity_bindings = length(var.workload_identity_bindings) > 0 ? var.workload_identity_bindings : (
    var.enable_workload_identity && var.workload_identity_sa_name != "" ? [
      {
        namespace            = var.workload_identity_namespace
        service_account_name = var.workload_identity_sa_name
      }
    ] : []
  )
}

resource "google_service_account_iam_member" "workload_identity_binding" {
  for_each = var.enable_workload_identity ? {
    for binding in local.workload_identity_bindings :
    "${binding.namespace}/${binding.service_account_name}" => binding
  } : {}

  service_account_id = google_service_account.service_account.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${each.value.namespace}/${each.value.service_account_name}]"
}
