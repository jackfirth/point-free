#lang scribble/manual

@(require scribble/eval
          (for-label "main.rkt"
                     racket/base
                     racket/function))

@title{point-free}

@(define the-eval (make-base-eval))
@(the-eval '(require "main.rkt"
                     racket/function))

@defmodule[point-free]

@author[@author+email["Jack Firth" "jackhfirth@gmail.com"]]

Tools for defining point-free functions with very little
syntactic overhead.

source code: @url["https://github.com/jackfirth/point-free"]

@section{Thrush Combinator}

The @italic{thrush combinator} is a higher order function that
reverses the order of application. It can be seen as the reverse
of function composition.

@deftogether[(@defproc[(thrush [f procedure?] ...) procedure?]
              @defproc[(λ~> [f procedure?] ...) procedure?])]{
  Returns a procedure that composes the given functions in a way that
  is the @italic{reverse} of using @racket[compose]. That is, the new
  procedure gives its arguments to the first @racket[f], which gives
  its result to the second @racket[f], and so on to the last @racket[f].
  The result of the last function is the result of the entire thrushed
  function application. This logic can be interpreted as representing
  a function as a data flow between the given procedures, since values
  given to the thrushed function flow from left to right through the
  given procedures. @racket[λ~>] is a shorthand, and means the
  same thing as the more literate @racket[thrush] form. Note that the
  thrushed procedure can accept multiple arguments if the first @racket[f]
  given to it does.
  @examples[#:eval the-eval
    ((thrush add1 positive?) 0)
    ((thrush string->list length even?) "foo")
    ((thrush + even?) 1 2 3)
    ]}

@deftogether[(@defproc[(thrush+ [v any?] [f procedure?] ...) any?]
              @defproc[(~> [v any?] [f procedure?] ...) any?])]{
  Returns the result of giving @racket[v] to @racket[(thrush f ...)].
  This is for expressing data-flow logic in a pointful manner rather
  than a point-free manner, in cases where constructing the intermediate
  thrushed procedure and applying it as two seperate instances would be
  awkward syntactically. This limits the thrushed procedure to only accept
  one argument. @racket[~>] is a shorthand, and means the same thing as
  the more literate @racket[thrush+] form.
  @examples[#:eval the-eval
    (thrush+ 0 add1 positive?)
    (thrush+ "foo" string->list length even?)
    (thrush+ 'foo symbol->string string-length)
    ]}

@deftogether[(@defproc[(thrush* [v any?] ...) (-> [f procedure?] ... any?)]
              @defproc[(~>* [v any?] ...) (-> [f procedure?] ... any?)])]{
  Returns a procedure that accepts procedures and composes them with @racket[thrush],
  then calls the thrushed procedure with @racket[v ...] as arguments. In essence,
  this flips the order of evaluation - the arguments to the composed function are
  given first, and the functions to compose are given second. @racket[~>*] is a
  shorthand, and means the same thing as the more literate @racket[thrush*] form.
  @examples[#:eval the-eval
    ((thrush* 1 2 3) + even?)
    ((thrush* "foo" "bar") string-append string-length)
    ]}

@section{Define forms of function composition}

@defform[(define/compose name func-expr)]{
  Defines @racket[name] as the result of @racket[(compose func-expr ...)].
  @examples[#:eval the-eval
    (define/compose symbol-length string-length symbol->string)
    (symbol-length 'foo)
    (symbol-length 'bazzz)
    ]}

@defform[(define/thrush name func-expr ...)]{
  Defines @racket[name] as the result of @racket[(thrush func-expr ...)].
  @examples[#:eval the-eval
    (define/thrush symbol-length symbol->string string-length)
    (symbol-length 'foo)
    (symbol-length 'bazzz)
    ]}

@section{Point-free argument counts}

These forms define ways to define anonymous functions in a point-free style while
binding a single variable that contains the number of arguments passed to the
function. This can be useful for removing boilerplate.

@defform[(arg-count n func-expr)]{
  Returns the function that @racket[func-expr] evaluates to, with @racket[n] bound
  in @racket[func-expr] to the number of arguments passed to the returned function.
  @examples[#:eval the-eval
    ((arg-count n (const n)) 'foo 'bar 'baz)
    ]}

@defform[(define/arg-count name n func-expr)]{
  Defines @racket[name] as the result of @racket[(arg-count n func-expr)].
  @examples[#:eval the-eval
    (define/arg-count average n
      (compose (curryr / n) +))
    (average 8 10 12)
    ]}

@section{Point-free parallel function composition}

Racket functions can accept and return any number of arguments, so there are two ways
to combine them - chaining them together in @italic{serial} with @racket[compose], or
joining them in @italic{parallel} with the @racket[join] function defined in this module.
These two primitives can be combined in powerful and expressive ways, making point-free
function definitions much easier for many cases.

@defproc[(join [f (-> any/c any/c)] ...) procedure?]{
  Returns a procedure that accepts one argument for each @racket[f], and returns one value
  for each @racket[f] that is determined by calling @racket[f] on its given argument. This
  can be thought of as joining the functions @racket[(f ...)] in parallel.
  @examples[#:eval the-eval
    ((join add1 sub1) 0 0)
    ((join string->symbol even?) "foo" 5)
    ]}