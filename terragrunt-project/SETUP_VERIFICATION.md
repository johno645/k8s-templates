# Setup Verification Checklist

Use this checklist to verify your Terragrunt project is properly configured for environment-specific state file management.

## ✅ Project Structure

- [ ] `app1/` directory exists with:
  - [ ] `terragrunt.hcl`
  - [ ] `terraform.tfvars`
- [ ] `app2/` directory exists with:
  - [ ] `terragrunt.hcl`
  - [ ] `terraform.tfvars`
  - [ ] `pre-deploy.sh`
- [ ] `modules/` directory exists with:
  - [ ] `app1/main.tf`
  - [ ] `app2/main.tf`
- [ ] Root files exist:
  - [ ] `terragrunt.hcl`
  - [ ] `terraform.dev.tfvars`
  - [ ] `terraform.prod.tfvars`
  - [ ] `deploy.sh` (executable)
  - [ ] `.gitlab-ci.yml`
  - [ ] `README.md`
  - [ ] `STATE_MANAGEMENT.md`

## ✅ State File Configuration

### Root terragrunt.hcl

- [ ] Uses `TG_ENVIRONMENT` env var for environment selection
- [ ] Uses `TG_GITLAB_PROJECT_ID` env var for project ID
- [ ] Remote state backend is configured as HTTP (GitLab)
- [ ] State path includes environment: `${local.environment}/${path_relative_to_include()}`
- [ ] State path structure: `terraform/state/dev/app1`, `terraform/state/prod/app2`, etc.

### Environment Files

- [ ] `terraform.dev.tfvars` contains:
  - [ ] `environment = "dev"`
  - [ ] `gitlab_project_id = "12345"` (your dev project ID)
- [ ] `terraform.prod.tfvars` contains:
  - [ ] `environment = "prod"`
  - [ ] `gitlab_project_id = "67890"` (your prod project ID)

### App Configurations

- [ ] `app1/terragrunt.hcl` includes root terragrunt.hcl
- [ ] `app2/terragrunt.hcl` includes root terragrunt.hcl
- [ ] `app2/terragrunt.hcl` has dependency on app1
- [ ] Both app configs reference correct modules

## ✅ Environment Variables

Before deployment, verify these are set:

```bash
# Check dev environment setup
echo "Dev Environment: $TG_ENVIRONMENT"
echo "Dev Project ID: $TG_GITLAB_PROJECT_ID"
echo "GitLab Token: ${GITLAB_ACCESS_TOKEN:0:10}..." # First 10 chars

# Should output something like:
# Dev Environment: dev
# Dev Project ID: 12345
# GitLab Token: glpat-abc...
```

- [ ] `GITLAB_ACCESS_TOKEN` is set and has `api` scope
- [ ] `TG_ENVIRONMENT` can be set to `dev` or `prod`
- [ ] `TG_GITLAB_PROJECT_ID` matches your GitLab project ID

## ✅ GitLab Configuration

- [ ] GitLab project has Terraform state enabled (Premium tier)
- [ ] Personal access token created with `api` scope
- [ ] Token has not expired
- [ ] Two separate GitLab projects for dev and prod (recommended)

## ✅ Deployment Test

### Test Dev Deployment

```bash
# Set environment variables
export TG_ENVIRONMENT=dev
export TG_GITLAB_PROJECT_ID=12345
export GITLAB_ACCESS_TOKEN=your-token

# Run validation
cd app1
terragrunt validate
cd ../app2
terragrunt validate

# Expected: No errors
```

- [ ] `terragrunt validate` passes for app1
- [ ] `terragrunt validate` passes for app2

### Test Prod Deployment

```bash
# Set environment variables
export TG_ENVIRONMENT=prod
export TG_GITLAB_PROJECT_ID=67890
export GITLAB_ACCESS_TOKEN=your-token

# Run validation
terragrunt run-all validate

# Expected: No errors, both apps validated
```

- [ ] `terragrunt run-all validate` passes for prod environment

### Test Deploy Script

```bash
# Test dev deployment
./deploy.sh dev plan

# Test prod deployment (with confirmation)
./deploy.sh prod plan app1
```

- [ ] `./deploy.sh dev plan` works
- [ ] `./deploy.sh prod plan app1` works
- [ ] Script properly sets environment variables

## ✅ State File Verification

### Verify State Files Are Created in Correct Locations

After running `terragrunt apply`, verify state files exist:

```bash
# Via GitLab UI
# Go to: Infrastructure → Terraform states
# Should see:
# - dev/app1/terraform.tfstate
# - dev/app2/terraform.tfstate
# - prod/app1/terraform.tfstate
# - prod/app2/terraform.tfstate
```

- [ ] Dev app1 state file exists at `terraform/state/dev/app1/terraform.tfstate`
- [ ] Dev app2 state file exists at `terraform/state/dev/app2/terraform.tfstate`
- [ ] Prod app1 state file exists at `terraform/state/prod/app1/terraform.tfstate`
- [ ] Prod app2 state file exists at `terraform/state/prod/app2/terraform.tfstate`

### Verify State File Isolation

```bash
# Deploy to dev
export TG_ENVIRONMENT=dev
export TG_GITLAB_PROJECT_ID=12345
terragrunt run-all init

# Deploy to prod
export TG_ENVIRONMENT=prod
export TG_GITLAB_PROJECT_ID=67890
terragrunt run-all init

# Verify different state files were created
# Dev should use project 12345
# Prod should use project 67890
```

- [ ] Dev and prod use different GitLab projects
- [ ] State files are completely isolated between environments
- [ ] No state file mixing between environments

## ✅ Dependency Management

- [ ] app2 depends on app1
- [ ] Running `terragrunt apply` in app2 automatically applies app1 first
- [ ] Both apps use same environment (dev or prod)
- [ ] app1 outputs are available to app2

## ✅ Documentation

- [ ] README.md explains the new structure
- [ ] STATE_MANAGEMENT.md provides detailed state management guide
- [ ] deploy.sh has usage documentation
- [ ] All comments in terragrunt.hcl files are clear

## 🚀 Ready for Production

Once all checkboxes are marked, your Terragrunt project is ready for production use:

- ✅ State files are properly separated by environment
- ✅ No duplication between dev and prod
- ✅ Easy deployment with deploy.sh script
- ✅ Proper dependency management
- ✅ Complete isolation between environments

## Troubleshooting

If any checks fail, refer to:
1. `STATE_MANAGEMENT.md` - Detailed state management guide
2. `README.md` - Setup instructions
3. Root `terragrunt.hcl` - Backend configuration
4. App `terragrunt.hcl` files - App-specific configuration
