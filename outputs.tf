output "gar_repository_url" {
  description = "Google Artifact Registry repository URL"
  value       = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.github_registry.repository_id}"
}

output "gar_repository_full_path" {
  description = "Full path of the GAR repository"
  value       = google_artifact_registry_repository.github_registry.name
}

output "service_account_email" {
  description = "Service account email for GitHub Actions"
  value       = google_service_account.github_gar.email
}

output "service_account_id" {
  description = "Service account ID"
  value       = google_service_account.github_gar.unique_id
}

output "workload_identity_pool_name" {
  description = "Workload Identity Pool resource name"
  value       = google_iam_workload_identity_pool.github_pool.name
}

output "workload_identity_provider_name" {
  description = "Workload Identity Provider resource name"
  value       = google_iam_workload_identity_provider.github_provider.name
}

output "workload_identity_provider_resource" {
  description = "Full resource name for Workload Identity Provider (use in GitHub Actions)"
  value       = google_iam_workload_identity_provider.github_provider.name
}

output "github_secrets_created" {
  description = "GitHub Actions secrets created"
  value = {
    GCP_PROJECT_ID                = github_actions_secret.gcp_project_id.secret_name
    GCP_REGION                    = github_actions_secret.gcp_region.secret_name
    GAR_REPOSITORY_NAME           = github_actions_secret.gar_repository_name.secret_name
    GCP_SERVICE_ACCOUNT_EMAIL     = github_actions_secret.service_account_email.secret_name
    WORKLOAD_IDENTITY_PROVIDER    = github_actions_secret.workload_identity_provider_resource.secret_name
    GCP_PROJECT_NUMBER            = github_actions_secret.workload_identity_provider_project_number.secret_name
  }
}

output "gar_repository_name" {
  description = "Name of the created GAR repository"
  value       = google_artifact_registry_repository.github_registry.repository_id
}

output "gcp_project_id" {
  description = "GCP Project ID"
  value       = var.gcp_project_id
}

output "gcp_project_number" {
  description = "GCP Project Number"
  value       = data.google_project.current.number
}
