# Enable required GCP APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "containerregistry.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = true
}

# Create a service account for GitHub Actions to use with Workload Identity
resource "google_service_account" "github_gar" {
  account_id   = var.service_account_id
  display_name = "GitHub Actions Service Account for GAR"
  description  = "Service account for GitHub Actions to push/pull from Google Artifact Registry"

  depends_on = [google_project_service.required_apis]
}

# Grant Artifact Registry Writer role to the service account
resource "google_project_iam_member" "gar_writer" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_gar.email}"
}

# Grant Artifact Registry Reader role to the service account
resource "google_project_iam_member" "gar_reader" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.github_gar.email}"
}

# Create Workload Identity Pool for GitHub
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = var.workload_identity_pool_id
  location                  = "global"
  display_name              = "GitHub Pool"
  description               = "Workload Identity Pool for GitHub Actions"
  disabled                  = false

  depends_on = [google_project_service.required_apis]
}

# Create Workload Identity Provider for GitHub
resource "google_iam_workload_identity_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_provider_id      = var.workload_identity_provider_id
  location                           = "global"
  display_name                       = "GitHub Provider"
  description                        = "OIDC provider for GitHub Actions"
  disabled                           = false
  attribute_mapping                  = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.environment" = "assertion.environment"
    "attribute.aud"        = "assertion.aud"
  }
  attribute_condition = "assertion.aud == 'sts.amazonaws.com'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Create IAM binding for Workload Identity between GitHub and the service account
resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.github_gar.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_client_config.current.project_number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/attribute.repository/${var.github_org}/${var.github_repo_name}"
}

# Get current GCP config for project number
data "google_client_config" "current" {}

data "google_project" "current" {
  project_id = var.gcp_project_id
}
