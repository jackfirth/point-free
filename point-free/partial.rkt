#lang racket/base

(provide partial partialr)

(require racket/function
         racket/list
         racket/local
         racket/match)
(module+ test
  (require rackunit))

;; conventions used in this file:
;;  - `ks` means keywords.
;;  - `vs` means values associated with keywords.
;;  - If ks and vs are both in the same function, they should be
;;    the same length, and in the same order. The ith element of
;;    ks is associated with the ith element of vs. The same
;;    convention applies to ks1 and vs1, ks2 and vs2, and so on.
;;  - `as` or `bs` means by-position arguments

;; A ByPosArity is a procedure-arity?
;; An Arity is a Procedure that is only used for its arity

(define (keyword-apply^2 f ks1 vs1 ks2 vs2 as)
  (keyword-apply keyword-apply ks1 vs1
                 f ks2 vs2
                 (list as)))


;; ((partial f a ...) b ...)
;; =
;; (f a ... b ...)
(define partial
  (local
    [(define (partial f . as)
       ;; conceptually return
       ;; partial-f = (λ bs (apply f (append as bs)))
       ;; except that kw arguments to partial-f are also passed
       ;; to f
       (define (partial-f . bs)
         (apply f (append as bs)))

       (define (partial-f/kw ks2 vs2 . bs)
         (keyword-apply f ks2 vs2 (append as bs)))

       (unless (arity-prefix? f (length as) '())
         (raise-too-many-partial-arguments-error f '() '() as))

       (arity-subtract
        f (length as) '()
        (make-keyword-procedure partial-f/kw partial-f)))

     (define (partial/kw ks1 vs1 f . as)
       ;; conceptually return
       ;; partial-f = (λ bs (kw-apply f ks1 vs1 (append as bs)))
       ;; except that kw arguments to partial-f are also passed
       ;; to f
       (define (partial-f . bs)
         (keyword-apply f ks1 vs1 (append as bs)))

       (define (partial-f/kw ks2 vs2 . bs)
         (keyword-apply^2 f ks1 vs1 ks2 vs2 (append as bs)))

       (unless (arity-prefix? f (length as) ks1)
         (raise-too-many-partial-arguments-error f ks1 vs1 as))

       (arity-subtract
        f (length as) ks1
        (make-keyword-procedure partial-f/kw partial-f)))]

    (make-keyword-procedure partial/kw partial)))

;; ((partialr f b ...) a ...)
;; =
;; (f a ... b ...)
(define partialr
  (local
    [(define (partialr f . bs)
       ;; conceptually return
       ;; partial-f = (λ bs (apply f (append bs as)))
       ;; except that kw arguments to partial-f are also passed
       ;; to f
       (define (partial-f . as)
         (apply f (append as bs)))

       (define (partial-f/kw ks2 vs2 . as)
         (keyword-apply f ks2 vs2 (append as bs)))

       (unless (arity-prefix? f (length bs) '())
         (raise-too-many-partial-arguments-error f '() '() bs))

       (arity-subtract
        f (length bs) '()
        (make-keyword-procedure partial-f/kw partial-f)))

     (define (partialr/kw ks1 vs1 f . bs)
       ;; conceptually return
       ;; partial-f = (λ bs (kw-apply f ks1 vs1 (append bs as)))
       ;; except that kw arguments to partial-f are also passed
       ;; to f
       (define (partial-f . as)
         (keyword-apply f ks1 vs1 (append as bs)))

       (define (partial-f/kw ks2 vs2 . as)
         (keyword-apply^2 f ks2 vs2 ks1 vs1 (append as bs)))

       (unless (arity-prefix? f (length bs) ks1)
         (raise-too-many-partial-arguments-error f ks1 vs1 bs))

       (arity-subtract
        f (length bs) ks1
        (make-keyword-procedure partial-f/kw partial-f)))]

    (make-keyword-procedure partialr/kw partialr)))

;; --------------------------------------------------------------

;; Checking and Fixing Arity

;; Arity Natural [Listof Keyword] -> Boolean
;; the function arr is only used for its arity
;; checks than the pre-n and pre-ks are a possible prefix of the
;; arguments to arr
(define (arity-prefix? arr pre-n pre-ks)
  (define n (procedure-arity arr))
  (define-values [req-ks all-ks] (procedure-keywords arr))

  (and
   (arr-prefix? n pre-n)
   (for/and ([pre-k (in-list pre-ks)])
     (member pre-k all-ks))))

;; ByPosArity Natural -> Boolean
(define (arr-prefix? n pre-n)
  (match n
    [(? integer? n)     (<= pre-n n)]
    [(arity-at-least n) #true]
    [(list ns ...)
     (for/or ([n (in-list ns)])
       (arr-prefix? n pre-n))]))

;; Arity Natural [Listof Keyword] Procedure -> Procedure
;; the function arr is only used for its arity
;; reduces the arity of f to (arr - sub-n - sub-ks)
(define (arity-subtract arr sub-n sub-ks f)
  (define n (procedure-arity arr))
  (define-values [req-ks all-ks] (procedure-keywords arr))

  (procedure-reduce-keyword-arity
   f
   (arr-subtract n sub-n)
   (remove* sub-ks req-ks)
   (remove* sub-ks all-ks)))

;; ByPosArity Natural -> ByPosArity
(define (arr-subtract n sub-n)
  (match n
    [(? integer? n)     (if (<= sub-n n) (- n sub-n) '())]
    [(arity-at-least n) (arity-at-least (max 0 (- n sub-n)))]
    [(list ns ...)
     (normalize-arity
      (flatten
       (for/list ([n (in-list ns)])
         (arr-subtract n sub-n))))]))

;; --------------------------------------------------------------

;; Error Messages

(define (raise-too-many-partial-arguments-error f ks vs as)
  (error 'partial
         (string-append "too many arguments\n"
                        "  function:          ~v\n"
                        "  partial arguments: ~a")
         f
         (kw-args->string ks vs as)))

(define (kw-args->string ks vs as)
  (define (string-append* . args)
    (apply string-append (flatten args)))
  (string-append*
   (for/list ([a (in-list as)])
     (format "~v " a))
   (for/list ([k (in-list ks)] [v (in-list vs)])
     (format "~s ~v " k v))))

;; --------------------------------------------------------------

;; Tests

(module+ test
  (define-check (check-arity f n req-ks all-ks)
    (check-equal? (procedure-arity f) n)
    (define-values [f-req-ks f-all-ks] (procedure-keywords f))
    (check-equal? f-req-ks req-ks)
    (check-equal? f-all-ks all-ks))

  ;; If we tested against the variable-arity `+` there would
  ;; be no difference between `partial` and `curry`.
  (define (+* x y) (+ x y))

  (check-equal? ((partial +*) 1 2) 3)
  (check-equal? ((partial +* 1) 2) 3)
  (check-equal? ((partial +* 1 2)) 3)
  (check-exn #rx"too many arguments"
             (λ () (partial +* 1 2 3)))
  (check-equal? ((partial list) 1 2) (list 1 2))
  (check-equal? ((partial list 3) 4) (list 3 4))
  (check-equal? ((partial list 5 6)) (list 5 6))
  (check-equal? ((partialr list) 1 2) (list 1 2))
  (check-equal? ((partialr list 3) 4) (list 4 3))
  (check-equal? ((partialr list 5 6)) (list 5 6))

  ;; arity
  (check-arity (partial +*)     2 '() '())
  (check-arity (partial +* 1)   1 '() '())
  (check-arity (partial +* 1 2) 0 '() '())
  
  ;; keywords
  (test-case "partial with keywords"
    (define (KE #:m m #:v v)
      (* 1/2 m v v))
    (define (f #:a a #:b b #:c [c 0] #:d [d 0])
      (+ a b c d))

    (check-equal? ((partial KE) #:m 2 #:v 1) 1)
    (check-equal? ((partial KE #:m 2) #:v 1) 1)
    (check-equal? ((partial KE #:m 2 #:v 1)) 1)
    (check-exn #rx"too many arguments"
               (λ () (partial KE #:unexpected "turtle")))
    (check-equal? ((partial f) #:a 1 #:b 2 #:c 3) 6)
    (check-equal? ((partial f #:a 2) #:b 3 #:d 4) 9)
    (check-equal? ((partial f #:a 3 #:c 4) #:b 5) 12)
    (check-exn #rx"too many arguments"
               (λ () (partial f #:e "eeee")))

    ;; arity
    (check-arity (partial KE)             0 '(#:m #:v) '(#:m #:v))
    (check-arity (partial KE #:m 2)       0 '(#:v) '(#:v))
    (check-arity (partial KE #:v 1)       0 '(#:m) '(#:m))
    (check-arity (partial KE #:m 2 #:v 1) 0 '() '())
    (check-arity (partial f)             0 '(#:a #:b) '(#:a #:b #:c #:d))
    (check-arity (partial f #:a 1)       0 '(#:b)     '(#:b #:c #:d))
    (check-arity (partial f #:c 3)       0 '(#:a #:b) '(#:a #:b #:d))
    (check-arity (partial f #:a 1 #:b 2) 0 '()        '(#:c #:d))
    (check-arity (partial f #:a 1 #:c 3) 0 '(#:b)     '(#:b #:d))
    (check-arity (partial f #:b 2 #:d 4) 0 '(#:a)     '(#:a #:c))
    (check-arity (partial f #:c 3 #:d 4) 0 '(#:a #:b) '(#:a #:b))
    ))
