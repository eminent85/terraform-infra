# Staging Environment

Production-like GKE cluster configuration for pre-production testing and validation.

## Purpose

The staging environment is designed to:

- Mirror production configuration as closely as possible
- Provide a stable environment for final testing before production
- Allow for load testing and performance validation
- Test deployment procedures and rollback scenarios

## Configuration Highlights

This environment balances cost and production-readiness:

- ✅ **Regional cluster** for high availability (3 control plane replicas)
- ✅ **Standard nodes** (not preemptible) for stability
- ✅ **Mid-size instances** (e2-standard-2) - adequate for most workloads
- ✅ **Network policies** enabled for security testing
- ✅ **REGULAR release channel** for stable Kubernetes versions
- ✅ **IAP access** for secure bastion connectivity

## Cost Considerations

Approximate costs for this staging environment:
- GKE control plane (regional): ~$73/month
- 1x e2-standard-2 node per zone (3 zones): ~$150/month
- 1x e2-small bastion: ~$12/month
- Network egress: ~$10/month (variable)
- **Total: ~$245/month**

To reduce costs:
- Scale down to 1 node per zone when not in use
- Consider using preemptible nodes for non-critical testing
- Use zonal cluster instead of regional

## Usage

```bash
cd environments/staging

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply
```

## Environment Promotion

When promoting from staging to production:

1. ✅ Validate all application deployments work correctly
2. ✅ Test monitoring and alerting configurations
3. ✅ Verify network policies and security controls
4. ✅ Load test to ensure adequate capacity
5. ✅ Test backup and disaster recovery procedures
6. ✅ Document any environment-specific configurations

## Accessing the Cluster

```bash
# From your local machine
gcloud compute ssh gke-bastion-staging --zone=us-central1-a --tunnel-through-iap --project=your-project-id

# From bastion
gcloud container clusters get-credentials gke-cluster-staging --region=us-central1 --project=your-project-id
kubectl get nodes
```

## Differences from Production

- Smaller machine types (e2-standard-2 vs e2-standard-4)
- Lower max node count (5 vs 10)
- Managed Prometheus disabled by default
- Smaller disk sizes (75GB vs 100GB)
