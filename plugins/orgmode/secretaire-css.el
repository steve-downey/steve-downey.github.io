;;; secretaire-css.el --- Export syntax highlighting CSS from Emacs faces  -*- lexical-binding: t; -*-

;; Author: Steve Downey
;; URL: https://github.com/steve-downey/secretaire
;; Version: 0.2.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: faces, tools, convenience

;; SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

;;; Commentary:

;; Generate curated CSS from Emacs face definitions for use as external
;; stylesheets with org-mode's CSS-class-based syntax highlighting.
;;
;; Designed to work with the modus-themes palette architecture (or any
;; theme following the same pattern).  The exported CSS:
;;
;;  - Uses CSS custom properties for all palette colors (DRY)
;;  - References colors via var(--palette-name) in face rules
;;  - Annotates each rule with the Emacs face name and palette entry
;;  - Emits only palette entries actually referenced by exported faces
;;  - Looks like a human carefully curated it
;;  - Requires no post-editing
;;
;; Usage:
;;   (require 'secretaire-css)
;;   (setq secretaire-css-output-directory "~/blog/themes/my-theme/assets/css/")
;;   M-x secretaire-css-menu

;;; Code:

(require 'cl-lib)

;;;; Customization

(defgroup secretaire-css nil
  "Export Emacs face definitions as CSS for org-mode syntax highlighting."
  :group 'faces
  :group 'tools
  :prefix "secretaire-css-")

(defcustom secretaire-css-output-directory
  (expand-file-name "~/.emacs.d/exported-css/")
  "Default directory for exported CSS files."
  :type 'directory
  :group 'secretaire-css)

(defcustom secretaire-css-default-theme nil
  "Default theme to load before exporting CSS.
If nil, use the currently active theme."
  :type '(choice (const :tag "Current theme" nil)
                 (symbol :tag "Theme name"))
  :group 'secretaire-css)

(defcustom secretaire-css-face-prefix "org-"
  "Prefix for CSS class names.
Corresponds to `org-html-htmlize-font-prefix'.  The default \"org-\"
produces classes like .org-keyword, .org-string, etc."
  :type 'string
  :group 'secretaire-css)

(defcustom secretaire-css-ensure-modes
  '(cc-mode python ruby-mode perl-mode sh-script
    js css-mode mhtml-mode nxml-mode json yaml-mode
    rust-mode go-mode
    org markdown-mode tex-mode
    make-mode cmake-mode conf-mode
    diff-mode elisp-mode sql)
  "Features to require before generating CSS.
Modes that are normally autoloaded won't have their faces registered
until loaded.  Entries that fail to load are silently skipped."
  :type '(repeat symbol)
  :group 'secretaire-css)

(defcustom secretaire-css-extra-modes nil
  "Additional features to require beyond `secretaire-css-ensure-modes'."
  :type '(repeat symbol)
  :group 'secretaire-css)

(defcustom secretaire-css-header t
  "Whether to include a header comment in exported CSS."
  :type 'boolean
  :group 'secretaire-css)

;;;; Mode loading

(defun secretaire-css--ensure-modes-loaded ()
  "Load all configured modes so their faces are registered.
Returns the list of features successfully loaded."
  (let ((loaded nil))
    (dolist (feat (append secretaire-css-ensure-modes
                         secretaire-css-extra-modes))
      (condition-case nil
          (progn (require feat) (push feat loaded))
        (error nil)))
    (nreverse loaded)))

(defun secretaire-css--current-theme-name ()
  "Return the name of the first enabled custom theme, or \"current\"."
  (if custom-enabled-themes
      (symbol-name (car custom-enabled-themes))
    "current"))

;;;; Palette access

(defun secretaire-css--palette ()
  "Return the current theme palette as an alist of (NAME . HEX).
Works with modus-themes 3.x and 4.x."
  (cond
   ((fboundp 'modus-themes--current-theme-palette)
    (modus-themes--current-theme-palette))
   ((fboundp 'modus-themes-current-palette)
    (modus-themes-current-palette))
   (t
    (error "No modus-compatible palette API found.  Is a modus theme loaded?"))))

(defun secretaire-css--reverse-palette (palette)
  "Build a hash table mapping lowercase hex → palette name.
First entry wins for duplicate hex values."
  (let ((table (make-hash-table :test #'equal)))
    (dolist (entry palette)
      (when (and (symbolp (car entry)) (stringp (cdr entry)))
        (let ((hex (downcase (cdr entry))))
          (unless (gethash hex table)
            (puthash hex (car entry) table)))))
    table))

;;;; Face → CSS mapping

(defun secretaire-css--face-css-name (face)
  "Convert FACE symbol to a CSS class name.
Replicates htmlize's naming convention:
  `font-lock-keyword-face' → \"org-keyword\"
  `org-code'               → \"org-org-code\"
  `c-annotation-face'      → \"org-c-annotation\""
  (let ((name (symbol-name face)))
    (setq name (replace-regexp-in-string "-face\\'" "" name))
    (setq name (replace-regexp-in-string "\\`font-lock-" "" name))
    (concat secretaire-css-face-prefix name)))

(defun secretaire-css--face-properties (face)
  "Resolve CSS-relevant properties for FACE.
Returns alist with :foreground :background :weight :slant.
Inheritance is fully resolved."
  (let ((fg (face-foreground face nil t))
        (bg (face-background face nil t))
        (weight (face-attribute face :weight nil t))
        (slant (face-attribute face :slant nil t)))
    `((:foreground . ,(when (stringp fg) (downcase fg)))
      (:background . ,(when (stringp bg) (downcase bg)))
      (:weight . ,(when (and weight
                             (not (memq weight '(normal unspecified))))
                    weight))
      (:slant . ,(when (and slant
                            (not (memq slant '(normal unspecified))))
                   slant)))))

(defun secretaire-css--exportable-faces ()
  "Return sorted list of faces worth exporting.
Excludes faces identical to default and faces with no visual properties."
  (let ((faces nil)
        (default-fg (face-foreground 'default nil t))
        (default-bg (face-background 'default nil t)))
    (dolist (face (face-list))
      (when (symbolp face)
        (let ((fg (face-foreground face nil t))
              (bg (face-background face nil t))
              (weight (face-attribute face :weight nil t))
              (slant (face-attribute face :slant nil t)))
          (when (or (and (stringp fg) (not (equal fg default-fg)))
                    (and (stringp bg) (not (equal bg default-bg)))
                    (and weight (not (memq weight '(normal unspecified))))
                    (and slant (not (memq slant '(normal unspecified)))))
            (push face faces)))))
    (sort faces (lambda (a b) (string< (symbol-name a) (symbol-name b))))))

;;;; CSS emission

(defun secretaire-css--emit-rule (face props reverse-map)
  "Emit an annotated CSS rule for FACE using var() palette references.
PROPS is from `--face-properties'.  REVERSE-MAP maps hex → palette name.
Returns a string, or nil if face has no visual effect."
  (let* ((fg-hex (alist-get :foreground props))
         (bg-hex (alist-get :background props))
         (weight (alist-get :weight props))
         (slant (alist-get :slant props))
         (fg-name (when fg-hex (gethash fg-hex reverse-map)))
         (bg-name (when bg-hex (gethash bg-hex reverse-map)))
         (css-class (secretaire-css--face-css-name face))
         (declarations nil)
         (annotations nil))
    (unless (or fg-hex bg-hex weight slant)
      (cl-return-from secretaire-css--emit-rule nil))
    ;; Foreground
    (when fg-hex
      (push (if fg-name
                (format "    color: var(--%s);" fg-name)
              (format "    color: %s;" fg-hex))
            declarations)
      (push (or (and fg-name (symbol-name fg-name)) fg-hex) annotations))
    ;; Background
    (when bg-hex
      (push (if bg-name
                (format "    background-color: var(--%s);" bg-name)
              (format "    background-color: %s;" bg-hex))
            declarations)
      (push (format "bg:%s" (or (and bg-name (symbol-name bg-name)) bg-hex))
            annotations))
    ;; Weight
    (when weight
      (let ((css-weight (pcase weight
                          ('bold "bold")
                          ('semi-bold "600")
                          ('light "300")
                          (_ nil))))
        (when css-weight
          (push (format "    font-weight: %s;" css-weight) declarations))))
    ;; Slant
    (when slant
      (let ((css-slant (pcase slant
                         ('italic "italic")
                         ('oblique "oblique")
                         (_ nil))))
        (when css-slant
          (push (format "    font-style: %s;" css-slant) declarations))))
    ;; Assemble
    (when declarations
      (format "/* %s: %s */\n.%s {\n%s\n}\n"
              (symbol-name face)
              (string-join (nreverse annotations) ", ")
              css-class
              (string-join (nreverse declarations) "\n")))))

;;;; Top-level generation

(defun secretaire-css-generate (&optional theme)
  "Generate CSS string for all faces, optionally under THEME.
Loads the theme temporarily (restores original afterward).
Returns a complete CSS string with :root palette and face rules."
  (secretaire-css--ensure-modes-loaded)
  (let ((original-themes custom-enabled-themes))
    (when theme
      (mapc #'disable-theme custom-enabled-themes)
      (load-theme theme t))
    (unwind-protect
        (let* ((palette (secretaire-css--palette))
               (reverse-map (secretaire-css--reverse-palette palette))
               (used-palette (make-hash-table :test #'eq))
               (rules nil))
          ;; Generate face rules
          (dolist (face (secretaire-css--exportable-faces))
            (let* ((props (secretaire-css--face-properties face))
                   (rule (secretaire-css--emit-rule face props reverse-map)))
              (when rule
                (let ((fg (alist-get :foreground props))
                      (bg (alist-get :background props)))
                  (when-let* ((n (and fg (gethash fg reverse-map))))
                    (puthash n t used-palette))
                  (when-let* ((n (and bg (gethash bg reverse-map))))
                    (puthash n t used-palette)))
                (push rule rules))))
          ;; Always include structural palette entries
          (dolist (name '(bg-main fg-main bg-dim fg-dim))
            (when (assq name palette)
              (puthash name t used-palette)))
          ;; Build :root with used palette entries only
          (let ((root-entries nil))
            (dolist (entry palette)
              (when (and (gethash (car entry) used-palette)
                         (stringp (cdr entry)))
                (push (format "    --%s: %s;" (car entry) (cdr entry))
                      root-entries)))
            (concat
             ":root {\n"
             (string-join (nreverse root-entries) "\n")
             "\n}\n\n"
             (string-join (nreverse rules) "\n"))))
      ;; Restore original themes
      (when theme
        (mapc #'disable-theme custom-enabled-themes)
        (dolist (th (reverse original-themes))
          (load-theme th t))))))

(defun secretaire-css--write-file (css theme-name output-file)
  "Write CSS string to OUTPUT-FILE with optional header."
  (make-directory (file-name-directory output-file) t)
  (with-temp-file output-file
    (when secretaire-css-header
      (insert (format "/* secretaire-css: %s\n" theme-name))
      (insert (format " * Generated: %s\n"
                      (format-time-string "%Y-%m-%d %H:%M:%S")))
      (insert " * Strategy: palette-aware — colors reference CSS custom properties\n")
      (insert " * Source: (modus-themes-current-palette) → face-attribute resolution\n")
      (insert " */\n\n"))
    (insert css)))

;;;; Interactive commands

;;;###autoload
(defun secretaire-css-export (&optional theme output-file)
  "Export CSS for all Emacs faces to a file.
Interactively, prompts for a theme.  C-u also prompts for file path."
  (interactive
   (let* ((theme-input
           (completing-read
            "Theme (empty for current): "
            (mapcar #'symbol-name (custom-available-themes))
            nil nil nil nil ""))
          (theme-val (if (string-empty-p theme-input) nil (intern theme-input)))
          (default-name (if theme-val
                            (symbol-name theme-val)
                          (secretaire-css--current-theme-name)))
          (default-file (expand-file-name
                         (concat default-name ".css")
                         secretaire-css-output-directory))
          (file (if current-prefix-arg
                    (read-file-name "Output file: "
                                    secretaire-css-output-directory
                                    nil nil (concat default-name ".css"))
                  default-file)))
     (list theme-val file)))
  (let* ((theme-to-use (or theme secretaire-css-default-theme))
         (theme-name (if theme-to-use
                         (symbol-name theme-to-use)
                       (secretaire-css--current-theme-name)))
         (outfile (or output-file
                      (expand-file-name (concat theme-name ".css")
                                        secretaire-css-output-directory)))
         (css (secretaire-css-generate theme-to-use)))
    (secretaire-css--write-file css theme-name outfile)
    (message "Exported %s → %s (%d bytes)"
             theme-name outfile
             (file-attribute-size (file-attributes outfile)))
    outfile))

;;;###autoload
(defun secretaire-css-export-current ()
  "Export CSS for the currently active theme."
  (interactive)
  (secretaire-css-export nil))

;;;###autoload
(defun secretaire-css-export-modus-vivendi ()
  "Export CSS for the modus-vivendi-tinted theme."
  (interactive)
  (secretaire-css-export
   'modus-vivendi-tinted
   (expand-file-name "modus-vivendi-tinted.css" secretaire-css-output-directory)))

;;;###autoload
(defun secretaire-css-export-modus-operandi ()
  "Export CSS for the modus-operandi-tinted theme."
  (interactive)
  (secretaire-css-export
   'modus-operandi-tinted
   (expand-file-name "modus-operandi-tinted.css" secretaire-css-output-directory)))

;;;###autoload
(defun secretaire-css-export-both-modus ()
  "Export CSS for both modus-vivendi-tinted and modus-operandi-tinted."
  (interactive)
  (secretaire-css-export-modus-vivendi)
  (secretaire-css-export-modus-operandi))

;;;###autoload
(defun secretaire-css-list-loaded-modes ()
  "Display which configured modes are loadable and palette status."
  (interactive)
  (let ((buf (get-buffer-create "*secretaire-css*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "secretaire-css: status\n")
        (insert (make-string 40 ?=) "\n\n")
        (insert (format "Palette API: %s\n"
                        (cond
                         ((fboundp 'modus-themes--current-theme-palette) "4.x")
                         ((fboundp 'modus-themes-current-palette) "3.x")
                         (t "NOT FOUND"))))
        (insert (format "Active theme: %s\n" (secretaire-css--current-theme-name)))
        (insert (format "Total faces: %d\n" (length (face-list))))
        (insert (format "Exportable: %d\n\n" (length (secretaire-css--exportable-faces))))
        (insert "Configured modes:\n")
        (dolist (feat (append secretaire-css-ensure-modes
                             secretaire-css-extra-modes))
          (insert (format "  %-20s %s\n" feat
                          (if (locate-library (symbol-name feat)) "ok" "NOT FOUND"))))))
    (pop-to-buffer buf)))

;;;; Transient menu

;;;###autoload
(when (require 'transient nil t)

  (transient-define-prefix secretaire-css-menu ()
    "Export syntax highlighting CSS from Emacs face definitions."
    ["Export"
     ("v" "Modus Vivendi Tinted"   secretaire-css-export-modus-vivendi)
     ("o" "Modus Operandi Tinted"  secretaire-css-export-modus-operandi)
     ("b" "Both Modus themes"      secretaire-css-export-both-modus)
     ("c" "Current theme"          secretaire-css-export-current)
     ("e" "Choose theme..."        secretaire-css-export)]
    ["Inspect"
     ("l" "Status & modes"         secretaire-css-list-loaded-modes)]
    ["Settings"
     ("d" "Set output directory"   secretaire-css-set-output-directory)
     ("m" "Add extra mode"         secretaire-css-add-extra-mode)]
    ["Quit"
     ("q" "Quit"                   transient-quit-one)])

  (defun secretaire-css-set-output-directory ()
    "Interactively set `secretaire-css-output-directory'."
    (interactive)
    (setq secretaire-css-output-directory
          (read-directory-name "CSS output directory: "
                               secretaire-css-output-directory))
    (message "Output directory: %s" secretaire-css-output-directory))

  (defun secretaire-css-add-extra-mode ()
    "Interactively add a mode to `secretaire-css-extra-modes'."
    (interactive)
    (let ((feat (intern (read-string "Feature to add: "))))
      (cl-pushnew feat secretaire-css-extra-modes)
      (message "Added %s to extra modes" feat))))

(provide 'secretaire-css)
;;; secretaire-css.el ends here
