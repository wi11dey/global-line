;;; global-line.el --- -*- lexical-binding: t; -*-

;; Author: Will Dey
;; Created: 8 January 2019

;; Generate README:
;;; Commentary:

;;; Code:

;; TODO Multiple frame support.
;; TODO Reuse same window across multiple created frames.
;; TODO Make errors in `global-line-refresh-function' un-intrusive and fail gracefully
;; TODO Enable immediately on `global-line-mode'

(defgroup global-line nil
  ""
  :group 'mode-line)

(defconst global-line-buffer-name " *Global Line*"
  "")

(defvar global-line--window nil)

(defcustom global-line-refresh-interval 1
  ""
  :type 'number)

(defvar global-line--refresh-timer nil)

(defcustom global-line-format
  '((:eval (format-time-string "%F %T")))
  ""
  :type 'sexp)

(defun global-line-use-format ()
  ""
  (erase-buffer)
  (insert (format-mode-line global-line-format nil)))

(defcustom global-line-refresh-function #'global-line-use-format
  ""
  :type 'function)

(defcustom global-line-side 'above
  "Which side of the root window the global line should be located. Should be either 'above' or 'below'."
  :type '(radio (const :tag "Above" above)
		(const :tag "Below" below)))

(defvar global-line-setup-hook nil
  "")

(defun global-line--refresh ()
  ""
  (with-selected-window global-line--window
    (set-buffer (get-buffer-create global-line-buffer-name))
    (let ((inhibit-read-only t))
      (funcall global-line-refresh-function))
    (global-line--set-window-height)))

(defun global-line--set-window-height (&optional window)
  ""
  (let ((window-resize-pixelwise t)
        window-size-fixed)
    (fit-window-to-buffer window nil 1)))

;;;###autoload
(define-minor-mode global-line-mode
  "Global Line mode"
  :lighter " _"
  :global t
  ;; Teardown:
  (when global-line--refresh-timer
    (setq global-line--refresh-timer (cancel-timer global-line--refresh-timer)))
  (when (get-buffer global-line-buffer-name)
    (delete-windows-on global-line-buffer-name)
    (kill-buffer global-line-buffer-name))
  (setq global-line--window nil)
  (when global-line-mode
    (with-selected-window (setq global-line--window (let ((ignore-window-parameters t))
						      (split-window (frame-root-window) -1 global-line-side)))
      (switch-to-buffer (get-buffer-create global-line-buffer-name))
      (setq buffer-read-only t
	    window-size-fixed t
	    cursor-type nil
	    mode-line-format nil
	    display-line-numbers nil)
      (set-window-dedicated-p global-line--window t)
      (set-window-parameter global-line--window 'no-other-window t)
      (set-window-parameter global-line--window 'no-delete-other-windows t)
      (set-window-fringes global-line--window 0 0)
      (run-hooks 'global-line-setup-hook))
    (setq global-line--refresh-timer (run-with-timer t
						     global-line-refresh-interval
						     #'global-line--refresh))))

(provide 'global-line)
