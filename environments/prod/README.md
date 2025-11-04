# Production Environment

Production-grade GKE cluster configuration with high availability, security, and monitoring.

## Production Features

This environment is configured for production workloads with:

- ✅ **Regional cluster** with 3 control plane replicas across zones
- ✅ **High availability** with minimum 2 nodes per zone (6 total)
- ✅ **Standard nodes** for reliability (no preemptible)
- ✅ **Production-sized instances** (e2-standard-4)
- ✅ **Full disk capacity** (100GB per node)
- ✅ **Managed Prometheus** enabled for comprehensive monitoring
- ✅ **Network policies** for security
- ✅ **REGULAR release channel** for stable Kubernetes versions
- ✅ **Workload Identity** for secure pod authentication
- ✅ **Private nodes** with no external IPs
- ✅ **IAP access** for secure bastion connectivity

## Cost Estimate

Approximate costs for this production environment:
- GKE control plane (regional): ~$73/month
- 2x e2-standard-4 nodes per zone (6 total): ~$600/month
- 1x e2-small bastion: ~$12/month
- Managed Prometheus: ~$20/month
- Network egress: ~$20/month (variable)
- Load balancer: ~$18/month
- **Total: ~$743/month**

## High Availability

This configuration provides:

- **Control plane HA**: 3 replicas across zones (99.95% SLA)
- **Node HA**: Minimum 6 nodes across 3 zones
- **Automatic node repair**: Failed nodes are automatically replaced
- **Automatic upgrades**: Managed during maintenance windows
- **Pod distribution**: Spread across zones for resilience

## Usage

```bash
cd environments/prod

# Initialize
terraform init

# Plan (review carefully in production)
terraform plan

# Apply with approval
terraform apply

# IMPORTANT: Never run terraform destroy in production without proper approval
```

## Production Best Practices

### Before Deploying

1. ✅ Review all terraform plan changes carefully
2. ✅ Ensure state is stored in GCS backend (remote state)
3. ✅ Enable state locking to prevent concurrent modifications
4. ✅ Set up monitoring and alerting before deploying workloads
5. ✅ Configure backup strategies for critical data
6. ✅ Document disaster recovery procedures
7. ✅ Set up log aggregation and retention policies

### Change Management

1. **Always run terraform plan first** and review all changes
2. **Use workspaces or separate state files** for isolation
3. **Enable audit logging** for all GCP API calls
4. **Test changes in staging** before applying to production
5. **Schedule maintenance windows** for infrastructure changes
6. **Have rollback procedures** documented and tested

### Security Checklist

- ✅ Bastion has no external IP (IAP access only)
- ✅ GKE nodes have no external IPs
- ✅ Network policies are enabled
- ✅ Workload Identity is configured
- ✅ Master authorized networks are restricted
- ✅ Shielded GKE nodes with Secure Boot
- ✅ Binary authorization can be enabled if needed

## Monitoring and Observability

With Managed Prometheus enabled, you can:

```bash
# Query metrics using PromQL
kubectl port-forward -n gmp-system svc/frontend 9090:9090

# View metrics in Cloud Monitoring
# https://console.cloud.google.com/monitoring
```

## Disaster Recovery

### Backup Strategies

1. **Cluster configuration**: All IaC stored in git
2. **Application state**: Use Velero or GKE Backup for backups
3. **Persistent data**: Regular snapshots of PVs
4. **Terraform state**: Backed up in GCS with versioning enabled

### Recovery Procedures

1. Terraform can recreate infrastructure from state
2. Application deployments should be automated via CI/CD
3. Data restored from backups
4. DNS updated to point to new cluster

## Accessing the Cluster

```bash
# From your local machine (requires GCP authentication)
gcloud compute ssh gke-bastion-prod --zone=us-central1-a --tunnel-through-iap --project=your-project-id

# From bastion
gcloud container clusters get-credentials gke-cluster-prod --region=us-central1 --project=your-project-id
kubectl get nodes
```

## Scaling Guidance

### When to Scale Up

Monitor these metrics:
- CPU utilization consistently > 70%
- Memory utilization consistently > 80%
- Pod pending time increasing
- Request latency degradation

### Scaling Options

```hcl
# Increase max node count
gke_max_node_count = 15

# Upgrade machine type
gke_machine_type = "e2-standard-8"

# Add more initial nodes
gke_node_count = 3
gke_min_node_count = 3
```

## Support and Escalation

For production issues:
1. Check cluster health: `kubectl get nodes`
2. Review GKE logs in Cloud Logging
3. Check Managed Prometheus alerts
4. Review terraform state for drift
5. Escalate to on-call if needed

## Maintenance Windows

Default maintenance window: 03:00-07:00 UTC

To change:
```hcl
# In modules/gcp/gke/variables.tf
maintenance_start_time = "02:00"  # 2 AM UTC
```
