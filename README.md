# Terraform GCP - GitHub Actions to Google Artifact Registry

This Terraform configuration sets up a complete integration between GitHub Actions and Google Artifact Registry (GAR), enabling secure containerized application deployment using Workload Identity Federation.

## Overview

This setup creates:
- A Google Artifact Registry repository for Docker images
- A GCP service account for GitHub Actions
- Workload Identity Pool and Provider for OIDC-based authentication
- GitHub Actions secrets with necessary credentials
- IAM roles and bindings for secure access

## Features

✅ **Workload Identity Federation**: No long-lived credentials needed  
✅ **OIDC Authentication**: Secure token-based authentication from GitHub  
✅ **Automated Setup**: Complete infrastructure in code  
✅ **GitHub Secrets Management**: Automatically creates and manages secrets  
✅ **Cleanup Policies**: Automated image cleanup to manage costs  
✅ **Production Ready**: Best practices and security hardening included  

## Prerequisites

1. **GCP Account** with appropriate permissions
2. **Terraform** >= 1.0
3. **GitHub Token** with `repo` and `admin:repo_hook` permissions
4. **GCP CLI** configured with appropriate credentials

### Create GitHub Token

```bash
# Go to GitHub Settings → Developer settings → Personal access tokens
# Or use GitHub CLI:
gh auth login
```

## Installation & Usage

### 1. Clone or Initialize Repository

```bash
git clone https://github.com/Rajkumar06706/terraform-gcp.git
cd terraform-gcp
```

### 2. Set Up Variables

```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

**Required variables:**
- `gcp_project_id`: Your GCP project ID
- `github_token`: GitHub Personal Access Token
- `github_org`: GitHub organization or username
- `github_repo_name`: Target GitHub repository name

### 3. Set Environment Variables (Optional but Recommended)

```bash
# For GitHub Token (keeps it out of tfvars)
export TF_VAR_github_token="ghp_xxxxxxxxxxxx"

# For GCP authentication
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
```

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Review Plan

```bash
terraform plan -out=tfplan
```

### 6. Apply Configuration

```bash
terraform apply tfplan
```

## Outputs

After applying, you'll get:

```bash
# View all outputs
terraform output

# View specific output
terraform output gar_repository_url
terraform output workload_identity_provider_resource
```

Key outputs:
- `gar_repository_url`: Full URL for pushing/pulling images
- `service_account_email`: Service account for GitHub
- `workload_identity_provider_resource`: OIDC provider resource name
- `github_secrets_created`: List of secrets created in GitHub

## GitHub Actions Workflow Example

Create `.github/workflows/docker-build-push.yml`:

```yaml
name: Build and Push to GAR

on:
  push:
    branches:
      - main
    paths:
      - 'Dockerfile'
      - 'src/**'

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    environment: gar-deploy
    
    permissions:
      contents: read
      id-token: write
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: google-github-actions/auth@v1
        with:
          workload_identity_provider: ${{ secrets.WORKLOAD_IDENTITY_PROVIDER }}
          service_account_email: ${{ secrets.GCP_SERVICE_ACCOUNT_EMAIL }}
      
      - uses: google-github-actions/setup-gcloud@v1
      
      - name: Configure Docker for GAR
        run: |
          gcloud auth configure-docker ${{ secrets.GCP_REGION }}-docker.pkg.dev
      
      - name: Build Docker Image
        run: |
          docker build -t ${{ secrets.GCP_REGION }}-docker.pkg.dev/${{ secrets.GCP_PROJECT_ID }}/${{ secrets.GAR_REPOSITORY_NAME }}/my-app:${{ github.sha }} .
      
      - name: Push to GAR
        run: |
          docker push ${{ secrets.GCP_REGION }}-docker.pkg.dev/${{ secrets.GCP_PROJECT_ID }}/${{ secrets.GAR_REPOSITORY_NAME }}/my-app:${{ github.sha }}
      
      - name: Push Latest Tag
        run: |
          docker tag ${{ secrets.GCP_REGION }}-docker.pkg.dev/${{ secrets.GCP_PROJECT_ID }}/${{ secrets.GAR_REPOSITORY_NAME }}/my-app:${{ github.sha }} ${{ secrets.GCP_REGION }}-docker.pkg.dev/${{ secrets.GCP_PROJECT_ID }}/${{ secrets.GAR_REPOSITORY_NAME }}/my-app:latest
          docker push ${{ secrets.GCP_REGION }}-docker.pkg.dev/${{ secrets.GCP_PROJECT_ID }}/${{ secrets.GAR_REPOSITORY_NAME }}/my-app:latest
```

## Pushing Images to GAR

### Using Docker CLI

```bash
# Authenticate
gcloud auth configure-docker us-central1-docker.pkg.dev

# Build image
docker build -t us-central1-docker.pkg.dev/my-project/github-docker/my-app:latest .

# Push to GAR
docker push us-central1-docker.pkg.dev/my-project/github-docker/my-app:latest
```

### Using gcloud CLI

```bash
# Submit build to Cloud Build (pushes directly to GAR)
gcloud builds submit \
  --config=cloudbuild.yaml \
  --substitutions="_GAR_REPO=github-docker,_IMAGE_NAME=my-app"
```

## Pulling Images from GAR

```bash
# Configure Docker authentication
gcloud auth configure-docker us-central1-docker.pkg.dev

# Pull image
docker pull us-central1-docker.pkg.dev/my-project/github-docker/my-app:latest
```

## Managing Artifacts

### List repositories
```bash
gcloud artifacts repositories list --location=us-central1
```

### List images
```bash
gcloud artifacts docker images list us-central1-docker.pkg.dev/my-project/github-docker
```

### Delete an image
```bash
gcloud artifacts docker images delete us-central1-docker.pkg.dev/my-project/github-docker/my-app:v1.0.0
```

## Security Best Practices

1. **Never commit `terraform.tfvars`** - Use environment variables instead
2. **Use Workload Identity** - No long-lived service account keys
3. **Scope service account permissions** - Only grant necessary roles
4. **Enable audit logging** - Monitor GAR access
5. **Use branch protection** - Require approval for deployment workflows
6. **Rotate secrets regularly** - Especially GitHub tokens

## Troubleshooting

### "Permission denied" when pushing to GAR

```bash
# Verify authentication
gcloud auth application-default print-access-token

# Reconfigure Docker authentication
gcloud auth configure-docker us-central1-docker.pkg.dev --quiet
```

### GitHub secret creation fails

```bash
# Verify GitHub token permissions
gh auth status

# Regenerate token if needed
gh auth login --scopes repo,admin:repo_hook
```

### Workload Identity issues

```bash
# Verify pool exists
gcloud iam workload-identity-pools list --location=global --project=PROJECT_ID

# Verify provider exists
gcloud iam workload-identity-providers list \
  --workload-identity-pool=github-pool \
  --location=global \
  --project=PROJECT_ID

# Test token generation (in GitHub Actions)
echo $GITHUB_TOKEN  # Should be JWT token
```

## Cleaning Up

To destroy all resources:

```bash
terraform destroy
```

⚠️ **Warning**: This will delete the GAR repository and all stored images. Make sure you've backed up any important images.

## Additional Resources

- [Google Artifact Registry Documentation](https://cloud.google.com/artifact-registry/docs)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub Actions - Google Cloud Auth](https://github.com/google-github-actions/auth)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

## Contributing

Contributions are welcome! Please submit a pull request with improvements.

## License

MIT License - see LICENSE file for details

## Support

For issues or questions:
1. Check existing GitHub issues
2. Create a new issue with detailed information
3. Include Terraform version and error messages
