terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  # The billing budget API needs a quota project when you authenticate with user
  # credentials (gcloud auth application-default login). Only switched on when a
  # budget is requested.
  user_project_override = var.billing_account_id != ""
  billing_project       = var.billing_account_id != "" ? var.project_id : null
}
