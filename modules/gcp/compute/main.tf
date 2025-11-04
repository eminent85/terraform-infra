# Service Account for Bastion
resource "google_service_account" "bastion" {
  account_id   = "${var.bastion_name}-sa"
  display_name = "Service Account for ${var.bastion_name}"
  project      = var.project_id
}

# IAM roles for bastion service account
resource "google_project_iam_member" "bastion_gke_viewer" {
  project = var.project_id
  role    = "roles/container.viewer"
  member  = "serviceAccount:${google_service_account.bastion.email}"
}

resource "google_project_iam_member" "bastion_gke_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.bastion.email}"
}

resource "google_project_iam_member" "bastion_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.bastion.email}"
}

resource "google_project_iam_member" "bastion_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.bastion.email}"
}

# Bastion VM
resource "google_compute_instance" "bastion" {
  name         = var.bastion_name
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  tags = concat(["bastion"], var.additional_tags)

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size_gb
      type  = var.disk_type
    }
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.subnetwork_name

    # Only assign external IP if enabled
    dynamic "access_config" {
      for_each = var.assign_external_ip ? [1] : []
      content {
        # Ephemeral IP
      }
    }
  }

  metadata = merge(
    {
      enable-oslogin = "TRUE"
      # Startup script to install essential tools
      startup-script = <<-EOF
        #!/bin/bash
        set -e

        # Update package list
        apt-get update

        # Install kubectl
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl

        # Install gcloud components
        apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin

        # Install helm
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

        # Install istioctl
        curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${var.istio_version} sh -
        cd istio-${var.istio_version}
        cp bin/istioctl /usr/local/bin/
        cd ..
        rm -rf istio-${var.istio_version}

        # Install FluxCD CLI
        curl -s https://fluxcd.io/install.sh | sudo bash

        # Install useful tools
        apt-get install -y vim git jq

        echo "Bastion setup complete" | tee /var/log/bastion-setup.log
      EOF
    },
    var.additional_metadata
  )

  service_account {
    email  = google_service_account.bastion.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = var.enable_secure_boot
    enable_vtpm                 = true
    enable_integrity_monitoring = var.enable_integrity_monitoring
  }

  labels = var.labels

  # Allow stopping for updates
  allow_stopping_for_update = true

  lifecycle {
    ignore_changes = [
      # Ignore changes to metadata that may be updated by instance
      metadata["ssh-keys"],
    ]
  }
}

# Optional: Create a static IP for the bastion if external IP is assigned
resource "google_compute_address" "bastion_ip" {
  count   = var.assign_external_ip && var.create_static_ip ? 1 : 0
  name    = "${var.bastion_name}-ip"
  region  = var.region
  project = var.project_id
}

# Firewall rule to allow SSH from specific IPs (if external IPs are used)
resource "google_compute_firewall" "bastion_ssh_external" {
  count   = var.assign_external_ip && length(var.allowed_ssh_cidrs) > 0 ? 1 : 0
  name    = "${var.bastion_name}-allow-ssh-external"
  network = var.network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_cidrs
  target_tags   = ["bastion"]
}
