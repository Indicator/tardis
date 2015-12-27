;; Make sure the .emacs has no warning and no error.
;; .emacs warning when loading will halt emacsserver starting.

;; Global config, working with most emacs versions
(defmacro with-library (symbol &rest body)
  `(condition-case nil
       (progn
	 (require ',symbol)
	 ,@body)
     
     (error (message (format "I guess we don't have %s available." ',symbol))
	    nil)))

(defun load-file-if-exists (file-name) 
  (if (file-exists-p file-name) 
    (load-file file-name)
  )
)

(custom-set-variables '(inhibit-startup-screen t))
(custom-set-faces)
(global-set-key [(f5)] 'compile)
(set 'compile-command "")

(add-to-list 'auto-mode-alist '("\\.*bashrc\\'" . sh-mode))

;; scroll line by line
(setq scroll-step 1)
(column-number-mode)
;; Fast window move keys
(global-set-key (kbd "C-x <up>") 'windmove-up)
(global-set-key (kbd "C-x <down>") 'windmove-down)
(global-set-key (kbd "C-x <left>") 'windmove-left)
(global-set-key (kbd "C-x <right>") 'windmove-right)

;; TODO: autocompletion

(if (file-exists-p "~/Dropbox/diary")
  (setq diary-file "~/Dropbox/diary")
)

(load-file-if-exists "~/.emacs.d/emacs-keys.el")
(load-file-if-exists "~/.emacs.d/programming.el")

(global-font-lock-mode t)
;; White background color                                                              ;(set-background-color "white")                                                        
;; Syntax highlighting:
(transient-mark-mode t)
(setq dired-recursive-copies 'always)

;; enable visual feedback on selections
(setq-default transient-mark-mode t)
 (require 'cc-mode)
 (c-set-offset 'inline-open 0)
 (c-set-offset 'friend '-)
 (c-set-offset 'substatement-open 0)

;; ocaml
(add-to-list 'load-path "/home/zywang/.opam/system/share/tuareg/")
(with-library tuareg-site-file)

;;julia
(add-to-list 'load-path "/home/zywang/program/julia/contrib/")
(with-library julia-mode)

;(add-hook 'term-mode-hook 'char-line-mode)                                            

(add-to-list 'load-path "/home/zywang/program/cscope-15.8a/contrib/xcscope/")
(with-library 'xcscope)

(when (>= emacs-major-version 24) 
  (require 'package)
  (package-initialize)
  (add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)
)

;; ESS setup
;; (require 'ess-site)
;; (ess-toggle-underscore nil)
;; (load "~/.emacs.d/ess-13.09-1/lisp/ess-site.el")


;; Color theme
(with-library color-theme
  (color-theme-initiliaze)
  (color-theme-calm-forest)
)
;; (grok-init)
