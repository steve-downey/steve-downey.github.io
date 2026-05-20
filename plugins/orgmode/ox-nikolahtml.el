;; ox-nikolahtml.el --- org exporter for Nikola export  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Steve Downey

;; Author: Steve Downey <sdowney@gmail.com>

;; URL:

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;;; Commentary:

;;; Code:

(require 'ox-html)


(org-export-define-derived-backend 'nikola-html 'html
  :translate-alist '((headline . nikola-html-headline))

  :menu-entry '(?w "Export Nikola Post"
                   ((?H "As HTML buffer" nikola-export-as-html)
	                (?h "As HTML file" nikola-export-to-html)
	                (?o "As HTML file and open"
	                    (lambda (a s v b)
	                      (if a (nikola-export-to-html t s v b)
		                    (org-open-file (nikola-export-to-html nil s v b))))))))



;;;; Headline

(defun nikola-html-headline (headline contents info)
  "Transcode a HEADLINE element from Org to HTML.
CONTENTS holds the contents of the headline.  INFO is a plist
holding contextual information."
  (princ "nikola-html-headline\n" 'external-debugging-output)
  (unless (org-element-property :footnote-section-p headline)
    (let* ((numberedp (org-export-numbered-headline-p headline info))
           (numbers (org-export-get-headline-number headline info))
           (level (+ (org-export-get-relative-level headline info)
                     (1- (plist-get info :html-toplevel-hlevel))))
           (todo (and (plist-get info :with-todo-keywords)
                      (let ((todo (org-element-property :todo-keyword headline)))
                        (and todo (org-export-data todo info)))))
           (todo-type (and todo (org-element-property :todo-type headline)))
           (priority (and (plist-get info :with-priority)
                          (org-element-property :priority headline)))
           (text (org-export-data (org-element-property :title headline) info))
           (tags (and (plist-get info :with-tags)
                      (org-export-get-tags headline info)))
           (full-text (funcall (plist-get info :html-format-headline-function)
                               todo todo-type priority text tags info))
           (contents (or contents ""))
	       (id (org-html--reference headline info))
	       (formatted-text
	        (if (plist-get info :html-self-link-headlines)
		        (format "<a href=\"#%s\">%s</a>" id full-text)
	          full-text)))
      (if (org-export-low-level-p headline info)
          ;; This is a deep sub-tree: export it as a list item.
          (let* ((html-type (if numberedp "ol" "ul")))
	        (concat
	         (and (org-export-first-sibling-p headline info)
		          (apply #'format "<%s class=\"org-%s\">\n"
			             (make-list 2 html-type)))
	         (org-html-format-list-item
	          contents (if numberedp 'ordered 'unordered)
	          nil info nil
	          (concat (org-html--anchor id nil nil info) formatted-text)) "\n"
	         (and (org-export-last-sibling-p headline info)
		          (format "</%s>\n" html-type))))
	    ;; Standard headline.  Export it as a section.
        (let ((extra-class
	           (org-element-property :HTML_CONTAINER_CLASS headline))
	          (headline-class
	           (org-element-property :HTML_HEADLINE_CLASS headline))
              (first-content (car (org-element-contents headline))))
          (format "<%s id=\"%s\" class=\"%s\">%s%s</%s>\n"
                  (org-html--container headline info)
                  (format "ox-nikola-outline-container-%s" id)
                  (concat (format "ox-nikola-outline-%d" level)
                          (and extra-class " ")
                          extra-class)
                  (format "\n<h%d id=\"%s\"%s>%s</h%d>\n"
                          level
                          id
			              (if (not headline-class) ""
			                (format " class=\"%s\"" headline-class))
                          (concat
                           (and numberedp
                                (format
                                 "<span class=\"section-number-%d\">%s</span> "
                                 level
                                 (concat (mapconcat #'number-to-string numbers ".") ".")))
                           formatted-text)
                          level)
                  ;; When there is no section, pretend there is an
                  ;; empty one to get the correct <div
                  ;; class="outline-...> which is needed by
                  ;; `org-info.js'.
                  (if (org-element-type-p first-content 'section) contents
                    (concat (org-html-section first-content "" info) contents))
                  (org-html--container headline info)))))))


;;; End-user functions

;;;###autoload
(defun nikola-export-as-html
    (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to an HTML buffer.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting buffer should be accessible
through the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

When optional argument BODY-ONLY is non-nil, only write code
between \"<body>\" and \"</body>\" tags.

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Export is done in a buffer named \"*Org HTML Export*\", which
will be displayed when `org-export-show-temporary-export-buffer'
is non-nil."
  (interactive)
  (org-export-to-buffer 'nikola-html "*NIKOLA HTML Export*"
    async subtreep visible-only body-only ext-plist
    (lambda () (set-auto-mode t))))

;;;###autoload
(defun nikola-convert-region-to-html ()
  "Assume the current region has Org syntax, and convert it to HTML.
This can be used in any buffer.  For example, you can write an
itemized list in Org syntax in an HTML buffer and use this command
to convert it."
  (interactive)
  (org-export-replace-region-by 'nikola-html))

(defalias 'nikola-export-region-to-html #'nikola-convert-region-to-html)

;;;###autoload
(defun nikola-export-to-html
    (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a HTML file.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting file should be accessible through
the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

When optional argument BODY-ONLY is non-nil, only write code
between \"<body>\" and \"</body>\" tags.

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Return output file's name."
  (interactive)
  (let* ((extension (concat
		             (when (> (length org-html-extension) 0) ".")
		             (or (plist-get ext-plist :html-extension)
			             org-html-extension
			             "html")))
	     (file (org-export-output-file-name extension subtreep))
	     (org-export-coding-system org-html-coding-system))
    (org-export-to-file 'nikola-html file
      async subtreep visible-only body-only ext-plist)))

;;;###autoload
(defun nikola-publish-to-html (plist filename pub-dir)
  "Publish an org file to HTML.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
  (org-publish-org-to 'nikola-html filename
		              (concat (when (> (length org-html-extension) 0) ".")
			                  (or (plist-get plist :html-extension)
				                  org-html-extension
				                  "html"))
		              plist pub-dir))


(provide 'ox-nikolahtml)

;;; ox-nikolahtml.el ends here
