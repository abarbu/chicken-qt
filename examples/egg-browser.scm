;;;; egg-browser.scm


(use qt posix regex utils matchable)


(define *application* (qt:init))
(define *window* (qt:widget (read-all "egg-browser.ui")))
(define *list* (qt:find *window* "eggList"))
(define *props* (qt:find *window* "eggProperties"))
(define *count* (qt:find *window* "countLabel"))
(define *ubutton* (qt:find *window* "uninstallButton"))

(define (refresh)
  (let ((eggs (sort (map pathname-file (glob (make-pathname (repository-path) "*.setup-info"))) string<?)))
    (qt:clear *list*)
    (qt:clear *props*)
    (for-each (cut qt:add *list* <>) eggs)
    (set! (qt:property *count* "text") (number->string (length eggs))) ) )

(define (item-changed)
  (set! (qt:property *ubutton* "enabled") #t)
  (qt:clear *props*)
  (let ((row (qt:property *list* "currentRow")))
    (if (positive? row)
	(for-each
	 (cut qt:add *props* <>)
	 (let ((info (extension-information (string->symbol (qt:item *list* row)))))
	   (if info
	       (sort
		(map (match-lambda
		       ((name) (->string name))
		       ((name vals ...) (conc name ": " (string-intersperse (map ->string vals) " ")))
		       (_ "") )
		     info)
		string<?)
	       '("") ) ) )
	(set! (qt:property *ubutton* "enabled") #f) ) ) )

(define (uninstall)
  (and-let* ((i (qt:property *list* "currentRow"))
	     (name (qt:item *list* i)) )
    (when (zero? (qt:message (conc "Are you sure you want to uninstall `" name "' ?")
			     button1: "Yes" button2: "No") )
      (set! (qt:property *count* "text") (number->string (sub1 (string->number (qt:property *count* "text")))))
      (set! (qt:property *ubutton* "enabled") #f)
      (system* "chicken-uninstall ~s" name)
      (refresh) ) ) )

(qt:connect (qt:find *window* "exitButton") "clicked()" *application* "quit()")
(qt:connect (qt:find *window* "refreshButton") "clicked()" refresh)
(qt:connect *list* "currentItemChanged(QListWidgetItem *, QListWidgetItem *)" item-changed)
(qt:connect *ubutton* "clicked()" uninstall)
(qt:show *window*)
(refresh)
(qt:run)
