(eval-after-load "eshell"
  '(progn
     (setq eshell-save-history-on-exit t)

     ;; bind C-a to eshell-bol
     (local-set-key "\C-a" 'eshell-bol)))

(add-hook 'eshell-first-time-mode-hook
   '(lambda ()
      (add-to-list 'eshell-visual-commands "ssh")))

(provide 'my-eshell)
