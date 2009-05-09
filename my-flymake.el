;;; customize the flymake
(require 'flymake)

;(setq flymake-log-level 3)

;; disable the flymake gui warning, it's very annoying
(setq flymake-gui-warnings-enabled nil)

(defvar ecj-jar-file "/path/to/ecj-3.3.2.jar")

(if linuxp
    (setq ecj-jar-file "/home/neil/.emacs.d/load-path/lib/ecj-3.3.2.jar"))
(if mac-osx-p 
    (setq ecj-jar-file "/Users/lwang/.emacs.d/load-path/lib/ecj-3.3.2.jar"))

(defun flymake-java-ecj-init ()
  (let* ((temp-file   (flymake-init-create-temp-buffer-copy
                       'jde-ecj-create-temp-file))
         (local-file  (file-relative-name
                       temp-file
                       (file-name-directory buffer-file-name))))
    ;;    (Message (jde-build-classpath jde-global-classpath))
    ;; Change your ecj.jar location here
    (list "java" (list "-jar" ecj-jar-file
                       "-Xemacs" 
                       "-g" ;; all debug info
                       ;; "-d" "none" ;; generate no .class files
                       "-d" (flymake-built-class-path)
                       "-source" "1.5" "-target" "1.5" "-proceedOnError"
                       ;; Do not need below "sourcepath" parameter,
                       ;; cuase we don't want to build the whole
                       ;; source classes
                       ;;"-sourcepath" (car jde-sourcepath)
                       "-classpath" 
                       (jde-build-classpath jde-global-classpath) local-file))))
 
(defun flymake-java-ecj-cleanup ()
  "Cleanup after `flymake-java-ecj-init' -- delete temp file and dirs."
  (flymake-safe-delete-file flymake-temp-source-file-name)
  (when flymake-temp-source-file-name
    (flymake-safe-delete-directory (file-name-directory flymake-temp-source-file-name))))

(defun jde-ecj-create-temp-file (file-name prefix)
  "Create the file FILE-NAME in a unique directory in the temp directory."
  (file-truename (expand-file-name (file-name-nondirectory file-name)
                                   (expand-file-name  (int-to-string (random)) (flymake-get-temp-dir)))))
 
(push '(".+\\.java$" flymake-java-ecj-init flymake-java-ecj-cleanup) flymake-allowed-file-name-masks)
 
(add-to-list 'flymake-err-line-patterns '("\\(.*?\\):\\([0-9]+\\): error: \\(.*?\\)\n" 1 2 nil 2 3 (6 compilation-error-face)))
(add-to-list 'flymake-err-line-patterns '("\\(.*?\\):\\([0-9]+\\): warning: \\(.*?\\)\n" 1 2 nil 1 3 (6 compilation-warning-face)))

;; Displays the error/warning for the current line in the minibuffer, instead of using menu.
(defun flymake-display-err-minibuf () 
  "Displays the error/warning for the current line in the minibuffer"
  (interactive)
  (let* ((line-no             (flymake-current-line-no))
         (line-err-info-list  (nth 0 (flymake-find-err-info flymake-err-info line-no)))
         (count               (length line-err-info-list))
         )
    (while (> count 0)
      (when line-err-info-list
        (let* ((file       (flymake-ler-file (nth (1- count) line-err-info-list)))
               (full-file  (flymake-ler-full-file (nth (1- count) line-err-info-list)))
               (text (flymake-ler-text (nth (1- count) line-err-info-list)))
               (line       (flymake-ler-line (nth (1- count) line-err-info-list))))
          (message "[%s] %s" line text)
          )
        )
      (setq count (1- count)))))

(add-hook 'flymake-mode-hook
          '(lambda nil
             (local-set-key "\M-n" 'flymake-goto-next-error)
             (local-set-key "\M-p" 'flymake-goto-prev-error)
             (local-set-key "\M-i" 'flymake-display-err-minibuf)))

(add-hook 'jde-mode-hook 'flymake-mode)

(defun flymake-built-class-path ()
  "Return the directory for the built .class files.
   the built .class files will be put into <current project dir>/<jde-built-class-path>. 
   if `jde-built-class-path' have not been set, it will return nil"
  (if (and (stringp (car jde-built-class-path))
           (stringp jde-current-project))
      (concat (file-name-directory jde-current-project) (car jde-built-class-path))
    nil))
  
(message "Loaded Flymake successfully")