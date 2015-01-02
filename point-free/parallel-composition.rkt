#lang racket

(provide join
         join*
         wind-pre
         wind-post
         wind
         wind-pre*
         wind-post*
         wind*)

;; Function form of flat application - (app + 2 3) is equivalent to (+ 2 3).
;; Used to simplify logic in joining functins

(define (app f . vs)           (apply f vs))

;; Joining functions - composes functions in parallel

(define ((join . fs) . vs)     (apply values (map app fs vs)))
(define ((join* f) . vs)       (apply values (map f vs)))

;; Winding functions - composes functions in series and parallel

(define (wind-pre f . gs)      (compose f (apply join gs)))
(define (wind-post f . gs)     (compose (apply join gs) f))
(define ((wind f . gs) . hs)   (apply wind-post (apply wind-pre f gs) hs))

(define (wind-pre* f g)        (compose f (join* g)))
(define (wind-post* f g)       (compose (join* g) f))
(define (wind* f g h)          (wind-post* (wind-pre* f g) h))