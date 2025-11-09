project_id       = "${PROJECT_ID}"
region           = "${REGION}"
zone             = "${ZONE}"
environment_name = "${ENVIRONMENT_NAME}"

# Cluster configuration
regional_cluster      = false
use_preemptible_nodes = true
machine_type          = "${MACHINE_TYPE}"
disk_size_gb          = 50
initial_node_count    = ${INITIAL_NODE_COUNT}
min_node_count        = ${MIN_NODE_COUNT}
max_node_count        = ${MAX_NODE_COUNT}

# Networking
enable_private_endpoint = false
master_authorized_networks = [
  {
    cidr_block   = "0.0.0.0/0"
    display_name = "github-actions"
  }
]

# Features (minimal for ephemeral)
enable_network_policy     = false
enable_managed_prometheus = false
enable_gateway_api        = false

# Bastion
create_bastion = ${CREATE_BASTION}

# Workload Identity
create_test_service_account = true
test_k8s_namespace          = "default"
test_k8s_sa_name            = "app-sa"

# Labels for tracking and cleanup
additional_labels = {
  ephemeral       = "true"
  created_by      = "github-actions"
  workflow_run_id = "${WORKFLOW_RUN_ID}"
  source_repo     = "${SOURCE_REPO}"
}
