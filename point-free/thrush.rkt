#lang racket

(provide thrush
         thrush1
         thrush*
         define/thrush
         ~>
         λ~>
         ~>*)

(define (thrush . fs)
  (apply compose (reverse fs)))

(define (thrush1 v . fs)
  ((apply thrush fs) v))

(define ((thrush* . vs) . fs)
  (apply (apply thrush fs) vs))

(define-syntax-rule (define/thrush id expr ...)
  (define id (thrush expr ...)))

(define λ~> thrush)
(define ~> thrush1)
(define ~>* thrush*)