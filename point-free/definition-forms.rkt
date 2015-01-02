#lang racket

(provide define/wind
         define/wind-pre
         define/wind-post
         define/wind*
         define/wind-pre*
         define/wind-post*)

(require "parallel.composition.rkt")

;; Helper macro for defining lots of simple macros
(define-syntax-rule (define-syntaxes-rule [pattern expansion] ...)
  (begin (define-syntax-rule pattern expansion) ...))

;; Definition forms
(define-syntaxes-rule
  [(define/wind id f (pre ...) (post ...))    (define id ((wind f pre ...) post ...))]
  [(define/wind-pre id f pre ...)             (define id (wind-pre f pre ...))]
  [(define/wind-post id f post ...)           (define id (wind-post f post ...))]
  [(define/wind* id f pre post)               (define id (wind* f pre post))]
  [(define/wind-pre* id f pre)                (define id (wind-pre* f pre))]
  [(define/wind-post* id f post)              (define id (wind-post* f post))])