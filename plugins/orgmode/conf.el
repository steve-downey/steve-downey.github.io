;;; conf.el --- site-local configuration for the org compiler  -*- lexical-binding: t; -*-

;; Loaded by init.el after the packages it configures.

;;; Where the code behind pinned transclusions lives.
;;
;; A post with `orgit-file:' links is drafted in the repository whose code it
;; is about, and there its links name a checkout -- a path that differs
;; between laptops and means nothing on a build host.  Published here the post
;; is finished, and what it points at has to outlive any checkout: this site
;; must rebuild from nothing but itself and GitHub.
;;
;; This table is that translation, and it belongs here, in the site, under
;; version control.  The left side matches the REPO component of a link as the
;; post happens to spell it; the right side is the repository's permanent home
;; on GitHub, which is where its pinned code is read from and what its
;; permalinks point at.  Matching on the repository name rather than a full
;; path is deliberate -- it is what lets the same entry cover a post drafted
;; on a different machine, or in a worktree named after its branch.
;;
;; A post whose links already name `owner/name' needs no entry here.

(setq orgit-file-transclusion-repo-alist
      '(("/expected/"            . "steve-downey/expected")
        ("/transpose/"           . "steve-downey/transpose")
        ("/compile-time-scheme/" . "steve-downey/compile-time-scheme")))

;;; conf.el ends here
