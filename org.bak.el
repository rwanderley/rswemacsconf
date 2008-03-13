;; configuring and remember
(add-to-list 'load-path "/usr/share/emacs/site-lisp/remember/")
(require 'remember-autoloads)

(setq org-default-notes-file "~/org/notes.org")
(setq organizer-data-file "~/org/organizer.org")

(setq org-remember-templates
;      '((?t "* TODO %?\n  %i\n  %a" "~/emacs/organizer.org")
       '((?a "* Appointment: %?\n%^T\n%i\n  %a" "~/org/agenda.org")))

(setq remember-annotation-functions '(org-remember-annotation))
(setq remember-handler-functions '(org-remember-handler))

(eval-after-load 'remember
  '(add-hook 'remember-mode-hook 'org-remember-apply-template))

(global-set-key (kbd "C-c r") 'remember)

(require 'org)

(add-to-list 'auto-mode-alist '("\\.org$" . org-mode))

(global-set-key (kbd "C-c a") 'org-agenda)

(setq org-todo-keywords '("TODO" "STARTED" "WAITING" "DONE"))
(setq org-agenda-include-diary t)
(setq org-agenda-include-all-todo t)

;; This function was taken from Sacha's blog
(defun rsw/organizer-review-file ()
  "Open `remember-data-file'."
  (interactive)
  (find-file-other-window organizer-data-file))

(global-set-key (kbd "C-c o") 'rsw/organizer-review-file)
