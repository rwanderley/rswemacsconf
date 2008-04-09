(require 'muttrc)

(add-to-list 'auto-mode-alist '("/mutt" . mail-mode))

(add-hook 'mail-mode-hook
	  '(lambda ()
	     (turn-on-auto-fill)
	     (flyspell-mode t)
	     (ispell-change-dictionary "brasileiro")
	     (local-set-key "<TAB>" 'bbdb-complete-name)))

(provide 'my-mutt)