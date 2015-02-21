#lang racket

(require scribble/xref
         setup/xref
         racket/syntax
         rackunit
         point-free)

(provide module->all-exported-names
         module->documented-exported-names
         module->undocumented-exported-names
         has-docs?)

;; The funcitons used here to list module documentation
;; info should be in their own seperate package ideally.
;; Once that's done, they'll be tested/expanded there.

(define xref (load-collections-xref))

(define (phase-exported-names phase-exports)
  (map first phase-exports))

(define (phase-exports->names exports)
  (map first
       (apply append (map (curryr drop 1) exports))))

(define (module->all-exported-names mod)
  (let-values ([(exp-values exp-syntax) (module->exports mod)])
    (append (phase-exports->names exp-values)
            (phase-exports->names exp-syntax))))

(define (has-docs? mod binding)
  (not (not (xref-binding->definition-tag xref (list mod binding) #f))))

(define (module->documented-exported-names mod)
  (filter (curry has-docs? mod)
          (module->all-exported-names mod)))

(define (module->undocumented-exported-names mod)
  (filter-not (curry has-docs? mod)
              (module->all-exported-names mod)))

(define module-num-exports (compose length module->all-exported-names))
(define module-num-documented-exports (compose length module->documented-exported-names))
(define module-num-undocumented-exports (compose length module->undocumented-exported-names))

(define (module-documentation% mod)
  (/ (module-num-documented-exports mod)
     (module-num-undocumented-exports mod)))

(check-pred zero? (module-num-undocumented-exports 'point-free))