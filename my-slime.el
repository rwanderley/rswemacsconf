(add-to-list 'load-path "/usr/share/emacs/site-lisp/slime")
(setenv "SBCL_HOME" "/usr/lib/sbcl")
(setq inferior-lisp-program "/usr/bin/sbcl")
(setq common-lisp-hyperspec-root "file:/home/rwanderley/docs/HyperSpec/") 
(require 'slime)
(slime-setup)

(provide 'my-slime)