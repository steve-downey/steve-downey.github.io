#!/usr/bin/env bash
# split-secretaire-css.sh
#
# Promote secretaire-css.el from plugins/orgmode/ into its own directory,
# create sdowney/secretaire-css on BBGitHub, and populate it via git subtree
# split.
#
# secretaire-css.el is the standalone Emacs package for palette-aware CSS
# export from modus-themes faces.  wctm-css.el and strip_base_rules.py are
# wctm-specific and stay in plugins/orgmode/.
#
# The prep step (moving secretaire-css.el to plugins/secretaire-css/) commits
# a directory reorganization that enables git subtree to track it as an
# independent unit.  It only runs once — skipped if the directory exists.
#
# Run from the wctm repo root on the tailwind-theme branch (or after merge).

set -euo pipefail

REPO_ORG="sdowney"
REPO_NAME="secretaire-css"
REMOTE_URL="git@bbgithub.dev.bloomberg.com:${REPO_ORG}/${REPO_NAME}.git"
PREFIX="plugins/secretaire-css"
SPLIT_BRANCH="split/${REPO_NAME}"
SRC_DIR="plugins/orgmode"

if [[ ! -f conf.py ]] || [[ ! -d plugins ]]; then
    echo "Error: run from the wctm repo root" >&2
    exit 1
fi

# --- Prep: promote secretaire-css.el to its own directory ---

if [[ ! -d "$PREFIX" ]]; then
    echo "Prep: moving secretaire-css.el to $PREFIX/ ..."
    mkdir -p "$PREFIX"

    git mv "$SRC_DIR/secretaire-css.el" "$PREFIX/secretaire-css.el"

    # Default use-package config that ships with the package.
    # wctm-specific config stays in plugins/orgmode/wctm-css.el.
    cat > "$PREFIX/secretaire-css-use-package.el" << 'ELISP'
;;; secretaire-css-use-package.el --- Default use-package config  -*- lexical-binding: t; -*-

;; Default configuration for secretaire-css.
;; For machine-specific settings (output directory, extra modes), create
;; config/secretaire-css-use-package.el in your Emacs user directory.

;;; Code:

(use-package secretaire-css
  :ensure nil
  :commands (secretaire-css-export
             secretaire-css-export-current
             secretaire-css-export-modus-vivendi
             secretaire-css-export-modus-operandi
             secretaire-css-export-both-modus
             secretaire-css-menu
             secretaire-css-list-loaded-modes))

(provide 'secretaire-css-use-package)
;;; secretaire-css-use-package.el ends here
ELISP

    git add "$PREFIX/secretaire-css-use-package.el"

    git commit -m "move secretaire-css to plugins/secretaire-css/ for subtree split

Promotes secretaire-css.el from plugins/orgmode/ into its own
directory, enabling git subtree to track it as an independent unit.
wctm-css.el and strip_base_rules.py are wctm-specific and remain in
plugins/orgmode/."

    echo "Prep commit done."
else
    echo "Prep: $PREFIX already exists, skipping move."
fi

# --- Create remote repo ---

if ! git ls-remote "$REMOTE_URL" HEAD &>/dev/null 2>&1; then
    echo "Creating ${REPO_ORG}/${REPO_NAME} on BBGitHub..."
    gh repo create "${REPO_ORG}/${REPO_NAME}" \
        --description "Palette-aware CSS export from Emacs modus-themes faces" \
        --private
    echo "  Created."
else
    echo "Remote repo already exists — skipping creation."
fi

# --- Split ---

git branch -D "$SPLIT_BRANCH" 2>/dev/null || true

echo "Splitting $PREFIX (may take a while)..."
git subtree split --prefix="$PREFIX" --rejoin -b "$SPLIT_BRANCH"

echo "Pushing to ${REPO_NAME}..."
git push "$REMOTE_URL" "${SPLIT_BRANCH}:main"

git branch -D "$SPLIT_BRANCH"

echo ""
echo "Done. ${REPO_ORG}/${REPO_NAME} is ready at: $REMOTE_URL"
echo "Run add-subtree-remotes.sh to register for future pulls."
