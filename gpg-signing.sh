#!/bin/bash

# Script to retroactively GPG sign all commits in a git repository
# WARNING: This rewrites git history and will require force-pushing

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${YELLOW}================================================${NC}"
echo -e "${YELLOW}Git Commit GPG Signing Script${NC}"
echo -e "${YELLOW}================================================${NC}"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Check if GPG is configured
if ! git config user.signingkey > /dev/null 2>&1; then
    echo -e "${RED}Error: No GPG signing key configured${NC}"
    echo "Please configure your signing key with:"
    echo "  git config user.signingkey YOUR_KEY_ID"
    exit 1
fi

# Get the signing key
SIGNING_KEY=$(git config user.signingkey)
echo -e "${GREEN}Using GPG key: ${SIGNING_KEY}${NC}"
echo ""

# Check if there are uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}Error: You have uncommitted changes${NC}"
    echo "Please commit or stash your changes before running this script"
    exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo -e "Current branch: ${GREEN}${CURRENT_BRANCH}${NC}"

# Get the number of commits to sign
COMMIT_COUNT=$(git rev-list --count HEAD)
echo -e "Total commits to sign: ${GREEN}${COMMIT_COUNT}${NC}"
echo ""

# Warning message
echo -e "${RED}⚠️  WARNING ⚠️${NC}"
echo -e "${YELLOW}This operation will:${NC}"
echo "1. Rewrite the entire git history of this branch"
echo "2. Change all commit hashes"
echo "3. Require force-pushing to remote repositories"
echo "4. Potentially cause conflicts for other collaborators"
echo ""
echo -e "${YELLOW}For shared repositories:${NC}"
echo "- Coordinate with your team before running this"
echo "- All collaborators will need to re-clone or reset their branches"
echo "- Protected branches may prevent force-pushing"
echo ""

# Confirmation
read -p "Do you want to continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Operation cancelled"
    exit 0
fi

echo ""
echo -e "${YELLOW}Starting to sign commits...${NC}"
echo ""

# Create a backup branch
BACKUP_BRANCH="backup-before-signing-$(date +%Y%m%d-%H%M%S)"
git branch "$BACKUP_BRANCH"
echo -e "${GREEN}Created backup branch: ${BACKUP_BRANCH}${NC}"
echo ""

# Filter-branch approach (works with older git versions)
# Use filter-repo if available (recommended for git 2.28+)
if command -v git-filter-repo &> /dev/null; then
    echo "Using git-filter-repo (recommended method)..."
    git filter-repo --commit-callback '
        commit.committer_date = commit.author_date
    ' --sign-commits "$SIGNING_KEY"
else
    # Fall back to filter-branch
    echo "Using git filter-branch..."
    git filter-branch -f --commit-filter '
        if [ "$GIT_COMMITTER_NAME" = "'"$(git config user.name)"'" ]; then
            git commit-tree -S "$@"
        else
            git commit-tree "$@"
        fi
    ' HEAD
fi

echo ""
echo -e "${GREEN}✓ All commits have been signed!${NC}"
echo ""

# Show some signed commits
echo "Sample of signed commits:"
git log --show-signature --oneline -5
echo ""

echo -e "${YELLOW}Next steps:${NC}"
echo "1. Verify the signatures: git log --show-signature"
echo "2. Push to remote (THIS REQUIRES FORCE PUSH):"
echo "   git push --force-with-lease origin ${CURRENT_BRANCH}"
echo ""
echo "3. If something went wrong, restore from backup:"
echo "   git reset --hard ${BACKUP_BRANCH}"
echo ""
echo -e "${RED}Remember:${NC} All team members will need to update their local repositories!"
echo "They should run: git fetch origin && git reset --hard origin/${CURRENT_BRANCH}"
echo ""
echo -e "${GREEN}Script completed successfully!${NC}"

#!/bin/bash

# Script to delete all S3 buckets matching the pattern “app-*”

# This script will empty buckets before deletion if they contain objects

set -e  # Exit on error

# Color codes for output

RED=’\033[0;31m’
GREEN=’\033[0;32m’
YELLOW=’\033[1;33m’
NC=’\033[0m’ # No Color

# Function to check if AWS CLI is installed

check_aws_cli() {
if ! command -v aws &> /dev/null; then
echo -e “${RED}Error: AWS CLI is not installed${NC}”
exit 1
fi
}

# Function to empty a bucket

empty_bucket() {
local bucket_name=$1
echo -e “${YELLOW}Emptying bucket: $bucket_name${NC}”

```
# Delete all object versions (for versioned buckets)
aws s3api delete-objects \
    --bucket "$bucket_name" \
    --delete "$(aws s3api list-object-versions \
        --bucket "$bucket_name" \
        --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
        --output json)" 2>/dev/null || true

# Delete all delete markers (for versioned buckets)
aws s3api delete-objects \
    --bucket "$bucket_name" \
    --delete "$(aws s3api list-object-versions \
        --bucket "$bucket_name" \
        --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
        --output json)" 2>/dev/null || true

# Delete all objects using s3 rm (for non-versioned buckets or remaining objects)
aws s3 rm "s3://$bucket_name" --recursive 2>/dev/null || true

echo -e "${GREEN}Bucket emptied: $bucket_name${NC}"
```

}

# Function to delete a bucket

delete_bucket() {
local bucket_name=$1
echo -e “${YELLOW}Deleting bucket: $bucket_name${NC}”

```
if aws s3api delete-bucket --bucket "$bucket_name" 2>/dev/null; then
    echo -e "${GREEN}Successfully deleted: $bucket_name${NC}"
    return 0
else
    echo -e "${RED}Failed to delete: $bucket_name${NC}"
    return 1
fi
```

}

# Main script

main() {
check_aws_cli

```
echo -e "${YELLOW}Fetching all S3 buckets matching pattern 'app-*'...${NC}"

# Get all buckets matching the pattern
buckets=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, 'app-')].Name" --output text)

if [ -z "$buckets" ]; then
    echo -e "${YELLOW}No buckets found matching pattern 'app-*'${NC}"
    exit 0
fi

# Count buckets
bucket_count=$(echo "$buckets" | wc -w)
echo -e "${YELLOW}Found $bucket_count bucket(s) to delete:${NC}"
echo "$buckets" | tr '\t' '\n'

# Ask for confirmation
echo ""
read -p "Are you sure you want to delete these buckets? (yes/no): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo -e "${YELLOW}Operation cancelled${NC}"
    exit 0
fi

# Process each bucket
success_count=0
fail_count=0

for bucket in $buckets; do
    echo ""
    echo -e "${YELLOW}Processing: $bucket${NC}"
    
    # Empty the bucket first
    if empty_bucket "$bucket"; then
        # Then delete the bucket
        if delete_bucket "$bucket"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    else
        echo -e "${RED}Failed to empty bucket: $bucket${NC}"
        ((fail_count++))
    fi
done

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deletion Summary:${NC}"
echo -e "${GREEN}Successfully deleted: $success_count${NC}"
if [ $fail_count -gt 0 ]; then
    echo -e "${RED}Failed to delete: $fail_count${NC}"
fi
echo -e "${GREEN}========================================${NC}"
```

}

# Run main function

main