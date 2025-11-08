terraform {
  backend "gcs" {
    bucket = "eminent-dev-terraform-state"
    prefix = "ephemeral-cluster"

    # State will be stored at:
    # gs://eminent-dev-terraform-state/ephemeral-cluster/{workspace}/default.tfstate
    #
    # Each ephemeral cluster uses a separate workspace for isolation
    # Workspace naming: ephemeral-{cluster-identifier}
  }
}
