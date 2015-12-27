;; Imported from work computer

(require 'ess-site)
;; (grok-init)
(custom-set-variables '(inhibit-startup-screen t))
(custom-set-faces)
(global-set-key [(f5)] 'compile)
(set 'compile-command "")
(ess-toggle-underscore nil)
(require 'color-theme)
(color-theme-initiliaze)
(color-theme-calm-forest)

(add-to-list 'auto-mode-alist '("\\.*bashrc\\'" . sh-mode))

;; scroll line by line
(setq scroll-step 1)
;; TODO: autocompletion
(column-number-mode)
;; Fast window move keys
(global-set-key (kbd "C-x <up>") 'windmove-up)
(global-set-key (kbd "C-x <down>") 'windmove-down)
(global-set-key (kbd "C-x <left>") 'windmove-left)
(global-set-key (kbd "C-x <right>") 'windmove-right)


;; Imported from cruncher.
;                                                                                                                                                                                                                                    
(setq diary-file "~/Dropbox/diary")
(load-file "~/.emacs.d/emacs-keys.el")
(load-file "~/.emacs.d/programming.el")
(load "~/.emacs.d/ess-13.09-1/lisp/ess-site.el")



;; ocaml                                                                                                                                                                                                                             
(add-to-list 'load-path "/home/zywang/.opam/system/share/tuareg/")
(load "tuareg-site-file")

;;julia                                                                                                                                                                                                                              
(add-to-list 'load-path "/home/zywang/program/julia/contrib/")
(load "julia-mode")


(global-font-lock-mode t)
;; enable visual feedback on selections                                                                                                                                                                                              
(setq-default transient-mark-mode t)
 (require 'cc-mode)
 (c-set-offset 'inline-open 0)
 (c-set-offset 'friend '-)
 (c-set-offset 'substatement-open 0)


;;; Other settings:                                                                                                                                                                                                                  

;; White background color                                                                                                                                                                                                            
;(set-background-color "white")                                                                                                                                                                                                      

;; Syntax highlighting:                                                                                                                                                                                                              
(global-font-lock-mode t)
(transient-mark-mode t)


;(add-hook 'term-mode-hook 'char-line-mode)                                                                                                                                                                                          
;;(setq load-path (append load-path (list "/home/zywang/program/ess-12.09-2/lisp")))                                                                                                                                                 
(setq dired-recursive-copies 'always)


(setq load-path (append load-path (list "/home/zywang/program/cscope-15.8a/contrib/xcscope/") ))
(require 'xcscope)

(when (>= emacs-major-version 24) 
  (require 'package)
  (package-initialize)
  (add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)
)


