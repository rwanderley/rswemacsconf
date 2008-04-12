(require 'muttrc)

(add-to-list 'auto-mode-alist '("/mutt" . mail-mode))

(add-hook 'mail-mode-hook
	  '(lambda ()
	     (auto-fill-mode 1)
	     (abbrev-mode 1)
	     (flyspell-mode t)
	     (local-set-key "\C-Xk" 'server-edit)
	     (ispell-change-dictionary "brasileiro")))

(provide 'my-mutt)