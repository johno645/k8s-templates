# GitLab State Management Setup

This document explains how to configure GitLab for Terraform state management.

## GitLab Project Setup

1. **Create a GitLab Project** (if you don't have one):
   - Go to GitLab and create a new project
   - Note the Project ID (found in Settings → General)

2. **Create a Personal Access Token**:
   - Go to User Settings → Access Tokens
   - Create a token with `api` scope
   - Save the token securely

3. **Set Environment Variables**:
   ```bash
   export GITLAB_PROJECT_ID="12345678"  # Your project ID
   export GITLAB_USERNAME="your-username"
   export GITLAB_ACCESS_TOKEN="glpat-xxxxxxxxxxxx"
   ```

## State File Locations

Each Terragrunt component will store its state at:
```
https://gitlab.com/api/v4/projects/{project_id}/terraform/state/{state_name}
```

For this project:
- Network: `dev/network`
- Database: `dev/database`
- Application: `dev/application`

## Viewing State in GitLab

Navigate to your GitLab project:
- Go to **Operate → Terraform states**
- You'll see all state files listed with their lock status

## State Locking

GitLab automatically handles state locking:
- Lock is acquired before operations
- Lock is released after operations
- Prevents concurrent modifications

## Alternative: GitLab Self-Managed

If using self-managed GitLab, update the URLs in `terragrunt.hcl`:
```hcl
address = "https://your-gitlab-instance.com/api/v4/projects/${local.gitlab_project_id}/terraform/state/${path_relative_to_include()}"
```

## Troubleshooting

### Authentication Issues
- Verify your access token has `api` scope
- Check that GITLAB_ACCESS_TOKEN is set correctly
- Ensure your user has Maintainer or Owner role on the project

### State Not Found
- Verify GITLAB_PROJECT_ID is correct
- Check that the project exists and you have access
- State files are created automatically on first `terraform apply`
