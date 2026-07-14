#!/usr/bin/env bash
# split-nikola-tailwind-base.sh
#
# Create sdowney/nikola-tailwind-base on BBGitHub and populate it from
# themes/nikola-tailwind-base/ via git subtree split.
#
# Run from the wctm repo root on any branch that contains the theme
# (typically tailwind-theme, or after merge to src).

set -euo pipefail

REPO_ORG="sdowney"
REPO_NAME="nikola-tailwind-base"
REMOTE_URL="git@bbgithub.dev.bloomberg.com:${REPO_ORG}/${REPO_NAME}.git"
PREFIX="themes/nikola-tailwind-base"
SPLIT_BRANCH="split/${REPO_NAME}"

if [[ ! -f conf.py ]] || [[ ! -d themes ]]; then
    echo "Error: run from the wctm repo root" >&2
    exit 1
fi

if [[ ! -d "$PREFIX" ]]; then
    echo "Error: $PREFIX does not exist" >&2
    exit 1
fi

# Create the remote repo if it doesn't exist
if ! git ls-remote "$REMOTE_URL" HEAD &>/dev/null 2>&1; then
    echo "Creating ${REPO_ORG}/${REPO_NAME} on BBGitHub..."
    gh repo create "${REPO_ORG}/${REPO_NAME}" \
        --description "Generic Tailwind CSS base theme for Nikola static sites" \
        --private
    echo "  Created."
else
    echo "Remote repo already exists — skipping creation."
fi

git branch -D "$SPLIT_BRANCH" 2>/dev/null || true

echo "Splitting $PREFIX (may take a while)..."
git subtree split --prefix="$PREFIX" --rejoin -b "$SPLIT_BRANCH"

echo "Pushing to ${REPO_NAME}..."
git push "$REMOTE_URL" "${SPLIT_BRANCH}:main"

git branch -D "$SPLIT_BRANCH"

echo ""
echo "Done. ${REPO_ORG}/${REPO_NAME} is ready at: $REMOTE_URL"
echo "Run add-subtree-remotes.sh to register for future pulls."
