#lang scribble/manual

@(require scribble/eval
          (for-label "main.rkt"
                     racket/base
                     racket/function
                     racket/list))

@title{point-free}

@(define the-eval (make-base-eval))
@(the-eval '(require "main.rkt"
                     racket/function
                     racket/list))

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
function definitions much simpler in many cases. Note that this has absolutely nothing
to do with parallel execution or concurrency, this is purely a handy terminology for
talking about function operations.

@defproc[(join [f (-> any/c any/c)] ...) procedure?]{
  Returns a procedure that accepts one argument for each @racket[f], and returns one value
  for each @racket[f] that is determined by calling @racket[f] on its given argument. This
  can be thought of as joining the functions @racket[(f ...)] in parallel.
  @examples[#:eval the-eval
    ((join add1 sub1) 0 0)
    ((join string->symbol even?) "foo" 5)
    ]}

@defproc[(wind-pre [f procedure?] [g (-> any/c any/c)] ...) procedure?]{
  Returns a procedure that accepts one argument for each @racket[g], calls each @racket[g]
  on each argument, then passes the results of all the @racket[g]s to @racket[f]. The result
  of @racket[f] is then the result of the whole procedure. Conceptually, this is equivalent
  to @racket[(compose f (join g ...))].
  @examples[#:eval the-eval
    ((wind-pre < string-length symbol-length) "foo" 'bazz)
    ((wind-pre + string-length symbol-length) "foo" 'bazz)
    ]}

@defproc[(wind-post [f procedure?] [g (-> any/c any/c)] ...) procedure?]{
  Opposite of @racket[wind-pre], instead of calling each @racket[g] on the @italic{inputs}
  of @racket[f], each @racket[g] is called on the @italic{outputs} of @racket[f]. This is
  therefore equivalent to @racket[(compose (join g ...) f)].
  @examples[#:eval the-eval
    ((wind-post partition length length) number? '(1 2 3 a 4 5 6 "foo" 8))
    (define (first-and-second lst) (values (first lst) (second lst)))
    ((wind-post first-and-second string? number?) '(1 2 3 4 5))
    ]}

@defproc[(wind [f procedure?]
               [gs (listof (-> any/c any/c))]
               [hs (listof (-> any/c any/c))])
         procedure?]{
  Combination of @racket[wind-pre] and @racket[wind-post]. The procedures in @racket[gs]
  are used to transform the @italic{inputs} to @racket[f], and the @italic{outputs} are
  transformed with @racket[hs].
  @examples[#:eval the-eval
    (define pythagoras (wind + (list sqr sqr) (list sqrt)))
    (pythagoras 3 4)
    (pythagoras 5 12)
    ]}

@defproc[(join* [f (-> any/c any/c)]) procedure?]{
  Similar to @racket[join], but instead of accepting several functions and mapping them
  one-to-one with the inputs of the returned procedure, it accepts only one function and
  the returned procedure accepts any number of arguments, maps @racket[f] to each of them,
  then returns the results as values. Essentially a version of @racket[map] that returns
  multiple values instead of a list.
  @examples[#:eval the-eval
    ((join* add1) 1 2 3)
    ((join* symbol->string) 'foo 'bar)
    ]}

@defproc[(wind-pre* [f procedure?] [g (-> any/c any/c)]) procedure?]{
  Analog of @racket[wind-pre] using @racket[join*] instead of @racket[join], returns a
  new procedure that maps @racket[g] to each of its arguments, then returns the result
  of calling @racket[f] with those values. Equivalent to @racket[(compose f (join* g))].
  @examples[#:eval the-eval
    ((wind-pre* < string-length) "foo" "barrr")
    ((wind-pre* < string-length) "foooo" "bar")
    ]}

