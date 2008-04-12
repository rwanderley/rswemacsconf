(add-hook 'latex-mode-hook '(lambda ()
			      (auto-fill-mode 1)
			      (abbrev-mode 1)
			      (flyspell-mode t)
			      (flyspell-babel-setup)))

(provide 'my-latex)