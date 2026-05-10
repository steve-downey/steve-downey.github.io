#!/usr/bin/env bash
# push-subtrees.sh
#
# Push wctm changes to each external theme/package repo via git subtree push.
#
# Use this when you've made changes to a subtree directory in wctm and want
# to contribute them back to the standalone repo.  git subtree push extracts
# commits that touched the prefix and pushes them to the remote.
#
# NOTE: This rewrites the commits' perspective so they look like they only
# touch the root of the standalone repo (not themes/nikola-tailwind-base/).
# The standalone repo maintainer can merge or fast-forward as normal.
#
# Prerequisites:
#   - add-subtree-remotes.sh has been run
#   - Changes are committed in wctm
#
# Run from the wctm repo root.

set -euo pipefail

if [[ ! -f conf.py ]] || [[ ! -d themes ]]; then
    echo "Error: run from the wctm repo root" >&2
    exit 1
fi

push_subtree() {
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

    echo "Pushing $prefix → $remote/main ..."
    git subtree push --prefix="$prefix" "$remote" main
    echo "  Done."
}

push_subtree "nikola-tailwind-base" "themes/nikola-tailwind-base"
push_subtree "nikola-tailwind-blog" "themes/nikola-tailwind-blog"
push_subtree "secretaire-css"       "plugins/secretaire-css"

echo ""
echo "All subtrees pushed."
