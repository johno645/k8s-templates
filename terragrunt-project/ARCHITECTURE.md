# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Terragrunt Project                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           Root Terragrunt Configuration                 │  │
│  │  (terragrunt.hcl)                                        │  │
│  │  - Backend: GitLab HTTP                                 │  │
│  │  - Environment: TG_ENVIRONMENT env var                  │  │
│  │  - Project ID: TG_GITLAB_PROJECT_ID env var            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          ▲                                      │
│                          │ includes                             │
│                          │                                      │
│  ┌──────────────────────┴──────────────────────┐               │
│  │                                             │               │
│  ▼                                             ▼               │
│ ┌─────────────────┐                   ┌─────────────────┐     │
│ │   app1/         │                   │   app2/         │     │
│ │ terragrunt.hcl  │                   │ terragrunt.hcl  │     │
│ │ terraform.tfvars│                   │ terraform.tfvars│     │
│ │                 │                   │ pre-deploy.sh   │     │
│ │ module: app1    │                   │                 │     │
│ └─────────────────┘                   │ module: app2    │     │
│         │                             │ depends: app1   │     │
│         │                             └─────────────────┘     │
│         │                                     ▲                │
│         │                                     │                │
│         └─────────────────────────────────────┘                │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         Terraform Modules                              │  │
│  │  modules/app1/main.tf                                  │  │
│  │  modules/app2/main.tf                                  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         Environment Variables                          │  │
│  │  terraform.dev.tfvars                                  │  │
│  │  terraform.prod.tfvars                                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## State File Structure

```
GitLab Project (Dev: 12345)
└── terraform/state/
    └── dev/
        ├── app1/
        │   └── terraform.tfstate
        │       ├── aws_s3_bucket.app1_bucket
        │       └── outputs: bucket_name, bucket_arn, etc.
        └── app2/
            └── terraform.tfstate
                ├── aws_dynamodb_table.app2_table
                ├── app1 outputs (passed through)
                └── outputs: table_name, table_arn, etc.

GitLab Project (Prod: 67890)
└── terraform/state/
    └── prod/
        ├── app1/
        │   └── terraform.tfstate
        │       ├── aws_s3_bucket.app1_bucket
        │       └── outputs: bucket_name, bucket_arn, etc.
        └── app2/
            └── terraform.tfstate
                ├── aws_dynamodb_table.app2_table
                ├── app1 outputs (passed through)
                └── outputs: table_name, table_arn, etc.
```

## Deployment Flow

### Single App Deployment (app1 to dev)

```
┌─────────────────────────────────────────┐
│  export TG_ENVIRONMENT=dev              │
│  export TG_GITLAB_PROJECT_ID=12345      │
│  ./deploy.sh dev apply app1             │
└─────────────────────────────────────────┘
                 │
                 ▼
        ┌────────────────────┐
        │ Load root config   │
        │ (terragrunt.hcl)   │
        └────────────────────┘
                 │
                 ▼
        ┌────────────────────┐
        │ Load app1 config   │
        │ (app1/terragrunt)  │
        └────────────────────┘
                 │
                 ▼
        ┌────────────────────┐
        │ Connect to GitLab  │
        │ Project 12345      │
        └────────────────────┘
                 │
                 ▼
        ┌────────────────────┐
        │ Create/Update      │
        │ State: dev/app1    │
        └────────────────────┘
                 │
                 ▼
        ┌────────────────────┐
        │ Deploy app1        │
        │ (S3 bucket)        │
        └────────────────────┘
```

### Multi-App Deployment (all to dev)

```
┌─────────────────────────────────────────┐
│  export TG_ENVIRONMENT=dev              │
│  export TG_GITLAB_PROJECT_ID=12345      │
│  ./deploy.sh dev apply                  │
└─────────────────────────────────────────┘
                 │
                 ▼
        ┌────────────────────┐
        │ Load root config   │
        │ (terragrunt.hcl)   │
        └────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
    ┌────────┐        ┌────────┐
    │ app1   │        │ app2   │
    │ config │        │ config │
    └────────┘        └────────┘
        │                 │
        │                 ▼
        │         ┌──────────────────┐
        │         │ Check dependency │
        │         │ on app1          │
        │         └──────────────────┘
        │                 │
        ▼                 │
    ┌────────────────┐    │
    │ Deploy app1    │    │
    │ (S3 bucket)    │    │
    │ State: dev/app1│    │
    └────────────────┘    │
        │                 │
        │ outputs         │
        │ (bucket_name)   │
        │                 │
        └────────┬────────┘
                 │
                 ▼
    ┌────────────────────────┐
    │ Deploy app2            │
    │ (DynamoDB table)       │
    │ State: dev/app2        │
    │ Inputs: app1 outputs   │
    └────────────────────────┘
```

## Environment Isolation

```
┌──────────────────────────────────────────────────────────────┐
│                    Development Environment                  │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  GitLab Project: 12345                                       │
│  TG_ENVIRONMENT: dev                                         │
│  TG_GITLAB_PROJECT_ID: 12345                                │
│                                                              │
│  State Files:                                                │
│  ├── terraform/state/dev/app1/terraform.tfstate             │
│  └── terraform/state/dev/app2/terraform.tfstate             │
│                                                              │
│  Variables: terraform.dev.tfvars                             │
│                                                              │
└──────────────────────────────────────────────────────────────┘
                          │
                          │ Completely Isolated
                          │
┌──────────────────────────────────────────────────────────────┐
│                   Production Environment                    │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  GitLab Project: 67890                                       │
│  TG_ENVIRONMENT: prod                                        │
│  TG_GITLAB_PROJECT_ID: 67890                                │
│                                                              │
│  State Files:                                                │
│  ├── terraform/state/prod/app1/terraform.tfstate            │
│  └── terraform/state/prod/app2/terraform.tfstate            │
│                                                              │
│  Variables: terraform.prod.tfvars                            │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## Dependency Graph

```
app2 (DynamoDB Table)
  │
  └─── depends on ──→ app1 (S3 Bucket)
       
       Outputs from app1:
       ├── bucket_name
       ├── bucket_arn
       ├── bucket_region
       └── environment
       
       ↓ (passed to app2)
       
       Inputs to app2:
       ├── app1_bucket
       ├── app1_bucket_arn
       ├── app1_bucket_region
       └── app1_environment
```

## Deployment Order

### When deploying app2:
```
1. Check if app1 is deployed
   ├─ If not: Deploy app1 first
   └─ If yes: Continue
   
2. Run app2 pre-deployment script
   (pre-deploy.sh)
   
3. Deploy app2 with app1 outputs
   
4. Complete
```

## State File Path Resolution

```
State Path = https://gitlab.com/api/v4/projects/{project_id}/terraform/state/{environment}/{app}

Example for dev/app1:
  Project ID: 12345
  Environment: dev (from TG_ENVIRONMENT)
  App: app1 (from path_relative_to_include())
  
  Result: https://gitlab.com/api/v4/projects/12345/terraform/state/dev/app1

Example for prod/app2:
  Project ID: 67890
  Environment: prod (from TG_ENVIRONMENT)
  App: app2 (from path_relative_to_include())
  
  Result: https://gitlab.com/api/v4/projects/67890/terraform/state/prod/app2
```

## Configuration Hierarchy

```
┌─────────────────────────────────────────┐
│  Environment Variables                  │
│  (TG_ENVIRONMENT, TG_GITLAB_PROJECT_ID) │
└─────────────────────────────────────────┘
           ▲
           │ read by
           │
┌─────────────────────────────────────────┐
│  Root terragrunt.hcl                    │
│  (Backend & Provider Configuration)     │
└─────────────────────────────────────────┘
           ▲
           │ included by
           │
┌──────────────────────┬──────────────────┐
│                      │                  │
▼                      ▼                  ▼
app1/              app2/            (other apps)
terragrunt.hcl     terragrunt.hcl
│                  │
▼                  ▼
app1/              app2/
terraform.tfvars   terraform.tfvars
│                  │
▼                  ▼
modules/app1/      modules/app2/
main.tf            main.tf
```

---

This architecture ensures:
- ✅ Complete environment isolation
- ✅ No state file mixing
- ✅ Proper dependency management
- ✅ Easy scaling to new environments
- ✅ Clear deployment paths
