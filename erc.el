;; ERC configuration
(add-to-list 'load-path "/usr/share/emacs/site-lisp/erc/")
(require 'erc)
(require 'erc-spelling)
(require 'erc-services)
(require 'erc-log)

; its necessary for nickserv password to work
(erc-services-mode 1)

(setq erc-encoding-coding-alist
      '(("#archlinux.br" . utf-8)))

(setq erc-server-coding-system
      '(lambda (target)
	 (if (and erc-server-announced-name
		  (string-match "localhost" erc-server-announced-name))
	     '(iso-8859-1 . undecided)
	   '(utf-8 . undecided))))

;; set up spelling
(erc-spelling-enable)

(defadvice erc-spelling-init (after erc-spelling-init-choose-dict)
  (when (and erc-server-announced-name
	     (string-match "localhost" erc-server-announced-name))
    (ispell-change-dictionary "brasileiro")))
(ad-activate 'erc-spelling-init)

(setq erc-spelling-dictionaries 
      '(("#archlinux.br" "brasileiro")))


;; Ignore messages from the server that are not channel activity
(setq erc-track-exclude-types '("JOIN" "NICK" "PART" "QUIT" "MODE"
                                "324" "329" "332" "333" "353" "477"))
(setq erc-track-exclude '("&bitlbee"))

;; set up nickserv
(load "~/.ercpass")
(setq erc-prompt-for-nickserv-password nil)
(setq erc-nickserv-passwords
      `((freenode     (("rwanderley" . ,freenodepass)))))



(setq erc-autojoin-channels-alist '(("freenode.net" 
				     "#emacs"
				     "#archlinux.br" "#lisp"
				     "#ratpoison")))

;; Conect to freenode with C-c e f
(global-set-key "\C-cef" (lambda ()
			   (interactive)
			   (erc :server "irc.freenode.net"
				:port "6667"
				:nick "rwanderley")))

;; Conect to Bitlbee with C-c e b
(global-set-key "\C-ceb" (lambda ()
			   (interactive)
			   (erc :server "localhost"
				:port "6667"
				:nick "rwanderley")))

(add-hook 'erc-join-hook 'bitlbee-identify)
(defun bitlbee-identify ()
  "If we're on the bitlbee server, send the identify command to the 
 &bitlbee channel."
  (when (and (string= "localhost" erc-session-server)
	     (string= "&bitlbee" (buffer-name)))
    (erc-message "PRIVMSG" (format "%s identify %s" 
				   (erc-default-target)
				   bitlbeepass))))

;; update nick when emms changes track
(defvar *default-bitlbee-nick* "Rodrigo [Alumônius]")

(defun rsw/erc-enable-emms-change-nick ()
  (interactive)
  (add-hook 'emms-player-started-hook 'rsw/bitlbee-emms-change-nick))

(defun rsw/erc-disable-emms-change-nick ()
  (interactive)
  (remove-hook 'emms-player-started-hook 'rsw/bitlbee-emms-change-nick)
  (rsw/bitlbee-change-nick *default-bitlbee-nick*))

(defun rsw/emms-get-current-track-name ()
  "Return current track playing at emms, if there's
any '/' on the name is probably because were getting
an absolute path name, in this case just remove the
directories and return the filename."
  (car (last
	(split-string
	 (emms-track-description
	  (emms-playlist-current-selected-track))
	 "/" t))))

(defun rsw/bitlbee-change-nick (nick)
  "Change bitlbee's MSN (account 0) nick."
  (let ((buffer (erc-get-buffer "&bitlbee")))
    (when buffer
      (save-window-excursion
	(switch-to-buffer buffer)
	(erc-message "PRIVMSG" (format "%s nick 0 \"%s\""
				       (erc-default-target)
				       nick))))))

(defun rsw/bitlbee-emms-change-nick () 
  "Update nick when emms changes track."
  (let* ((track (rsw/emms-get-current-track-name))
	 (new-nick (concat *default-bitlbee-nick*
			   " Ouvindo " 
			   track)))
    (rsw/bitlbee-change-nick new-nick)))

;(add-hook 'emms-player-started-hook 'rsw/archlinux-br-change-nick)
;(remove-hook 'emms-player-started-hook 'rsw/archlinux-br-change-nick)
(defun rsw/archlinux-br-change-nick ()
  "Update nick when am on the #archlinux.br channel."
  (interactive)
  (let ((buffer (erc-get-buffer "#archlinux.br")))
    (when buffer
      (save-window-excursion
	(switch-to-buffer buffer)
	(erc-send-action (erc-default-target)
			 (format "Ouvindo %s." (rsw/emms-get-current-track-name)))))))

(setq erc-auto-query 'bury)

;; configure logging
(setq erc-enable-logging t
      erc-log-channels t
      erc-log-channels-directory "~/.emacs.d/erc-log"
      erc-save-buffer-on-part nil
      erc-save-queries-on-quit nil
      erc-log-write-after-send t
      erc-log-write-after-insert t)

(defadvice save-buffers-kill-emacs (before save-logs (arg) activate)
  (save-some-buffers t (lambda () (when (and (eq major-mode 'erc-mode)
                                             (not (null buffer-file-name)))))))

(add-hook 'erc-insert-post-hook 'erc-save-buffer-in-logs)
(add-hook 'erc-mode-hook '(lambda () (when (not (featurep 'xemacs))
                                       (set (make-variable-buffer-local
                                             'coding-system-for-write)
                                            'emacs-mule))))
