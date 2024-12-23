;; Init file to use with the orgmode plugin.

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


(setq org-export-global-macros '(
                                 ("TEASER_END" . "<!-- TEASER_END -->")
                                 ))
;; (use-package ox-html
;;   :after (org)
;;   :custom
;;   )

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

;; Export function used by Nikola.
(defun nikola-html-export (infile outfile)
  "Export the body only of the input file and write it to
specified location."
  (with-current-buffer (find-file infile)
    (org-html-export-as-html nil nil t t)
    (write-file outfile nil)))
