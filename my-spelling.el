(setq ispell-program-name "ispell")
;; flyspell
(load-file "~/.emacs.d/spelling/ispell-multi.el")
(load-file "~/.emacs.d/spelling/flyspell-babel.el")
(setq flyspell-babel-to-ispell-alist
      '(("brazilian" "brasileiro")
	("brazil" "brasileiro")
	("portuges" "brasileiro")))
(autoload 'flyspell-babel-setup "flyspell-babel")

(provide 'my-spelling)