#!/bin/bash

set -e

# Script to deploy GCP service account JSON as a Kubernetes secret
# Usage: ./deploy-gcp-serviceaccount.sh <path-to-json> [namespace]

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print error messages
error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# Function to print success messages
success() {
    echo -e "${GREEN}$1${NC}"
}

# Function to print info messages
info() {
    echo -e "${YELLOW}$1${NC}"
}

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    error "kubectl is not installed or not in PATH"
fi

# Parse arguments
SA_JSON_PATH="$1"
NAMESPACE="${2:-default}"

# Validate inputs
if [ -z "$SA_JSON_PATH" ]; then
    error "Usage: $0 <path-to-service-account-json> [namespace]"
fi

if [ ! -f "$SA_JSON_PATH" ]; then
    error "Service account JSON file not found: $SA_JSON_PATH"
fi

# Validate JSON file
if ! jq empty "$SA_JSON_PATH" 2>/dev/null; then
    error "Invalid JSON file: $SA_JSON_PATH"
fi

# Generate secret name from service account email (sanitize for k8s naming)
SECRET_NAME="gcp-service-account"

info "Deploying GCP service account to Kubernetes..."
info "Service Account: $SA_EMAIL"
info "Namespace: $NAMESPACE"
info "Secret Name: $SECRET_NAME"

# Check if namespace exists, create if it doesn't
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    info "Namespace '$NAMESPACE' does not exist. Creating..."
    kubectl create namespace "$NAMESPACE"
fi

# Check if secret already exists
if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &> /dev/null; then
    info "Secret '$SECRET_NAME' already exists in namespace '$NAMESPACE'"
    read -p "Do you want to replace it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Deployment cancelled."
        exit 0
    fi
    kubectl delete secret "$SECRET_NAME" -n "$NAMESPACE"
fi

# Create the secret
kubectl create secret generic "$SECRET_NAME" \
    --from-file=credentials.json="$SA_JSON_PATH" \
    --namespace="$NAMESPACE"

# Verify the secret was created
if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &> /dev/null; then
    success " Service account secret deployed successfully!"
    echo ""
    echo "Secret details:"
    echo "  Name: $SECRET_NAME"
    echo "  Namespace: $NAMESPACE"
    echo "  Data key: credentials.json"
    echo ""
    echo "To use this secret in a pod, mount it as a volume:"
    echo ""
    echo "  volumes:"
    echo "  - name: gcp-sa"
    echo "    secret:"
    echo "      secretName: $SECRET_NAME"
    echo ""
    echo "  containers:"
    echo "  - name: your-container"
    echo "    volumeMounts:"
    echo "    - name: gcp-sa"
    echo "      mountPath: /var/secrets/google"
    echo "    env:"
    echo "    - name: GOOGLE_APPLICATION_CREDENTIALS"
    echo "      value: /var/secrets/google/credentials.json"
else
    error "Failed to create secret"
fi
