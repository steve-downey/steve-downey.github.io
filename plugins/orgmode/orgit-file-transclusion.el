;;; orgit-file-transclusion.el --- transclude UUID-anchored regions at a git rev  -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

;; Provenance: docs/epistolary-pinning-plan.md (section 3), shared across
;; compile-time-scheme sibling repositories by copy, not by load-path coupling.
;;
;; Link form: [[orgit-file:REPO::REV::PATH::UUID]]
;; Used with: :lines 2- :src LANG :end "UUID end"   (unchanged conventions)
;;
;; Where the sibling `orgit:' adapter in init.el resolves PATH against a
;; worktree -- showing the file as of now -- this one resolves it against REV,
;; so an epistolary post keeps showing the code its prose was written about.
;; REV is normally an annotated `blog/...' tag; see the source repo's pins
;; table.
;;
;; This copy differs from the one in a source repository, and the difference is
;; the point.  There, a post is in flight and REPO is a checkout on the laptop
;; it is being written on.  Here the post is published: it needs an address
;; that outlives any checkout, and building the site must not require one to
;; exist.  So REPO is resolved to a repository on GitHub -- directly when a
;; link already names one, otherwise through the site's own translation table
;; -- and the pinned code is read from a local bare mirror of it, cloned on
;; demand.  Nothing here reads a working tree.

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
;;
;; Implementation note -- the mirror:
;;
;; A pin is a tag and a path, which is all `git show' needs; it does not need
;; a working tree, and it does not need file content for anything the post
;; does not transclude.  So the mirror is cloned `--bare --filter=blob:none':
;; history and tags arrive, and a blob is fetched only when some post actually
;; asks for it.  The mirrors and the extracted blobs are caches -- deleting
;; either costs one clone, never correctness, because everything is addressed
;; by a commit SHA the tag resolved to.

;;; Code:

(require 'org-transclusion)
(require 'subr-x)
(require 'seq)
(require 'xdg)

(defgroup orgit-file-transclusion nil
  "Transclude UUID-anchored source regions pinned to a git revision."
  :group 'org-transclusion)

(defcustom orgit-file-transclusion-repo-alist nil
  "Alist of (REPO-REGEXP . \"owner/name\") naming source repositories on GitHub.

REPO-REGEXP is matched against the REPO component of a link exactly as
the post spells it; the first match wins.  The value is the repository's
permanent home, which is where its pinned code is read from.

This table exists because a post is drafted somewhere else.  In its
source repository the link names a checkout -- a path that differs
between laptops and means nothing on a build host.  Published here it
needs an address that outlives the checkout, and this is where that
translation is recorded, in the site, under version control.

A link that already names `owner/name', or gives a GitHub URL in any
form git accepts, is understood without an entry.  The table is
consulted first regardless, so it can always override."
  :type '(alist :key-type regexp :value-type string)
  :group 'orgit-file-transclusion)

(defcustom orgit-file-transclusion-github-url "https://github.com/"
  "Base URL of the forge, with a trailing slash.
Used both to clone a mirror and to build a permalink."
  :type 'string
  :group 'orgit-file-transclusion)

(defcustom orgit-file-transclusion-mirror-dir
  (expand-file-name "orgit-file-transclusion/mirrors" (xdg-cache-home))
  "Directory holding bare mirrors of the repositories posts pin to.
A cache: deleting it costs one clone per repository, never correctness."
  :type 'directory
  :group 'orgit-file-transclusion)

(defcustom orgit-file-transclusion-cache-dir
  (expand-file-name "orgit-file-transclusion/blobs" (xdg-cache-home))
  "Directory holding blobs extracted from a mirror.
Contents are disposable: each blob is cached under the repository and
the resolved commit SHA, so a stale entry cannot be served for a
different revision."
  :type 'directory
  :group 'orgit-file-transclusion)

(defvar orgit-file-transclusion--fetched (make-hash-table :test 'equal)
  "Repositories already refreshed this session, so a build fetches once.")

(defun orgit-file-transclusion--git (what &rest args)
  "Run git with ARGS, returning its trimmed output.
Signal a message beginning WHAT, with git's own diagnosis, on failure."
  (with-temp-buffer
    (unless (zerop (apply #'call-process "git" nil t nil args))
      (error "orgit-file: %s: %s" what (string-trim (buffer-string))))
    (string-trim (buffer-string))))

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

(defun orgit-file-transclusion--self-naming-slug (repo)
  "Return the \"owner/name\" REPO names on the forge, or nil if it names none.
Accepts a bare slug and any URL form git accepts."
  (cond
   ;; A bare `owner/name': two segments and nothing that could be a scheme, a
   ;; host or a home directory.  Tested before the URL forms, since
   ;; `file-name-directory' sees the separator in a slug too.
   ((string-match-p
     "\\`[A-Za-z0-9][A-Za-z0-9._-]*/[A-Za-z0-9][A-Za-z0-9._-]*\\'" repo)
    repo)
   (t (let ((browse (orgit-file-transclusion--browse-url repo)))
        (when (and browse
                   (string-prefix-p orgit-file-transclusion-github-url browse))
          (substring browse (length orgit-file-transclusion-github-url)))))))

(defun orgit-file-transclusion--slug (repo)
  "Resolve REPO, as a link spells it, to a GitHub \"owner/name\".
The site's table wins over a self-naming link, so a post can be
redirected without editing it."
  (let ((s (string-trim repo)))
    (or (cdr (seq-find (lambda (entry) (string-match-p (car entry) s))
                       orgit-file-transclusion-repo-alist))
        (orgit-file-transclusion--self-naming-slug s)
        (error "orgit-file: %s names no GitHub repository; add it to \
orgit-file-transclusion-repo-alist" repo))))

(defun orgit-file-transclusion--mirror (slug)
  "Return the local bare mirror of SLUG, cloning it if it is not there yet.
Blobless: history and tags arrive with the clone, and a file's content
is fetched only when a post transcludes it."
  (let ((dir (expand-file-name (concat slug ".git")
                               orgit-file-transclusion-mirror-dir)))
    (unless (file-directory-p dir)
      (make-directory (file-name-directory dir) t)
      (orgit-file-transclusion--git
       (format "cannot mirror %s" slug)
       "clone" "--bare" "--filter=blob:none" "--quiet"
       (concat orgit-file-transclusion-github-url slug) dir))
    dir))

(defun orgit-file-transclusion--resolve (dir rev)
  "Resolve REV to a commit SHA in mirror DIR, or nil if it is not there."
  (with-temp-buffer
    (when (zerop (call-process "git" nil t nil "-C" dir
                               "rev-parse" "--verify" "--quiet"
                               (concat rev "^{commit}")))
      (string-trim (buffer-string)))))

(defun orgit-file-transclusion--rev-parse (slug rev)
  "Resolve REV to a full commit SHA in SLUG, refreshing the mirror if needed."
  (let ((dir (orgit-file-transclusion--mirror slug)))
    (or (orgit-file-transclusion--resolve dir rev)
        ;; A pin newer than the mirror.  Refresh once per repository per
        ;; build, so an unresolvable rev costs one fetch rather than one
        ;; per link.
        (unless (gethash slug orgit-file-transclusion--fetched)
          (puthash slug t orgit-file-transclusion--fetched)
          (orgit-file-transclusion--git (format "cannot fetch %s" slug)
                                        "-C" dir "fetch" "--quiet" "--tags" "--prune")
          (orgit-file-transclusion--resolve dir rev))
        (error "orgit-file: cannot resolve rev %s in %s: no such tag or commit \
on the forge (was the pin tag pushed?)" rev slug))))

(defun orgit-file-transclusion--blob-file (slug rev path)
  "Materialise PATH at REV in SLUG as a local file; return its name.
The returned path ends in PATH, so the buffer gets the major mode it
would have had for the real file."
  (let* ((sha (orgit-file-transclusion--rev-parse slug rev))
         (cached (expand-file-name
                  path (expand-file-name
                        sha (expand-file-name
                             slug orgit-file-transclusion-cache-dir)))))
    (unless (file-exists-p cached)
      (make-directory (file-name-directory cached) t)
      ;; Write via a temp name and rename, so a failed `git show' can never
      ;; leave a truncated blob behind for a later run to trust.
      (let ((tmp (concat cached ".partial")))
        (with-temp-buffer
          (unless (zerop (call-process "git" nil t nil
                                       "-C" (orgit-file-transclusion--mirror slug)
                                       "show" (format "%s:%s" sha path)))
            (error "orgit-file: %s:%s is not in %s at %s: %s"
                   rev path slug (substring sha 0 12)
                   (string-trim (buffer-string))))
          (let ((coding-system-for-write 'no-conversion))
            (write-region (point-min) (point-max) tmp nil 'quiet)))
        (rename-file tmp cached t)))
    cached))

(defun orgit-file-transclusion--parse (raw)
  "Split RAW into (REPO REV PATH UUID); signal on any other shape."
  (let ((parts (split-string raw "::")))
    (unless (= 4 (length parts))
      (error "orgit-file link needs REPO::REV::PATH::UUID, got: %s" raw))
    parts))

(defun orgit-file-transclusion-add (link _plist)
  "Resolve an `orgit-file' LINK into a `file' link on the pinned blob.
Mutates LINK in place and returns nil, so `org-transclusion-add-src-lines'
applies the post's :lines/:src/:end attributes exactly as it does for a
worktree-resolved link."
  (when (string= "orgit-file" (org-element-property :type link))
    (pcase-let* ((`(,repo ,rev ,path ,uuid)
                  (orgit-file-transclusion--parse
                   (org-element-property :path link)))
                 (blob (orgit-file-transclusion--blob-file
                        (orgit-file-transclusion--slug repo) rev path)))
      ;; Mutate in place so downstream handlers see the resolved file path.
      (org-element-put-property link :type "file")
      (org-element-put-property link :path blob)
      (org-element-put-property link :raw-link (concat "file:" blob "::" uuid))
      (org-element-put-property link :search-option uuid)))
  ;; Always nil: let the next add-function build the payload.
  nil)

(add-hook 'org-transclusion-add-functions #'orgit-file-transclusion-add)

;; Export `orgit-file' links as forge permalinks at the pinned revision.
;; The repository comes from REPO, through the same resolution the
;; transclusion uses, so a link and its permalink cannot name different
;; places.
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
                 (concat orgit-file-transclusion-github-url
                         (orgit-file-transclusion--slug repo)
                         "/blob/" rev "/" filepath))))
     (cond
      ((memq backend '(md gfm)) (format "[`%s`](%s)" (or desc filepath) url))
      ((eq backend 'html)
       (format "<a href=\"%s\"><code>%s</code></a>" url (or desc filepath)))
      (t url)))))

(provide 'orgit-file-transclusion)
;;; orgit-file-transclusion.el ends here
