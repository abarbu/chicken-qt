;;;; chicken-compile-qt-extension.scm


(module main ()

(import scheme chicken)

(use files utils setup-api srfi-1 extras data-structures posix)

(define (quit fstr . args)
  (flush-output)
  (fprintf (current-error-port) "~?~%" fstr args)
  (exit 1))

(define QTDIR
  (or (get-environment-variable "QTDIR")
      (and (file-execute-access? "/usr/bin/qmake") "/usr")
      (and (file-execute-access? "/usr/local/bin/qmake") "/usr/local")
      (quit "please set the QTDIR environment variable") ) )

(define prefix chicken-prefix)
(define libpath (make-pathname prefix "lib"))
(define incpath (make-pathname prefix "include"))
;; need both -I<incdir> (pre 4.6.4) and -i<incdir>/chicken (4.6.4)
(define cincpath (make-pathname incpath "chicken"))
(define binpath (make-pathname prefix "bin"))
(define csc (make-pathname binpath "csc"))
(define keepfiles #f)
(define qmake (make-pathname QTDIR "bin/qmake"))
(define mingw32 (eq? (build-platform) 'mingw32))
(define outfile #f)

(define gmake
  (cond ((memq (software-version) '(freebsd netbsd openbsd))
	 "gmake")
	(mingw32 "mingw32-make")
	(else "make")))

(define options-with-arguments
  '("-debug" "-output-file" "-heap-size" "-nursery" "-stack-size" "-compiler"
    "-unit" "-uses" "-keyword-style" "-optimize-level" "-include-path"
    "-database-size" "-extend" "-prelude" "-postlude" "-prologue" "-epilogue"
    "-inline-limit" "-profile-name" "-disable-warning" "-emit-inline-file"
    "-types" "-feature" "-debug-level" "-heap-growth" "-heap-shrinkage"
    "-heap-initial-size" "-consult-inline-file" "-emit-import-library"
    "-static-extension" "-D" "-K" "-X" "-j" "-I" "-o" "-n" "-R" "-C" "-L"
    "-cc" "-cxx" "-ld" "-rpath" "-framework"))

(define (filter-options args)
  (let loop ((args args) (opts '()) (files '()))
    (if (null? args)
	(values (reverse opts) (reverse files))
	(let ((arg (car args))
	      (more (cdr args)))
	  (cond ((string=? "-k" arg) (set! keepfiles #t))
		((string=? "-v" arg)
		 (setup-verbose-mode #t)
		 (run-verbose #t))
		((member arg '("--help" "-h" "-help"))
		 (compile -h))
		((and (string=? "-o" arg) (pair? more))
		 (set! outfile (car more))))
	  (if (and (> (string-length arg) 1)
		   (char=? #\- (string-ref arg 0)))
	      (if (member arg options-with-arguments)
		  (if (null? more)
		      (loop more (cons arg opts) files)
		      (loop (cdr more) (cons* (car more) arg opts) files))
		  (loop more (cons arg opts) files))
	      (loop more opts (cons arg files)))))))

(define (compile-qt-extension cppfiles hfiles)
  (let* ((cppfile (car cppfiles))
	 (pro (pathname-replace-extension cppfile "pro"))
	 (name (pathname-file cppfile))
	 (mkfile (qs (pathname-replace-extension cppfile "make")))
	 (output (or outfile (make-pathname #f name "so"))))
    (with-output-to-file pro
      (lambda ()
	(let ((csc (qs (normalize-pathname csc)))
	      (libdir (qs (normalize-pathname libpath)))
	      (incdir (qs (normalize-pathname incpath)))
	      (cincdir (qs (normalize-pathname cincpath))))
	  (print #<#EOF
SOURCES=#{(string-intersperse cppfiles)}
CONFIG+=uitools qt
TEMPLATE=lib
HEADERS=#{(string-intersperse hfiles)}
TARGET=#{name}
unix:QMAKE_LFLAGS_RELEASE+= `#{csc} -libs -ldflags` -L#{libdir}
unix:QMAKE_CFLAGS_RELEASE+=-w `#{csc} -cflags` -I#{incdir} -I#{cincdir}
unix:QMAKE_CXXFLAGS_RELEASE+=-w `#{csc} -cflags` -I#{incdir} -I#{cincdir}
unix:QMAKE_CFLAGS_WARN_ON=-w
unix:QMAKE_CXXFLAGS_WARN_ON=-w
win32:QMAKE_LFLAGS_RELEASE+=-L#{libdir}
win32:QMAKE_CFLAGS_RELEASE+=-w -I#{incdir} -I#{cincdir} -DHAVE_CHICKEN_CONFIG_H -DPIC
win32:QMAKE_CXXFLAGS_RELEASE+=-w -I#{incdir} -I#{cincdir} -DHAVE_CHICKEN_CONFIG_H -DPIC
win32:QMAKE_CFLAGS_WARN_ON=--w
win32:QMAKE_CXXFLAGS_WARN_ON=-w
win32:LIBS+=-lchicken -lm -lws2_32
QT+=opengl dbus network webkit
EOF
) ) ))
    (run (,qmake ,(qs pro) -o ,mkfile))
    (delete-file* output)
    (run (,gmake -f ,mkfile clean ,(if mingw32 "release" "all")))
    (cp
     (make-pathname 
      (if mingw32 "release" #f)
      (if mingw32 name (string-append "lib" name))
      (if mingw32 "dll" "so.1.0.0"))
     output)
    ) )

(define (rm-f . files)
  (for-each
   (lambda (fname)
     (when (setup-verbose-mode) (print "  rm -f " (qs fname)))
     (delete-file* fname))
   files))

(define (cp from to)
  (when (setup-verbose-mode)
    (print "  cp " (qs from) " " (qs to))
    (file-copy from to)))

(define (main args)
  (let-values (((opts files) (filter-options args)))
    (let ((cppfiles
	   (filter-map
	    (lambda (fname)
	      (let ((ext (pathname-extension fname)))
		(cond ((member ext '("scm" "ss"))
		       (compile -t -c++ ,(qs fname) ,@opts)
		       (pathname-replace-extension fname "cpp"))
		      ((member ext '("cxx" "c++" "cpp"))
		       fname)
		      (else #f))))
	    files))
	  (hfiles
	   (filter
	    (lambda (fname)
	      (let ((ext (pathname-extension fname)))
		(member ext '("h" "hpp"))))
	    files)))
      (if (null? cppfiles)
	  (quit "no Scheme or C++ files to process")
	  (handle-exceptions ex
	      (begin
		(flush-output)
		(print-error-message ex (current-error-port))
		(exit 1))
	    (compile-qt-extension cppfiles hfiles))))))

(main (command-line-arguments))

)
