(eval-after-load 'eshell
  '(progn
     (setq eshell-save-history-on-exit t)

     (add-to-list 'eshell-visual-commands "ssh")

     ;; bind C-a to eshell-bol
     (local-set-key "\C-a" 'eshell-bol)))

(provide 'my-eshell)
