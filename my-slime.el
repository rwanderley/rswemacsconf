(setq inferior-lisp-program "/usr/bin/sbcl")
(setq common-lisp-hyperspec-root "file:/home/rwanderley/docs/HyperSpec/") 
(require 'slime)
(slime-setup)

(eval-after-load 'slime
  (slime-highlight-edits-mode nil))

(provide 'my-slime)
