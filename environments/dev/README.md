# Development Environment

Cost-optimized GKE cluster configuration for development and testing.

## Cost Optimizations

This environment uses the following cost-saving measures:

- ✅ **Zonal cluster** instead of regional (lower control plane costs)
- ✅ **Preemptible nodes** (up to 80% cheaper than regular instances)
- ✅ **Smaller machine types** (e2-micro bastion, e2-medium GKE nodes)
- ✅ **Smaller disk sizes** (50GB instead of 100GB)
- ✅ **Lower node count** (1-3 nodes instead of 1-5)
- ✅ **Managed Prometheus disabled** (saves monitoring costs)
- ✅ **No external IPs** (IAP access only)

## Estimated Monthly Cost

Approximate costs for this dev environment:
- GKE control plane (zonal): ~$0/month (free tier)
- 1x e2-medium preemptible node: ~$7/month
- 1x e2-micro bastion: ~$2.50/month
- Network egress: ~$5/month (variable)
- **Total: ~$15-20/month**

## Usage

```bash
cd environments/dev

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply

# Destroy when done
terraform destroy
```

## Notes

- **Preemptible nodes**: Can be terminated by GCP with 30 seconds notice. Not suitable for production workloads.
- **Zonal cluster**: Single zone means no HA for control plane. Acceptable for dev/test.
- **RAPID release channel**: Gets latest Kubernetes features but may have more updates.

## Accessing the Cluster

```bash
# From your local machine
gcloud compute ssh gke-bastion-dev --zone=us-central1-a --tunnel-through-iap --project=your-project-id

# From bastion
gcloud container clusters get-credentials gke-cluster-dev --zone=us-central1-a --project=your-project-id
kubectl get nodes
```
