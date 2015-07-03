;;; jinari-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (global-jinari-mode jinari-minor-mode jinari-launch
;;;;;;  jinari-cap jinari-rake) "jinari" "jinari.el" (21906 24499
;;;;;;  789629 467000))
;;; Generated autoloads from jinari.el

(autoload 'jinari-rake "jinari" "\
Select and run a rake TASK using `ruby-compilation-rake'.

\(fn &optional TASK EDIT-CMD-ARGS)" t nil)

(autoload 'jinari-cap "jinari" "\
Select and run a capistrano TASK using `ruby-compilation-cap'.

\(fn &optional TASK EDIT-CMD-ARGS)" t nil)

(autoload 'jinari-launch "jinari" "\
Call function `jinari-minor-mode' if inside a rails project.
Otherwise, disable that minor mode if currently enabled.

\(fn)" t nil)

(autoload 'jinari-minor-mode "jinari" "\
Enable Jinari minor mode to support working with the Ruby on Rails framework.

\(fn &optional ARG)" t nil)

(defvar global-jinari-mode nil "\
Non-nil if Global-Jinari mode is enabled.
See the command `global-jinari-mode' for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-jinari-mode'.")

(custom-autoload 'global-jinari-mode "jinari" nil)

(autoload 'global-jinari-mode "jinari" "\
Toggle Jinari minor mode in all buffers.
With prefix ARG, enable Global-Jinari mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if
ARG is omitted or nil.

Jinari minor mode is enabled in all buffers where
`jinari-launch-maybe' would do it.
See `jinari-minor-mode' for more information on Jinari minor mode.

\(fn &optional ARG)" t nil)

;;;***

;;;### (autoloads nil nil ("jinari-pkg.el") (21906 24499 813181 88000))

;;;***

(provide 'jinari-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; jinari-autoloads.el ends here
