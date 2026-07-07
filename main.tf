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

  project            = var.gcp_project_id
  service            = each.value
  disable_on_destroy = false
}

# Create a service account for GitHub Actions to use with Workload Identity
resource "google_service_account" "github_gar" {
  project      = var.gcp_project_id
  account_id   = var.service_account_id
  display_name = "GitHub Actions Service Account for GAR"
  description  = "Service account for GitHub Actions to push and pull images from Google Artifact Registry"

  depends_on = [
    google_project_service.required_apis
  ]
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

# Create Workload Identity Pool for GitHub Actions
resource "google_iam_workload_identity_pool" "github_pool" {
  project                   = var.gcp_project_id
  workload_identity_pool_id = var.workload_identity_pool_id
  display_name              = "GitHub Pool"
  description               = "Workload Identity Pool for GitHub Actions"
  disabled                  = false

  depends_on = [
    google_project_service.required_apis
  ]
}

# Create Workload Identity Provider for GitHub Actions
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                            = var.gcp_project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.workload_identity_provider_id

  display_name = "GitHub Provider"
  description  = "OIDC provider for GitHub Actions"
  disabled     = false

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.aud"              = "assertion.aud"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"              = "assertion.ref"
  }

  # Restrict authentication only to your GitHub repository
  attribute_condition = "attribute.repository == '${var.github_org}/${var.github_repo_name}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  depends_on = [
    google_iam_workload_identity_pool.github_pool
  ]
}

# Allow GitHub Actions repository identity to impersonate the GCP service account
resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.github_gar.name
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_org}/${var.github_repo_name}"

  depends_on = [
    google_iam_workload_identity_pool_provider.github_provider,
    google_service_account.github_gar
  ]
}

# Get current GCP project information
data "google_project" "current" {
  project_id = var.gcp_project_id
}
