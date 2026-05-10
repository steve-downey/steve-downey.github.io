;;; wctm-css.el --- WCTM blog configuration for secretaire-css  -*- lexical-binding: t; -*-

;; Site-specific glue that configures secretaire-css for the
;; "What Comes To Mind" Nikola blog.  Load this after secretaire-css.

;;; Code:

(require 'secretaire-css)

;; Point output at the tailwind theme's CSS directory.
(when-let* ((root (or (locate-dominating-file default-directory "conf.py")
                      (locate-dominating-file
                       (file-name-directory (or load-file-name
                                                buffer-file-name
                                                ""))
                       "conf.py"))))
  (setq secretaire-css-output-directory
        (expand-file-name "themes/sdowney-tailwind/assets/css/" root)))

;; Modes used in this blog beyond the default set.
(setq secretaire-css-extra-modes '(c++-mode cmake-mode))

(provide 'wctm-css)
;;; wctm-css.el ends here
