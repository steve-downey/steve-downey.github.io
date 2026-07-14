#!/usr/bin/env bash
# remove-from-wctm.sh
#
# Remove split-out directories from wctm once they live in standalone repos.
# This is the FINAL step — run only after:
#   1. All three split-*.sh scripts have been run
#   2. add-subtree-remotes.sh has been run
#   3. The standalone repos are verified to be correct
#   4. sdowney-tailwind.theme has been updated to reference external repos
#      (if using submodules) or the subtree remotes are registered (if using
#      git subtree pull going forward)
#
# This commits the removal but does NOT push.  Review the diff, then push
# manually.
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

echo "About to remove the following from wctm:"
echo "  themes/nikola-tailwind-base/"
echo "  themes/nikola-tailwind-blog/"
echo "  plugins/secretaire-css/"
echo ""
echo "This is irreversible in this branch.  The content is preserved in:"
echo "  git@bbgithub.dev.bloomberg.com:sdowney/nikola-tailwind-base.git"
echo "  git@bbgithub.dev.bloomberg.com:sdowney/nikola-tailwind-blog.git"
echo "  git@bbgithub.dev.bloomberg.com:sdowney/secretaire-css.git"
echo ""
read -r -p "Continue? [y/N] " response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

removed=()

if [[ -d "themes/nikola-tailwind-base" ]]; then
    git rm -r "themes/nikola-tailwind-base"
    removed+=("themes/nikola-tailwind-base")
fi

if [[ -d "themes/nikola-tailwind-blog" ]]; then
    git rm -r "themes/nikola-tailwind-blog"
    removed+=("themes/nikola-tailwind-blog")
fi

if [[ -d "plugins/secretaire-css" ]]; then
    git rm -r "plugins/secretaire-css"
    removed+=("plugins/secretaire-css")
fi

if [[ ${#removed[@]} -eq 0 ]]; then
    echo "Nothing to remove — directories not found."
    exit 0
fi

git commit -m "remove subtree directories: now in standalone repos

The following directories have been split into standalone repositories
and removed from wctm:

$(printf '  %s\n' "${removed[@]}")

Use 'git subtree pull' with the registered remotes to bring in future
upstream changes, or manage them as git submodules."

echo ""
echo "Removal committed.  To push: git push origin HEAD"
echo ""
echo "To pull future upstream changes, use pull-subtrees.sh."
