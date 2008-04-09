(add-hook 'eshell-first-time-mode-hook
   '(lambda ()
      (add-to-list 'eshell-visual-commands "ssh")
      (add-to-list 'eshell-visual-commands "mutt")
      (setq eshell-save-history-on-exit t)
      (local-set-key "\C-a" 'eshell-bol)))

(provide 'my-eshell)
