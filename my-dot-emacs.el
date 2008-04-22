;; -*- Lisp-Interaction -*-
;; Import configurations of some modules I
;; use frequently

(add-to-list 'load-path "~/.emacs.d")
(require 'my-spelling)
(require 'my-ecb)
(require 'my-emms)
(require 'my-erc)
;(require 'my-git)
(require 'my-slime)
(require 'my-org)
(require 'my-weblogger)
(require 'my-gnus)
(require 'my-mutt)
(require 'my-latex)
(require 'my-eshell)
(require 'my-w3m)
(require 'my-twittering)
;(require 'my-newsticker)

;;;; Misc configurations

;; Bazaar
(unless (memq 'Bzr vc-handled-backends)
  (add-to-list 'vc-handled-backends 'Bzr))

(require 'bazaar)
(add-hook 'find-file-hooks 'bzr-maybe-activate)

;; enable emacsclient
(server-start)

;; Following the 10 mandamentos of
;; http://steve.yegge.googlepages.com/effective-emacs

;; #2: Makes typing M-x easier
(global-set-key "\C-x\C-m" 'execute-extended-command)
(global-set-key "\C-c\C-m" 'execute-extended-command)

;; #7: Removing some unusefull things
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(if (fboundp 'menu-bar-mode) (menu-bar-mode -1))

(ansi-color-for-comint-mode-on)		;enable nice color in shell mode

;; Set default browser
(setq browse-url-browser-function 'browse-url-firefox
      browse-url-new-window-flag  t
      browse-url-firefox-new-window-is-tab t)

;; Set ediff to not open new frames
(setq ediff-window-setup-function 'ediff-setup-windows-plain)

;; scroll output automatically as it apears on the *compilation*
;; buffer
(setq compilation-scroll-output t)

;; set time at the toolbar
(display-time)

(setq backup-directory-alist
      (list 
       (cons ".*"
	     (expand-file-name	"~/.emacsbackup/"))))

(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(ecb-options-version "2.32")
 '(newsticker-url-list (quote (("Nerdson" "http://feeds.feedburner.com/nerdson" nil nil nil) ("Tribuna do Norte" "http://tribunadonorte.com.br/ultnoticia.php" nil nil nil) ("CBN Comentaristas" "http://www.cbn.com.br/ipod/comentaristas.xml" nil nil nil) ("CBN Esporte Clube" "http://www.cbn.com.br/ipod/cbnesporteclube_cbn.xml" nil nil nil) ("CBN Fim de expediente" "http://www.cbn.com.br/ipod/fimdeexpediente_cbn.xml" nil nil nil))))
 '(newsticker-url-list-defaults (quote (("Kuro5hin.org" "http://www.kuro5hin.org/backend.rdf") ("NY Times" "http://partners.userland.com/nytRss/nytHomepage.xml") ("Quote of the day" "http://www.quotationspage.com/data/qotd.rss" "07:00" 86400))))
 '(org-agenda-custom-commands (quote (("d" todo #("DELEGATED" 0 9 (face org-warning)) nil) ("c" todo #("DONE|DEFERRED|CANCELLED" 0 23 (face org-warning)) nil) ("w" todo #("WAITING" 0 7 (face org-warning)) nil) ("W" agenda "" ((org-agenda-ndays 21))) ("A" agenda "" ((org-agenda-skip-function (lambda nil (org-agenda-skip-entry-if (quote notregexp) "\\=.*\\[#A\\]"))) (org-agenda-ndays 1) (org-agenda-overriding-header "Today's Priority #A tasks: "))) ("u" alltodo "" ((org-agenda-skip-function (lambda nil (org-agenda-skip-entry-if (quote scheduled) (quote deadline) (quote regexp) "<[^>
]+>"))) (org-agenda-overriding-header "Unscheduled TODO entries: "))))))
 '(org-agenda-files (quote ("~/todo.org")))
 '(org-agenda-ndays 7)
 '(org-agenda-show-all-dates t)
 '(org-agenda-skip-deadline-if-done t)
 '(org-agenda-skip-scheduled-if-done t)
 '(org-agenda-start-on-weekday nil)
 '(org-deadline-warning-days 14)
 '(org-default-notes-file "~/notes.org")
 '(org-fast-tag-selection-single-key (quote expert))
 '(org-remember-store-without-prompt t)
 '(org-remember-templates (quote ((116 "* TODO %?
  %u" "~/todo.org" "Tasks") (110 "* %u %?" "~/notes.org" "Notes"))))
 '(org-reverse-note-order t)
 '(remember-annotation-functions (quote (org-remember-annotation)))
 '(remember-handler-functions (quote (org-remember-handler)))
 '(weblogger-config-alist (quote (("rsw" ("user" . "admin") ("server-url" . "http://rsw.digi.com.br/blog/xmlrpc.php") ("weblog" . "1"))))))
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 )
