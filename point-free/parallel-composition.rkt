#lang racket

(provide    join    join*
            
            wind-pre     wind-post     wind
            wind-pre*    wind-post*    wind*
            
            define/wind     define/wind-pre     define/wind-post
            define/wind*    define/wind-pre*    define/wind-post*)

;; Helper macro for defining lots of simple macros
(define-syntax-rule (define-syntaxes-rule [pattern expansion] ...)
  (begin (define-syntax-rule pattern expansion) ...))

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

;; Definition forms
(define-syntaxes-rule
  [(define/wind id f (pre ...) (post ...))    (define id ((wind f pre ...) post ...))]
  [(define/wind-pre id f pre ...)             (define id (wind-pre f pre ...))]
  [(define/wind-post id f post ...)           (define id (wind-post f post ...))]
  [(define/wind* id f pre post)               (define id (wind* f pre post))]
  [(define/wind-pre* id f pre)                (define id (wind-pre* f pre))]
  [(define/wind-post* id f post)              (define id (wind-post* f post))])