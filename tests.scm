(use qt test srfi-1 posix)

(define *application* (qt:init))

(define tmp #f)

(define (run-for-a-bit) (for-each (lambda (a) (qt:run 1)) (iota 1000)))

(test-group
 "Variant"
 (let ((v (qt:make-variant-list)))
  (test-assert "Creation" v)

  (test-group "Integers"
	      (test 0 (qt:variant-list-length v))
	      (qt:variant-list-insert-back v 3)
	      (test 1 (qt:variant-list-length v))
	      (test 3 (qt:variant-list-remove-front v))
	      (test 0 (qt:variant-list-length v)))

  (test-group "Strings"
	      (let ((t "hℝello"))
	       (qt:variant-list-insert-back v 5)
	       (qt:variant-list-insert-back v 6)
	       (qt:variant-list-insert-back v t)
	       (test 3 (qt:variant-list-length v))
	       (let* ((i (qt:variant-list-remove-front v))
		      (s (begin
			  (qt:variant-list-discard-front v)
			  (qt:variant-list-remove-front v))))
		(test 5 i)
		(test t s)
		(test 0 (qt:variant-list-length v)))))

  (test-group "Unsigned integers"
	      (test 0 (qt:variant-list-length v))
	      (qt:variant-list-insert-back v 3 #f)
	      (test 1 (qt:variant-list-length v))
	      (test 3 (qt:variant-list-remove-front v))
	      (test 0 (qt:variant-list-length v)))

  (test-group "Boolean"
	      (test 0 (qt:variant-list-length v))
	      (qt:variant-list-insert-back v #t)
	      (qt:variant-list-insert-back v #f)
	      (test #t (qt:variant-list-remove-front v))
	      (test #f (qt:variant-list-remove-front v))
	      (test 0 (qt:variant-list-length v)))

  (test-group "Double"
	      (test 0 (qt:variant-list-length v))
	      (qt:variant-list-insert-back v 0.1)
	      (qt:variant-list-insert-back v 0.2)
	      (test 0.1 (qt:variant-list-remove-front v))
	      (test 0.2 (qt:variant-list-remove-front v))
	      (test 0 (qt:variant-list-length v)))))

(test-group
 "Signals & Slots"
 (let ((r0 (qt:connect (qt:desktop) "resized(int)" (lambda () (set! tmp 0)) "resized()"))
       (r1 (qt:connect (qt:desktop) "resized(int)" (lambda (a) (set! tmp a)))))
  (test #f tmp)
  (test-assert "Connect without arguments" r0)
  (test-assert "Connect without one argument" r1)
  (test "Emitting" #t (qt:emit-signal (qt:desktop) "resized(int)" 3))
  (test-assert "Worked" (or (= tmp 0) (= tmp 3)))
  (set! tmp #f)
  (r0)
  (test "Emitting" #t (qt:emit-signal (qt:desktop) "resized(int)" 3))
  (test "Single argument" 3 tmp)))

(test-group
 "DBus"
 (let ((session-bus (qt:session-bus))
       (system-bus (qt:system-bus)))
  (test-group "Connection"
	      (test-assert "Session bus" session-bus)
	      (test-assert "System bus" system-bus)
	      (let ((l1 (qt:dbus-list-names session-bus))
		    (l2 (qt:dbus-list-names system-bus)))
	       (test-assert "Session bus" l1)
	       (test-assert "System bus" l2)
	       (test "org.freedesktop.DBus" "org.freedesktop.DBus" (car l2))))
  (test-group
   "Signals"
   (test-assert "Send" (qt:dbus-send-signal system-bus "/" "org.chicken.ping" "ping"))
   (test-assert "Send 1 argument"
		(qt:dbus-send-signal system-bus "/" "org.chicken.ping" "ping" "a" 3))
   (let* ((pinged 0)
	  (c (qt:dbus-connect system-bus "" "" "org.chicken.ping" "ping"
			      (lambda () (set! pinged (+ pinged 1)))
			      "ping()")))
    (test-assert "Connection" c)
    (test-assert "Send" (qt:dbus-send-signal system-bus "/" "org.chicken.ping" "ping"))
    (run-for-a-bit)
    (test "Receive" 1 pinged)
    (test-assert "Send" (qt:dbus-send-signal system-bus "/" "org.chicken.ping" "ping"))
    (run-for-a-bit)
    (test "Receive" 2 pinged)
    (c)
    (test-assert "Send (disconnected)"
		 (qt:dbus-send-signal system-bus "/" "org.chicken.ping" "ping"))
    (run-for-a-bit)
    (test "Not received" 2 pinged)
    (let ((c (qt:dbus-connect system-bus "" "" "org.chicken.ping" "ping"
			      (lambda (a) (set! pinged (+ pinged a)))
			      "ping(int)")))
     (test-assert "Connection" c)
     (test-assert "Send 1 arg" (qt:dbus-send-signal system-bus "/" "org.chicken.ping" "ping" 2))
     (run-for-a-bit)
     (test "Receive" 4 pinged)
     (test-assert "Send 2 arg to 1"
		  (qt:dbus-send-signal system-bus "/" "org.chicken.ping" "ping" 2 3))
     (run-for-a-bit)
     (test "Received first" 6 pinged)
     (if #f
	 (begin
	  (test-assert "Send 0 arg to 1"
		       (qt:dbus-send-signal system-bus "/" "org.chicken.ping" "ping"))
	  (run-for-a-bit)
	  (test "Didn't receive" 6 pinged))
	 (test-assert "Fix Send 0 arg to 1 segfault" #f)))))
  (test-group
   "Methods"
   (let* ((pinged 0)
	  (bus
	   (cond
	    ((qt:dbus-register-service system-bus "Chicken.Test") system-bus)
	    ((qt:dbus-register-service session-bus "Chicken.Test") session-bus)
	    (else #f)))
	  (m0 (qt:dbus-register-method bus "/chicken/fun"
				       (lambda () (set! pinged (+ pinged 1)))
				       "ping()"))
	  (m1 (qt:dbus-register-method bus "/chicken/fun2"
				       (lambda (i) (set! pinged (+ pinged i)))
				       "arr(double)")))
    (test-assert "Register service" bus)
    (test-assert "Register method" m0)
    (test-assert "Register method" m1)
    (test "Method call result (a qt bug makes this fail with (0) on some machines),
     the actual call happens, the return value of the call is just incorrect"
	  '(2)
	  (qt:dbus-call bus "Chicken.Test" "/chicken/fun" "" "ping"))
    (run-for-a-bit)
    (test "Method call happened" 1 pinged)
    (test-assert
     "Call with callback"
     (qt:dbus-call-with-callback bus "Chicken.Test" "/chicken/fun" "" "ping"
				 (lambda () (set! pinged (+ 1 pinged)))
				 "ping()"))
    (run-for-a-bit)
    (test "Call happened, reply received" 3 pinged)
    (test "Method call (args) result" '(2)
	  (qt:dbus-call bus "Chicken.Test" "/chicken/fun2" "" "arr" 3.1))
    (run-for-a-bit)
    (test "Call happened, reply received" 6.1 pinged)
    (test-assert
     "Call (args) with callback"
     (qt:dbus-call-with-callback bus "Chicken.Test" "/chicken/fun2" "" "arr"
				 (lambda () (set! pinged (+ 1 pinged))) "arr(double)"
				 4.1))
    (run-for-a-bit)
    (test "Call happened, reply received" 10.2 pinged)
    (test-assert
     "Call (args) with mismatched callback"
     (qt:dbus-call-with-callback bus "Chicken.Test" "/chicken/fun2" "" "arr"
				 (lambda () (set! pinged (+ 1 pinged))) "arr()"
				 4.0))

    (run-for-a-bit)
    (test "Call happened, reply received" 15.2 pinged)
    (m0)
    (m1)
    (test "Bad method call"
	  '(3 "org.freedesktop.DBus.Error.UnknownObject")
	  (qt:dbus-call bus "Chicken.Test" "/chicken/fun" "" "ping"))
    (run-for-a-bit)
    (test 15.2 pinged)
    (test-assert "Bad method call with callback"
		 (qt:dbus-call-with-callback bus "Chicken.Test" "/chicken/fun" "" "ping"
					     (lambda () (set! pinged (+ 1 pinged)))
					     "ping()"))
    (run-for-a-bit)
    (test 15.2 pinged)
    (test-assert "Unregister" (qt:dbus-unregister-service bus "Chicken.Test"))))))

(test-group
 "HTTP"
 (let ((h (qt:make-http)))
  (test-assert "Creation" h)
  (test-assert "Setting host" (qt:http-set-host h "google.com" 80))
  (let* ((done? #f)
	 (progress '())
	 (c (qt:connect h "done(bool)" (lambda (b) (set! done? #t))))
	 (p (qt:connect h "dataReadProgress(int,int)"
			(lambda (p t) (set! progress (cons p progress))))))
   (test-assert "HTTP Get" (qt:http-get h "/"))
   (let loop () (qt:run 1) (unless done? (loop)))
   (test-assert "Reading back string" (> (string-length (qt:http-read-string h)) 0))
   (test-assert "Progress" (> (length progress) 0))
   (c)
   (qt:destroy-http h)
   (p))))


(test-exit)
