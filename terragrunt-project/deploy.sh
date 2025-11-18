#!/bin/bash

# Terragrunt deployment helper script
# This script sets up environment variables and runs terragrunt commands
# Usage: ./deploy.sh dev|prod [init|plan|apply|destroy] [app1|app2|all]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <environment> <command> [app]"
    echo ""
    echo "Environments: dev, prod"
    echo "Commands: init, plan, apply, destroy"
    echo "Apps: app1, app2, all (default: all)"
    echo ""
    echo "Examples:"
    echo "  $0 dev plan"
    echo "  $0 prod apply app1"
    echo "  $0 dev destroy all"
    exit 1
fi

ENVIRONMENT=$1
COMMAND=$2
APP=${3:-all}

# Validate environment
if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]; then
    print_error "Invalid environment: $ENVIRONMENT"
    echo "Valid environments: dev, prod"
    exit 1
fi

# Validate command
if [ "$COMMAND" != "init" ] && [ "$COMMAND" != "plan" ] && [ "$COMMAND" != "apply" ] && [ "$COMMAND" != "destroy" ]; then
    print_error "Invalid command: $COMMAND"
    echo "Valid commands: init, plan, apply, destroy"
    exit 1
fi

# Validate app
if [ "$APP" != "app1" ] && [ "$APP" != "app2" ] && [ "$APP" != "all" ]; then
    print_error "Invalid app: $APP"
    echo "Valid apps: app1, app2, all"
    exit 1
fi

# Load environment-specific configuration
if [ ! -f "terraform.${ENVIRONMENT}.tfvars" ]; then
    print_error "Configuration file not found: terraform.${ENVIRONMENT}.tfvars"
    exit 1
fi

# Extract GitLab project ID from tfvars
GITLAB_PROJECT_ID=$(grep 'gitlab_project_id' terraform.${ENVIRONMENT}.tfvars | cut -d'=' -f2 | tr -d ' "')

if [ -z "$GITLAB_PROJECT_ID" ]; then
    print_error "Could not extract gitlab_project_id from terraform.${ENVIRONMENT}.tfvars"
    exit 1
fi

# Check for GitLab access token
if [ -z "$GITLAB_ACCESS_TOKEN" ]; then
    print_error "GITLAB_ACCESS_TOKEN environment variable not set"
    echo "Set it with: export GITLAB_ACCESS_TOKEN=your-token"
    exit 1
fi

# Set Terragrunt environment variables
export TG_ENVIRONMENT=$ENVIRONMENT
export TG_GITLAB_PROJECT_ID=$GITLAB_PROJECT_ID

print_info "Environment: $ENVIRONMENT"
print_info "GitLab Project ID: $GITLAB_PROJECT_ID"
print_info "Command: $COMMAND"
print_info "App(s): $APP"
echo ""

# Confirm before destructive operations
if [ "$COMMAND" = "destroy" ]; then
    print_warn "You are about to DESTROY infrastructure in $ENVIRONMENT"
    read -p "Type 'yes' to confirm: " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        print_info "Cancelled"
        exit 0
    fi
fi

# Execute terragrunt command
case $APP in
    app1)
        print_info "Running: cd app1 && terragrunt $COMMAND"
        cd app1
        terragrunt $COMMAND -var-file=../terraform.${ENVIRONMENT}.tfvars
        ;;
    app2)
        print_info "Running: cd app2 && terragrunt $COMMAND"
        cd app2
        terragrunt $COMMAND -var-file=../terraform.${ENVIRONMENT}.tfvars
        ;;
    all)
        print_info "Running: terragrunt run-all $COMMAND"
        terragrunt run-all $COMMAND -var-file=terraform.${ENVIRONMENT}.tfvars
        ;;
esac

print_info "Command completed successfully"
