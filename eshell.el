;; bind C-a to eshell-bol
(add-hook 'eshell-first-time-mode-hook
	  '(lambda ()
	     (local-set-key "\C-a" 'eshell-bol)))
