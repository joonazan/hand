(use-modules
 (sxml simple)
 (ice-9 format)
 (srfi srfi-1))

(define (finger-geom len)
  `(geom (@ (type "capsule") (size "0.09") (fromto ,(format #f "0 0 0 0 0 ~a" len)))))

(define (pip-name finger) (string-append finger "-pip"))
(define (dip-name finger) (string-append finger "-dip"))
(define (mcp-flex-name finger) (string-append finger "-flex"))
(define (mcp-aa-name finger) (string-append finger "-aa"))

(define (finger name metacarpal proximal middle distal)
  `(,(finger-geom metacarpal)
    (body
     (@ (pos ,(format #f "0 0 ~a" metacarpal)))
     ,(finger-geom proximal)
     (joint (@ (name ,(mcp-flex-name name)) (axis "0 1 0") (limited "true") (range "-15 90")))
     (joint (@ (name ,(mcp-aa-name name)) (axis "1 0 0") (limited "false") (range "-25 30")))
     (body
      (@ (pos ,(format #f "0 0 ~a" proximal)))
      ,(finger-geom middle)
      (joint (@ (name ,(pip-name name)) (axis "0 1 0") (limited "true") (range "-5 120")))
      (body
       (@  (pos ,(format #f "0 0 ~a" middle)))
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

(define finger-names '("index" "middle" "ring" "pinky"))

(sxml->xml
 `(mujoco
   (@ (model "Hand"))
   (compiler (@ (angle "degree")))

   (worldbody
    (body (@ (pos "0 0.18 0") (axisangle "1 0 0 -8")) ,@(finger "index" 0.8 0.45 0.25 0.2))
    (body ,@(finger "middle" 0.78 0.5 0.3 0.2))
    (body (@ (pos "0 -0.18 0") (axisangle "1 0 0 6")) ,@(finger "ring" 0.7 0.45 0.3 0.2))
    (body (@ (pos "0 -0.36 0") (axisangle "1 0 0 14")) ,@(finger "pinky" 0.65 0.35 0.2 0.2))

    (body
     (@ (pos "0 0.18 -0.17"))
     (geom (@ (type "capsule") (size "0.12") (fromto "0 0.2 0 0 0.25 0.43")))
     (joint (@ (axis "0 0 1") (limited "true") (range "-90 25")))
     (joint (@ (axis "1 0 0") (limited "true") (range "-50 30")))
     (body
      (@ (pos "0 0.25 0.43"))
      (geom (@ (type "capsule") (size "0.1") (fromto "0 0 0 0 0 0.3")))
      (joint (@ (axis "0 1 0") (limited "true") (range "-10 45")))
      (body
       (@ (pos "0 0 0.3"))
       (geom (@ (type "capsule") (size "0.1") (fromto "0 0 0 0 0 0.2")))
       (joint (@ (axis "0 1 0") (limited "true") (range "-20 90")))))))

   (equality ,@(map dip-pip finger-names))

   (tendon ,@(append-map flex-aa-relation finger-names))
   ))
