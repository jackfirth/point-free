#lang scribble/manual

@(require scribble/eval
          (for-label point-free
                     racket/base
                     racket/contract
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

The @hyperlink["https://en.wikipedia.org/wiki/To_Mock_a_Mockingbird"]{@italic{thrush combinator}} is a higher order function that
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
    ((thrush + even?) 1 2 3)
    ((thrush string->list length even?) "foo")
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

@deftogether[(@defproc[(thrush-and [f procedure?] ...) procedure?]
              @defproc[(λand~> [f procedure?] ...) procedure?])]{
  Like @racket[thrush], performs reverse function composition. However, @racket[thrush-and] includes
  the short-circuiting behavior of @racket[and], so if any intermediate function returns @racket[#f],
  the entire chain returns @racket[#f] without continuing to thread the value through the chain.
  @examples[#:eval the-eval
    (define find-odd (curry findf odd?))
    ((thrush-and find-odd add1) '(2 3 4))
    ((thrush-and find-odd add1) '(2 4 6))
    ]}

@deftogether[(@defproc[(thrush+-and [v any/c] [f procedure?] ...) any]
              @defproc[(and~> [v any/c] [f procedure?] ...) any]
              @defproc[((thrush*-and [v any/c] ...) [f procedure?] ...) any]
              @defproc[((and~>* [v any/c] ...) [f procedure?] ...) any])]{
  Like @racket[thrush+] and @racket[thrush*], but with the short-circuiting behavior of
  @racket[thrush-and].}

@section{Define forms of function composition}

@defform[(define/compose name func-expr ...)]{
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

@defform[(define/thrush-and name func-expr ...)]{
  Defines @racket[name] as the result of @racket[(thrush-and func-expr ...)].
  @examples[#:eval the-eval
    (define/thrush-and inc-odd (curry findf odd?) add1)
    (inc-odd '(2 3 4))
    (inc-odd '(2 4 6))
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

@defproc[((wind [f procedure?]
                [g (-> any/c any/c)] ...)
          [h (-> any/c any/c)] ...)
         procedure?]{
  Combination of @racket[wind-pre] and @racket[wind-post]. The procedures in @racket[g]s
  are used to transform the @italic{inputs} to @racket[f], and the @italic{outputs} are
  transformed with @racket[h]s. This function is defined with partial application, the
  input transformer functions are given first, then the output ones, then finally the
  wound function is returned.
  @examples[#:eval the-eval
    (define (sqr x) (* x x))
    (define pythagoras ((wind + sqr sqr) sqrt))
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
    (define string< (wind-pre* < string-length))
    (string< "foo" "barrr" "bazzzzz")
    (string< "foooooo" "barrr" "baz")
    ]}

@defproc[(wind-post* [f procedure?] [g (-> any/c any/c)]) procedure?]{
  Analog of @racket[wind-post] using @racket[join*] instead of @racket[join], returns a
  new procedure that first calls @racket[f] with its arguments, then maps @racket[g] to
  the resulting values and returns the mapped values. Equivalent to
  @racket[(compose (join* g) f)].
  @examples[#:eval the-eval
    (define partition-counts (wind-post* partition length))
    (partition-counts symbol? '(a b 1 2 3 4 5 c 5 7 8 d 8 e))
    (partition-counts even? '(1 2 3 4 5 6 7 8 9 10))
    ]}

@defproc[(wind* [f procedure?]
                [g (-> any/c any/c)]
                [h (-> any/c any/c)])
         procedure?]{
  Analog of @racket[wind] using @racket[join*] instead of @racket[join], returns a new
  procedure that first maps @racket[g] to its inputs, passes the mapped values to @racket[f],
  maps @racket[h] to the outputs of @racket[f], then returns those mapped values. Equivalent
  to @racket[(compose (join* h) f (join* g))].
  @examples[#:eval the-eval
    (define str-append (wind* append string->list list->string))
    (str-append "foo" "bar" "baz")
    ]}

@section{Definition forms of winding functions}

These forms allow for short definitions of point-free functions using @racket[wind] and friends.

@defform[(define/wind id f (pre ...) (post ...))]{
  Definition form of @racket[wind]. Binds @racket[id] as a wound form of @racket[f], with @racket[(pre ...)]
  used as the input transforming functions and @racket[(post ...)] used as the output transformers.
  @examples[#:eval the-eval
    (define/wind pythagoras + (sqr sqr) (sqrt))
    (pythagoras 3 4)
    (pythagoras 5 12)
    ]}

@defform[(define/wind-pre id f pre ...)]{
  Definition form of @racket[wind-pre]. Binds @racket[id] as a wound form of @racket[f], with @racket[(pre ...)]
  used as the input transforming functions.
  @examples[#:eval the-eval
    (define/wind-pre sym-and-num->str
      string-append symbol->string number->string)
    (sym-and-num->str 'foo 123)
    ]}

@defform[(define/wind-post id f post ...)]{
  Definition form of @racket[wind-post]. Binds @racket[id] as a wound form of @racket[f], with @racket[(post ...)]
  used as the output transforming functions.
  @examples[#:eval the-eval
    (define/wind-post first-true-last-false partition first last)
    (first-true-last-false symbol? '(1 2 a b 3 c 4 5 6 d))
    ]}

@defform[(define/wind* id f pre post)]{
  Definition form of @racket[wind*]. Binds @racket[id] as a wound form of @racket[f], with @racket[pre] used as
  the input transforming function and @racket[post] as the output transformer.
  @examples[#:eval the-eval
    (define/wind* pythagoras + sqr sqrt)
    (pythagoras 3 4)
    (pythagoras 5 12)
    ]}

@defform[(define/wind-pre* f pre)]{
  Definition form of @racket[wind-pre*]. Binds @racket[id] as a wound form of @racket[f], with @racket[post] used
  as the input transforming function.
  @examples[#:eval the-eval
    (define/wind-pre* symbol-shorter
      < (λ~> symbol->string string-length))
    (symbol-shorter 'foo 'bazz 'barrr)
    (symbol-shorter 'blah 'bloo)
    ]}

@defform[(define/wind-post* f post)]{
  Definition form of @racket[wind-post*]. Binds @racket[id] as a wound form of @racket[f], with @racket[post] used
  as the output transforming function.
  @examples[#:eval the-eval
    (define/wind-post* firstf partition first)
    (firstf symbol? '(1 2 3 a b 4 5 c 6 d e))
    ]}

@section{Fixpoint functions}

These functions manipulate other functions based on their @italic{fixpoints} - the values that can be given to the
function such that the function does nothing and returns just those values. The fixpoints of the function @racket[abs]
for example, are all nonnegative numbers. The absolute value of a nonnegative number @code{x} is just @racket{x}.

@defproc[(fixpoint? [f (-> any/c any/c)] [v any/c]) boolean?]{
  Returns @racket[#t] if @racket[v] is a fixpoint of @racket[f], that is if @racket[(f v)] is @racket[eq?] to
  @racket[v]. This function must necessarily call @racket[f], so avoid using side-effecting functions and expensive
  functions unless they memoize or cache their calls.
  @examples[#:eval the-eval
    (fixpoint? abs 10)
    (fixpoint? abs -10)
    ]}

@defproc[((until-fixpoint [f (-> any/c any/c)]) [v any/c]) any]{
  Returns a procedure that accepts one argument @racket[v] and applies @racket[f] to it. If @racket[v] is not a
  fixpoint of @racket[f], then @racket[f] is applied to @racket[(f v)], and again and again recursively until it
  reaches a value that is a fixpoint of @racket[f].
  @examples[#:eval the-eval
    (define (count-once-to-ten n)
      (if (< n 10)
          (begin (displayln n)
                 (add1 n))
          n))
    (count-once-to-ten 5)
    (define count-to-ten (until-fixpoint count-once-to-ten))
    (count-to-ten 5)
    ]}

@section{Partially Applying Functions}

@defproc[((partial [f (-> A ... B ... C)] [a A] ...) [b B] ...)
         C]{
  Partially applies @racket[f] with a prefix of its arguments,
  including keyword arguments.

  @examples[#:eval the-eval
    (define lstab (partial list 'a 'b))
    (lstab)
    (lstab 1 2 3)
    (define (f #:a a #:b b #:c [c 0] #:d [d 0])
      (+ a b c d))
    (define fac (partial f #:a 1 #:c 2))
    (fac #:b 3)
    (fac #:b 4 #:d 5)
    (procedure-keywords f)
    (procedure-keywords fac)
  ]}

@defproc[((partialr [f (-> A ... B ... C)] [b B] ...) [A A] ...)
         C]{
  Partially applies @racket[f] with a postfix of its arguments,
  including keyword arguments.

  @examples[#:eval the-eval
    (define lstab (partialr list 'a 'b))
    (lstab)
    (lstab 1 2 3)
  ]}

