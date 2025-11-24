#!/bin/bash
# Environment Setup Script for Terragrunt
# This script helps set the deployment environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Terragrunt Environment Setup        ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo ""

# Prompt for environment
echo -e "${YELLOW}Select deployment environment:${NC}"
echo "  1) dev      - Development environment (shared state)"
echo "  2) staging  - Staging environment (user-isolated state)"
echo "  3) prod     - Production environment (user-isolated state)"
echo ""
read -p "Enter your choice [1-3]: " choice

case $choice in
    1)
        DEPLOY_ENV="dev"
        ;;
    2)
        DEPLOY_ENV="staging"
        ;;
    3)
        DEPLOY_ENV="prod"
        ;;
    *)
        echo -e "${RED}Invalid choice. Please run the script again.${NC}"
        exit 1
        ;;
esac

# Export the environment variable
export DEPLOY_ENV

echo ""
echo -e "${GREEN}✓ Environment set to: ${DEPLOY_ENV}${NC}"
echo ""

# Check if required environment variables are set
echo -e "${BLUE}Checking required environment variables...${NC}"

MISSING_VARS=()

# Check GitLab variables
if [ -z "$GITLAB_PROJECT_ID" ]; then
    MISSING_VARS+=("GITLAB_PROJECT_ID")
fi

if [ -z "$GITLAB_USERNAME" ]; then
    MISSING_VARS+=("GITLAB_USERNAME")
fi

if [ -z "$GITLAB_ACCESS_TOKEN" ]; then
    MISSING_VARS+=("GITLAB_ACCESS_TOKEN")
fi

# Check AWS variables
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    MISSING_VARS+=("AWS_ACCESS_KEY_ID")
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    MISSING_VARS+=("AWS_SECRET_ACCESS_KEY")
fi

# Check AMI ID
if [ -z "$AMI_ID" ]; then
    MISSING_VARS+=("AMI_ID")
fi

# Check database credentials
if [ -z "$DB_PASSWORD" ]; then
    MISSING_VARS+=("DB_PASSWORD")
fi

# Display results
if [ ${#MISSING_VARS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ All required environment variables are set${NC}"
else
    echo -e "${YELLOW}⚠ Missing environment variables:${NC}"
    for var in "${MISSING_VARS[@]}"; do
        echo -e "  ${RED}✗${NC} $var"
    done
    echo ""
    echo -e "${YELLOW}Please set these variables before running Terragrunt.${NC}"
    echo -e "${YELLOW}See README.md for details.${NC}"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}Environment: ${DEPLOY_ENV}${NC}"

if [ "$DEPLOY_ENV" != "dev" ]; then
    echo -e "${YELLOW}Note: State will be isolated under ${GITLAB_USERNAME}/${DEPLOY_ENV}${NC}"
else
    echo -e "${YELLOW}Note: Using shared dev state${NC}"
fi

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "  cd $DEPLOY_ENV"
echo "  terragrunt run-all plan"
echo ""
echo -e "${YELLOW}Note: This script must be sourced to export variables to your shell:${NC}"
echo -e "${BLUE}  source ./set-env.sh${NC}"
echo ""
