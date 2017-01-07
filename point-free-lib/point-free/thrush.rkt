#lang racket/base

(provide thrush
         thrush+
         thrush*
         define/thrush
         thrush-and
         thrush+-and
         thrush*-and
         define/thrush-and
         (rename-out [thrush λ~>]
                     [thrush+ ~>]
                     [thrush* ~>*]
                     [thrush-and λand~>]
                     [thrush+-and and~>]
                     [thrush*-and and~>*]))

(module+ test
  (require rackunit))

(define (thrush . fs)
  (apply compose (reverse fs)))

(module+ test
  (define symbol-length-even? (thrush symbol->string string-length even?))
  (check-true (symbol-length-even? 'blah))
  (check-false (symbol-length-even? 'foo)))

(define (thrush+ v . fs)
  ((apply thrush fs) v))

(module+ test
  (check-true (thrush+ 'blah symbol->string string-length even?))
  (check-false (thrush+ 'foo symbol->string string-length even?)))

(define ((thrush* . vs) . fs)
  (apply (apply thrush fs) vs))

(module+ test
  (check string=? ((thrush* 2 3 4) * - number->string) "-24"))

(define-syntax-rule (define/thrush id expr ...)
  (define id (thrush expr ...)))

(define (thrush-and . fs)
  (define ((apply-and f) v)
    (and v (f v)))
  (apply compose1 (map apply-and (reverse fs))))

(module+ test
  (define (find-odd lst) (findf odd? lst))
  (define inc-odd (thrush-and find-odd add1))
  (check-equal? (inc-odd '(2 3 4)) 4)
  (check-equal? (inc-odd '(2 4 6)) #f))

(define (thrush+-and v . fs)
  ((apply thrush-and fs) v))

(define ((thrush*-and . vs) . fs)
  (apply (apply thrush-and fs) vs))

(define-syntax-rule (define/thrush-and id expr ...)
  (define id (thrush-and expr ...)))
