#lang racket/base

(provide until-fixpoint
         fixpoint?)

(module+ test
  (require rackunit))

(define (until-fixpoint f)
  (define (fixpoint-f v)
    (let ([fv (f v)])
      (if (eq? fv v)
          fv
          (fixpoint-f fv))))
  fixpoint-f)

(module+ test
  (define (f x)
    (if (zero? (modulo x 3))
        x
        (sub1 x)))
  (define fixpoint-f (until-fixpoint f))
  (check-eqv? (fixpoint-f 3) 3)
  (check-eqv? (fixpoint-f 10) 9)
  (check-eqv? (fixpoint-f 20) 18))

(define (fixpoint? f v)
  (eq? (f v) v))

(module+ test
  (check-true (fixpoint? abs 10))
  (check-false (fixpoint? abs -10)))