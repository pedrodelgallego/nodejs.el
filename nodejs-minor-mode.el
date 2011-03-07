;;; node-minor-mode.el --- run a node process in a compilation buffer

;; Copyright (C) 2010 Pedro Del Gallego

;; Author: Pedro Del Gallego
;; Version: 0.1
;; Created: Mon 16 Aug 2010 
;; Keywords: test convenience node javascript 

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Allow for execution of node processes dumping the results into a
;; compilation buffer. Useful for executing tests, or node jake tasks
;; where the ability to jump to errors in source code is desirable.

(require 'ansi-color)
(require 'pcomplete)
(require 'compile)

(setq  nodejs-minor-mode nil)

(defvar nodejs-compilation-clear-between t)

(defun nodejs-minor-mode-start ()
  "Enable flag nodejs-minor-mode"
  (setq nodejs-minor-mode t))

(defun nodejs-minor-mode-stop ()
  "Disbale flag nodejs-minor-mode"
  (setq nodejs-minor-mode nil))

;;;--------------------------------
;;; Functions for Node Jake
;;;-------------------------------

(defcustom jake-command "node" 
  "Command to run Jake.")

;;;###autoload
(defun nodejs-compilation-jake (&optional task)
  "Run a Jake process dumping output to a node compilation buffer."
  (interactive "sTask: ")
  (print ( buffer-file-name))
  (pop-to-buffer (compile (concat jake-command task))))

;;---------------------------------
;; Functions for Node Compilation. 
;;---------------------------------

(defcustom node-command "node" 
  "Command to run node.")

(defvar node-compilation-error-regexp-alist
  '((">[[:space:]](\\(.*?\\)\\([0-9A-Za-z_./\:-]+\\.js\\):\\([0-9]+\\)" 2 3))
  "Alist that specifies how to match errors in node output.")

;;;###autoload
(defun nodejs-compilation-this-buffer ()
  "Run the current buffer through Node compilation."
  (interactive)
  (nodejs-compilation-run (buffer-file-name)))

;;;###autoload
(defun nodejs-compilation-run (cmd)
  "Run a node process dumping output to a node compilation buffer."
  (interactive "FNode Comand: ")
  
  (let ((name (file-name-nondirectory (car (split-string cmd))))   
        (cmdlist (cons node-command (split-string (expand-file-name cmd)))))
    (print cmdlist)
    (pop-to-buffer  (nodejs-compilation-do name cmdlist))))

(defun nodejs-compilation-do (name cmdlist)
  (let ((comp-buffer-name (format "*%s*" name)))
    (if (get-buffer comp-buffer-name)  (kill-buffer comp-buffer-name))
     (let* ((buffer (apply 'make-comint name (car cmdlist) nil (cdr cmdlist)))
            (proc (get-buffer-process buffer))
            (compilation-error-regexp-alist node-compilation-error-regexp-alist ))                  
       (set (make-local-variable 'kill-buffer-hook)
            (lambda ()
              (let ((orphan-proc (get-buffer-process (buffer-name))))
                (if orphan-proc
                    (kill-process orphan-proc)))))
       (save-excursion
         (set-buffer buffer)
         (buffer-disable-undo)
         (nodejs-minor-mode t)
         (compilation-minor-mode t)))
     comp-buffer-name))

(defun nodejs-compilation-sentinel (proc msg)
  "Notify to changes in process state"
  (message "%s - %s" proc (replace-regexp-in-string "\n" "" msg)))


;;; Define the key binding in assoc with this keymap

(defvar nodejs-minor-mode-map 
  (let ((map (make-sparse-keymap))
        keys)
    (define-key map (kbd "C-c ,v")  'disable-command)
    (define-key map (kbd "C-c C-c")  'comint-interrupt-subjob)
    (define-key map (kbd "C-c ,c")  'kill-buffer-hook)
    (define-key espresso-mode-map (kbd "C-x ,v") 'nodejs-compilation-this-buffer)
    (define-key espresso-mode-map (kbd "C-x ,j") 'nodejs-compilation-jake)
    map)
  "Keymap used in `nodejs-minor-mod'e buffers.")

;; (defvar nodejs-minor-mode-map
;;   (let ((map (make-sparse-keymap)))
;;     (define-key map "q"              'quit-window)
;;     (define-key map "p"              'previous-error-no-select)
;;     (define-key map "n"              'next-error-no-select)
;;     (define-key map "\M-p"           'js-compilation-previous-error-group)
;;     (define-key map "\M-n"           'js-compilation-next-error-group)
;;   map) 

(define-minor-mode nodejs-minor-mode 
  "Enable Node Compilation minor mode providing some key-bindings
  for navigating Node compilation buffers."
  :lighter " NodeJs"
  :global nil
  :init-value "Welcome to nodejs"
  :keymap nodejs-minor-mode-map
   (if nodejs-minor-mode
       (nodejs-minor-mode-start)
     (nodejs-minor-mode-stop))
   "Key map for Nodejs minor mode.")

;; So we can invoke it easily.
(eval-after-load 'js2-mode
  '(progn
     (define-key js2-mode-map (kbd "C-x ,v") 'nodejs-compilation-this-buffer)     
     (define-key js2-mode-map (kbd "C-x ,j") 'nodejs-compilation-jake)
     (nodejs-minor-mode)))

;; So we can invoke it easily.
(eval-after-load 'espresso-mode
  '(progn
     (define-key espresso-mode-map (kbd "C-x ,v") 'nodejs-compilation-this-buffer)     
     (define-key espresso-mode-map (kbd "C-x ,j") 'nodejs-compilation-jake)
     (nodejs-minor-mode)))
 
(provide 'nodejs-minor-mode)
