(use-modules
 (sxml simple)
 (srfi srfi-1)
 (srfi srfi-13))

(define (number-string . nums)
  (string-join (map number->string nums) " "))

(define (finger-geom len)
  `(geom (@ (type "capsule") (size "0.9") (fromto ,(number-string 0 0 0 0 0 len)))))

(define (pip-name finger) (string-append finger "-pip"))
(define (dip-name finger) (string-append finger "-dip"))
(define (mcp-flex-name finger) (string-append finger "-flex"))
(define (mcp-aa-name finger) (string-append finger "-aa"))

(define (finger name metacarpal proximal middle distal)
  `(,(finger-geom metacarpal)
    (body
     (@ (pos ,(number-string 0 0 metacarpal)))
     ,(finger-geom proximal)
     (joint (@ (name ,(mcp-flex-name name)) (axis "0 1 0") (limited "true") (range "-15 90")))
     (joint (@ (name ,(mcp-aa-name name)) (axis "1 0 0")))
     (body
      (@ (pos ,(number-string 0 0 proximal)))
      ,(finger-geom middle)
      (joint (@ (name ,(pip-name name)) (axis "0 1 0") (limited "true") (range "-5 120")))
      (body
       (@  (pos ,(number-string 0 0 middle)))
       ,(finger-geom distal)
       (joint (@ (name ,(dip-name name)) (axis "0 1 0") (limited "true") (range "-5 90")))
       )))))

(define (dip-pip finger)
  `(joint (@ (joint1 ,(dip-name finger)) (joint2 ,(pip-name finger)) (polycoef "0 0.66 0 0 0"))))

;;; Limits the abduction of fingers that are bent.
;;; Left and right limits are modeled separately.
;;; The left limits double as right limits for hyperextension and vice versa.
;;;
;;; The lengths of fixed tendons are calculated with radians.
;;; -0.44 and 0.52 are approximations of -25 and 30 degrees.
(define (flex-aa-relation finger)
  `((fixed
     (@ (limited "true") (range "-0.44 0.52"))
     (joint (@ (joint ,(mcp-aa-name finger)) (coef "1")))
     (joint (@ (joint ,(mcp-flex-name finger)) (coef "0.33"))) ; 0.52 / (pi / 2)
     )
    (fixed
     (@ (limited "true") (range "-0.44 0.52"))
     (joint (@ (joint ,(mcp-aa-name finger)) (coef "1")))
     (joint (@ (joint ,(mcp-flex-name finger)) (coef "-0.28"))) ; -0.44 / (pi / 2)
     )))

;;; Limits the difference of adjacent MCP joints
;;; extension-slack and flexion-slack are the allowed amounts of flexion
;;; and extension of finger a if finger b is held in place.
(define (finger-correlation a b extension-slack flexion-slack)
  `((fixed
     (@ (limited "true") (range ,(number-string -5 extension-slack)))
     (joint (@ (joint ,(mcp-flex-name a)) (coef "-1")))
     (joint (@ (joint ,(mcp-flex-name b)) (coef "1"))))
    (fixed
     (@ (limited "true") (range ,(number-string -5 flexion-slack)))
     (joint (@ (joint ,(mcp-flex-name a)) (coef "1")))
     (joint (@ (joint ,(mcp-flex-name b)) (coef "-1"))))))

(define finger-names '("index" "middle" "ring" "pinky"))

(define (degrees->radians x) (* 3.14159 (/ x 180)))

(define (dh-link theta-degrees alpha-degrees d r minangle maxangle child)
  (let ((theta (degrees->radians theta-degrees))
	(alpha (degrees->radians alpha-degrees)))
      `(body
	(@
	 (pos ,(number-string r 0 d))
	 (xyaxes ,(number-string
		   (cos theta) (sin theta) 0
		   (- (* (sin theta) (cos alpha)))
		   (* (cos theta) (cos alpha))
		   (sin alpha)
		   )))
	(geom (@ (type "sphere") (size "1")))
	(joint (@ (axis "0 0 1") (limited "true") (range ,(number-string minangle maxangle))))
	,child)))

(define (dh-assembly links)
  (fold
   (lambda (next acc)
     (apply dh-link (append next (list acc))))
   '(body (geom (@ (type "sphere") (size 0.1))))
   links))

(sxml->xml
 `(mujoco
   (@ (model "Hand"))

   (compiler (@ (angle "degree")))

   (worldbody
    (body (@ (pos "0 1.8 0") (axisangle "1 0 0 -8")) ,@(finger "index" 8 4.5 2.5 2))
    (body ,@(finger "middle" 7.8 5 3 2))
    (body (@ (pos "0 -1.8 0") (axisangle "1 0 0 6")) ,@(finger "ring" 7 4.5 3 2))
    (body (@ (pos "0 -3.6 0") (axisangle "1 0 0 14")) ,@(finger "pinky" 6.5 3.5 2 2))

    (body (@ (pos "0 4 0") (axisangle "0 0 1 -45"))
	  ,(dh-assembly
	    '((0 0 3.42 0.03 0 1)
	      (74.47 94.89 -0.71 0 0 1)
	      (-18.41 106.43 -1.16 3.99 -25 90)
	      (4.08 -110.37 0.85 0.31 -10 10)
	      (16.81 88.41 -0.51 4.45 -25 45)
	      (-85.11 -86.86 0.21 1.31 -22 22)
	      (0 -93.86 0.59 -0.12 -22 22)
	      ))))

   (equality ,@(map dip-pip finger-names))

   (tendon
    ,@(append-map flex-aa-relation finger-names)
    ,@(finger-correlation "index" "middle" 0.94 0.44)
    ,@(finger-correlation "middle" "ring" 0.79 0.35)
    ,@(finger-correlation "ring" "pinky" 0.84 0.77)
    )
   ))
