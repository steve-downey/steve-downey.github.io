#!/usr/bin/env bash
# add-subtree-remotes.sh
#
# Register the split-out repos as git remotes in wctm, and record the
# current subtree HEAD for each.  After this, pull-subtrees.sh can fetch
# upstream changes and merge them back into the correct prefix.
#
# Run this after running each split-*.sh script.
# Safe to re-run — existing remotes are skipped with a warning.
#
# Run from the wctm repo root.

set -euo pipefail

if [[ ! -f conf.py ]] || [[ ! -d themes ]]; then
    echo "Error: run from the wctm repo root" >&2
    exit 1
fi

add_remote() {
    local name="$1"
    local url="$2"
    local prefix="$3"

    if git remote get-url "$name" &>/dev/null; then
        echo "Remote '$name' already exists — skipping (url: $(git remote get-url $name))"
        return
    fi

    if ! git ls-remote "$url" HEAD &>/dev/null; then
        echo "Warning: cannot reach $url — skipping '$name'"
        echo "  (Run split-${name}.sh first to create the remote repo)"
        return
    fi

    git remote add "$name" "$url"
    echo "Added remote '$name' → $url"

    # Record the subtree state so future subtree pull knows the merge base.
    # This requires the prefix directory to already be in the repo.
    if [[ -d "$prefix" ]]; then
        git fetch "$name" main
        echo "  Fetched $name/main"
        # --rejoin writes a synthetic merge commit that lets subtree operations
        # be fast on subsequent runs.
        git subtree split --prefix="$prefix" --rejoin -b "split/${name}-rejoin" 2>/dev/null
        git branch -D "split/${name}-rejoin" 2>/dev/null || true
        echo "  Recorded subtree split point for $prefix"
    else
        echo "  Warning: $prefix not found in working tree; skipping rejoin"
    fi
}

add_remote \
    "nikola-tailwind-base" \
    "git@bbgithub.dev.bloomberg.com:sdowney/nikola-tailwind-base.git" \
    "themes/nikola-tailwind-base"

add_remote \
    "nikola-tailwind-blog" \
    "git@bbgithub.dev.bloomberg.com:sdowney/nikola-tailwind-blog.git" \
    "themes/nikola-tailwind-blog"

add_remote \
    "secretaire-css" \
    "git@bbgithub.dev.bloomberg.com:sdowney/secretaire-css.git" \
    "plugins/secretaire-css"

echo ""
echo "Done. To pull upstream changes: bash scripts/pull-subtrees.sh"
