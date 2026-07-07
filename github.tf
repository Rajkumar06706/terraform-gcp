# Get GitHub repository details
data "github_repository" "target" {
  name = var.github_repo_name
}

# Create GitHub secrets for GAR authentication
resource "github_actions_secret" "gcp_project_id" {
  repository       = data.github_repository.target.name
  secret_name      = "GCP_PROJECT_ID"
  plaintext_value  = var.gcp_project_id
}

resource "github_actions_secret" "gcp_region" {
  repository       = data.github_repository.target.name
  secret_name      = "GCP_REGION"
  plaintext_value  = var.gcp_region
}

resource "github_actions_secret" "gar_repository_name" {
  repository       = data.github_repository.target.name
  secret_name      = "GAR_REPOSITORY_NAME"
  plaintext_value  = google_artifact_registry_repository.github_registry.repository_id
}

resource "github_actions_secret" "service_account_email" {
  repository       = data.github_repository.target.name
  secret_name      = "GCP_SERVICE_ACCOUNT_EMAIL"
  plaintext_value  = google_service_account.github_gar.email
}

resource "github_actions_secret" "workload_identity_provider_resource" {
  repository       = data.github_repository.target.name
  secret_name      = "WORKLOAD_IDENTITY_PROVIDER"
  plaintext_value  = google_iam_workload_identity_provider.github_provider.name
}

resource "github_actions_secret" "workload_identity_provider_project_number" {
  repository       = data.github_repository.target.name
  secret_name      = "GCP_PROJECT_NUMBER"
  plaintext_value  = data.google_project.current.number
}

# Optional: Create GitHub environment for staging/production deployments
resource "github_repository_environment" "gar_environment" {
  environment = "gar-deploy"
  repository  = data.github_repository.target.name
  description = "Environment for GAR deployment"
}

# Add environment secrets (optional - can be more specific per environment)
resource "github_actions_environment_secret" "env_gar_repo" {
  environment         = github_repository_environment.gar_environment.environment
  secret_name         = "GAR_REPOSITORY_NAME"
  plaintext_value     = google_artifact_registry_repository.github_registry.repository_id
  repository          = data.github_repository.target.name
}
