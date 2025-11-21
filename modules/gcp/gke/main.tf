# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.regional ? var.region : var.zone
  project  = var.project_id

  deletion_protection = false

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network_name
  subnetwork = var.subnetwork_name

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_ip_range_name
    services_secondary_range_name = var.services_ip_range_name
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block

    master_global_access_config {
      enabled = true
    }
  }

  # Master authorized networks - allow bastion access
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Enable Autopilot or Standard mode
  dynamic "cluster_autoscaling" {
    for_each = var.enable_autopilot ? [] : [1]
    content {
      enabled = var.enable_cluster_autoscaling
      dynamic "auto_provisioning_defaults" {
        for_each = var.enable_cluster_autoscaling ? [1] : []
        content {
          oauth_scopes = [
            "https://www.googleapis.com/auth/cloud-platform"
          ]
        }
      }
    }
  }

  # Addons
  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = !var.enable_network_policy
    }

    gce_persistent_disk_csi_driver_config {
      enabled = true
    }

    # Enable GKE Gateway API for Istio
    gke_backup_agent_config {
      enabled = var.enable_backup_agent
    }
  }

  # Network policy
  dynamic "network_policy" {
    for_each = var.enable_network_policy ? [1] : []
    content {
      enabled  = true
      provider = "CALICO"
    }
  }

  # Release channel
  release_channel {
    channel = var.release_channel
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_start_time
    }
  }

  # Binary authorization
  dynamic "binary_authorization" {
    for_each = var.enable_binary_authorization ? [1] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }

  # Logging and monitoring
  logging_config {
    enable_components = var.logging_components
  }

  monitoring_config {
    enable_components = var.monitoring_components
    managed_prometheus {
      enabled = var.enable_managed_prometheus
    }
  }

  # Gateway API config for Istio
  gateway_api_config {
    channel = var.enable_gateway_api ? "CHANNEL_STANDARD" : "CHANNEL_DISABLED"
  }

  # Resource labels
  resource_labels = var.cluster_labels

  lifecycle {
    ignore_changes = [
      # Ignore changes to node pool since it's removed after creation
      initial_node_count,
    ]
  }
}

# Separately managed node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.regional ? var.region : var.zone
  cluster    = google_container_cluster.primary.name
  project    = var.project_id
  node_count = var.node_count

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = var.preemptible_nodes
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = var.service_account_email != "" ? var.service_account_email : null
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = var.node_labels
    tags   = var.node_tags

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Shielded instance config
    shielded_instance_config {
      enable_secure_boot          = var.enable_secure_boot
      enable_integrity_monitoring = var.enable_integrity_monitoring
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  upgrade_settings {
    max_surge       = var.max_surge
    max_unavailable = var.max_unavailable
  }
}

# Static IP for Istio Ingress Gateway
resource "google_compute_address" "istio_ingress_ip" {
  count   = var.create_ingress_ip ? 1 : 0
  name    = "${var.cluster_name}-istio-ingress-ip"
  region  = var.region
  project = var.project_id
}

# Service Account for pulling containers and Helm charts from Artifact Registry
resource "google_service_account" "registry_sa" {
  count        = var.create_registry_sa ? 1 : 0
  project      = var.project_id
  account_id   = "${var.cluster_name}-registry-sa"
  display_name = "GKE Registry Service Account for ${var.cluster_name}"
  description  = "Service account for pulling containers and Helm charts from Artifact Registry"
}

# Grant Artifact Registry Reader role to the service account
resource "google_project_iam_member" "registry_sa_artifact_registry_reader" {
  count   = var.create_registry_sa ? 1 : 0
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.registry_sa[0].email}"
}

# Workload Identity binding - allows Kubernetes service account to impersonate the GCP service account
resource "google_service_account_iam_member" "registry_sa_workload_identity" {
  count              = var.create_registry_sa ? 1 : 0
  service_account_id = google_service_account.registry_sa[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.registry_sa_namespace}/${var.registry_sa_k8s_name}]"
}
