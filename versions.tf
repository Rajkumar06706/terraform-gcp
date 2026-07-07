terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0.0"
    }

    github = {
      source  = "integrations/github"
      version = ">= 6.0.0"
    }
  }

  # Uncomment this block only when you want to use GCS remote backend
  # backend "gcs" {
  #   bucket = "your-terraform-state-bucket"
  #   prefix = "terraform/state"
  # }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "github" {
  token = var.github_token
  owner = var.github_org
}
