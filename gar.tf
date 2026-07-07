# Create Google Artifact Registry repository
resource "google_artifact_registry_repository" "github_registry" {
  location      = var.gcp_region
  repository_id = var.gar_repository_name
  description   = var.gar_repository_description
  format        = upper(var.gar_repository_format)

  labels = var.repository_labels

  depends_on = [google_project_service.required_apis]
}

# Optional: Set repository cleanup policies
resource "google_artifact_registry_cleanup_policies" "github_registry_cleanup" {
  location      = google_artifact_registry_repository.github_registry.location
  repository_id = google_artifact_registry_repository.github_registry.repository_id

  cleanup_policies {
    id     = "delete-old-images"
    action = "DELETE"
    condition {
      # Delete images older than 30 days
      older_than = "2592000s" # 30 days in seconds
    }
  }

  cleanup_policies {
    id     = "keep-recent-images"
    action = "KEEP"
    condition {
      # Keep the 10 most recent tagged images
      most_recent_versions {
        keep_count = 10
      }
    }
  }
}

# Optional: Configure repository IAM bindings for public read access (if needed)
resource "google_artifact_registry_repository_iam_member" "public_read" {
  count      = 0 # Change to 1 to enable public read access
  location   = google_artifact_registry_repository.github_registry.location
  repository = google_artifact_registry_repository.github_registry.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "allUsers"
}
