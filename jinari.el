;;; jinari.el --- Jinari Is Not A Express IDE

;; Copyright (C) 2008 Phil Hagelberg, Eric Schulte

;; Author: Phil Hagelberg, Eric Schulte
;; URL: https://github.com/eschulte/jinari
;; Version: DEV
;; Created: 2006-11-10
;; Keywords: javascript, express, project, convenience, web
;; EmacsWiki: Jinari
;; Package-Requires: ((js2-mode "1.0") (ruby-compilation "0.16") (jump "2.0"))

;; This file is NOT part of GNU Emacs.

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

;; Jinari Is Not A JavaScript IDE.

;; Well, ok it kind of is.  Jinari is a set of Emacs Lisp modes that is
;; aimed towards making Emacs into a top-notch JavaScript and Rails
;; development environment.

;; Jinari can be installed through ELPA (see http://tromey.com/elpa/)

;; To install from source, copy the directory containing this file
;; into your Emacs Lisp directory, assumed here to be ~/.emacs.d.  Add
;; these lines of code to your .emacs file:

;; ;; jinari
;; (add-to-list 'load-path "~/.emacs.d/jinari")
;; (require 'jinari)
;; (global-jinari-mode)

;; Whether installed through ELPA or from source you probably want to
;; add the following lines to your .emacs file:

;; ;; ido
;; (require 'ido)
;; (ido-mode t)

;; Note: if you cloned this from a git repo, you will have to grab the
;; submodules which can be done by running the following commands from
;; the root of the jinari directory

;;  git submodule init
;;  git submodule update

;;; Code:
;;;###begin-elpa-ignore
(let* ((this-dir (file-name-directory (or load-file-name buffer-file-name)))
       (util-dir (file-name-as-directory (expand-file-name "util" this-dir)))
       (inf-javascript-dir (file-name-as-directory (expand-file-name "inf-ruby" util-dir)))
       (jump-dir (file-name-as-directory (expand-file-name "jump" util-dir))))
  (dolist (dir (list util-dir inf-javascript-dir jump-dir))
    (when (file-exists-p dir)
      (add-to-list 'load-path dir))))
;;;###end-elpa-ignore
(require 'js2-mode)
(require 'ruby-mode)
(require 'ruby-compilation)
(require 'jump)
(require 'cl)
(require 'json)
(require 'easymenu)

;; fill in some missing variables for XEmacs
(when (eval-when-compile (featurep 'xemacs))
  ;;this variable does not exist in XEmacs
  (defvar safe-local-variable-values ())
  ;;find-file-hook is not defined and will otherwise not be called by XEmacs
  (define-compatible-variable-alias 'find-file-hook 'find-file-hooks))

(defgroup jinari nil
  "Jinari customizations."
  :prefix "jinari-"
  :group 'jinari)

(defcustom jinari-major-modes nil
  "Major Modes from which to launch Jinari."
  :type '(repeat symbol)
  :group 'jinari)

(defcustom jinari-exclude-major-modes nil
  "Major Modes in which to never launch Jinari."
  :type '(repeat symbol)
  :group 'jinari)

(defcustom jinari-tags-file-name
  "TAGS"
  "Path to your TAGS file inside of your express project.  See `tags-file-name'."
  :group 'jinari)

(defcustom jinari-fontify-express-keywords t
  "When non-nil, fontify keywords such as 'before_filter', 'url_for'.")

(defcustom jinari-controller-keywords
  '("logger" "polymorphic_path" "polymorphic_url" "mail" "render" "attachments"
    "default" "helper" "helper_attr" "helper_method" "layout" "url_for"
    "serialize" "exempt_from_layout" "filter_parameter_logging" "hide_action"
    "cache_sweeper" "protect_from_forgery" "caches_page" "cache_page"
    "caches_action" "expire_page" "expire_action" "rescue_from" "params"
    "request" "response" "session" "flash" "head" "redirect_to"
    "render_to_string" "respond_with"
    ;; Rails < 4
    "before_filter" "append_before_filter"
    "prepend_before_filter" "after_filter" "append_after_filter"
    "prepend_after_filter" "around_filter" "append_around_filter"
    "prepend_around_filter" "skip_before_filter" "skip_after_filter" "skip_filter"
    ;; Rails >= 4
    "after_action" "append_after_action" "append_around_action"
    "append_before_action" "around_action" "before_action" "prepend_after_action"
    "prepend_around_action" "prepend_before_action" "skip_action_callback"
    "skip_after_action" "skip_around_action" "skip_before_action")
  "List of keywords to highlight for controllers"
  :group 'jinari
  :type '(repeat string))

(defcustom jinari-migration-keywords
  '("create_table" "change_table" "drop_table" "rename_table" "add_column"
    "rename_column" "change_column" "change_column_default" "remove_column"
    "add_index" "remove_index" "rename_index" "execute")
  "List of keywords to highlight for migrations"
  :group 'jinari
  :type '(repeat string))

(defcustom jinari-model-keywords
  '("default_scope" "named_scope" "scope" "serialize" "belongs_to" "has_one"
    "has_many" "has_and_belongs_to_many" "composed_of" "accepts_nested_attributes_for"
    "before_create" "before_destroy" "before_save" "before_update" "before_validation"
    "before_validation_on_create" "before_validation_on_update" "after_create"
    "after_destroy" "after_save" "after_update" "after_validation"
    "after_validation_on_create" "after_validation_on_update" "around_create"
    "around_destroy" "around_save" "around_update" "after_commit" "after_find"
    "after_initialize" "after_rollback" "after_touch" "attr_accessible"
    "attr_protected" "attr_readonly" "validates" "validate" "validate_on_create"
    "validate_on_update" "validates_acceptance_of" "validates_associated"
    "validates_confirmation_of" "validates_each" "validates_exclusion_of"
    "validates_format_of" "validates_inclusion_of" "validates_length_of"
    "validates_numericality_of" "validates_presence_of" "validates_size_of"
    "validates_uniqueness_of" "validates_with")
  "List of keywords to highlight for models"
  :group 'jinari
  :type '(repeat string))

(defvar jinari-minor-mode-hook nil
  "*Hook for customising Jinari.")

(defcustom jinari-express-env nil
  "Use this to force a value for EXPRESS_ENV when running jinari.
Leave this set to nil to not force any value for EXPRESS_ENV, and
leave this to the environment variables outside of Emacs.")

(defvar jinari-minor-mode-prefixes
  (list ";" "'")
  "List of characters, each of which will be bound (with control-c) as a prefix for `jinari-minor-mode-map'.")

(defvar jinari-partial-regex
  "render \\(:partial *=> \\)?*[@'\"]?\\([A-Za-z/_]+\\)['\"]?"
  "Regex that matches a partial rendering call.")

(defadvice ruby-compilation-do (around jinari-compilation-do activate)
  "Set default directory to the express root before running ruby processes."
  (let ((default-directory (or (jinari-root) default-directory)))
    ad-do-it
    (jinari-launch)))

(defadvice ruby-compilation-rake (around jinari-compilation-rake activate)
  "Set default directory to the express root before running rake processes."
  (let ((default-directory (or (jinari-root) default-directory)))
    ad-do-it
    (jinari-launch)))

(defadvice ruby-compilation-cap (around jinari-compilation-cap activate)
  "Set default directory to the express root before running cap processes."
  (let ((default-directory (or (jinari-root) default-directory)))
    ad-do-it
    (jinari-launch)))

(defun jinari-parse-yaml (file)
  "Parse the YAML contents of FILE."
  (json-read-from-string
   (shell-command-to-string
    (concat ruby-compilation-executable
            " -ryaml -rjson -e 'JSON.dump(YAML.load(ARGF.read), STDOUT)' "
            (shell-quote-argument file)))))

(defun jinari-root (&optional dir home)
  "Return the root directory of the project within which DIR is found.
Optional argument HOME is ignored."
  (let ((default-directory (or dir default-directory)))
    (when (file-directory-p default-directory)
      (if (file-exists-p (expand-file-name "gulpfile.js"))
          default-directory
        ;; regexp to match windows roots, tramp roots, or regular posix roots
        (unless (string-match "\\(^[[:alpha:]]:/$\\|^/[^\/]+:/?$\\|^/$\\)" default-directory)
          (jinari-root (expand-file-name (file-name-as-directory ".."))))))))

(defun jinari-highlight-keywords (keywords)
  "Highlight the passed KEYWORDS in current buffer.
Use `font-lock-add-keywords' in case of `js2-mode' or
`javascript-extra-keywords' in case of Enhanced JavaScript Mode."
  (if (boundp 'javascript-extra-keywords)
      (progn
        (setq javascript-extra-keywords (append javascript-extra-keywords keywords))
        (javascript-local-enable-extra-keywords))
    (font-lock-add-keywords
     nil
     (list (list
            (concat "\\(^\\|[^_:.@$]\\|\\.\\.\\)\\b"
                    (regexp-opt keywords t)
                    (eval-when-compile (if (string-match "\\_>" "javascript")
                                           "\\_>"
                                         "\\>")))
            (list 2 'font-lock-builtin-face))))))

(defun jinari-apply-keywords-for-file-type ()
  "Apply extra font lock keywords specific to models, controllers etc."
  (when (and jinari-fontify-express-keywords (buffer-file-name))
    (loop for (re keywords) in `(("_controller\\.js$"   ,jinari-controller-keywords)
                                 ("src/app/models/.+\\.js$" ,jinari-model-keywords)
                                 ("db/migrate/.+\\.js$" ,jinari-migration-keywords))
          do (when (string-match-p re (buffer-file-name))
               (jinari-highlight-keywords keywords)))))


(add-hook 'js2-mode-hook 'jinari-apply-keywords-for-file-type)

;;--------------------------------------------------------------------------------
;; user functions

;;;###autoload
(defun jinari-rake (&optional task edit-cmd-args)
  "Select and run a rake TASK using `ruby-compilation-rake'."
  (interactive "P")
  (ruby-compilation-rake task edit-cmd-args
                         (when jinari-express-env
                           (list (cons "RAILS_ENV" jinari-express-env)))))

(defun jinari-rake-migrate-down (path &optional edit-cmd-args)
  "Perform a down migration for the migration with PATH."
  (interactive "fMigration: ")
  (let* ((file (file-name-nondirectory path))
         (n (if (string-match "^\\([0-9]+\\)_[^/]+$" file)
                (match-string 1 file)
              (error "Couldn't determine migration number"))))
    (ruby-compilation-rake "db:migrate:down"
                           edit-cmd-args
                           (list (cons "VERSION" n)))))

;;;###autoload
(defun jinari-cap (&optional task edit-cmd-args)
  "Select and run a capistrano TASK using `ruby-compilation-cap'."
  (interactive "P")
  (ruby-compilation-cap task edit-cmd-args
                        (when jinari-express-env
                          (list (cons "RAILS_ENV" jinari-express-env)))))

(defun jinari--discover-gulp-commands ()
  "Return a list of commands supported by the main gulp script."
  (let ((gulp-script (jinari--gulp-path)))
    (when gulp-script
      (ruby-compilation-extract-output-matches gulp-script "^ \\([a-z]+\\)[[:space:]].*$"))))

(defvar jinari-gulp-commands-cache nil
  "Cached values for commands that can be used with 'script/rails' in Rails 3.")

(defun jinari-get-gulp-commands ()
  "Return a cached list of commands supported by the main rails script."
  (when (null jinari-gulp-commands-cache)
    (setq jinari-gulp-commands-cache (jinari--discover-gulp-commands)))
  jinari-gulp-commands-cache)

(defun jinari-script (&optional script)
  "Select and run SCRIPT from the script/ directory of the express application."
  (interactive)
  (let* ((completions (append (and (file-directory-p (jinari-script-path))
                                   (directory-files (jinari-script-path) nil "^[^.]"))
                              (jinari-get-gulp-commands)))
         (script (or script (jump-completing-read "Script: " completions)))
         (ruby-compilation-error-regexp-alist ;; for jumping to newly created files
          (if (equal script "generate")
              '(("^ +\\(create\\) +\\([^[:space:]]+\\)" 2 3 nil 0 2)
                ("^ +\\(identical\\) +\\([^[:space:]]+\\)" 2 3 nil 0 2)
                ("^ +\\(exists\\) +\\([^[:space:]]+\\)" 2 3 nil 0 2)
                ("^ +\\(conflict\\) +\\([^[:space:]]+\\)" 2 3 nil 0 2))
            ruby-compilation-error-regexp-alist))
         (script-path (concat (jinari--wrap-gulp-command script) " ")))
    (when (string-match-p "^\\(db\\)?console" script)
      (error "Use the dedicated jinari function to run this interactive script"))
    (ruby-compilation-run (concat script-path " " (read-from-minibuffer (concat script " ")))
                          nil
                          (concat "gulp " script))))

(defun jinari-test (&optional edit-cmd-args)
  "Run the current ruby function as a test, or run the corresponding test.
If current function is not a test,`jinari-find-test' is used to
find the corresponding test.  Output is sent to a compilation buffer
allowing jumping between errors and source code.  Optional prefix
argument EDIT-CMD-ARGS lets the user edit the test command
arguments."
  (interactive "P")
  ;; (or (jinari-test-function-name)
  ;;     (string-match "test" (or (ruby-add-log-current-method)
  ;;                              (file-name-nondirectory (buffer-file-name))))
  ;;     (jinari-find-test))
  (let* ((fn (jinari-test-function-name))
         (path (buffer-file-name))
         (javascript-options (list "-I" (expand-file-name "test" (jinari-root)) path))
         (default-command (mapconcat
                           'identity
                           (append (list path) (when fn (list "--name" (concat "/" fn "/"))))
                           " "))
         (command (if edit-cmd-args
                      (read-string "Run w/Compilation: " default-command)
                    default-command)))
    ;; (if path
    ;;     (shell-command command "test")
    ;;     ;; (ruby-compilation-run command javascript-options)
    ;;   (message "no test available"))
    (shell-command command "test"))
  (jinari-launch))

(defun jinari-test-function-name()
  "Return the name of the test function at point, or nil if not found."
  (save-excursion
    (when (re-search-backward (concat "^[ \t]*\\(def\\|test\\)[ \t]+"
                                      "\\([\"'].*?[\"']\\|" ruby-symbol-re "*\\)"
                                      "[ \t]*") nil t)
      (let ((name (match-string 2)))
        (if (string-match "^[\"']\\(.*\\)[\"']$" name)
            (replace-regexp-in-string
             "\\?" "\\\\\\\\?"
             (replace-regexp-in-string " +" "_" (match-string 1 name)))
          (when (string-match "^test" name)
            name))))))

(defun jinari--gulp-path ()
  "Return the path of the 'gulp' command, or nil if not found."
  (let* ((script-gulp (expand-file-name "gulp" (jinari-script-path)))
         (bin-gulp (expand-file-name "gulp" (jinari-bin-path))))
    (cond
     ((file-exists-p bin-gulp) bin-gulp)
     ((file-exists-p script-gulp) script-gulp)
     (t (executable-find "gulp")))))

(defun jinari--maybe-wrap-with-ruby (command-line)
  "If the first part of COMMAND-LINE is not executable, prepend with ruby."
  (if (file-executable-p (first (split-string-and-unquote command-line)))
      command-line
    (concat ruby-compilation-executable " " command-line)))

(defun jinari--wrap-gulp-command (command)
  "Given a COMMAND such as 'console', return a suitable command line.
Where the corresponding script is executable, it will be run
as-is.  Otherwise, as can be the case on Windows, the command will
be prepended with `ruby-compilation-executable'."
  (let* ((default-directory (jinari-root))
         (script (jinari-script-path))
         (script-command (expand-file-name command script)))
    (if (file-exists-p script-command)
        script-command
      (concat (jinari--gulp-path) " " command))))

(defun jinari-console (&optional edit-cmd-args)
  "Run a Rails console in a compilation buffer.
The buffer will support command history and links between errors
and source code.  Optional prefix argument EDIT-CMD-ARGS lets the
user edit the console command arguments."
  (interactive "P")
  (let* ((default-directory (jinari-root))
         (command (jinari--maybe-wrap-with-ruby
                   (jinari--wrap-gulp-command "console"))))
    ;; Start console in correct environment.
    (when jinari-express-env
      (setq command (concat command " " jinari-express-env)))
    ;; For customization of the console command with prefix arg.
    (setq command (if edit-cmd-args
                      (read-string "Run JavaScript: " (concat command " "))
                    command))
    (with-current-buffer (run-ruby command "rails console")
      (jinari-launch))))

(defun jinari-sql ()
  "Browse the application's database.
Looks up login information from your conf/database.sql file."
  (interactive)
  (let* ((environment (or jinari-rails-env (getenv "RAILS_ENV") "development"))
         (existing-buffer (get-buffer (concat "*SQL: " environment "*"))))
    (if existing-buffer
        (pop-to-buffer existing-buffer)
      (unless (featurep 'sql)
        (require 'sql))
      (let* ((database-yaml (jinari-parse-yaml
                             (expand-file-name
                              "database.yml"
                              (file-name-as-directory
                               (expand-file-name "config" (jinari-root))))))
             (database-alist (or (cdr (assoc (intern environment) database-yaml))
                                 (error "Couldn't parse database.yml")))
             (product (let* ((adapter (or (cdr (assoc 'adapter database-alist)) "sqlite")))
                        (cond
                         ((string-match "mysql" adapter) "mysql")
                         ((string-match "sqlite" adapter) "sqlite")
                         ((string-match "postgresql" adapter) "postgres")
                         (t adapter))))
             (port (cdr (assoc 'port database-alist)))
             (sql-login-params (or (intern-soft (concat "sql-" product "-login-params"))
                                   (error "`%s' is not a known product; use `sql-add-product' to add it first" product))))
        (with-temp-buffer
          (set (make-local-variable 'sql-user) (cdr (assoc 'username database-alist)))
          (set (make-local-variable 'sql-password) (cdr (assoc 'password database-alist)))
          (set (make-local-variable 'sql-database) (or (cdr (assoc 'database database-alist))
                                                       (when (string-match-p "sqlite" product)
                                                         (expand-file-name (concat "db/" environment ".sqlite3")
                                                                           (jinari-root)))
                                                       (concat (file-name-nondirectory
                                                                (directory-file-name (jinari-root)))
                                                               "_" environment)))
          (when (string= "sqlite" product)
            ;; Always expand sqlite DB filename relative to RAILS_ROOT
            (setq sql-database (expand-file-name sql-database (jinari-root))))
          (set (make-local-variable 'sql-server) (or (cdr (assoc 'host database-alist)) "localhost"))
          (when port
            (set (make-local-variable 'sql-port) port)
            (set (make-local-variable sql-login-params) (add-to-list sql-login-params 'port t)))
          (funcall
           (intern (concat "sql-" product))
           environment))))
    (jinari-launch)))

(defun jinari-web-server (&optional edit-cmd-args)
  "Start a Rails webserver.
Dumps output to a compilation buffer allowing jumping between
errors and source code.  Optional prefix argument EDIT-CMD-ARGS
lets the user edit the server command arguments."
  (interactive "P")
  (let* ((default-directory (jinari-root))
         (command (jinari--wrap-gulp-command "serve")))
    ;; Start web server in correct environment.
    (when jinari-express-env
      (setq command (concat command " -e " jinari-express-env)))
    ;; For customization of the web server command with prefix arg.
    (setq command (if edit-cmd-args
                      (read-string "Run JavaScript: " (concat command " "))
                    command))
    (shell-command command "serve"))
    ;; (ruby-compilation-run command nil "serve"))
  (jinari-launch))

(defun jinari-web-server-restart (&optional edit-cmd-args)
  "Ensure a fresh `jinari-web-server' is running, first killing any old one.
Optional prefix argument EDIT-CMD-ARGS lets the user edit the
server command arguments."
  (interactive "P")
  (let ((jinari-web-server-buffer "*gulp*"))
    (when (get-buffer jinari-web-server-buffer)
      (set-process-query-on-exit-flag (get-buffer-process jinari-web-server-buffer) nil)
      (kill-buffer jinari-web-server-buffer))
    (jinari-web-server edit-cmd-args)))

(defun jinari-generate (type name)
  "Run the generate command to generate a TYPE called NAME."
  (let* ((default-directory (jinari-root))
         (command (jinari--wrap-gulp-command "generate")))
    (shell-command
     (jinari--maybe-wrap-with-ruby
      (concat command " " type " " (read-from-minibuffer (format "create %s: " type) name))))))

(defun jinari-insert-erb-skeleton (no-equals)
  "Insert an erb skeleton at point.
With optional prefix argument NO-EQUALS, don't include an '='."
  (interactive "P")
  (insert "{{ ")
  (insert " }}")
  (backward-char (if no-equals 4 3)))

(defun jinari-extract-partial (begin end partial-name)
  "Extracts the region from BEGIN to END into a partial called PARTIAL-NAME."
  (interactive "r\nsName your partial: ")
  (let ((path (buffer-file-name))
        (ending (jinari-ending)))
    (if (string-match "view" path)
        (let ((partial-name
               (replace-regexp-in-string "[[:space:]]+" "_" partial-name)))
          (kill-region begin end)
          (if (string-match "\\(.+\\)/\\(.+\\)" partial-name)
              (let ((default-directory (expand-file-name (match-string 1 partial-name)
                                                         (expand-file-name ".."))))
                (find-file (concat "_" (match-string 2 partial-name) ending)))
            (find-file (concat "_" partial-name ending)))
          (yank) (pop-to-buffer nil)
          (jinari-insert-partial partial-name ending))
      (message "not in a view"))))

(defun jinari-insert-output (javascript-expr ending)
  "Insert view code which outputs JAVASCRIPT-EXPR, suitable for the file's ENDING."
  (let ((surround
         (cond
          ((string-match "\\.erb" ending)
           (cons "<%= " " %>"))
          ((string-match "\\.haml" ending)
           (cons "= " " ")))))
    (insert (concat (car surround) javascript-expr (cdr surround) "\n"))))

(defun jinari-insert-partial (partial-name ending)
  "Insert a call to PARTIAL-NAME, formatted for the file's ENDING.

Supported markup languages are: Erb, Haml"
  (jinari-insert-output (concat "render :partial => \"" partial-name "\"") ending))

(defun jinari-goto-partial ()
  "Visits the partial that is called on the current line."
  (interactive)
  (let ((line (buffer-substring-no-properties (line-beginning-position) (line-end-position))))
    (when (string-match jinari-partial-regex line)
      (setq line (match-string 2 line))
      (let ((file
             (if (string-match "/" line)
                 (concat (jinari-root) "src/app/views/"
                         (replace-regexp-in-string "\\([^/]+\\)/\\([^/]+\\)$" "\\1/_\\2" line))
               (concat default-directory "_" line))))
        (find-file (concat file (jinari-ending)))))))

(defvar jinari-rgrep-file-endings
  "*.[^l]*"
  "Ending of files to search for matches using `jinari-rgrep'.")

(defun jinari-rgrep (&optional arg)
  "Search through the rails project for a string or `regexp'.
With optional prefix argument ARG, just run `rgrep'."
  (interactive "P")
  (grep-compute-defaults)
  (if arg
      (call-interactively 'rgrep)
    (let ((query (if mark-active
                     (buffer-substring-no-properties (point) (mark))
                   (thing-at-point 'word))))
      (funcall 'rgrep (read-from-minibuffer "search for: " query)
               jinari-rgrep-file-endings (jinari-root)))))

(defun jinari-ending ()
  "Return the file extension of the current file."
  (let* ((path (buffer-file-name))
         (ending
          (and (string-match ".+?\\(\\.[^/]*\\)$" path)
               (match-string 1 path))))
    ending))

(defun jinari-script-path ()
  "Return the absolute path to the script folder."
  (concat (file-name-as-directory (expand-file-name "script" (jinari-root)))))

(defun jinari-bin-path ()
  "Return the absolute path to the bin folder."
  (concat (file-name-as-directory (expand-file-name "bin" (jinari-root)))))

;;--------------------------------------------------------------------
;; jinari movement using jump.el

(defun jinari-generate (type name)
  "Run the generate command to generate a TYPE called NAME."
  (let* ((default-directory (jinari-root))
         (command (jinari--wrap-gulp-command "generate")))
    (shell-command
     (jinari--maybe-wrap-with-ruby
      (concat command " " type " " (read-from-minibuffer (format "create %s: " type) name))))))

(defvar jinari-javascript-hash-regexp
  "\\(:[^[:space:]]*?\\)[[:space:]]*\\(=>[[:space:]]*[\"\':]?\\([^[:space:]]*?\\)[\"\']?[[:space:]]*\\)?[,){}\n]"
  "Regexp to match subsequent key => value pairs of a ruby hash.")

(defun jinari-javascript-values-from-render (controller action)
  "Return (CONTROLLER . ACTION) after adjusting for the hash values at point."
  (let ((end (save-excursion
               (re-search-forward "[^,{(]$" nil t)
               (1+ (point)))))
    (save-excursion
      (while (and (< (point) end)
                  (re-search-forward jinari-javascript-hash-regexp end t))
        (when (> (length (match-string 3)) 1)
          (case (intern (match-string 1))
            (:partial
             (let ((partial (match-string 3)))
               (if (string-match "\\(.+\\)/\\(.+\\)" partial)
                   (progn
                     (setf controller (match-string 1 partial))
                     (setf action (concat "_" (match-string 2 partial))))
                 (setf action (concat "_" partial)))))
            (:action  (setf action (match-string 3)))
            (:controller (setf controller (match-string 3)))))))
    (cons controller action)))

(defun jinari-which-render (renders)
  "Select and parse one of the RENDERS supplied."
  (let ((path (jump-completing-read
               "Follow: "
               (mapcar (lambda (lis)
                         (concat (car lis) "/" (cdr lis)))
                       renders))))
    (string-match "\\(.*\\)/\\(.*\\)" path)
    (cons (match-string 1 path) (match-string 2 path))))

(defun jinari-follow-controller-and-action (controller action)
  "Follow CONTROLLER and ACTION through to the final controller or view.
The user is prompted to follow through any intermediate renders
and redirects."
  (save-excursion ;; if we can find the controller#action pair
    (if (and (jump-to-path (format "app/controllers/%s_controller.rb#%s" controller action))
             (equalp (jump-method) action))
        (let ((start (point)) ;; demarcate the borders
              (renders (list (cons controller action))) render view)
          (javascript-forward-sexp)
          ;; collect redirection options and pursue
          (while (re-search-backward "re\\(?:direct_to\\|nder\\)" start t)
            (add-to-list 'renders (jinari-javascript-values-from-render controller action)))
          (let ((render (if (equalp 1 (length renders))
                            (car renders)
                          (jinari-which-render renders))))
            (if (and (equalp (cdr render) action)
                     (equalp (car render) controller))
                (list controller action) ;; directed to here so return
              (jinari-follow-controller-and-action (or (car render)
                                                       controller)
                                                   (or (cdr render)
                                                       action)))))
      ;; no controller entry so return
      (list controller action))))

(defvar jinari-jump-schema
  '((model
     "m"
     (("src/app/controllers/\\1_controller.js#\\2$" . "src/app/models/\\1.js#\\2")
      ("src/app/views/\\1/.*"                       . "src/app/models/\\1.js")
      ("src/app/helpers/\\1_helper.js"              . "src/app/models/\\1.js")
      ("db/migrate/.*create_\\1.js"                 . "src/app/models/\\1.js")
      ("spec/models/\\1_spec.js"                    . "src/app/models/\\1.js")
      ("spec/controllers/\\1_controller_spec.js"    . "src/app/models/\\1.js")
      ("spec/views/\\1/.*"                          . "src/app/models/\\1.js")
      ("spec/fixtures/\\1.yml"                      . "src/app/models/\\1.js")
      ("test/functional/\\1_controller_test.js"     . "src/app/models/\\1.js")
      ("test/unit/\\1_test.js#test_\\2$"            . "src/app/models/\\1.js#\\2")
      ("test/unit/\\1_test.js"                      . "src/app/models/\\1.js")
      ("test/fixtures/\\1.yml"                      . "src/app/models/\\1.js")
      (t                                            . "src/app/models/"))
     (lambda (path)
       (rinari-generate "model"
                        (and (string-match ".*/\\(.+?\\)\.js" path)
                             (match-string 1 path)))))
    (store
     "M"
     (("spec/stores/\\1_spec.js"         . "src/app/stores/\\1.js")
      ("spec/fixtures/\\1.yml"           . "src/app/stores/\\1.js")
      ("test/stores/\\1_test.js"         . "src/app/stores/\\1.js")
      ("test/unit/\\1_test.js#test_\\2$" . "src/app/stores/\\1.js#\\2")
      ("test/unit/\\1_test.js"           . "src/app/stores/\\1.js")
      ("test/fixtures/\\1.yml"           . "src/app/stores/\\1.js")
      (t                                 . "src/app/stores/"))
     t)
    (controller
     "c"
     (("src/app/models/\\1.js"                 . "src/app/controllers/\\1_controller.js")
      ("src/app/views/\\1/\\2\\..*"            . "src/app/controllers/\\1_controller.js#\\2")
      ("src/app/helpers/\\1_helper.js"         . "src/app/controllers/\\1_controller.js")
      ("db/migrate/.*create_\\1.js"            . "src/app/controllers/\\1_controller.js")
      ("spec/models/\\1_spec.js"               . "src/app/controllers/\\1_controller.js")
      ("spec/controllers/\\1_spec.js"          . "src/app/controllers/\\1.js")
      ("spec/views/\\1/\\2\\.*_spec.js"        . "src/app/controllers/\\1_controller.js#\\2")
      ("spec/fixtures/\\1.yml"                 . "src/app/controllers/\\1_controller.js")
      ("test/models/\\1_test.js"               . "src/app/controllers/\\1_controller.js")
      ("test/controllers/\\1_test.js"          . "src/app/controllers/\\1.js")
      ("test/views/\\1/\\2\\.*_test.js"        . "src/app/controllers/\\1_controller.js#\\2")
      ("test/functional/\\1_test.js#test_\\2$" . "src/app/controllers/\\1.js#\\2")
      ("test/functional/\\1_test.js"           . "src/app/controllers/\\1.js")
      ("test/unit/\\1_test.js#test_\\2$"       . "src/app/controllers/\\1_controller.js#\\2")
      ("test/unit/\\1_test.js"                 . "src/app/controllers/\\1_controller.js")
      ("test/fixtures/\\1.yml"                 . "src/app/controllers/\\1_controller.js")
      (t                                       . "src/app/controllers/"))
     (lambda (path)
       (jinari-generate "controller"
                        (and (string-match ".*/\\(.+?\\)_controller\.js" path)
                             (match-string 1 path)))))
    (view
     "v"
     (("src/app/models/\\1.js"                      . "src/app/views/\\1/.*")
      ((lambda () ;; find the controller/view
         (let* ((raw-file (and (buffer-file-name)
                               (file-name-nondirectory (buffer-file-name))))
                (file (and raw-file
                           (string-match "^\\(.*\\)_controller.js" raw-file)
                           (match-string 1 raw-file))) ;; controller
                (raw-method (ruby-add-log-current-method))
                (method (and file raw-method ;; action
                             (string-match "#\\(.*\\)" raw-method)
                             (match-string 1 raw-method))))
           (when (and file method) (jinari-follow-controller-and-action file method))))
       . "src/app/views/\\1/\\2.*")
      ("src/app/controllers/\\1_controller.js"  . "src/app/views/\\1/.*")
      ("src/app/helpers/\\1_helper.js"          . "src/app/views/\\1/.*")
      ("db/migrate/.*create_\\1.js"             . "src/app/views/\\1/.*")
      ("spec/models/\\1_spec.js"                . "src/app/views/\\1/.*")
      ("spec/controllers/\\1_spec.js"           . "src/app/views/\\1/.*")
      ("spec/views/\\1/\\2_spec.js"             . "src/app/views/\\1/\\2.*")
      ("spec/fixtures/\\1.yml"                  . "src/app/views/\\1/.*")
      ("test/models/\\1_test.js"                . "src/app/views/\\1/.*")
      ("test/controllers/\\1_test.js"           . "src/app/views/\\1/.*")
      ("test/views/\\1/\\2_test.js"             . "src/app/views/\\1/\\2.*")
      ("test/functional/\\1_controller_test.js" . "src/app/views/\\1/.*")
      ("test/unit/\\1_test.js#test_\\2$"        . "src/app/views/\\1/_?\\2.*")
      ("test/fixtures/\\1.yml"                  . "src/app/views/\\1/.*")
      (t                                        . "src/app/views/.*"))
     t)
    (component
     "V"
     (("spec/components/\\1/\\2_spec.js"        . "src/app/components/\\1/\\2.*")
      ("spec/fixtures/\\1.yml"                  . "src/app/components/\\1/.*")
      ("test/components/\\1/\\2_test.js"        . "src/app/components/\\1/\\2.*")
      ("test/unit/\\1_test.js#test_\\2$"        . "src/app/components/\\1/_?\\2.*")
      ("test/fixtures/\\1.yml"                  . "src/app/components/\\1/.*")
      (t                                        . "src/app/components/"))
     t)
    (test
     "t"
     (("src/app/models/\\1.js#\\2$"             . "test/unit/\\1_test.js#test_\\2")
      ("src/app/controllers/\\1.js#\\2$"        . "test/functional/\\1_test.js#test_\\2")
      ("src/app/views/\\1/_?\\2\\..*"           . "test/functional/\\1_controller_test.js#test_\\2")
      ("src/app/helpers/\\1_helper.js"          . "test/functional/\\1_controller_test.js")
      ("src/app/stores/\\1.js#\\2$"             . "test/stores/\\1_test.js#test_\\2")
      ("src/app/components/\\1.js#\\2$"         . "test/components/\\1/\\2_test.js")
      ("src/app/utilities/\\1_helper.js"        . "test/utilities/\\1_test.js")
      ("db/migrate/.*create_\\1.js"             . "test/unit/\\1_test.js")
      ("test/functional/\\1_controller_test.js" . "test/unit/\\1_test.js")
      ("test/unit/\\1_test.js"                  . "test/functional/\\1_controller_test.js")
      (t                                        . "test/.*"))
     t)
    (rspec
     "r"
     (("src/app/\\1\\.js"       . "spec/\\1_spec.js")
      ("src/app/\\1$"           . "spec/\\1_spec.js")
      ("spec/views/\\1_spec.js" . "src/app/views/\\1")
      ("spec/\\1_spec.js"       . "src/app/\\1.js")
      (t                        . "spec/.*"))
     t)
    (fixture
     "x"
     (("src/app/models/\\1.js"                   . "test/fixtures/\\1.yml")
      ("src/app/controllers/\\1_controller.js"   . "test/fixtures/\\1.yml")
      ("src/app/views/\\1/.*"                    . "test/fixtures/\\1.yml")
      ("src/app/helpers/\\1_helper.js"           . "test/fixtures/\\1.yml")
      ("db/migrate/.*create_\\1.js"              . "test/fixtures/\\1.yml")
      ("spec/models/\\1_spec.js"                 . "test/fixtures/\\1.yml")
      ("spec/controllers/\\1_controller_spec.js" . "test/fixtures/\\1.yml")
      ("spec/views/\\1/.*"                       . "test/fixtures/\\1.yml")
      ("test/functional/\\1_controller_test.js"  . "test/fixtures/\\1.yml")
      ("test/unit/\\1_test.js"                   . "test/fixtures/\\1.yml")
      (t                                         . "test/fixtures/"))
     t)
    (rspec-fixture
     "z"
     (("src/app/models/\\1.js"                   . "spec/fixtures/\\1.yml")
      ("src/app/controllers/\\1_controller.js"   . "spec/fixtures/\\1.yml")
      ("src/app/views/\\1/.*"                    . "spec/fixtures/\\1.yml")
      ("src/app/helpers/\\1_helper.js"           . "spec/fixtures/\\1.yml")
      ("db/migrate/.*create_\\1.js"              . "spec/fixtures/\\1.yml")
      ("spec/models/\\1_spec.js"                 . "spec/fixtures/\\1.yml")
      ("spec/controllers/\\1_controller_spec.js" . "spec/fixtures/\\1.yml")
      ("spec/views/\\1/.*"                       . "spec/fixtures/\\1.yml")
      ("test/functional/\\1_controller_test.js"  . "spec/fixtures/\\1.yml")
      ("test/unit/\\1_test.js"                   . "spec/fixtures/\\1.yml")
      (t                                         . "spec/fixtures/"))
     t)
    (helper
     "h"
     (("src/app/models/\\1.js"                  . "src/app/helpers/\\1_helper.js")
      ("src/app/controllers/\\1_controller.js"  . "src/app/helpers/\\1_helper.js")
      ("src/app/views/\\1/.*"                   . "src/app/helpers/\\1_helper.js")
      ("src/app/helpers/\\1_helper.js"          . "src/app/helpers/\\1_helper.js")
      ("db/migrate/.*create_\\1.js"             . "src/app/helpers/\\1_helper.js")
      ("spec/models/\\1_spec.js"                . "src/app/helpers/\\1_helper.js")
      ("spec/controllers/\\1_spec.js"           . "src/app/helpers/\\1_helper.js")
      ("spec/views/\\1/.*"                      . "src/app/helpers/\\1_helper.js")
      ("test/functional/\\1_controller_test.js" . "src/app/helpers/\\1_helper.js")
      ("test/unit/\\1_test.js#test_\\2$"        . "src/app/helpers/\\1_helper.js#\\2")
      ("test/unit/\\1_test.js"                  . "src/app/helpers/\\1_helper.js")
      (t                                        . "src/app/helpers/"))
     t)
    (utility
     "H"
     (("src/app/util/\\1_utility.js"      . "src/app/util/\\1_utility.js")
      ("test/util/\\1_test.js"            . "src/app/util/\\1_utility.js")
      ("test/unit/\\1_test.js#test_\\2$"  . "src/app/util/\\1_utility.js#\\2")
      ("test/unit/\\1_test.js"            . "src/app/util/\\1_utility.js")
      (t                                  . "src/app/util/")
      ("src/app/utilities/\\1_utility.js" . "src/app/utilities/\\1_utility.js")
      ("test/utilities/\\1_test.js"       . "src/app/utilities/\\1_utility.js")
      ("test/unit/\\1_test.js#test_\\2$"  . "src/app/utilities/\\1_utility.js#\\2")
      ("test/unit/\\1_test.js"            . "src/app/utilities/\\1_utility.js")
      (t                                  . "src/app/utilities/"))
     t)
    (migration
     "i"
     (("src/app/controllers/\\1_controller.js"  . "db/migrate/.*create_\\1.js")
      ("src/app/views/\\1/.*"                   . "db/migrate/.*create_\\1.js")
      ("src/app/helpers/\\1_helper.js"          . "db/migrate/.*create_\\1.js")
      ("src/app/models/\\1.js"                  . "db/migrate/.*create_\\1.js")
      ("spec/models/\\1_spec.js"                . "db/migrate/.*create_\\1.js")
      ("spec/controllers/\\1_spec.js"           . "db/migrate/.*create_\\1.js")
      ("spec/views/\\1/.*"                      . "db/migrate/.*create_\\1.js")
      ("test/functional/\\1_controller_test.js" . "db/migrate/.*create_\\1.js")
      ("test/unit/\\1_test.js#test_\\2$"        . "db/migrate/.*create_\\1.js#\\2")
      ("test/unit/\\1_test.js"                  . "db/migrate/.*create_\\1.js")
      (t                                        . "db/migrate/"))
     (lambda (path)
       (jinari-generate "migration"
                        (and (string-match ".*create_\\(.+?\\)\.js" path)
                             (match-string 1 path)))))
    (cells
     "L"
     (("src/app/cells/\\1_cell.js" . "src/app/cells/\\1/.*")
      ("src/app/cells/\\1/\\2.*"   . "src/app/cells/\\1_cell.js#\\2")
      (t                           . "src/app/cells/"))
     (lambda (path)
       (jinari-generate "cells"
                        (and (string-match ".*/\\(.+?\\)_cell\.js" path)
                             (match-string 1 path)))))
    (client          "F" ((t . "src/client/.*")) nil)
    (server          "B" ((t . "src/server/.*")) nil)
    (features        "f" ((t . "features/.*feature")) nil)
    (steps           "S" ((t . "features/step_definitions/.*")) nil)
    (environment     "e" ((t . "config/environments/")) nil)
    (gulp            "g" ((t . "gulpfile.es6")
                          (t . "gulpfile.js")
                          (t . "gulp/")) nil)
    (application     "a" ((t . "app.js")
                          (t . "config/application.js")) nil)
    (routes          "R" ((t . "config/routes.js")
                          (t . "src/app/routes.js")) nil)
    (configuration   "n" ((t . "config/")) nil)
    (script          "s" ((t . "script/")) nil)
    (lib             "l" ((t . "lib/")) nil)
    (log             "o" ((t . "log/")) nil)
    (worker          "w" ((t . "lib/workers/")) nil)
    (public          "p" ((t . "public/")) nil)
    (stylesheet      "y" ((t . "public/stylesheets/.*")
                          (t . "public/styles/.*")
                          (t . "src/app/assets/stylesheets/.*")
                          (t . "src/app/assets/styles/.*")) nil)
    (sass            "Y" ((t . "public/stylesheets/sass/.*")
                          (t . "public/styles/sass/.*")
                          (t . "src/app/stylesheets/.*")
                          (t . "src/app/styles/.*")) nil)
    (javascript      "j" ((t . "public/javascripts/.*")
                          (t . "public/scripts/.*")
                          (t . "src/app/assets/javascripts/.*")
                          (t . "src/app/assets/scripts/.*")) nil)
    (plugin          "u" ((t . "vendor/plugins/")) nil)
    (mailer          "I" ((t . "src/app/mailers/")) nil)
    (file-in-project "*" ((t . ".*")) nil)
    (by-context
     ";"
     (((lambda () ;; Find-by-Context
         (let ((path (buffer-file-name)))
           (when (string-match ".*/\\(.+?\\)/\\(.+?\\)\\..*" path)
             (let ((cv (cons (match-string 1 path) (match-string 2 path))))
               (when (re-search-forward "<%=[ \n\r]*render(? *" nil t)
                 (setf cv (jinari-javascript-values-from-render (car cv) (cdr cv)))
                 (list (car cv) (cdr cv)))))))
       . "src/app/views/\\1/\\2.*"))))
  "Jump schema for jinari.")

(defun jinari-apply-jump-schema (schema)
  "Define the jinari-find-* functions by passing each element SCHEMA to `defjump'."
  (mapcar
   (lambda (type)
     (let ((name (first type))
           (specs (third type))
           (make (fourth type)))
       (eval `(defjump
                ,(intern (format "jinari-find-%S" name))
                ,specs
                jinari-root
                ,(format "Go to the most logical %S given the current location" name)
                ,(when make `(quote ,make))
                'ruby-add-log-current-method))))
   schema))
(jinari-apply-jump-schema jinari-jump-schema)

;;--------------------------------------------------------------------
;; minor mode and keymaps

(defvar jinari-minor-mode-map
  (let ((map (make-sparse-keymap)))
    map)
  "Key map for Jinari minor mode.")

(defun jinari-bind-key-to-func (key func)
  "Bind KEY to FUNC with each of the `jinari-minor-mode-prefixes'."
  (dolist (prefix jinari-minor-mode-prefixes)
    (eval `(define-key jinari-minor-mode-map
             ,(format "\C-c%s%s" prefix key) ,func))))

(defvar jinari-minor-mode-keybindings
  '(("s" . 'jinari-script)              ("q" . 'jinari-sql)
    ("e" . 'jinari-insert-erb-skeleton) ("t" . 'jinari-test)
    ("r" . 'jinari-rake)                ("c" . 'jinari-console)
    ("w" . 'jinari-web-server)          ("g" . 'jinari-rgrep)
    ("x" . 'jinari-extract-partial)     ("p" . 'jinari-goto-partial)
    (";" . 'jinari-find-by-context)     ("'" . 'jinari-find-by-context)
    ("d" . 'jinari-cap))
  "Alist mapping of keys to functions in `jinari-minor-mode-map'.")

(dolist (el (append (mapcar (lambda (el)
                              (cons (concat "f" (second el))
                                    (read (format "'jinari-find-%S" (first el)))))
                            jinari-jump-schema)
                    jinari-minor-mode-keybindings))
  (jinari-bind-key-to-func (car el) (cdr el)))

(easy-menu-define jinari-minor-mode-menu jinari-minor-mode-map
  "Jinari menu"
  '("Jinari"
    ["Search" jinari-rgrep t]
    "---"
    ["Find file in project" jinari-find-file-in-project t]
    ["Find file by context" jinari-find-by-context t]
    ("Jump to..."
     ["Model" jinari-find-model t]
     ["Store" jinari-find-store t]
     ["Controller" jinari-find-controller t]
     ["View" jinari-find-view t]
     ["Component" jinari-find-component t]
     ["Helper" jinari-find-helper t]
     ["Utilty" jinari-find-utility t]
     ["Worker" jinari-find-worker t]
     ["Mailer" jinari-find-mailer t]
     "---"
     ["Client" jinari-find-client t]
     ["Server" jinari-find-server t]
     "---"
     ["Javascript" jinari-find-javascript t]
     ["Stylesheet" jinari-find-stylesheet t]
     ["Sass" jinari-find-sass t]
     ["public/" jinari-find-public t]
     "---"
     ["Test" jinari-find-test t]
     ["Rspec" jinari-find-rspec t]
     ["Fixture" jinari-find-fixture t]
     ["Rspec fixture" jinari-find-rspec-fixture t]
     ["Feature" jinari-find-features t]
     ["Step" jinari-find-steps t]
     "---"
     ["application.rb" jinari-find-application t]
     ["config/" jinari-find-configuration t]
     ["environments/" jinari-find-environment t]
     ["migrate/" jinari-find-migration t]
     ["lib/" jinari-find-lib t]
     ["script/" jinari-find-script t]
     ["log/" jinari-find-log t])
    "---"
    ("Web server"
     ["Start" jinari-web-server t]
     ["Restart" jinari-web-server-restart t])
    ["Console" jinari-console t]
    ["SQL prompt" jinari-sql t]
    "---"
    ["Script" jinari-script t]
    ["Rake" jinari-rake t]
    ["Cap" jinari-cap t]))

;;;###autoload
(defun jinari-launch ()
  "Call function `jinari-minor-mode' if inside a rails project.
Otherwise, disable that minor mode if currently enabled."
  (interactive)
  (let ((root (jinari-root)))
    (if root
        (let ((r-tags-path (concat root jinari-tags-file-name)))
          (set (make-local-variable 'tags-file-name)
               (and (file-exists-p r-tags-path) r-tags-path))
          (jinari-minor-mode t))
      (when jinari-minor-mode
        (jinari-minor-mode -1)))))

(defun jinari-launch-maybe ()
  "Call `jinari-launch' if customized to do so.
Both `jinari-major-modes' and `jinari-exclude-major-modes' will
be used to make the decision.  When the global jinari mode is
active, the default is to try to launch jinari in any major
mode.  If `jinari-major-modes' is non-nil, then launching will
happen only in the listed modes.  Major modes listed in
`jinari-exclude-major-modes' will never have jinari
auto-launched, but `jinari-launch' can still be used to manually
enable jinari in buffers using those modes."
  (when (and (not (minibufferp))
             (or (null jinari-major-modes)
                 (memq major-mode jinari-major-modes))
             (or (null jinari-exclude-major-modes)
                 (not (memq major-mode jinari-exclude-major-modes))))
    (jinari-launch)))

(add-hook 'mumamo-after-change-major-mode-hook 'jinari-launch)

(defadvice cd (after jinari-on-cd activate)
  "Call `jinari-launch' when changing directories.
This will activate/deactivate jinari as necessary when changing
into and out of rails project directories."
  (jinari-launch))

;;;###autoload
(define-minor-mode jinari-minor-mode
  "Enable Jinari minor mode to support working with the ExpressJS framework."
  nil
  " Jinari"
  jinari-minor-mode-map)

;;;###autoload
(define-global-minor-mode global-jinari-mode
  jinari-minor-mode jinari-launch-maybe)

(provide 'jinari)

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; byte-compile-warnings: (not cl-functions)
;; eval: (checkdoc-minor-mode 1)
;; End:

;;; jinari.el ends here
