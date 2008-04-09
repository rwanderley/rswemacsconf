;;;
;;; Twittering mode
;;;
(require 'twittering-mode)
(load-file "~/.twitter")
(setq twittering-username twitter-user)
(setq twittering-password twitter-pass)
(twittering-icon-mode t)

(provide 'my-twittering)
