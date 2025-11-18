# Terragrunt Project with GitLab State Management

This project uses Terragrunt to manage multiple Terraform state files using GitLab as the remote backend. It uses a single set of modules with environment-specific tfvars files to eliminate duplication.

## Project Structure

```
terragrunt-project/
├── app1/
│   ├── terragrunt.hcl
│   └── terraform.tfvars
├── app2/
│   ├── terragrunt.hcl
│   ├── terraform.tfvars
│   └── pre-deploy.sh
├── modules/
│   ├── app1/
│   │   └── main.tf
│   └── app2/
│       └── main.tf
├── terragrunt.hcl
├── terraform.dev.tfvars
├── terraform.prod.tfvars
└── .gitlab-ci.yml
```

## Setup Instructions

### 1. GitLab Project Setup

1. Create or identify your GitLab project where you want to store the Terraform state
2. Note your GitLab project ID (visible in project settings)
3. Update the `gitlab_project_id` in:
   - `terraform.dev.tfvars`
   - `terraform.prod.tfvars`

### 2. GitLab Access Token

1. Go to GitLab → Settings → Access Tokens
2. Create a new token with `api` scope
3. Set the environment variable:
   ```bash
   export GITLAB_ACCESS_TOKEN="your-token-here"
   ```

### 3. Enable Terraform State in GitLab

Your GitLab project needs to support Terraform state management. This is available in:
- GitLab Premium and above
- GitLab.com with Premium tier

### 4. Initialize and Deploy

**Using the deploy helper script (recommended):**
```bash
# Deploy all apps to dev
./deploy.sh dev plan
./deploy.sh dev apply

# Deploy specific app to prod
./deploy.sh prod plan app1
./deploy.sh prod apply app1

# Destroy infrastructure
./deploy.sh dev destroy all
```

**Manual deployment:**
```bash
# Deploy to Dev
export TG_ENVIRONMENT=dev
export TG_GITLAB_PROJECT_ID=12345  # Your dev project ID
terragrunt run-all init
terragrunt run-all plan -var-file=terraform.dev.tfvars
terragrunt run-all apply -var-file=terraform.dev.tfvars

# Deploy to Prod
export TG_ENVIRONMENT=prod
export TG_GITLAB_PROJECT_ID=67890  # Your prod project ID
terragrunt run-all init
terragrunt run-all plan -var-file=terraform.prod.tfvars
terragrunt run-all apply -var-file=terraform.prod.tfvars

# Deploy specific app
cd app1
terragrunt init
terragrunt plan -var-file=../terraform.dev.tfvars
terragrunt apply -var-file=../terraform.dev.tfvars
```

## State Files

Each application gets its own state file per environment:
- `app1` (dev) → `dev/app1/terraform.tfstate`
- `app2` (dev) → `dev/app2/terraform.tfstate`
- `app1` (prod) → `prod/app1/terraform.tfstate`
- `app2` (prod) → `prod/app2/terraform.tfstate`

## State File Management

Each environment and application has its own isolated state file:

```
terraform/state/
├── dev/
│   ├── app1/terraform.tfstate
│   └── app2/terraform.tfstate
└── prod/
    ├── app1/terraform.tfstate
    └── app2/terraform.tfstate
```

**Key Points:**
- State files are separated by `TG_ENVIRONMENT` (dev/prod)
- Each app gets its own state file
- Dev and prod use different GitLab projects (different project IDs)
- State locking is automatic via GitLab's Terraform state API

See [STATE_MANAGEMENT.md](STATE_MANAGEMENT.md) for detailed information.

## GitLab CI/CD

The `.gitlab-ci.yml` file provides automated pipelines:

- **Validate**: Runs on merge requests to validate all configurations
- **Plan**: Generates and stores Terraform plans
- **Apply**: Applies changes to dev on `develop` branch, prod on `main` branch

### CI/CD Variables

Set these in GitLab CI/CD settings:
- `GITLAB_ACCESS_TOKEN`: Your GitLab personal access token

## Customization

### Adding New Applications

1. Create a new module in `modules/new-app/main.tf`
2. Create app directory:
   ```bash
   mkdir new-app
   ```
3. Create `new-app/terragrunt.hcl` (copy from `app1/terragrunt.hcl` and update as needed)
4. Create `new-app/terraform.tfvars` with app-specific variables

### Modifying Providers

Edit the `generate "provider"` block in the root `terragrunt.hcl` to configure your providers (AWS, Azure, GCP, etc.)

### Adding Environment-Specific Variables

Create new tfvars files for additional environments:
```bash
cp terraform.dev.tfvars terraform.staging.tfvars
# Edit terraform.staging.tfvars with staging-specific values
```

Then deploy to staging:
```bash
export TG_ENVIRONMENT=staging
export TG_GITLAB_PROJECT_ID=xxxxx
terragrunt run-all apply -var-file=terraform.staging.tfvars
```

## Troubleshooting

### State Lock Issues

If you encounter state lock issues, you can manually unlock:
```bash
curl -X DELETE \
  -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" \
  "https://gitlab.com/api/v4/projects/<project-id>/terraform/state/<state-name>/lock"
```

### Authentication Errors

Ensure your `GITLAB_ACCESS_TOKEN` is set and has the `api` scope:
```bash
echo $GITLAB_ACCESS_TOKEN
```

## References

- [Terragrunt Documentation](https://terragrunt.gruntwork.io/)
- [GitLab Terraform State](https://docs.gitlab.com/ee/user/infrastructure/terraform_state.html)
- [Terraform HTTP Backend](https://www.terraform.io/language/settings/backends/http)
