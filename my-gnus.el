;; BBDB: Adress list
(add-to-list 'load-path "/usr/share/emacs/site-lisp/bbdb/")
(require 'bbdb)
(bbdb-initialize 'message 'gnus 'sendmail)
(setq bbdb-file "~/.emacs.d/bbdb.db")
(add-hook 'gnus-startup-hook 'bbdb-insinuate-gnus)
(setq bbdb/mail-auto-create-p t
      bbdb/news-auto-create-p t)

;(setq gnus-select-method 
;      '(nnimap "gmail"
;	       (nnimap-address "localhost")
;	       (nnimap-server-port 143)))

(setq gnus-select-method 
      '(nnimap "gmail"
	       (nnimap-address "imap.gmail.com")
	       (nnimap-server-port 993)
	       (nnimap-stream ssl)))

;; If you want to use local maildirv
;(setq gnus-select-method 
;      '(nnmaildir "gmail"
;	  (directory "~/Gmail")))

(setq gnus-fetch-old-headers nil)

;; Configure outbound mail (SMTP)
;; Let Gnus change the "From:" line by looking at current group we are in.
(setq gnus-posting-styles
      '(("gmail" (address "rodrigoswanderley@gmail.com"))))

;; Available SMTP accounts.
(defvar smtp-accounts
  '((plain   "rodrigoswanderley@gmail.com" "localhost" 25)))
;  '((ssl   "rodrigoswanderley@gmail.com" "smtp.gmail.com" 587 "key" nil)))

;; Default smtpmail.el configurations.
(require 'smtpmail)
(setq send-mail-function 'smtpmail-send-it
      message-send-mail-function 'smtpmail-send-it
      mail-from-style nil
      user-full-name "Rodrigo S. Wanderley"
      user-mail-address "rodrigoswanderley@gmail.com"
      message-signature-file "~/.signature"
      smtpmail-debug-info t
      smtpmail-debug-verb t)

(defun set-smtp-plain (server port)
  "Set related SMTP variables for supplied parameters."
  (setq smtpmail-smtp-server server
	smtpmail-smtp-service port
	smtpmail-auth-credentials "~/.authinfo"
	smtpmail-starttls-credentials nil)
  (message "Setting SMTP server to `%s:%s'."
	   server port address))

(defun set-smtp-ssl (server port key cert)
  "Set related SMTP and SSL variables for supplied parameters."
  (setq starttls-use-gnutls t
	starttls-gnutls-program "gnutls-cli"
	starttls-extra-arguments nil
	smtpmail-smtp-server server
	smtpmail-smtp-service port
	smtpmail-starttls-credentials (list (list server port key cert))
	smtpmail-auth-credentials "~/.authinfo")
  (message
   "Setting SMTP server to `%s:%s'. (SSL enabled.)"
   server port address))

(defun change-smtp ()
  "Change the SMTP server according to the current from line."
  (save-excursion
    (loop with from = (save-restriction
			(message-narrow-to-headers)
			(message-fetch-field "from"))
	  for (acc-type address . auth-spec) in smtp-accounts
	  when (string-match address from)
	  do (cond
	      ((eql acc-type 'plain)
	       (return (apply 'set-smtp-plain auth-spec)))
	      ((eql acc-type 'ssl)
	       (return (apply 'set-smtp-ssl auth-spec)))
	      (t (error "Unrecognized SMTP account type: `%s'." acc-type)))
	  finally (error "Cannot interfere SMTP information."))))

(add-hook 'message-send-hook 'change-smtp)

;; Agentize is on
(require 'gnus-agent)
(setq gnus-agent t)

;; sig-quote
(load-file "~/.emacs.d/mail/sig-quote.el")
(require 'sig-quote)
(sig-quote-mode 'rmail)
(setq sq-quote-file "~/.signature.quote"
      sq-quote-delimeter "^%%$"
      sq-quote-type-default '("general")
      sq-gnus-too t
      sq-confirm-quote nil)

(add-hook 'message-mode-hook
	  '(lambda ()
	     (flyspell-mode t)
	     (sig-quote-mode 1)
	     (ispell-change-dictionary "brasileiro")
	     (local-set-key "<TAB>" 'bbdb-complete-name)))

;; use message-mail when hitting C-x m
(setq mail-user-agent 'message-user-agent)
(setq mail-user-agent 'gnus-user-agent)

(gnus-demon-add-handler 'gnus-group-get-new-news 2 t)
(gnus-demon-init)  ; this is redundant in No Gnus

;; speed things up
(setq gnus-use-correct-string-widths nil)
(setq gc-cons-threshold 3500000)
(gnus-compile)

(provide 'my-gnus)