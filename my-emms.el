;; EMMS configuration
(add-to-list 'load-path "/usr/share/emacs/site-lisp/emms/")
(require 'emms-setup)
(emms-devel)
(emms-default-players)

(eval-after-load 'emms
  '(progn
     (load-file "~/.emms")

     ;; Mplayer parameters
     (setq emms-player-mplayer-parameters '("-ao" "alsa"))
     (if (not (display-graphic-p))
	 ;; If in text mode use frame buffer as graphics output
	 (setq emms-player-mplayer-parameters
	       (append emms-player-mplayer-parameters '("-vo" "fbdev"))))

     (defun rsw/dired-mark-and-unmark-audio-files (emms-function)
       "Mark audio files in current dired buffer, call
EMMS-FUNCTION on those files and than unmark all marks"
       (let ((audio-regex "\\.\\(mp3\\|ogg\\)$"))
	 (dired-mark-files-regexp audio-regex)
	 (funcall emms-function)
	 (dired-unmark-all-marks)))

     (defun rsw/emms-dired-add-audio-files ()
       "Add audio files on current dired buffer to playlist."
       (interactive)
       (rsw/dired-mark-and-unmark-audio-files 'emms-add-dired))

     (defun rsw/emms-dired-play-audio-files ()
       "Play audio files on current dired buffer."
       (interactive)
       (rsw/dired-mark-and-unmark-audio-files 'emms-play-dired))

     ;; Last-fm
     (setq emms-lastfm-username "rwanderley"
	   emms-lastfm-password last-fm-pass)

     (global-set-key "\C-xppg" 'emms-playlist-mode-go)
     (global-set-key	"\C-xpdp" 'rsw/emms-dired-play-audio-files)
     (global-set-key	"\C-xpda" 'rsw/emms-dired-add-audio-files)
     (global-set-key	"\C-xpt" 'emms-pause)
     (global-set-key	"\C-xpf" 'emms-next) ;fwd
     (global-set-key	"\C-xpr" 'emms-previous) ;rwd
     (global-set-key "\C-xpb" 'emms-browser)
     (global-set-key "\C-xpl" 'emms-lyrics-visit-lyric)))

(provide 'my-emms)
