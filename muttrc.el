;;; muttrc.el --- generic mode for mutt configuration files                      
;	$Id: muttrc.el,v 1.3 2002/04/18 23:19:05 reid Exp $	

;; Copyright (C) 2002  Free Software Foundation, Inc.

;; Author: Rob Reid (Rob dot Reid Shift-2 nrc-cnrc dot gc period ca]
;; Keywords: faces, mail

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Provides syntax highlighting for the configuaration files of mutt, the mail
;; user agent.  It isn't perfect, but it highlights the keywords and comments
;; in my ~/.muttrc slightly better than sh-mode does.  generic-x is REALLY
;; convienient, but I don't see any simple way to make it smarter about cut
;; characters and keyword vs. variable conflicts.

;; $Log: muttrc.el,v $
;; Revision 1.3  2002/04/18 23:19:05  reid
;; Changed $log$ to $Log$.
;;

;;; Code:
(require 'generic)
(require 'generic-x)

(define-generic-mode 'muttrc-mode
  (list ?#)
  (list "alternative_order" "append-hook" "ask-no" "ask-yes" "attach"
	"attachment" "auto_view" "bind" "black" "blue" "body" "brightblue"
	"bringhtcyan" "brightgreen" "brightmagenta" "brightred" "brightyellow"
	"brightwhite" "close-hook" "color" "compose" "cyan" "default" "editor"
	"error" "folder-hook" "generic" "green" "header" "ignore" "index"
	"indicator" "macro" "magenta" "markers" "no" "normal" "open-hook"
	"pager" "red" "save-hook" "send-hook" "set" "source" "status" "tilde"
	"tree" "unset" "white" "yes")
  '(("\\(abort_unmodified\\|alias_file\\|attribution\\|confirmcreate\\|edit_hdrs\\|editor\\|folder\\|forw_decode\\|forw_quote\\|nohelp\\|hidden_host\\|history\\|include\\|mailcap_path\\|noconfirmappend\\|nomove\\|pager_context\\|pager_format\\|pager_index_lines\\|pager_stop\\|pgp_timeout\\|pgp_verify_sig\\|pgp_v2_language\\|postponed\\|print_cmd\\|noprompt_after\\|quote_regexp\\|quote_sig\\|quoted*\\|save_empty\\|record\\|signature\\|sort\\|sort_aux\\|status_format\\|suspend\\|timeout\\|tmpdir\\|use_8bitmime\\|web_browser\\)" 1
     'font-lock-variable-name-face))
  (list "Muttrc" "\\.muttrc")
  nil)

(provide 'muttrc)
;;; muttrc.el ends here
