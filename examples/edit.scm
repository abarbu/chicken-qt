(use qt utils extras)

(require-library chicken-syntax)

(define a (qt:init))
(define w (qt:widget (read-all "editor.ui")))
(define e (qt:find w "editor"))

(qt:insert e "Select some Scheme code and\npress CTRL-E to evaluate it.\n")

(define action (qt:shortcut w "Ctrl+E"))

(qt:connect
 action "triggered()"
 (qt:receiver
  (lambda ()
    (let ((code (qt:selection e)))
      (qt:insert e code)
      (qt:insert
       e
       (with-output-to-string
	 (lambda ()
	   (handle-exceptions ex
	       (begin
		 (print-error-message ex)
		 (print-call-chain))
	     (pp (eval (with-input-from-string code read)))))))))))

(qt:add-action e action)

(qt:show w)
(qt:run)
