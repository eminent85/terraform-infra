# Network Outputs
output "network_name" {
  description = "The name of the VPC network"
  value       = module.network.network_name
}

output "public_subnet_name" {
  description = "The name of the public subnet"
  value       = module.network.public_subnet_name
}

output "private_subnet_name" {
  description = "The name of the private subnet"
  value       = module.network.private_subnet_name
}

# Bastion Outputs
output "bastion_name" {
  description = "The name of the bastion instance"
  value       = module.bastion.bastion_instance_name
}

output "bastion_internal_ip" {
  description = "The internal IP address of the bastion"
  value       = module.bastion.bastion_internal_ip
}

output "bastion_external_ip" {
  description = "The external IP address of the bastion (if assigned)"
  value       = module.bastion.bastion_external_ip
}

output "bastion_connection_command" {
  description = "Command to SSH to the bastion via IAP"
  value       = "gcloud compute ssh ${module.bastion.bastion_instance_name} --zone=${module.bastion.bastion_zone} --tunnel-through-iap --project=${var.project_id}"
}

# GKE Outputs
output "gke_cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "The endpoint for the GKE cluster"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "gke_cluster_location" {
  description = "The location of the GKE cluster"
  value       = module.gke.cluster_location
}

output "istio_ingress_ip" {
  description = "The static IP address for Istio ingress gateway"
  value       = module.gke.istio_ingress_ip
}

output "get_credentials_command" {
  description = "Command to get GKE cluster credentials"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.project_id}"
}

# Workload Identity Outputs
output "workload_identity_sa_email" {
  description = "Email of the workload identity service account"
  value       = module.workload_identity_sa.email
}

output "workload_identity_bindings" {
  description = "List of Kubernetes namespace/service account bindings configured for workload identity"
  value       = module.workload_identity_sa.workload_identity_bindings
}

# Quick Start Instructions
output "quick_start" {
  description = "Quick start instructions"
  value       = <<-EOT

    === DEV Environment - Quick Start Guide ===

    1. Connect to bastion:
       ${module.bastion.bastion_external_ip != null ? "ssh to ${module.bastion.bastion_external_ip}" : "gcloud compute ssh ${module.bastion.bastion_instance_name} --zone=${module.bastion.bastion_zone} --tunnel-through-iap --project=${var.project_id}"}

    2. Get GKE credentials (from bastion):
       gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.project_id}

    3. Verify cluster access:
       kubectl get nodes

    4. Install Istio (from bastion):
       istioctl install --set profile=default -y

    5. Deploy Istio Ingress Gateway with static IP:
       kubectl apply -f - <<EOF
       apiVersion: v1
       kind: Service
       metadata:
         name: istio-ingressgateway
         namespace: istio-system
       spec:
         type: LoadBalancer
         loadBalancerIP: ${module.gke.istio_ingress_ip}
         selector:
           istio: ingressgateway
         ports:
         - name: http
           port: 80
           targetPort: 8080
         - name: https
           port: 443
           targetPort: 8443
       EOF

    Istio Ingress IP: ${module.gke.istio_ingress_ip}
    Environment: DEV

    === Workload Identity Setup ===

    6. Create Kubernetes service accounts with workload identity annotation:
       %{for binding in var.workload_identity_bindings~}
       kubectl create namespace ${binding.namespace} --dry-run=client -o yaml | kubectl apply -f -
       kubectl create serviceaccount ${binding.service_account_name} -n ${binding.namespace} --dry-run=client -o yaml | kubectl apply -f -
       kubectl annotate serviceaccount ${binding.service_account_name} \
         --namespace ${binding.namespace} \
         iam.gke.io/gcp-service-account=${module.workload_identity_sa.email} --overwrite
       %{endfor~}

    7. Use the service account in your deployments:
       spec:
         serviceAccountName: <service-account-name>

    The service account has access to:
    - Artifact Registry (read/write for Docker images and Helm charts)
    - Cloud SQL (client access)
    - Cloud Memorystore Redis (editor access)

    GCP Service Account: ${module.workload_identity_sa.email}

    Configured bindings:
    %{for binding in var.workload_identity_bindings~}
    - ${binding.namespace}/${binding.service_account_name}
    %{endfor~}
  EOT
}
