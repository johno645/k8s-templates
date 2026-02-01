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
