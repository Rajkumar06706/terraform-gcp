# Create Google Artifact Registry Repository

resource "google_artifact_registry_repository" "github_registry" {
  location      = var.gcp_region
  repository_id = var.gar_repository_name
  description   = var.gar_repository_description
  format        = upper(var.gar_repository_format)

  labels = var.repository_labels

  depends_on = [
    google_project_service.required_apis
  ]
}

# Optional IAM binding for public access (disabled by default)

resource "google_artifact_registry_repository_iam_member" "public_read" {
  count = 0

  location   = google_artifact_registry_repository.github_registry.location
  repository = google_artifact_registry_repository.github_registry.repository_id

  role   = "roles/artifactregistry.reader"
  member = "allUsers"
}
