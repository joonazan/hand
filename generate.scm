(use-modules (sxml simple) (ice-9 format))

(define (finger-geom len)
  `(geom (@ (type "capsule") (size "0.09") (fromto ,(format #f "0 0 0 0 0 ~a" len)))))

(define (finger name metacarpal proximal middle distal)
  `(,(finger-geom metacarpal)
    (body
     (@ (pos ,(format #f "0 0 ~a" metacarpal)))
     ,(finger-geom proximal)
     (joint (@ (type "hinge") (axis "0 1 0") (limited "true") (range "-15 90")))
     (joint (@ (type "hinge") (axis "1 0 0") (limited "true") (range "-25 30")))
     (body
      (@ (pos ,(format #f "0 0 ~a" proximal)))
      ,(finger-geom middle)
      (joint (@ (name ,(string-append name "-pip")) (axis "0 1 0") (limited "true") (range "-5 120")))
      (body
       (@  (pos ,(format #f "0 0 ~a" middle)))
       ,(finger-geom distal)
       (joint (@ (name ,(string-append name "-dip")) (axis "0 1 0") (limited "true") (range "-5 90")))
       )))))

(define (dip-pip name)
  `(joint (@ (joint1 ,(string-append name "-dip")) (joint2 ,(string-append name "-pip")) (polycoef "0 0.66 0 0 0"))))

(sxml->xml
 `(mujoco
   (@ (model "Hand"))
   (compiler (@ (angle "degree")))
   (worldbody
    (body
     (@ (pos "0 0.18 0") (axisangle "1 0 0 -8"))
     ,@(finger "index" 0.8 0.45 0.25 0.2))
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

   (equality ,@(map dip-pip '("index" "middle" "ring" "pinky"))
    )))
