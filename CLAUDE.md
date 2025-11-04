# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Terraform infrastructure-as-code repository for managing GCP (Google Cloud Platform) resources. The repository uses a modular structure to organize reusable Terraform modules.

## Repository Structure

```
modules/gcp/          # GCP-specific Terraform modules
├── gke/             # Google Kubernetes Engine modules
├── network/         # Network and VPC modules
└── storage/         # Storage (GCS, persistent disks) modules
```

## Common Commands

### Terraform Workflow
```bash
# Initialize Terraform (download providers and modules)
terraform init

# Format Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy
```

### Working with Modules
When developing modules in `modules/gcp/`, ensure each module includes:
- `main.tf` - Primary resource definitions
- `variables.tf` - Input variable declarations
- `outputs.tf` - Output value declarations
- `README.md` - Module documentation with usage examples

### Testing Individual Modules
```bash
# Navigate to module directory
cd modules/gcp/<module-name>

# Run Terraform commands from module directory
terraform init
terraform validate
terraform fmt
```

## Development Guidelines

### Module Structure
- Keep modules focused on a single responsibility (e.g., GKE cluster, VPC network)
- Use consistent variable naming across modules
- Document all variables and outputs with descriptions
- Include examples directory for module usage demonstrations

### Naming Conventions
- Use lowercase with hyphens for resource names
- Prefix module-specific resources appropriately
- Use descriptive variable names that indicate purpose and type

### Version Constraints
- Specify Terraform version constraints in module requirements
- Pin provider versions for stability
- Document minimum required versions
