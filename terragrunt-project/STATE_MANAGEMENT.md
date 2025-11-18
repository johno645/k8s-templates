# State File Management Guide

This document explains how state files are managed in this Terragrunt project.

## State File Structure

State files are organized by **environment** and **application** in GitLab:

```
terraform/state/
├── dev/
│   ├── app1/
│   │   └── terraform.tfstate
│   └── app2/
│       └── terraform.tfstate
└── prod/
    ├── app1/
    │   └── terraform.tfstate
    └── app2/
        └── terraform.tfstate
```

## How State Separation Works

### Environment Variable: `TG_ENVIRONMENT`

The `TG_ENVIRONMENT` environment variable controls which state files are used:

```bash
# Deploy to dev
export TG_ENVIRONMENT=dev
terragrunt run-all apply -var-file=terraform.dev.tfvars

# Deploy to prod
export TG_ENVIRONMENT=prod
terragrunt run-all apply -var-file=terraform.prod.tfvars
```

### State Path Construction

The state file path is built using:

1. **GitLab Project ID** - From `TG_GITLAB_PROJECT_ID` env var
2. **Environment** - From `TG_ENVIRONMENT` env var (dev/prod)
3. **App Name** - From directory name (app1/app2)

**Example:**
```
https://gitlab.com/api/v4/projects/12345/terraform/state/dev/app1
```

This resolves to:
- Project: `12345`
- Environment: `dev`
- App: `app1`
- State file: `terraform.tfstate`

## Deployment Scenarios

### Scenario 1: Deploy app1 to dev

```bash
export TG_ENVIRONMENT=dev
export TG_GITLAB_PROJECT_ID=12345
export GITLAB_ACCESS_TOKEN=your-token

cd app1
terragrunt init
terragrunt apply -var-file=../terraform.dev.tfvars
```

**Result:** State stored at `terraform/state/dev/app1/terraform.tfstate`

### Scenario 2: Deploy both apps to prod

```bash
export TG_ENVIRONMENT=prod
export TG_GITLAB_PROJECT_ID=67890
export GITLAB_ACCESS_TOKEN=your-token

terragrunt run-all init
terragrunt run-all apply -var-file=terraform.prod.tfvars
```

**Result:** 
- `terraform/state/prod/app1/terraform.tfstate`
- `terraform/state/prod/app2/terraform.tfstate`

### Scenario 3: Deploy app2 only (with dependency)

```bash
export TG_ENVIRONMENT=dev
export TG_GITLAB_PROJECT_ID=12345
export GITLAB_ACCESS_TOKEN=your-token

cd app2
terragrunt apply -var-file=../terraform.dev.tfvars
```

**Result:** 
- Terragrunt automatically applies app1 first (dependency)
- Both state files created: `dev/app1` and `dev/app2`

## State Locking

State locking is automatically handled via DynamoDB-like locking through GitLab's Terraform state API.

### Manual State Lock/Unlock

If you need to manually unlock a state:

```bash
# Unlock dev/app1
curl -X DELETE \
  -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" \
  "https://gitlab.com/api/v4/projects/12345/terraform/state/dev/app1/lock"

# Unlock prod/app2
curl -X DELETE \
  -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" \
  "https://gitlab.com/api/v4/projects/67890/terraform/state/prod/app2/lock"
```

## Viewing State Files

### Via GitLab UI

1. Go to your GitLab project
2. Navigate to **Infrastructure → Terraform states**
3. View state files organized by environment and app

### Via CLI

```bash
# List all state files for dev environment
curl -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" \
  "https://gitlab.com/api/v4/projects/12345/terraform/state"

# Get specific state file
curl -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" \
  "https://gitlab.com/api/v4/projects/12345/terraform/state/dev/app1"
```

## Important Notes

### ⚠️ Environment Isolation

- **Dev and Prod use different GitLab projects** (different project IDs)
- This ensures complete isolation between environments
- State files cannot be accidentally mixed between environments

### ⚠️ Dependency Management

- **app2 depends on app1**
- When deploying app2, app1 is automatically applied first
- Both apps must use the **same environment** in a single deployment
- You cannot mix dev app1 with prod app2

### ⚠️ State File Consistency

- Always set `TG_ENVIRONMENT` before running terragrunt commands
- Forgetting to set it will default to `dev`
- Double-check your environment before applying changes to prod

## Troubleshooting

### State File Not Found

**Problem:** `Error: Failed to read state`

**Solution:**
1. Verify `TG_GITLAB_PROJECT_ID` is correct for the environment
2. Verify `GITLAB_ACCESS_TOKEN` has `api` scope
3. Check GitLab project has Terraform state enabled (Premium tier)

### State Lock Timeout

**Problem:** `Error: Error acquiring the state lock`

**Solution:**
1. Check if another deployment is in progress
2. Manually unlock if needed (see State Locking section)
3. Verify network connectivity to GitLab

### Wrong Environment Deployed

**Problem:** Changes applied to wrong environment

**Solution:**
1. Check `TG_ENVIRONMENT` value: `echo $TG_ENVIRONMENT`
2. Check `TG_GITLAB_PROJECT_ID` value: `echo $TG_GITLAB_PROJECT_ID`
3. Verify correct tfvars file used: `-var-file=terraform.dev.tfvars`

## Best Practices

1. **Always verify environment before applying:**
   ```bash
   echo "Environment: $TG_ENVIRONMENT"
   echo "Project ID: $TG_GITLAB_PROJECT_ID"
   terragrunt plan -var-file=terraform.${TG_ENVIRONMENT}.tfvars
   ```

2. **Use different terminals for different environments** to avoid mistakes

3. **Use CI/CD for production deployments** to enforce approval workflows

4. **Backup state files regularly** using GitLab's backup features

5. **Never manually edit state files** - use `terraform state` commands if needed

## References

- [Terragrunt Remote State](https://terragrunt.gruntwork.io/docs/features/remote-state/)
- [GitLab Terraform State](https://docs.gitlab.com/ee/user/infrastructure/terraform_state.html)
- [Terraform State Management](https://www.terraform.io/language/state/)
