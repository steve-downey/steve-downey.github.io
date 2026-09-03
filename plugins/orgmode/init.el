;; Init file to use with the orgmode plugin.  -*- lexical-binding: t; -*-

;; Load org-mode

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(setq package-user-dir
      (locate-user-emacs-file (concat "elpa-" emacs-version)))

(when (fboundp 'native-comp-available-p)
  (setq package-native-compile (native-comp-available-p)))
(package-initialize)

(defun ignore-builtin (pkg)
  (assq-delete-all pkg package--builtins)
  (assq-delete-all pkg package--builtin-versions))

(ignore-builtin 'org)

(require 'use-package-ensure)
(setq use-package-always-ensure t)
(setq use-package-compute-statistics t)

(use-package citeproc)

(use-package org
  :commands (org-mode)
  :mode (("\\.org\\'" . org-mode))
  :bind
  (:map org-mode-map
        ([remap org-toggle-comment] . iedit-mode))
  :custom
  (org-startup-folded t)
  (org-log-into-drawer t)
  (org-startup-truncated nil)
  (org-startup-with-inline-images t)
  (org-src-fontify-natively t)
  (org-fontify-whole-heading-line t)
  (org-fontify-quote-and-verse-blocks t)
  (org-src-preserve-indentation t)
  (org-confirm-babel-evaluate nil)
  (org-support-shift-select t)
  (org-export-with-toc nil)
  (org-export-with-section-numbers nil)
  (org-startup-folded 'showeverything)
  (org-html-htmlize-output-type 'css
                                "Configure export using a css style sheet")

  :config
  (org-babel-do-load-languages
   'org-babel-load-languages
   `((perl       . t)
     (ruby       . t)
     (shell      . t)
     (python     . t)
     (emacs-lisp . t)
     (C          . t)
     (dot        . t)
     (sql        . t))))

(ignore-builtin 'htmlize)

(use-package htmlize
  :ensure t)

(setq org-html-head ""
      org-html-head-extra ""
      org-html-head-include-default-style nil
      org-html-head-include-scripts nil
      org-html-preamble nil
      org-html-postamble nil
      org-html-use-infojs nil)

(setq org-export-global-macros '(
                                 ("TEASER_END" . "#+HTML:<!-- TEASER_END -->")
                                 ))
;; (use-package ox-html
;;   :after (org)
;;   :custom
;;   )

(use-package ox-nikolahtml
  :load-path "./")

(use-package org-transclusion
  :vc (:url "https://github.com/nobiot/org-transclusion"))
;; No `org-mode-hook' entry: `nikola-html-export' calls
;; `org-transclusion-add-all' itself.  On the hook the pass ran several times
;; per export -- harmless when every pin resolves, but it multiplied the
;; "Not transcluded" messages when one did not, burying the cause.

;; Vendored locally (plugins/orgmode/orgit-file-transclusion.el); not on MELPA,
;; so load it from this directory rather than trying to install it.
(use-package orgit-file-transclusion
  :load-path "./"
  :ensure nil)

;; Allow org-transclusion to resolve orgit links to the local file system
(defun org-transclusion-add-orgit (link plist)
  "Resolve orgit links into file links in-place."
  (when (string= "orgit" (org-element-property :type link))
    (let* ((full-path (org-element-property :path link))
           (parts (split-string full-path "::"))
           (repo-dir (car parts))
           (inner-file (cadr parts))
           (search-uuid (if (> (length parts) 2) (caddr parts) nil))
           (actual-file (expand-file-name inner-file repo-dir))
           (raw-link (concat "file:" actual-file)))

      (when search-uuid
        (setq raw-link (concat raw-link "::" search-uuid)))

      ;; CRITICAL: Mutate the original link in-place so downstream plugins
      ;; (like org-transclusion-src-lines) see the correct file path!
      (org-element-put-property link :type "file")
      (org-element-put-property link :path actual-file)
      (org-element-put-property link :raw-link raw-link)
      (if search-uuid
          (org-element-put-property link :search-option search-uuid)
        (org-element-put-property link :search-option nil))))
  ;; ALWAYS return nil so the NEXT functions (like org-transclusion-add-src-lines) can handle it!
  nil)

(add-hook 'org-transclusion-add-functions 'org-transclusion-add-orgit)

(setq plantuml-jar-path "/usr/share/plantuml/plantuml.jar")
(setq plantuml-default-exec-mode 'jar)

;; Add any custom configuration that you would like to 'conf.el'.
;; Load additional configuration from conf.el
(let ((conf (expand-file-name "conf.el" (file-name-directory load-file-name))))
  (if (file-exists-p conf)
      (load-file conf)))

;;; Code highlighting
(defun org-html-decode-plain-text (text)
  "Convert HTML character to plain TEXT. i.e. do the inversion of
     `org-html-encode-plain-text`. Possible conversions are set in
     `org-html-protect-char-alist'."
  (mapc
   (lambda (pair)
     (setq text (replace-regexp-in-string (cdr pair) (car pair) text t t)))
   (reverse org-html-protect-char-alist))
  text)

(require 'ol)

;; Export images with custom link type
(defun org-custom-link-img-url-export (path desc format)
  (cond
   ((eq format 'html)
    (format "<img src=\"%s\" alt=\"%s\"/>" path desc))))
(org-link-set-parameters "img-url" nil 'org-custom-link-img-url-export)

;; Export images with built-in file scheme
(defun org-file-link-img-url-export (path desc format)
  (cond
   ((eq format 'html)
    (format "<img src=\"/%s\" alt=\"%s\"/>" path desc))))
(org-link-set-parameters "file" nil 'org-file-link-img-url-export)

;; Support for magic links (link:// scheme)
(org-link-set-parameters
  "link"
  :export (lambda (path desc backend)
             (cond
               ((eq 'html backend)
                (format "<a href=\"link:%s\">%s</a>"
                        path (or desc path))))))

;; Export orgit: links to GitHub blob URLs.
;;
;; orgit's own resolver needs a live magit/repo and fails under `emacs
;; --batch', aborting the export.  We only ever use orgit links as
;; source-file references following the convention:
;;
;;   orgit:REPO-DIR::FILE[::SEARCH]
;;
;; so translate them directly into a GitHub permalink built from the
;; repo's `origin' remote and its current HEAD.
(require 'orgit nil t)

(defun sd-orgit-github-permalink (repo file)
  "Build a GitHub blob URL for FILE in REPO, at the repository's default branch.
Return nil if REPO names no known repository.

REPO is resolved the way a pinned `orgit-file:' link resolves it --
through `orgit-file-transclusion-repo-alist' -- so this needs no local
checkout either.  It used to read one: `git remote get-url' and `git
rev-parse HEAD' run inside REPO, which meant a published post could only
be rebuilt on the laptop it was written on, and signalled from inside
`shell-command-to-string' when the directory was absent, defeating the
fallback its caller documents.

Unlike `orgit-file:', an `orgit:' link carries no revision: it means
the file as it currently stands, and `HEAD' is how GitHub spells that
in a blob URL.  Such a link therefore follows the file rather than
freezing it -- correct for a living document, and the reason prose in a
published post should prefer a pinned `orgit-file:' link."
  (let ((slug (ignore-errors (orgit-file-transclusion--slug repo))))
    (when slug
      (format "%s%s/blob/HEAD/%s" orgit-file-transclusion-github-url slug file))))

(defun org-orgit-link-export (path desc format)
  "Export orgit:REPO::FILE links as GitHub links.
Falls back to DESC (or PATH) so export never aborts on an
unresolvable repository."
  (let* ((parts (split-string path "::"))
         (repo (car parts))
         (file (cadr parts))
         (url (and file (sd-orgit-github-permalink repo file))))
    (cond
     ((and url (eq format 'html))
      (format "<a href=\"%s\">%s</a>" url (or desc file)))
     (url (or desc url))
     (t (or desc file path)))))

(org-link-set-parameters "orgit" :export #'org-orgit-link-export)

(defun nikola-transclusion-assert-resolved ()
  "Signal unless every `#+transclude:' keyword in the buffer resolved.

`org-transclusion-add-all' wraps each keyword in `with-demoted-errors',
so an unresolvable pin -- a tag that was never pushed, a path that moved
-- leaves the keyword inert and the post exports with a hole in it: no
error, no warning, just an article missing the code it is about.  A
resolved keyword is replaced by its content, so any keyword still
standing after the pass is a failure, and the build should stop rather
than publish the hole."
  (let (unresolved)
    (save-excursion
      (goto-char (point-min))
      ;; Same regexp and same exemptions as `org-transclusion-add-all',
      ;; so this counts exactly the keywords it undertook to resolve.
      (while (re-search-forward "^[ \t]*#\\+TRANSCLUDE:" nil t)
        (unless (or (org-transclusion-within-transclusion-p)
                    (plist-get (org-transclusion-keyword-string-to-plist)
                               :disable-auto))
          (push (format "  line %d: #+transclude:%s"
                        (line-number-at-pos)
                        (buffer-substring-no-properties
                         (point) (line-end-position)))
                unresolved))))
    (when unresolved
      (error "%s: %d transclusion(s) did not resolve (see the \"Not transcluded\" \
message above for the cause):\n%s"
             (file-name-nondirectory (or (buffer-file-name) (buffer-name)))
             (length unresolved)
             (mapconcat #'identity (nreverse unresolved) "\n")))))

;; Export function used by Nikola.
(defun nikola-html-export (infile outfile)
  "Export the body only of the input file and write it to
specified location."
  (with-current-buffer (find-file infile)
    ;; Explicit rather than relying on the `org-mode-hook' entry: the export
    ;; must not depend on hook ordering, and `org-transclusion-add-all' only
    ;; ever sees keywords a previous pass left unresolved.
    (org-transclusion-add-all)
    (nikola-transclusion-assert-resolved)
    (nikola-export-as-html nil nil t t)
    (write-file outfile nil)))
