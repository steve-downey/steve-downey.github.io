#!/usr/bin/env bash
# pull-subtrees.sh
#
# Pull upstream changes from each external theme/package repo into the
# corresponding wctm subdirectory via git subtree merge.
#
# Use this when a standalone repo has been updated and you want to bring
# those changes into wctm.  It creates a merge commit in wctm history that
# attributes the incoming changes to the external repo.
#
# Prerequisites:
#   - add-subtree-remotes.sh has been run
#   - Working tree is clean (commit or stash first)
#
# Run from the wctm repo root.

set -euo pipefail

if [[ ! -f conf.py ]] || [[ ! -d themes ]]; then
    echo "Error: run from the wctm repo root" >&2
    exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Error: working tree has uncommitted changes — commit or stash first" >&2
    exit 1
fi

pull_subtree() {
    local remote="$1"
    local prefix="$2"

    if ! git remote get-url "$remote" &>/dev/null; then
        echo "Skipping '$remote': remote not registered (run add-subtree-remotes.sh)"
        return
    fi

    if [[ ! -d "$prefix" ]]; then
        echo "Skipping '$remote': $prefix not found in working tree"
        return
    fi

    echo "Pulling $remote/main → $prefix ..."
    git fetch "$remote" main
    git subtree pull --prefix="$prefix" --squash "$remote" main \
        -m "subtree pull: $remote → $prefix"
    echo "  Done."
}

pull_subtree "nikola-tailwind-base" "themes/nikola-tailwind-base"
pull_subtree "nikola-tailwind-blog" "themes/nikola-tailwind-blog"
pull_subtree "secretaire-css"       "plugins/secretaire-css"

echo ""
echo "All subtrees updated."
