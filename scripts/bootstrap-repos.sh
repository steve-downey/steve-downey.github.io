#!/usr/bin/env bash
# bootstrap-repos.sh
#
# Starting from an empty directory: clone each repo from bbgithub
# (authoritative), add github.com as a mirror remote, rebase any
# github-only commits onto the bbgithub history, then push to both.
#
# bbgithub is the source of truth.  github is the mirror.  If github has
# commits that aren't on bbgithub (e.g. someone pushed there directly),
# they are rebased onto the bbgithub tip before pushing to both remotes.
#
# Run from whatever directory you want the clones to live in.

set -euo pipefail

BB_BASE="git@bbgithub.dev.bloomberg.com:sdowney"
GH_BASE="git@github.com:steve-downey"

REPOS=(
    trees
    wctm
    secretaire
)

# ---------------------------------------------------------------------------

integrate_branch() {
    # Examine one github branch.  If github has unique commits not on
    # bbgithub, rebase them onto the bbgithub tip and update the local
    # branch.  Returns 1 (and leaves a warning) if manual intervention is
    # needed.
    local branch="$1"
    local bb_ref="origin/$branch"
    local gh_ref="github/$branch"

    # Branch exists only on github — check it out locally
    if ! git rev-parse --verify "$bb_ref" &>/dev/null; then
        echo "    '$branch': github-only, checking out locally"
        git checkout -b "$branch" "$gh_ref" 2>/dev/null || true
        return 0
    fi

    local bb_tip gh_tip
    bb_tip=$(git rev-parse "$bb_ref")
    gh_tip=$(git rev-parse "$gh_ref")

    # Identical — nothing to do
    [[ "$bb_tip" == "$gh_tip" ]] && return 0

    # Same tree, different hash: bbgithub had a history rewrite (e.g.
    # co-author removal).  bbgithub wins; the force-push below handles it.
    if [[ "$(git rev-parse "${bb_ref}^{tree}")" == "$(git rev-parse "${gh_ref}^{tree}")" ]]; then
        echo "    '$branch': same content, different hash (history rewrite) — bbgithub wins"
        return 0
    fi

    local merge_base
    merge_base=$(git merge-base "$bb_tip" "$gh_tip" 2>/dev/null || true)

    if [[ -z "$merge_base" ]]; then
        echo "    WARNING '$branch': unrelated histories — skipping, needs manual review"
        return 1
    fi

    # bbgithub already contains everything github has — no action
    [[ "$merge_base" == "$gh_tip" ]] && return 0

    # github has unique commits; rebase them onto the bbgithub tip
    local n
    n=$(git log --oneline "${merge_base}..${gh_ref}" | wc -l | tr -d ' ')
    echo "    '$branch': rebasing $n github-only commit(s) onto bbgithub..."

    local tmp="tmp/integrate-${branch}-$$"
    git checkout -b "$tmp" "$gh_ref"

    if git rebase --onto "$bb_ref" "$merge_base" --; then
        local rebased
        rebased=$(git rev-parse HEAD)
        git checkout -
        git branch -f "$branch" "$rebased"
        git branch -D "$tmp"
        echo "    '$branch': rebased OK"
        return 0
    else
        git rebase --abort 2>/dev/null || true
        git checkout -
        git branch -D "$tmp" 2>/dev/null || true
        echo "    WARNING '$branch': rebase conflict — keeping bbgithub version, manual integration needed"
        return 1
    fi
}

setup_repo() {
    local name="$1"
    echo ""
    echo "=== $name ==="

    # Clone from bbgithub if not already present
    if [[ ! -d "$name/.git" ]]; then
        echo "  Cloning from bbgithub..."
        git clone "${BB_BASE}/${name}.git" "$name"
    else
        echo "  Directory exists — fetching from bbgithub..."
        git -C "$name" fetch origin --all --prune
    fi

    cd "$name"

    # Create local tracking branches for all bbgithub branches
    for ref in $(git branch -r | grep -E '^\s+origin/' | grep -v 'HEAD'); do
        local branch="${ref##*/}"
        git rev-parse --verify "$branch" &>/dev/null || git branch "$branch" "$ref"
    done

    # Check out the default branch
    local default_branch
    default_branch=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null \
        | sed 's|origin/||' || echo "main")
    git checkout "$default_branch"

    # Set up github remote (repos already exist)
    if ! git remote get-url github &>/dev/null 2>&1; then
        git remote add github "${GH_BASE}/${name}.git"
        echo "  Added github remote."
    fi

    # Fetch from github (tolerate empty repo on first bootstrap)
    git fetch github --all 2>/dev/null || true

    # Integrate any github-unique work, per branch
    local need_review=0
    for ref in $(git branch -r | grep -E '^\s+github/' | grep -v 'HEAD'); do
        local branch="${ref##*/}"
        integrate_branch "$branch" || need_review=1
    done

    # Push to bbgithub (incorporates any rebased github work)
    echo "  Pushing to bbgithub..."
    git push origin --all
    git push origin --tags

    # Push to github.  github is a mirror; bbgithub is authoritative.
    # --force is intentional: we want github to match bbgithub exactly,
    # including after history rewrites.  --force-with-lease is unsuitable
    # here because it fails with "stale info" when the remote-tracking refs
    # predate a force-push on the bbgithub side (e.g. co-author removal).
    echo "  Pushing to github..."
    git push github --all --force
    git push github --tags --force

    if [[ "$need_review" -ne 0 ]]; then
        echo "  *** One or more branches need manual integration — see warnings above ***"
    fi

    echo "  Done."
    cd ..
}

# ---------------------------------------------------------------------------

for repo in "${REPOS[@]}"; do
    setup_repo "$repo"
done

echo ""
echo "Bootstrap complete."
echo "  origin → bbgithub.dev.bloomberg.com:sdowney/* (authoritative)"
echo "  github → github.com/steve-downey/*            (mirror)"
