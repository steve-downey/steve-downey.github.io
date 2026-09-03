;;; orgit-file-transclusion.el --- transclude UUID-anchored regions at a git rev  -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

;; Provenance: docs/epistolary-pinning-plan.md (section 3), shared across
;; compile-time-scheme sibling repositories by copy, not by load-path coupling.
;;
;; Link form: [[orgit-file:REPO::REV::PATH::UUID]]
;; Used with: :lines 2- :src LANG :end "UUID end"   (unchanged conventions)
;;
;; Where the sibling `orgit:' adapter in init.el resolves PATH against the
;; worktree -- showing the file as of now -- this one resolves it against REV,
;; so an epistolary post keeps showing the code its prose was written about.
;; REV is normally an annotated `blog/phase-NN' tag; see docs/blog/pins.md.
;;
;; No magit dependency: the blob comes from a `git show' subprocess, so batch
;; export stays light. The interactive `orgit-file' package (gggion/orgit-file)
;; uses the same link syntax, so installing it makes these links followable in
;; a live Emacs, but nothing here requires it.

;;; Commentary:
;;
;; Implementation note -- why this extracts a blob to a file instead of
;; slicing the region itself:
;;
;; `org-transclusion-add-src-lines' already implements the exact semantics the
;; posts depend on, and they are fiddlier than they look.  `:end' is EXCLUSIVE
;; of the line holding the end marker; `:lines 2-' counts forward from the
;; anchor line found by the search option, not from the top of the file; and
;; `:src cpp' wraps the result in a fenced block.  Reimplementing that slicing
;; would duplicate three behaviours that must not drift.
;;
;; So this adapter mirrors `org-transclusion-add-orgit': it materialises the
;; pinned blob, rewrites the link in place into a plain `file:' link with the
;; same `::UUID' search option, and returns nil so the standard src-lines
;; handler does the work.  Post attributes keep meaning exactly what they
;; meant under worktree resolution -- by construction, not by imitation.
;;
;; The blob is written under a path that preserves the original repo-relative
;; path, so `find-file-noselect' picks the same major mode it would have for
;; the real file.  `org-link-search', which resolves the `::UUID' anchor, is
;; mode-sensitive, so this is what keeps anchor resolution identical.

;;; Code:

(require 'org-transclusion)
(require 'subr-x)
(require 'seq)

(defgroup orgit-file-transclusion nil
  "Transclude UUID-anchored source regions pinned to a git revision."
  :group 'org-transclusion)

(defcustom orgit-file-transclusion-cache-dir
  (expand-file-name "orgit-file-transclusion" temporary-file-directory)
  "Directory holding blobs extracted from git.
Contents are disposable: each blob is cached under its resolved commit
SHA, so a stale entry cannot be served for a different revision."
  :type 'directory
  :group 'orgit-file-transclusion)

(defcustom orgit-file-transclusion-remote "origin"
  "Name of the git remote a checkout's forge URL is derived from.
A blog draws posts from many source repositories, so the forge cannot be
a single constant: it is read per-link from the REPO component.  Where a
checkout has several remotes -- a personal fork as `origin' and the
project it tracks as `upstream' -- this picks which one a permalink
should point at."
  :type 'string
  :group 'orgit-file-transclusion)

(defcustom orgit-file-transclusion-forge-alist nil
  "Alist of (CHECKOUT-REGEXP . BASE-URL) overriding remote derivation.
CHECKOUT-REGEXP is matched against the expanded REPO path; the first
match wins.  BASE-URL is everything a permalink needs before the
revision, with a trailing slash -- so it also carries the forge's own
path convention, which is how a host that does not spell it
`.../blob/REV/PATH' (GitLab, sourcehut) is accommodated.

Leave this nil unless a checkout needs it.  Deriving from the remote is
what keeps a permalink honest when a repository moves."
  :type '(alist :key-type regexp :value-type string)
  :group 'orgit-file-transclusion)

(defvar orgit-file-transclusion--forge-cache (make-hash-table :test 'equal)
  "Memoised REPO -> base URL, so a post costs one `git remote' per repo.")

(defun orgit-file-transclusion--remote-url (repo)
  "Return the URL of `orgit-file-transclusion-remote' in REPO, or nil."
  (with-temp-buffer
    (when (zerop (call-process "git" nil t nil
                               "-C" (expand-file-name repo)
                               "remote" "get-url"
                               orgit-file-transclusion-remote))
      (let ((url (string-trim (buffer-string))))
        (unless (string-empty-p url) url)))))

(defun orgit-file-transclusion--browse-url (remote-url)
  "Convert REMOTE-URL, in any of git's transports, to a browsable base.
Returns nil for a URL with no recognisable host and path, which includes
a purely local remote -- a path or a `file://' URL names no forge."
  (let ((url (string-trim remote-url)))
    ;; scp-style `git@host:owner/name.git' is not a URI; normalise it first.
    ;; Guarded on the absence of a scheme, or `https://host/p' would parse as
    ;; host "https" with everything after the colon as its path.
    (when (and (not (string-match-p "://" url))
               (string-match "\\`\\(?:[^/@:]+@\\)?\\([^/:]+\\):\\(.+\\)\\'" url))
      (setq url (concat "https://" (match-string 1 url) "/" (match-string 2 url))))
    (when (string-match "\\`\\(?:https?\\|ssh\\|git\\)://\\(?:[^/@]+@\\)?\\([^/]+\\)/\\(.+\\)\\'" url)
      (let ((host (match-string 1 url))
            (path (match-string 2 url)))
        ;; A port belongs to the transport, not to the web front end.
        (setq host (replace-regexp-in-string ":[0-9]+\\'" "" host))
        (setq path (replace-regexp-in-string "/+\\'" "" path))
        (setq path (replace-regexp-in-string "\\.git\\'" "" path))
        (unless (string-empty-p path)
          (format "https://%s/%s" host path))))))

(defun orgit-file-transclusion--forge-base (repo)
  "Return the permalink base URL for checkout REPO, with a trailing slash.
Consults `orgit-file-transclusion-forge-alist' first, then the URL of
`orgit-file-transclusion-remote'.  Signals if neither yields one: a
permalink pointing at the wrong repository is worse than a failed
build."
  (let ((key (expand-file-name repo)))
    (or (gethash key orgit-file-transclusion--forge-cache)
        (puthash
         key
         (or (cdr (seq-find (lambda (entry) (string-match-p (car entry) key))
                            orgit-file-transclusion-forge-alist))
             (let* ((remote (orgit-file-transclusion--remote-url repo))
                    (browse (and remote
                                 (orgit-file-transclusion--browse-url remote))))
               (unless browse
                 (error "orgit-file: no forge URL for %s (remote %S is %s); \
set orgit-file-transclusion-forge-alist"
                        repo orgit-file-transclusion-remote
                        (if remote (format "%S" remote) "missing")))
               (concat browse "/blob/")))
         orgit-file-transclusion--forge-cache))))

(defun orgit-file-transclusion--parse (raw)
  "Split RAW into (REPO REV PATH UUID); signal on any other shape."
  (let ((parts (split-string raw "::")))
    (unless (= 4 (length parts))
      (error "orgit-file link needs REPO::REV::PATH::UUID, got: %s" raw))
    parts))

(defun orgit-file-transclusion--rev-parse (repo rev)
  "Resolve REV to a full commit SHA in REPO."
  (with-temp-buffer
    (unless (zerop (call-process "git" nil t nil
                                 "-C" (expand-file-name repo)
                                 "rev-parse" (concat rev "^{commit}")))
      (error "orgit-file: cannot resolve rev %s in %s (fetch tags?): %s"
             rev repo (string-trim (buffer-string))))
    (string-trim (buffer-string))))

(defun orgit-file-transclusion--blob-file (repo rev path)
  "Materialise PATH at REV in REPO as a local file; return its name.
The returned path ends in PATH, so the buffer gets the major mode it
would have had for the real file."
  (let* ((sha (orgit-file-transclusion--rev-parse repo rev))
         (cached (expand-file-name
                  path (expand-file-name sha orgit-file-transclusion-cache-dir))))
    (unless (file-exists-p cached)
      (make-directory (file-name-directory cached) t)
      ;; Write via a temp name and rename, so a failed `git show' can never
      ;; leave a truncated blob behind for a later run to trust.
      (let ((tmp (concat cached ".partial")))
        (with-temp-buffer
          (unless (zerop (call-process "git" nil t nil
                                       "-C" (expand-file-name repo)
                                       "show" (format "%s:%s" sha path)))
            (error "orgit-file: git show %s:%s failed in %s: %s"
                   rev path repo (string-trim (buffer-string))))
          (let ((coding-system-for-write 'no-conversion))
            (write-region (point-min) (point-max) tmp nil 'quiet)))
        (rename-file tmp cached t)))
    cached))

(defun orgit-file-transclusion-add (link _plist)
  "Resolve an `orgit-file' LINK into a `file' link on the pinned blob.
Mutates LINK in place and returns nil, so `org-transclusion-add-src-lines'
applies the post's :lines/:src/:end attributes exactly as it does for a
worktree-resolved link."
  (when (string= "orgit-file" (org-element-property :type link))
    (pcase-let* ((`(,repo ,rev ,path ,uuid)
                  (orgit-file-transclusion--parse
                   (org-element-property :path link)))
                 (blob (orgit-file-transclusion--blob-file repo rev path)))
      ;; Mutate in place so downstream handlers see the resolved file path.
      (org-element-put-property link :type "file")
      (org-element-put-property link :path blob)
      (org-element-put-property link :raw-link (concat "file:" blob "::" uuid))
      (org-element-put-property link :search-option uuid)))
  ;; Always nil: let the next add-function build the payload.
  nil)

(add-hook 'org-transclusion-add-functions #'orgit-file-transclusion-add)

;; Export `orgit-file' links as forge permalinks at the pinned revision.
;; The forge comes from REPO, not from a constant: a blog collects posts from
;; several source repositories, and they cannot share one base URL.
(org-link-set-parameters
 "orgit-file"
 :export
 (lambda (path desc backend)
   ;; Tolerates a UUID-less link: inline prose often points at a whole file
   ;; at the pinned revision, where a region anchor would say nothing.
   (let* ((parts (split-string path "::"))
          (repo (nth 0 parts))
          (rev (nth 1 parts))
          (filepath (nth 2 parts))
          (url (progn
                 (unless (and repo rev filepath)
                   (error "orgit-file link needs REPO::REV::PATH[::UUID], got: %s"
                          path))
                 (concat (orgit-file-transclusion--forge-base repo)
                         rev "/" filepath))))
     (cond
      ((memq backend '(md gfm)) (format "[`%s`](%s)" (or desc filepath) url))
      ((eq backend 'html)
       (format "<a href=\"%s\"><code>%s</code></a>" url (or desc filepath)))
      (t url)))))

(provide 'orgit-file-transclusion)
;;; orgit-file-transclusion.el ends here
