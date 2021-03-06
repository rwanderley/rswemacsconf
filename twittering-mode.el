;;; twittering-mode.el --- Major mode for Twitter

;; Copyright (C) 2007 Yuto Hayamizu.

;; Author: Y. Hayamizu <y.hayamizu@gmail.com>
;; Created: Sep 4, 2007
;; Version: 0.2.0
;; Keywords: twitter web
;; URL: http://lambdarepos.svnrepository.com/share/trac.cgi/browser/lang/elisp/twittering-mode/trunk/twittering-mode.el

;; Contributors:
;;  naoya_t
;;  * the templete string system for status
;;  id:masa_edw
;;  * twittering-scroll-mode
;;  Phil Hagelberg
;;  * misc. bug fixes

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
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

;; twittering-mode.el is a major mode for Twitter.
;; You can check friends timeline, and update your status on Emacs.

;;; History: (local changes)

;; twittering-(icon|scroll)-mode should *not* go in the modeline
;; q to bury-buffer
;; thanks; don't need a message every time HTTP GETs work
;; disable undo for the twittering buffer; it caused overflow

;;; Bugs:

;; should warn if you go over 140 chars
;; should not create a *twittering* buffer when you require, just when you launch.
;; sometimes icons get mixed up

;;; Code:

(require 'cl)
(require 'xml)
(require 'parse-time)

(defvar twittering-mode-map (make-sparse-keymap))

(defvar twittering-timer nil)

(defvar twittering-idle-time 20)

(defvar twittering-timer-interval 90)

(defvar twittering-username nil)

(defvar twittering-password nil)

(defvar twittering-scroll-mode nil)

(defvar twittering-status-format nil)
(setq twittering-status-format "%i %s,  %@:\n  %t // from %f%L")
; %s - screen_name
; %S - name
; %i - profile_image
; %d - description
; %l - location
; %L - " [location]"
; %u - url
; %j - user.id
; %p - protected?
; %c - created_at (raw UTC string)
; %C{time-format-str} - created_at (formatted with time-format-str)
; %@ - X seconds ago
; %t - text
; %' - truncated
; %f - source
; %# - id

(defvar twittering-buffer "*twittering*")
(defun twittering-buffer ()
  (twittering-get-or-generate-buffer twittering-buffer))

(defvar twittering-http-buffer "*twittering-http-buffer*")
(defun twittering-http-buffer ()
  (twittering-get-or-generate-buffer twittering-http-buffer))

(defvar twittering-friends-timeline-data nil)

(defvar twittering-username-face 'twittering-username-face)
(defvar twittering-uri-face 'twittering-uri-face)

(defun twittering-get-or-generate-buffer (buffer)
  (if (bufferp buffer)
      (if (buffer-live-p buffer)
          buffer
        (generate-new-buffer (buffer-name buffer)))
    (if (stringp buffer)
        (or (get-buffer buffer)
            (generate-new-buffer buffer)))))

(defun assocref (item alist)
    (cdr (assoc item alist)))

;;;
;;; to show image files

(defvar twittering-wget-buffer "*twittering-wget-buffer*")
(defun twittering-wget-buffer ()
  (twittering-get-or-generate-buffer twittering-wget-buffer))

(defvar twittering-tmp-dir "/tmp/twmode-images")

(defvar twittering-icon-mode nil "You MUST NOT CHANGE this variable directory. You should change through function'twittering-icon-mode'")
(defun twittering-icon-mode (&optional arg)
  (interactive)
  (setq twittering-icon-mode
        (if twittering-icon-mode
            (if (null arg)
                nil
              (> (prefix-numeric-value arg) 0))
          (when (or (null arg)
                    (and arg (> (prefix-numeric-value arg) 0)))
            (when (file-writable-p twittering-tmp-dir)
              (progn 
                (if (not (file-directory-p twittering-tmp-dir))
                    (make-directory twittering-tmp-dir))
                t)))))
  (twittering-render-friends-timeline))

(defun twittering-scroll-mode (&optional arg)
  (interactive)
  (setq twittering-scroll-mode
      (if (null arg)
          (not twittering-scroll-mode)
        (> (prefix-numeric-value arg) 0))))

(defvar twittering-image-stack nil)

(defun twittering-image-type (file-name)
  (cond
   ((string-match "\\.jpe?g" file-name) 'jpeg)
   ((string-match "\\.png" file-name) 'png)
   ((string-match "\\.gif" file-name) 'gif)
   (t nil)))

(defun twittering-local-strftime (fmt string)
  (format-time-string fmt ; like "%Y-%m-%d %H:%M:%S", shown in localtime
                      (apply 'encode-time (parse-time-string string))))

(defvar twittering-debug-mode nil)
(defvar twittering-debug-buffer "*debug*")
(defun twittering-debug-buffer ()
  (twittering-get-or-generate-buffer twittering-debug-buffer))
(defmacro debug-print (obj)
  (let ((obsym (gensym)))
    `(let ((,obsym ,obj))
       (if twittering-debug-mode
           (with-current-buffer (twittering-debug-buffer)
             (insert (prin1-to-string ,obsym))
             (newline)
             ,obsym)
         ,obsym))))

(defun twittering-debug-mode ()
  (interactive)
  (setq twittering-debug-mode
        (not twittering-debug-mode))
  (message (if twittering-debug-mode "debug mode:on" "debug mode:off")))

(if twittering-mode-map
    (let ((km twittering-mode-map))
      (define-key km "\C-c\C-f" 'twittering-friends-timeline)
      (define-key km "\C-c\C-s" 'twittering-update-status-interactive)
      (define-key km "\C-c\C-e" 'twittering-erase-old-statuses)
      (define-key km "\C-m" 'twittering-enter)
      (define-key km "\C-c\C-l" 'twittering-update-lambda)
      (define-key km [mouse-1] 'twittering-click)
      (define-key km "\C-c\C-v" 'twittering-view-user-page)
      (define-key km "j" 'next-line)
      (define-key km "k" 'previous-line)
      (define-key km "l" 'forward-char)
      (define-key km "h" 'backward-char)
      (define-key km "0" 'beginning-of-line)
      (define-key km "^" 'beginning-of-line-text)
      (define-key km "$" 'end-of-line)
      (define-key km [backspace] 'backward-char)
      (define-key km "G" 'end-of-buffer)
      (define-key km "H" 'beginning-of-buffer)
      (define-key km "q" 'bury-buffer)
      nil))

(defvar twittering-mode-syntax-table nil "")

(if twittering-mode-syntax-table
    ()
  (setq twittering-mode-syntax-table (make-syntax-table))
;  (modify-syntax-entry ?  "" twittering-mode-syntax-table)
  (modify-syntax-entry ?\" "w"  twittering-mode-syntax-table)
  )

(defun twittering-mode-init-variables ()
  ;(make-variable-buffer-local 'variable)
  ;(setq variable nil)
  (font-lock-mode -1)
  (defface twittering-username-face
    `((t nil)) "" :group 'faces)
  (copy-face 'font-lock-string-face 'twittering-username-face)
  (set-face-attribute 'twittering-username-face nil :underline t)
  (defface twittering-uri-face
    `((t nil)) "" :group 'faces)
  (set-face-attribute 'twittering-uri-face nil :underline t)
  (add-to-list 'minor-mode-alist '(twittering-icon-mode ""))
  (add-to-list 'minor-mode-alist '(twittering-scroll-mode ""))
  )

(defmacro case-string (str &rest clauses)
  `(cond
    ,@(mapcar
       (lambda (clause)
         (let ((keylist (car clause))
               (body (cdr clause)))
           `(,(if (listp keylist)
                  `(or ,@(mapcar (lambda (key) `(string-equal ,str ,key)) keylist))
                't)
             ,@body)))
       clauses)))

;; If you use Emacs21, decode-char 'ucs will fail unless Mule-UCS is loaded.
;; TODO: Show error messages if Emacs 21 without Mule-UCS
(defmacro twittering-ucs-to-char (num)
  (if (functionp 'ucs-to-char)
      `(ucs-to-char ,num)
    `(decode-char 'ucs ,num)))

(defun twittering-mode ()
  "Major mode for Twitter"
  (interactive)
  (switch-to-buffer (twittering-buffer))
  (kill-all-local-variables)
  (twittering-mode-init-variables)
  (use-local-map twittering-mode-map)
  (setq major-mode 'twittering-mode)
  (setq mode-name "Twittering mode")
  (set-syntax-table twittering-mode-syntax-table)
  (run-hooks 'twittering-mode-hook)
  (font-lock-mode -1)
  (buffer-disable-undo)
  (twittering-start)
  )

;;;
;;; Basic HTTP functions
;;;

(defun twittering-http-get (method-class method &optional sentinel)
  (if (null sentinel) (setq sentinel 'twittering-http-get-default-sentinel))

  ;; clear the buffer
  (save-excursion
    (set-buffer (twittering-http-buffer))
    (erase-buffer))

  (let (proc)
    (condition-case nil
        (progn
          (setq proc
                (open-network-stream
                 "network-connection-process" (twittering-http-buffer)
                 "twitter.com" 80))
          (set-process-sentinel proc sentinel)
          (process-send-string
           proc
           (let ((nl "\r\n"))
             (concat "GET /" method-class "/" method ".xml HTTP/1.1" nl
                     "Host: twitter.com" nl
                     "Authorization: Basic "
                     (base64-encode-string
                      (concat twittering-username ":" twittering-password))
                     nl
                     "Accept: text/xml"
                     ",application/xml"
                     ",application/xhtml+xml"
                     ",application/html;q=0.9"
                     ",text/plain;q=0.8"
                     ",image/png,*/*;q=0.5" nl
                     "Accept-Charset: utf-8;q=0.7,*;q=0.7"
                     nl nl))))
      (error
       (message "Failure: HTTP GET") nil))))

(defun twittering-http-get-default-sentinel (proc stat &optional suc-msg)
  (let ((header (twittering-get-response-header))
          (body (twittering-get-response-body))
          (status nil)
          )
      (if (string-match "HTTP/1\.[01] \\([a-z0-9 ]+\\)\r?\n" header)
          (progn
            (setq status (match-string-no-properties 1 header))
            (case-string
             status
             (("200 OK")
              (mapcar
               #'twittering-cache-status-datum
               (reverse (twittering-xmltree-to-status
                         body)))
              (twittering-render-friends-timeline)
              ;; (message (if suc-msg suc-msg "Success: Get."))
              )
             (t (message status))))
        (message "Failure: Bad http response.")))
  )

(defun twittering-render-friends-timeline ()
  (with-current-buffer (twittering-buffer)
    (let ((point (point))
          (end (point-max)))
      (setq buffer-read-only nil)
      (erase-buffer)
      (insert
       (mapconcat (lambda (status)
                    (twittering-format-status status twittering-status-format))
                  twittering-friends-timeline-data
                  "\n"))
      (if twittering-image-stack
          (clear-image-cache))
      (setq buffer-read-only t)
      (debug-print (current-buffer))
      (goto-char (+ point (if twittering-scroll-mode (- (point-max) end) 0))))
    ))

(defun twittering-format-status (status format-str)
  (flet ((attr (key)
               (assocref key status))
         (profile-image
          ()
          (let ((profile-image-url (attr 'user-profile-image-url))
                (icon-string "\n  "))
            (if (string-match "/\\([^/?]+\\)\\(?:\\?\\|$\\)" profile-image-url)
                (let ((filename (match-string-no-properties 1 profile-image-url)))
                  ;; download icons if does not exist
                  (if (file-exists-p (concat twittering-tmp-dir
                                             "/" filename))
                      t
                    (add-to-list 'twittering-image-stack profile-image-url))

                  (when (and icon-string twittering-icon-mode)
                    (set-text-properties
                     1 2 `(display
                           (image :type ,(twittering-image-type filename)
                                  :file ,(concat twittering-tmp-dir
                                                 "/"
                                                 filename)))
                     icon-string)
                    icon-string)
                  )))))
    (let ((cursor 0)
          (result ())
          c
          found-at)
      (setq cursor 0)
      (setq result '())
      (while (setq found-at (string-match "%\\(C{\\([^}]+\\)}\\|[A-Za-z#@']\\)" format-str cursor))
        (setq c (string-to-char (match-string-no-properties 1 format-str)))
        (if (> found-at cursor)
            (push (substring format-str cursor found-at) result)
          "|")
        (setq cursor (match-end 1))

        (case c
          ((?s)                         ; %s - screen_name
           (push (attr 'user-screen-name) result))
          ((?S)                         ; %S - name
           (push (attr 'user-name) result))
          ((?i)                         ; %i - profile_image
           (push (profile-image) result))
          ((?d)                         ; %d - description
           (push (attr 'user-description) result))
          ((?l)                         ; %l - location
           (push (attr 'user-location) result))
          ((?L)                         ; %L - " [location]"
           (let ((location (attr 'user-location)))
             (unless (or (null location) (string= "" location))
               (push (concat " [" location "]") result)) ))
          ((?u)                         ; %u - url
           (push (attr 'user-url) result))
          ((?j)                         ; %j - user.id
           (push (attr 'user-id) result))
          ((?p)                         ; %p - protected?
           (let ((protected (attr 'user-protected)))
             (when (string= "true" protected)
               (push "[x]" result))))
          ((?c)                     ; %c - created_at (raw UTC string)
           (push (attr 'created-at) result))
          ((?C) ; %C{time-format-str} - created_at (formatted with time-format-str)
           (push (twittering-local-strftime
                  (or (match-string-no-properties 2 format-str) "%H:%M:%S")
                  (attr 'created-at))
                 result))
          ((?@)                         ; %@ - X seconds ago
           (let ((created-at
                  (apply
                   'encode-time
                   (parse-time-string (attr 'created-at))))
                 (now (current-time)))
             (let ((secs (+ (* (- (car now) (car created-at)) 65536)
                            (- (cadr now) (cadr created-at)))))
               (push (cond ((< secs 5) "less than 5 seconds ago")
                           ((< secs 10) "less than 10 seconds ago")
                           ((< secs 20) "less than 20 seconds ago")
                           ((< secs 30) "half a minute ago")
                           ((< secs 60) "less than a minute ago")
                           ((< secs 150) "1 minute ago")
                           ((< secs 2400) (format "%d minutes ago"
                                                  (/ (+ secs 30) 60)))
                           ((< secs 5400) "about 1 hour ago")
                           ((< secs 84600) (format "about %d hours ago"
                                                   (/ (+ secs 1800) 3600)))
                           (t (format-time-string "%I:%M %p %B %d, %Y" created-at)))
                     result))))
          ((?t)                         ; %t - text
           (push                        ;(clickable-text)
            (attr 'text)
            result))
          ((?')                         ; %' - truncated
           (let ((truncated (attr 'truncated)))
             (when (string= "true" truncated)
               (push "..." result))))
          ((?f)                         ; %f - source
           (push (attr 'source) result))
          ((?#)                         ; %# - id
           (push (attr 'id) result))
          (t
           (push (char-to-string c) result)))
        )
      (push (substring format-str cursor) result)
      (apply 'concat (nreverse result))
      )))

(defun twittering-http-post
  (method-class method &optional parameters contents sentinel)
  "Send HTTP POST request to twitter.com

METHOD-CLASS must be one of Twitter API method classes(statuses, users or direct_messages).
METHOD must be one of Twitter API method which belongs to METHOD-CLASS.
PARAMETERS is alist of URI parameters. ex) ((\"mode\" . \"view\") (\"page\" . \"6\")) => <URI>?mode=view&page=6"
  (if (null sentinel) (setq sentinel 'twittering-http-post-default-sentinel))

  ;; clear the buffer
  (save-excursion
    (set-buffer (twittering-http-buffer))
    (erase-buffer))

  (let (proc)
    (progn
      (setq proc
            (open-network-stream
             "network-connection-process" (twittering-http-buffer)
             "twitter.com" 80))
      (set-process-sentinel proc sentinel)
      (process-send-string
       proc
       (let ((nl "\r\n"))
         (concat "POST /" method-class "/" method ".xml?"
                 (if parameters
                     (mapconcat
                      (lambda (param-pair)
                        (format "%s=%s"
                                (twittering-percent-encode (car param-pair))
                                (twittering-percent-encode (cdr param-pair))))
                      parameters
                      "&"))
                 " HTTP/1.1" nl
                 "Host: twitter.com" nl
                 "Authorization: Basic "
                 (base64-encode-string
                  (concat twittering-username ":" twittering-password))
                 nl
                 "Content-Type: text/plain" nl
                 "Content-Length: 0" nl
                 nl nl))))))

(defun twittering-http-post-default-sentinel (proc stat &optional suc-msg)
  
  (condition-case err-signal
      (let ((header (twittering-get-response-header))
            ; (body (twittering-get-response-body)) not used now.
            (status nil))
        (string-match "HTTP/1\.1 \\([a-z0-9 ]+\\)\r?\n" header)
        (setq status (match-string-no-properties 1 header))
        (case-string status
                     (("200 OK")
                      (message (if suc-msg suc-msg "Success: Post")))
                     (t (message status)))
        )
    (error (message (prin1-to-string err-signal))))
  )

(defun twittering-get-response-header (&optional buffer)
  "Exract HTTP response header from HTTP response.
`buffer' may be a buffer or the name of an existing buffer.
 If `buffer' is omitted, the value of `twittering-http-buffer' is used as `buffer'."
  (if (stringp buffer) (setq buffer (get-buffer buffer)))
  (if (null buffer) (setq buffer (twittering-http-buffer)))
  (save-excursion
    (set-buffer buffer)
    (let ((content (buffer-string)))
      (substring content 0 (string-match "\r?\n\r?\n" content)))))

(defun twittering-get-response-body (&optional buffer)
  "Exract HTTP response body from HTTP response, parse it as XML, and return a XML tree as list.
`buffer' may be a buffer or the name of an existing buffer.
 If `buffer' is omitted, the value of `twittering-http-buffer' is used as `buffer'."
  (if (stringp buffer) (setq buffer (get-buffer buffer)))
  (if (null buffer) (setq buffer (twittering-http-buffer)))
  (save-excursion
    (set-buffer buffer)
    (let ((content (buffer-string)))
      (let ((content (buffer-string)))
        (xml-parse-region (+ (string-match "\r?\n\r?\n" content)
                             (length (match-string 0 content)))
                          (point-max)))
      )))

(defun twittering-cache-status-datum (status-datum &optional data-var)
  "Cache status datum into data-var(default twittering-friends-timeline-data)
If STATUS-DATUM is already in DATA-VAR, return nil. If not, return t."
  (if (null data-var)
      (setf data-var 'twittering-friends-timeline-data))
  (let ((id (cdr (assq 'id status-datum)))) 
    (if (or (null (symbol-value data-var))
            (not (find-if
                  (lambda (item)
                    (eql id (cdr (assq 'id item))))
                  (symbol-value data-var))))
        (progn
          (set data-var (cons status-datum (symbol-value data-var)))
          t)
      nil)))

(defun twittering-status-to-status-datum (status)
  (flet ((assq-get (item seq)
                   (car (cddr (assq item seq)))))
    (let* ((status-data (cddr status))
           id text source created-at truncated
           (user-data (cddr (assq 'user status-data)))
           user-id user-name
           user-screen-name
           user-location
           user-description
           user-profile-image-url
           user-url
           user-protected
           regex-index)
    
      (setq id (string-to-number (assq-get 'id status-data)))
      (setq text (twittering-decode-html-entities 
                  (assq-get 'text status-data)))
      (setq source (twittering-decode-html-entities 
                    (assq-get 'source status-data)))
      (setq created-at (assq-get 'created_at status-data))
      (setq truncated (assq-get 'truncated status-data))
      (setq user-id (string-to-number (assq-get 'id user-data)))
      (setq user-name (twittering-decode-html-entities
                       (assq-get 'name user-data)))
      (setq user-screen-name (twittering-decode-html-entities 
                              (assq-get 'screen_name user-data)))
      (setq user-location (twittering-decode-html-entities
                           (assq-get 'location user-data)))
      (setq user-description (twittering-decode-html-entities
                              (assq-get 'description user-data)))
      (setq user-profile-image-url (assq-get 'profile_image_url user-data))
      (setq user-url (assq-get 'url user-data))
      (setq user-protected (assq-get 'protected user-data))

      ;; make username clickable
      (add-text-properties 0 (length user-screen-name)
                           `(mouse-face highlight
                                        uri ,(concat "http://twitter.com/" user-screen-name)
                                        username ,user-screen-name
                                        face twittering-username-face)
                           user-screen-name)

      ;; make URI clickable
      (setq regex-index 0)
      (while regex-index
        (setq regex-index
              (string-match "@\\([_a-zA-Z0-9]+\\)\\|\\(https?://[-_.!~*'()a-zA-Z0-9;/?:@&=+$,%#]+\\)"
                            text
                            regex-index))
        (when regex-index
          (let* ((matched-string (match-string-no-properties 0 text))
                 (screen-name (match-string-no-properties 1 text))
                 (uri (match-string-no-properties 2 text)))
            (add-text-properties
             (if screen-name
                 (+ 1 (match-beginning 0))
               (match-beginning 0))
             (match-end 0)
             (if screen-name
                 `(mouse-face
                   highlight
                   face twittering-uri-face
                   username ,screen-name
                   uri ,(concat "http://twitter.com/" screen-name))
               `(mouse-face highlight
                 face twittering-uri-face
                 uri ,uri))
             text))
          (setq regex-index (match-end 0)) ))

      ;; make screen-name clickable
      (add-text-properties
       0 (length user-screen-name)
       `(mouse-face highlight
                    face twittering-username-face
                    uri ,(concat "http://twitter.com/" user-screen-name)
                    username ,user-screen-name)
       user-screen-name)

      ;; make source pretty and clickable
      (if (string-match "<a href=\"\\(.*\\)\">\\(.*\\)</a>" source)
          (let ((uri (match-string-no-properties 1 source))
                (caption (match-string-no-properties 2 source)))
            (setq source caption)
            (add-text-properties
             0 (length source)
             `(mouse-face highlight
               uri ,uri
               face twittering-uri-face
               source ,source)
             source)
            ))

      (mapcar
       (lambda (sym)
         `(,sym . ,(symbol-value sym)))
       '(id text source created-at truncated
            user-id user-name user-screen-name user-location
            user-description
            user-profile-image-url
            user-url
            user-protected)))))

(defun twittering-xmltree-to-status (xmltree)
  (mapcar #'twittering-status-to-status-datum
          ;; quirk to treat difference between xml.el in Emacs21 and Emacs22
          ;; On Emacs22, there may be blank strings
          (let ((ret nil) (statuses (reverse (cddr (car xmltree)))))
            (while statuses
              (if (consp (car statuses))
                  (setq ret (cons (car statuses) ret)))
              (setq statuses (cdr statuses)))
            ret)))

(defun twittering-percent-encode (str &optional coding-system)
  (if (or (null coding-system)
          (not (coding-system-p coding-system)))
      (setq coding-system 'utf-8))
  (mapconcat
   (lambda (c)
     (cond
      ((twittering-url-reserved-p c)
       (char-to-string c))
      ((eq c ? ) "+")
      (t (format "%%%x" c))))
   (encode-coding-string str coding-system)
   ""))

(defun twittering-url-reserved-p (ch)
  (or (and (<= ?A ch) (<= ch ?z))
      (and (<= ?0 ch) (<= ch ?9))
      (eq ?. ch)
      (eq ?- ch)
      (eq ?_ ch)
      (eq ?~ ch)))

(defun twittering-decode-html-entities (encoded-str)
  (if encoded-str
      (let ((cursor 0)
            (found-at nil)
            (result '()))
        (while (setq found-at
                     (string-match "&\\(#\\([0-9]+\\)\\|\\([A-Za-z]+\\)\\);"
                                   encoded-str cursor))
          (when (> found-at cursor)
            (push (substring encoded-str cursor found-at) result))
          (let ((number-entity (match-string-no-properties 2 encoded-str))
                (letter-entity (match-string-no-properties 3 encoded-str)))
            (cond (number-entity
                   (push
                    (char-to-string
                     (twittering-ucs-to-char
                      (string-to-number number-entity))) result))
                  (letter-entity
                   (cond ((string= "gt" letter-entity) (push ">" result))
                         ((string= "lt" letter-entity) (push "<" result))
                         (t push "?" result)))
                  (t (push "?" result)))
            (setq cursor (match-end 0))))
        (push (substring encoded-str cursor) result)
        (apply 'concat (nreverse result)))
    ""))

(defun twittering-timer-action (func)
  (let ((buf (get-buffer twittering-buffer)))
    (if (null buf)
        (twittering-stop)
      (funcall func)
      )))

(defun twittering-update-status-if-not-blank (status)
  (if (string-match "^\\s-*\\(?:@[-_a-z0-9]+\\)?\\s-*$" status)
      nil
    (twittering-http-post "statuses" "update"
                          `(("status" . ,status)
                            ("source" . "twmode")))
    t))

(defun twittering-update-status-from-minibuffer (&optional init-str)
  (if (null init-str) (setq init-str ""))
  (let ((status init-str) (not-posted-p t))
    (while not-posted-p
      (setq status (read-from-minibuffer "status: " status nil nil nil nil t))
      (setq not-posted-p
            (not (twittering-update-status-if-not-blank status))))))

(defun twittering-update-lambda ()
  (interactive)
  (twittering-http-post
   "statuses" "update"
   `(("status" . "\xd34b\xd22b\xd26f\xd224\xd224\xd268\xd34b")
     ("source" . "twmode"))))

;;;
;;; Commands
;;;

(defun twittering-start (&optional action)
  (interactive)
  (if (null action)
      (setq action #'twittering-friends-timeline))
  (if twittering-timer
      nil
    (setq twittering-timer
          (run-at-time "0 sec"
                       twittering-timer-interval
                       #'twittering-timer-action action))))

(defun twittering-stop ()
  (interactive)
  (cancel-timer twittering-timer)
  (setq twittering-timer nil))

(defun twittering-friends-timeline ()
  (interactive)
  (let ((buf (get-buffer twittering-buffer)))
    (if (not buf)
        (twittering-stop)
      (twittering-http-get "statuses" "friends_timeline")
      ))

  (if twittering-icon-mode
      (if twittering-image-stack
          (let ((proc
                 (apply
                  #'start-process
                  "wget-images"
                  (twittering-wget-buffer)
                  "wget"
                  (format "--directory-prefix=%s" twittering-tmp-dir)
                  "--no-clobber"
                  "--quiet"
                  twittering-image-stack)))
            (set-process-sentinel
             proc
             (lambda (proc stat)
               (clear-image-cache)
               (save-excursion
                 (set-buffer (twittering-wget-buffer))
                 )))))))

(defun twittering-update-status-interactive ()
  (interactive)
  (twittering-update-status-from-minibuffer))

(defun twittering-erase-old-statuses ()
  (interactive)
  (setq twittering-friends-timeline-data nil)
  (twittering-http-get "statuses" "friends_timeline"))

(defun twittering-click ()
  (interactive)
  (let ((uri (get-text-property (point) 'uri)))
    (if uri
        (browse-url uri))))

(defun twittering-enter ()
  (interactive)
  (let ((username (get-text-property (point) 'username))
        (uri (get-text-property (point) 'uri)))
    (if username
        (twittering-update-status-from-minibuffer (concat "@" username " "))
      (if uri
          (browse-url uri)))))

(defun twittering-view-user-page ()
  (interactive)
  (let ((uri (get-text-property (point) 'uri)))
    (if uri
        (browse-url uri))))

(defun twittering-reply-to-user ()
  (interactive)
  (let ((username (get-text-property (point) 'username)))
    (if username
        (twittering-update-status-from-minibuffer (concat "@" username " ")))))

(provide 'twittering-mode)
;;; twittering.el ends here
