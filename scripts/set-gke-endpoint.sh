#!/bin/bash
set -e

# Script to set up SSH tunnel to GKE cluster via bastion host and configure kubectl
# Usage: ./set-gke-endpoint.sh <cluster-name> <region> [local-port]

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check arguments
if [ "$#" -lt 2 ]; then
    error "Usage: $0 <cluster-name> <region> [local-port]"
    error "Example: $0 my-cluster us-central1 8888"
    exit 1
fi

CLUSTER_NAME="$1"
REGION="$2"
LOCAL_PORT="${3:-8888}"  # Default to 8888 if not specified

info "Setting up kubectl access to GKE cluster: $CLUSTER_NAME"
info "Region: $REGION"
info "Local port for tunnel: $LOCAL_PORT"

# Check if required commands exist
for cmd in gcloud kubectl; do
    if ! command -v "$cmd" &> /dev/null; then
        error "$cmd is not installed. Please install it first."
        exit 1
    fi
done

# Get the current GCP project
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    error "No GCP project is set. Run: gcloud config set project <project-id>"
    exit 1
fi

info "Using GCP project: $PROJECT_ID"

# Check if cluster exists and get details
info "Fetching cluster information..."
if ! gcloud container clusters describe "$CLUSTER_NAME" --region="$REGION" &>/dev/null; then
    error "Cluster '$CLUSTER_NAME' not found in region '$REGION'"
    exit 1
fi

# Get cluster configuration
CLUSTER_INFO=$(gcloud container clusters describe "$CLUSTER_NAME" --region="$REGION" --format=json)
PRIVATE_ENDPOINT=$(echo "$CLUSTER_INFO" | jq -r '.privateClusterConfig.privateEndpoint // empty')

if [ -z "$PRIVATE_ENDPOINT" ]; then
    error "No private endpoint found for cluster '$CLUSTER_NAME'"
    error "This script requires a GKE cluster with a private endpoint configured"
    exit 1
fi

info "Cluster private endpoint: $PRIVATE_ENDPOINT"

# Get bastion host details
info "Looking for bastion host..."
BASTION_NAME=$(gcloud compute instances list \
    --filter="labels.environment:* AND tags.items:bastion" \
    --format="value(name)" \
    --limit=1 2>/dev/null || echo "")

if [ -z "$BASTION_NAME" ]; then
    error "No bastion host found with 'bastion' tag."
    error "A bastion host is required to access the private GKE cluster endpoint."
    error "Ensure your bastion instance is tagged with 'bastion' and has the appropriate labels."
    exit 1
fi

BASTION_ZONE=$(gcloud compute instances list \
    --filter="name=$BASTION_NAME" \
    --format="value(zone)" \
    --limit=1)

info "Found bastion host: $BASTION_NAME (zone: $BASTION_ZONE)"

# Use private endpoint for tunnel
TARGET_ENDPOINT="$PRIVATE_ENDPOINT"
info "Setting up tunnel to private endpoint: $TARGET_ENDPOINT"

# Check if tunnel is already running
if lsof -Pi :$LOCAL_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    warn "Port $LOCAL_PORT is already in use. Checking if it's our tunnel..."
    EXISTING_PID=$(lsof -Pi :$LOCAL_PORT -sTCP:LISTEN -t)
    if ps -p "$EXISTING_PID" -o command= | grep -q "gcloud compute ssh.*$BASTION_NAME"; then
        info "Existing tunnel found (PID: $EXISTING_PID). Reusing it."
    else
        error "Port $LOCAL_PORT is in use by another process (PID: $EXISTING_PID)"
        error "Please stop that process or choose a different port"
        exit 1
    fi
else
    # Start SSH tunnel in background
    info "Starting SSH tunnel to bastion..."
    info "Command: gcloud compute ssh $BASTION_NAME --zone=$BASTION_ZONE -- -L $LOCAL_PORT:$TARGET_ENDPOINT:443 -N -f"

    gcloud compute ssh "$BASTION_NAME" \
        --zone="$BASTION_ZONE" \
        --tunnel-through-iap \
        -- -L "$LOCAL_PORT:$TARGET_ENDPOINT:443" -N -f

    # Wait a moment for tunnel to establish
    sleep 2

    # Verify tunnel is running
    if ! lsof -Pi :$LOCAL_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        error "Failed to establish SSH tunnel"
        exit 1
    fi

    TUNNEL_PID=$(lsof -Pi :$LOCAL_PORT -sTCP:LISTEN -t)
    info "SSH tunnel established (PID: $TUNNEL_PID)"
    info "To stop the tunnel later, run: kill $TUNNEL_PID"
fi

# Get cluster credentials
info "Fetching cluster credentials..."
gcloud container clusters get-credentials "$CLUSTER_NAME" --region="$REGION"

# Update kubeconfig to use localhost tunnel
info "Updating kubeconfig to use SSH tunnel..."
CONTEXT_NAME="gke_${PROJECT_ID}_${REGION}_${CLUSTER_NAME}"
kubectl config set-cluster "$CONTEXT_NAME" --server="https://localhost:$LOCAL_PORT" --insecure-skip-tls-verify=true

# Test connection
info "Testing connection to cluster..."
if kubectl cluster-info &>/dev/null; then
    info "Successfully configured kubectl!"
    info ""
    info "Current context: $CONTEXT_NAME"
    info "Tunnel: localhost:$LOCAL_PORT -> $TARGET_ENDPOINT:443"
    info ""
    info "You can now use kubectl commands:"
    info "  kubectl get nodes"
    info "  kubectl get pods -A"
    info ""
    info "To stop the tunnel: kill $TUNNEL_PID"
else
    error "Connection test failed. Tunnel is running but kubectl cannot connect."
    error "You may need to check cluster authentication settings."
    exit 1
fi
