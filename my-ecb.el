;; First loads ECB
(load-file "/usr/share/emacs/site-lisp/cedet/common/cedet.el")
(add-to-list 'load-path "/usr/share/emacs/site-lisp/ecb")
(require 'ecb)

;; Then configure it
(ecb-add-source-path "~/src" "src" "n")

;; Disable tip-of-the-day
(setq ecb-tip-of-the-day nil)

;; enable compile window
;; (setq ecb-compile-window-height 15)
;; (setq ecb-compile-window-temporally-enlarge nil)

;; Add the repl to the compilation buffers
(setq ecb-compilation-buffer-names '(("\\*slime-repl.*\\*" . t)))

(provide 'my-ecb)