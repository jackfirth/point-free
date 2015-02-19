#lang racket


(require rackunit)

(provide thrush
         thrush+
         thrush*
         define/thrush
         ~>
         λ~>
         ~>*)

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

(define λ~> thrush)
(define ~> thrush+)
(define ~>* thrush*)