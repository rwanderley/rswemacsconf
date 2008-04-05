(add-hook 'latex-mode-hook '(lambda ()
			      (flyspell-mode t)
			      (flyspell-babel-setup)))

(provide 'my-latex)