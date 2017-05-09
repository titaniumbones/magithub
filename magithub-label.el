(require 'ghub+)
(require 'magithub-core)

(defun magithub-label-list ()
  "Return a list of issue and pull-request labels."
  (magithub-cache :label
    '(ghubp-get-repos-owner-repo-labels
      (magithub-source-repo))
    "Loading labels..."))

(defun magithub-label-read-labels (prompt &optional default)
  "Read some issue labels and return a list of strings.
Available issues are provided by `magithub-label-list'.

DEFAULT is a list of pre-selected labels.  These labels are not
prompted for again."
  (let ((remaining-labels
         (cl-set-difference (magithub-label-list) default
                            :test (lambda (a b)
                                    (= (alist-get 'name a)
                                       (alist-get 'name b))))))
    (magithub--completing-read-multiple
     prompt remaining-labels
     (lambda (l) (alist-get 'name l)))))

(defun magithub-issue-read-labels (prompt &optional default)
  "Read some issue labels and return a comma-separated string.
Available issues are provided by `magithub-issue-label-list'.

DEFAULT is a comma-separated list of issues -- those issues that
are in DEFAULT are not prompted for again."
  (thread-last (when default (s-split "," default t))
    (magithub-issue-read-labels-list prompt)
    (s-join ",")))

(defface magithub-label-face '((t :box t))
  "The inherited face used for labels.
Feel free to customize any part of this face, but be aware that
`:foreground' will be overridden by `magithub-label-propertize'.")

(defun magithub-label-browse (label)
  "Visit LABEL with `browse-url'.
Only GitHub.com is currently supported.  In the future, this will
likely be replaced with a search on issues and pull requests with
the label LABEL."
  (unless (string= ghub-base-url "https://api.github.com")
    (user-error "Label browsing not yet supported on GitHub Enterprise; pull requests welcome!"))
  (let-alist (magithub-source-repo)
    (browse-url (format "https://www.github.com/%s/%s/labels/%s"
                        .owner.login .name (alist-get 'name label)))))

(defcustom magithub-label-color-replacement-alist nil
  "Make certain label colors easier to see.
In your theme, you may find that certain colors are very
difficult to see.  Customize this list to map GitHub's label
colors to their Emacs replacements."
  :group 'magithub
  :type '(alist :key-type color :value-type color))

(defun magithub-label--get-display-color (label)
  "Gets the display color for LABEL.
Respects `magithub-label-color-replacement-alist'."
  (let ((original (concat "#" (alist-get 'color label))))
    (if-let ((color (assoc-string original magithub-label-color-replacement-alist t)))
        (cdr color)
      original)))

(defun magithub-label-propertize (label)
  "Propertize LABEL according to its color.
The face used is dynamically calculated, but it always inherits
from `magithub-label-face'.  Customize that to affect all labels."
  (magithub--object-propertize 'label label
    (propertize (alist-get 'name label)
                'face (list :foreground (magithub-label--get-display-color label)
                            :inherit 'magithub-label-face))))

(provide 'magithub-label)
