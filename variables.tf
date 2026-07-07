variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "gar_repository_name" {
  description = "Name of the Google Artifact Registry repository"
  type        = string
  default     = "github-docker"
}

variable "gar_repository_description" {
  description = "Description of the GAR repository"
  type        = string
  default     = "Docker repository for GitHub CI/CD pipeline"
}

variable "gar_repository_format" {
  description = "Format of the repository (docker, npm, python, apt, yum, etc.)"
  type        = string
  default     = "docker"
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
}

variable "service_account_id" {
  description = "Service account ID for GAR access"
  type        = string
  default     = "github-gar-sa"
}

variable "workload_identity_pool_id" {
  description = "Workload Identity Pool ID"
  type        = string
  default     = "github-pool"
}

variable "workload_identity_provider_id" {
  description = "Workload Identity Provider ID"
  type        = string
  default     = "github-provider"
}

variable "repository_labels" {
  description = "Labels to apply to the repository"
  type        = map(string)
  default = {
    environment = "dev"
    managed-by  = "terraform"
    source      = "github"
  }
}
