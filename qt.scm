;;;; qt.scm


(module qt (qt:init
	    qt:widget qt:show qt:hide qt:run
	    qt:delete qt:message qt:connect qt:find
	    qt:widget qt:pixmap qt:timer qt:destroy-timer
	    qt:property qt:gl qt:update qt:start qt:stop
	    qt:clear qt:add qt:item <qt> qt:classname
	    <qt-object> <qt-widget> <qt-pixmap> <qt-application>
	    <qt-timer> <qt-sound> <qt-text-edit>
	    <qt-action>
	    qt:get-open-filename qt:get-save-filename qt:get-directory
	    qt:sound qt:play qt:set-headers
	    qt:selection qt:insert
	    qt:shortcut
	    qt:add-action qt:remove-action
	    qt:char-encoding
	    qt:add-attribute qt:remove-attribute qt:attribute?
	    qt:window-flags qt:set-window-flags qt:desktop
	    qt:make-variant-list
	    qt:variant-list-remove-front qt:variant-list-insert-back
	    qt:variant-list-length qt:list->variant-list
	    qt:emit-signal qt:invoke-method
	    qt:variant-list-discard-front
	    qt:session-bus qt:system-bus qt:dbus-connect
	    qt:dbus-list-names qt:dbus-send-signal
	    qt:dbus-register-method qt:dbus-call
	    qt:dbus-call-with-callback
	    qt:dbus-register-service qt:dbus-unregister-service
	    qt:http-read-string qt:http-get qt:make-http
	    qt:destroy-http qt:http-set-host qt:http-read-bytes
	    qt:->pointer qt:pointer->widget qt:pointer->object
	    qt:pointer->timer qt:pointer->application qt:pointer->pixmap
	    qt:pointer->pixmap qt:pointer->dynamicreceiver
	    qt:pointer->sound qt:pointer->text-edit
	    qt:pointer->action qt:pointer->variant-list
	    qt:pointer->dbus-connection qt:pointer->http
	    )

(import scheme chicken
	(except foreign foreign-declare)
	easyffi
	miscmacros)
(use srfi-4 srfi-1 protobj matchable data-structures extras)

(define <qt>
  (% (current-root-object)
     (class '<qt>)
     (pointer #f)
     (print (lambda (self #!optional (port (current-output-port)))
	      (fprintf port "#<~a>" (? self class))))))

(define <qt-object> (% <qt> (class 'qt-object)))
(define <qt-sound> (% <qt-object> (class 'qt-sound)))
(define <qt-widget> (% <qt-object> (class 'qt-widget)))
(define <qt-application> (% <qt-object> (class 'qt-application)))
(define <qt-pixmap> (% <qt> (class 'qt-pixmap)))
(define <qt-dynamicreceiver> (% <qt-object> (class 'qt-dynamicreceiver)))
(define <qt-timer> (% <qt-object> (class 'qt-timer)))
(define <qt-text-edit> (% <qt-widget> (class 'qt-text-edit)))
(define <qt-action> (% <qt-object> (class 'qt-action)))
(define <qt-variant-list> (% <qt> (class 'qt-variant-list)))
(define <qt-dbus-connection> (% <qt> (class 'qt-dbus-connection)))
(define <qt-http> (% <qt> (class 'qt-http)))

(define (qt:->pointer i) (and i (? i pointer)))
(define (qt:pointer->widget p) (and p (% <qt-widget> (pointer p))))
(define (qt:pointer->object p) (and p (% <qt-object> (pointer p))))
(define (qt:pointer->timer p) (and p (% <qt-timer> (pointer p))))
(define (qt:pointer->application p) (and p (% <qt-application> (pointer p))))
(define (qt:pointer->pixmap p) (and p (% <qt-pixmap> (pointer p))))
(define (qt:pointer->dynamicreceiver p) (and p (% <qt-dynamicreceiver> (pointer p))))
(define (qt:pointer->sound p) (and p (% <qt-sound> (pointer p))))
(define (qt:pointer->text-edit p) (and p (% <qt-text-edit> (pointer p))))
(define (qt:pointer->action p) (and p (% <qt-action> (pointer p))))
(define (qt:pointer->variant-list p) (and p (% <qt-variant-list> (pointer p))))
(define (qt:pointer->dbus-connection p) (and p (% <qt-dbus-connection> (pointer p))))
(define (qt:pointer->http p) (and p (% <qt-http> (pointer p))))

#>?
___declare(substitute, "^qt_;qt:")
___declare(substitute, "_;-")
___declare(type, "qtobject;(c-pointer \"QObject\");qt:->pointer;qt:pointer->object")
___declare(type, "qtapplication;(c-pointer \"QApplication\");qt:->pointer;qt:pointer->application")
___declare(type, "qtwidget;(c-pointer \"QWidget\");qt:->pointer;qt:pointer->widget")
___declare(type, "qtdynamicreceiver;(c-pointer \"QDynamicReceiver\");qt:->pointer;qt:pointer->dynamicreceiver")
___declare(type, "qtpixmap;(c-pointer \"QPixmap\");qt:->pointer;qt:pointer->pixmap")
___declare(type, "qttimer;(c-pointer \"QTimer\");qt:->pointer;qt:pointer->timer")
___declare(type, "qtsound;(c-pointer \"QSound\");qt:->pointer;qt:pointer->sound")
___declare(type, "qttextedit;(c-pointer \"QTextEdit\");qt:->pointer;qt:pointer->text-edit")
___declare(type, "qtaction;(c-pointer \"QAction\");qt:->pointer;qt:pointer->action")
___declare(type, "qtvariantlist;(c-pointer \"QVariantList\");qt:->pointer;qt:pointer->variant-list")
___declare(type, "qtdbusconnection;(c-pointer \"QDBusConnection\");qt:->pointer;qt:pointer->dbus-connection")
___declare(type, "qthttp;(c-pointer \"QHttp\");qt:->pointer;qt:pointer->http")
<#

#>
#include <QtGui>
#include <QtUiTools>
#include <QGLWidget>
#include <QtCore>
#include <QtDBus>
#include <QHttp>
#include <chicken.h>
#include <assert.h>
<#

#>!
#include "prototypes.h"
<#

(define (qt:timer seconds) (qt:make-timer seconds))

(define (qt:variant-list-remove-front v)
  ((##core#primitive "qt_variantlist_remove_front") (qt:->pointer v)))
(define (qt:make-variant-list)
  (let ((v (qt:make-variantlist)))
    (set-finalizer! v qt:destroy-variantlist)
    v))
(define (qt:variant-list-insert-back q o #!optional (signed? #t))
  (cond ((flonum? o) (qt:variant-list-insert-back-double q o))
	((integer? o)
	 (if signed?
	     (qt:variant-list-insert-back-int q o)
	     (qt:variant-list-insert-back-uint q o)))
	((string? o) (qt:variant-list-insert-back-string q o))
	((boolean? o) (qt:variant-list-insert-back-bool q (if o 1 0)))
	(else (error "Unsupported type"))))

(define (qt:list->variant-list l)
  (let* ((v (qt:make-variant-list)))
    (for-each (lambda (a) (qt:variant-list-insert-back v a)) l)
    v))

(define (qt:variant-list->list l)
  (map (lambda (n) (qt:variant-list-remove-front l))
       (iota (qt:variant-list-length l))))

(define (qt:session-bus)
  (let ((b (qt:dbus-session-bus)))
    (set-finalizer! b qt:destroy-dbus-connection)
    b))
(define (qt:system-bus)
  (let ((b (qt:dbus-system-bus)))
    (set-finalizer! b qt:destroy-dbus-connection)
    b))

(define (qt:dbus-connect bus service object interface signal to
			 #!optional (slot signal))
  (let ((dest (if (procedure? to)
		  (qt:dynamicreceiver (->string (gensym "qt:dynamic-receiver"))
				      (string->slot slot)
				      to)
		  to)))
    (if (qt:c-dbus-connect bus service object interface signal dest (string->slot slot))
	(lambda ()
	  (if (procedure? to)
	      (qt:deleteobject dest)
	      (qt:dbus-disconnect bus service object interface signal dest (string->slot slot))))
	(begin (when (procedure? to) (qt:deleteobject dest)) #f))))

(define (qt:dbus-send-signal bus object interface signal . arguments)
  (let ((v (qt:list->variant-list arguments)))
    (qt:c-dbus-send-signal bus object interface signal v)))

(define (qt:dbus-list-names bus)
  (let ((v (qt:make-variant-list)))
    (qt:c-dbus-list-names bus v)
    (qt:variant-list->list v)))

(define (qt:dbus-register-method bus path f name)
  (let ((target (qt:dynamicreceiver (->string (gensym "qt:dynamic-receiver"))
				    (string->slot name)
				    f)))
    (if (qt:dbus-register-object bus path target)
	(lambda () (qt:deleteobject target))
	(begin (qt:deleteobject target) #f))))

;;; TODO Need blocking & timeouts, blocking with GUI & timeouts, slots
;;; Blocking with gui is implemented for now because we use signal/slots
;;; so we can service dbus calls to ourselves
(define (qt:dbus-call bus service path interface method . arguments)
  (let ((v (qt:list->variant-list arguments)))
    ((foreign-safe-lambda bool "qt_dbus_method_call"
       qtdbusconnection c-string c-string c-string c-string qtvariantlist)
     bus service path interface method v)
    (qt:variant-list->list v)))

(define (qt:dbus-call-with-callback bus service path interface method fun slot . arguments)
  (letrec ((v (qt:list->variant-list arguments))
	   (target (qt:dynamicreceiver (->string (gensym "qt:dynamic-receiver"))
				       (string->slot slot)
				       (lambda a (qt:deleteobject target) (apply fun a)))))
    ((foreign-safe-lambda bool "qt_dbus_method_call_with_callback"
       qtdbusconnection c-string c-string c-string c-string qtvariantlist
       qtobject c-string)
     bus service path interface method v target (string->slot slot))))


(define-enum encoding->int int->encoding
  unused latin1 utf8 ascii)

(define (qt:char-encoding #!optional enc)
  (if enc
      (qt:charencoding
       (or (encoding->int enc)
	   (error 'qt:char-encoding "invalid encoding mode" enc)))
      (int->encoding (qt:charencoding 0))))

(define (string->method s) (string-append "0" s))
(define (string->slot s) (string-append "1" s))
(define (string->signal s) (string-append "2" s))

(define qt:connect
  (let ((qt:connect qt:connect))
    (lambda (from sig to #!optional (slot sig))
      (let ((dest (if (procedure? to)
		      (qt:dynamicreceiver (->string (gensym "qt:dynamic-receiver"))
					  (string->slot slot)
					  to)
		      to)))
	(if (qt:connect from (string->signal sig) dest (string->slot slot))
	    (lambda ()
	      (if (procedure? to)
		  (qt:deleteobject dest)
		  (qt:disconnect from (string->signal sig) dest (string->slot slot))))
	    (begin (when (procedure? to) (qt:deleteobject dest)) #f))))))

(define (qt:emit-signal o s . args) (apply qt:invoke-method o s #f args))

(define (qt:invoke-method o s #!optional (r? #f) . args)
  (let ((v (qt:list->variant-list args)))
    (if ((foreign-safe-lambda bool "qt_invokemethod"
	   qtwidget c-string qtvariantlist)
	 o (string->signal s) v)
	(if r? (list (qt:variant-list-remove-front v)) #t)
	#f)))

(! <qt-object> 'delete
   (lambda (self) (qt:deleteobject self)))

(! <qt-pixmap> 'delete
   (lambda (self) (qt:deletepixmap self)))

(define (qt:delete o) (@ delete o))

(define qt:message
  (let ((qt:message qt:message))
    (lambda (text #!key (caption "") parent (button1 "OK") (button2 "Cancel") button3)
      (qt:message caption text parent button1 button2 button3))))

(define (qt:widget fname #!optional parent)
  (qt:create fname parent) )

(define qt:property
  (getter-with-setter
   (lambda (w p)
     (let ((p (->string p)))
       (case (qt:propertytype w p)
	 ((5) (qt:getstringproperty w p))
	 ((4) (qt:getintproperty w p))
	 ((3) (qt:getfloatproperty w p))
	 ((1) (qt:getboolproperty w p))
	 ((2) (integer->char (qt:getcharproperty w p)))
	 ((6) (qt:getpixmapproperty w p))
	 ((7) (qt:getpointfproperty w p (make-f64vector 2)))
	 ((8) (qt:getrectfproperty w p (make-f64vector 4)))
	 ((9) (qt:getsizefproperty w p (make-f64vector 2)))
	 ((10) (qt:getpointproperty w p (make-s32vector 2)))
	 ((11) (qt:getsizeproperty w p (make-s32vector 2)))
	 ((12) (qt:getrectproperty w p (make-s32vector 4)))
	 (else (error "unknown property" w p)) ) ) )
   (lambda (w p x)
     (let* ((p (->string p))
	    (ok (cond ((string? x) (qt:setstringproperty w p x))
		      ((fixnum? x) (qt:setintproperty w p x))
		      ((flonum? x) (qt:setfloatproperty w p x))
		      ((char? x) (qt:setcharproperty w p (char->integer x)))
		      ((boolean? x) (qt:setboolproperty w p x))
		      ((s32vector? x)
		       (if (fx= (s32vector-length x) 2)
			   (qt:setpointproperty w p x)
			   (qt:setrectproperty w p x) ) )
		      ((f64vector? x)
		       (if (fx= (f64vector-length x) 2)
			   (qt:setpointfproperty w p x)
			   (qt:setrectfproperty w p x) ) )
		      ((eq? (? x class) 'qt-pixmap) (qt:setpixmapproperty w p x))
		      (else (error "unknown property" w p)) ) ) )
       (unless ok (error 'qt:property/setter "unable to set widget property" w p x) ) ) ) ) )

(define qt:gl
  (let ((qt:gl qt:gl))
    (lambda (name parent init resize paint)
      (qt:gl
       name parent
       (match-lambda*
	 ((0) (init))
	 ((1 w h) (resize w h))
	 (_ (paint)) ) ) ) ) )

(define qt:run
  (let ((qt:run qt:run))
    (lambda (#!optional once)
      (qt:run once) ) ) )

(define (qt:add w x)
  (cond ((string=? "QComboBox" (qt:classname w)) (qt:addcomboboxitem w x))
	((string=? "QListWidget" (qt:classname w)) (qt:addlistwidgetitem w x))
	((string=? "QTreeWidget" (qt:classname w)) (qt:addtreewidgetitem w x))
	(else (error 'qt:add "invalid widget" w x)) ) )

(define (qt:item w i) (and (positive? i) (qt:listwidgetitem w i)))
(define qt:clear qt:clearlistwidget)

(define (qt:set-headers w x)
  (cond ((string=? "QTreeWidget" (qt:classname w)) (qt:setheaders w x))
	(else (error 'qt:set-headers "invalid widget" w x)) ) )

(define (file-dialog-options loc os)
  (let loop ((os os))
    (cond ((null? os) 0)
	  ((assq (car os)
		 '((show-dirs-only: . 1) (dont-resolve-symlinks: . 2) (dont-confirm-overwrite: . 4)
		   (dont-use-sheet: . 8) (dont-use-native-dialog: . 16) ) )
	   => (lambda (a) (loop (bitwise-ior (cdr a) (loop (cdr os))))) )
	  (else (error loc "invalid file-dialog option" (car os))) ) ) )

(define (qt:get-open-filename cap dir #!key parent (options '()) filter)
  (qt:getopenfilename parent cap dir filter (file-dialog-options 'qt:get-open-filename options)) )

(define (qt:get-save-filename cap dir #!key parent (options '()) filter)
  (qt:getsavefilename parent cap dir filter (file-dialog-options 'qt:get-save-filename options)) )

(define (qt:get-directory cap dir #!key parent (options '()))
  (qt:getexistingdirectory parent cap dir (file-dialog-options 'qt:get-directory options)) )

(! <qt-timer> 'stop
   (lambda (self) (qt:stoptimer self)))

(! <qt-sound> 'stop
   (lambda (self) (qt:stopsound self)))

(define (qt:stop x) (@ x stop))

(define (qt:add-attribute w a) (qt:attribute w a 1))
(define (qt:remove-attribute w a) (qt:attribute w a 0))
(define (qt:attribute? w a) (= (qt:testattribute w a) 1))
)
