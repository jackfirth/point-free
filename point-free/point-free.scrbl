#lang scribble/manual

@(require scribble/eval
          (for-label "main.rkt"))

@title{point-free}

@(define the-eval (make-base-eval))
@(the-eval '(require "main.rkt"))

@defmodule[point-free]

@author[@author+email["Jack Firth" "jackhfirth@gmail.com"]]

Tools for defining point-free functions with very little
syntactic overhead.

source code: @url["https://github.com/jackfirth/point-free"]

@section{thrush}

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

@deftogether[(@defproc[(thrush+ [v any?] [f procedure?] ...) procedure?]
              @defproc[(~> [v any?] [f procedure?] ...) procedure?])]{
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