(use utils gl glu srfi-18)

#+(not macosx) (use qt)

(define *test-ui* #<<EOF
<ui version="4.0" >
 <class>Form</class>
 <widget class="QWidget" name="Form" >
  <property name="geometry" >
   <rect>
    <x>0</x>
    <y>0</y>
    <width>469</width>
    <height>301</height>
   </rect>
  </property>
  <property name="sizePolicy" >
   <sizepolicy>
    <hsizetype>0</hsizetype>
    <vsizetype>0</vsizetype>
    <horstretch>0</horstretch>
    <verstretch>0</verstretch>
   </sizepolicy>
  </property>
  <property name="minimumSize" >
   <size>
    <width>469</width>
    <height>301</height>
   </size>
  </property>
  <property name="maximumSize" >
   <size>
    <width>496</width>
    <height>301</height>
   </size>
  </property>
  <property name="windowTitle" >
   <string>Form</string>
  </property>
  <widget class="QPushButton" name="pushButton_2" >
   <property name="geometry" >
    <rect>
     <x>130</x>
     <y>210</y>
     <width>191</width>
     <height>41</height>
    </rect>
   </property>
   <property name="text" >
    <string>Exit</string>
   </property>
  </widget>
  <widget class="QPushButton" name="pushButton" >
   <property name="geometry" >
    <rect>
     <x>100</x>
     <y>50</y>
     <width>261</width>
     <height>71</height>
    </rect>
   </property>
   <property name="text" >
    <string>Oink!</string>
   </property>
  </widget>
  <widget class="QCheckBox" name="checkBox" >
   <property name="geometry" >
    <rect>
     <x>180</x>
     <y>160</y>
     <width>111</width>
     <height>24</height>
    </rect>
   </property>
   <property name="text" >
    <string>Good?</string>
   </property>
  </widget>
  <widget class="QLabel" name="label" >
   <property name="geometry" >
    <rect>
     <x>370</x>
     <y>200</y>
     <width>81</width>
     <height>81</height>
    </rect>
   </property>
   <property name="text" >
    <string/>
   </property>
  </widget>
 </widget>
 <resources/>
 <connections/>
</ui>
EOF
)

(define app (qt:init))
(define w (qt:widget *test-ui* #f))
(print w)
(define pb (qt:find w "pushButton_2"))
(assert pb)
(pp pb)
(define cb (qt:find w "checkBox"))
(assert cb)
(pp cb)
(define i (qt:pixmap "lisp1pz.png"))
(when i (pp (##sys#slot i 1)))
(define f #f)
(define s (qt:sound "blip.wav"))
(pp s)
(define r (lambda () 
			 (qt:message "Oink!")
			 (set! (qt:property cb "checked") f)
			 (set! f (not f)) ) )
(qt:connect (ensure identity (qt:find w "pushButton_2")) "clicked()" (lambda () (print "exit") (exit)))
(qt:connect (ensure identity (qt:find w "pushButton")) "clicked()" 
	    (lambda ()
	       (qt:play s)
	       (pp (qt:get-open-filename "yo" "."))))
(qt:connect app "aboutToQuit()" (lambda () (print "about to quit")))
(when i (set! (qt:property (qt:find w "label") "pixmap") i))

(define a 0)

(define g
  (qt:gl 
   "gl" w 
   (cut gl:ClearColor 0 0 0 1)
   (lambda (w h)
     (when (zero? h) (set! h 1))
     (gl:Viewport 0 0 w h)
     (gl:MatrixMode gl:PROJECTION)
     (gl:LoadIdentity)
     (glu:Ortho2D -1 -1 1 1))
   (lambda ()
     (gl:Clear (bitwise-ior gl:COLOR_BUFFER_BIT gl:DEPTH_BUFFER_BIT))
     (gl:MatrixMode gl:MODELVIEW)
     (gl:LoadIdentity)
     (gl:Rotatef a 0 0 1)
     (gl:Begin gl:POLYGON)
     (gl:Vertex2f -0.5 -0.5)
     (gl:Vertex2f -0.5 0.5)
     (gl:Vertex2f 0.5 0.5)
     (gl:Vertex2f 0.5 -0.5)
     (gl:End) ) ) )

(set! (qt:property g "pos") '#s32(0 0))
(set! (qt:property g "size") '#s32(100 100))
(qt:show w)
(qt:show g)

(qt:connect app "lastWindowClosed()" (lambda () (print "closed") (exit)))

(define t (qt:timer 0.01))

(qt:connect
 t "timeout()"
 (lambda ()
    (set! a (+ a 0.3))
    (qt:update g) ) )

(qt:start t)

(qt:run)
