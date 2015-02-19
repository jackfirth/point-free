#lang racket

(require rackunit)

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

(module+ test
  (check-eqv? (app + 2 3) 5))

;; Functions to only get one value form a function that returns multiple values

(define ((value-ref n) . vs) (list-ref vs n))
(define first-value (value-ref 0))
(define second-value (value-ref 1))
(define third-value (value-ref 2))

(module+ test
  (check-eqv? (first-value 1 2 3) 1)
  (check-eqv? (second-value 1 2 3) 2)
  (check-eqv? (third-value 1 2 3) 3)
  (check-eqv? ((value-ref 5) 0 1 2 3 4 5) 5))

;; Joining functions - composes functions in parallel

(define ((join . fs) . vs)     (apply values (map app fs vs)))
(define ((join* f) . vs)       (apply values (map f vs)))

(module+ test
  (define add1sub1 (join add1 sub1))
  (define add1sub1-first (compose first-value add1sub1))
  (define add1sub1-second (compose second-value add1sub1))
  (check-eqv? (add1sub1-first 0 0) 1)
  (check-eqv? (add1sub1-second 0 0) -1))

;; Winding functions - composes functions in series and parallel

(define (wind-pre f . gs)      (compose f (apply join gs)))
(define (wind-post f . gs)     (compose (apply join gs) f))
(define ((wind f . gs) . hs)   (apply wind-post (apply wind-pre f gs) hs))

(module+ test
  (define sym-num-append (wind-pre string-append symbol->string number->string))
  (check string=? (sym-num-append 'foo 12) "foo12")
  (define str-add1sub1 (wind-post add1sub1 number->string number->string))
  (define first-str-add1sub1 (compose first-value str-add1sub1))
  (define second-str-add1sub1 (compose second-value str-add1sub1))
  (check string=? (first-str-add1sub1 0 0) "1")
  (check string=? (second-str-add1sub1 0 0) "-1")
  (define length-sym-num-append ((wind string-append symbol->string number->string) string-length))
  (check-eqv? (length-sym-num-append 'foo 12) 5))

(define (wind-pre* f g)        (compose f (join* g)))
(define (wind-post* f g)       (compose (join* g) f))
(define (wind* f g h)          (wind-post* (wind-pre* f g) h))

(module+ test
  (define append-nums (wind-pre* string-append number->string))
  (check string=? (append-nums 10 20 30) "102030")
  (define str-add1sub1* (wind-post* add1sub1 number->string))
  (define first-str-add1sub1* (compose first-value str-add1sub1*))
  (define second-str-add1sub1* (compose second-value str-add1sub1*))
  (check string=? (first-str-add1sub1* 0 0) "1")
  (check string=? (second-str-add1sub1* 0 0) "-1"))