point-free
==========

Collection of forms and higher order functions that assist function composition and definition of functions in a point-free style. Point-free functions are functions that don't name your arguments, they're created purely by composing other functions. For example:

    (define number->symbol (compose symbol->string number->string))

Racket functions have symmetry between output and input values. This means that functions can accept multiple values and return multiple output values. This makes point-free functions more difficult to define, because regular function composition can be unwieldy. Contrast this to a language like Haskell, where functions can only accept and return one value.

There are two ways to compose two functions of one input and one output `f` and `g`. You can chain the output of `g` to the input of `f` with standard function composition, as in `(compose f g)`. However, you can also make a function that accepts two values, gives one to `f` and one to `g`, and returns both outputs as two values. Basically, functions can be composed in *series* or in *parallel*.

This package defines several convenient ways of composing functions to make point-free logic clean and simple to express. Composing functions in parallel can be down with the `join` function:

    (define add1-sub1 (join add1 sub1))
    (add1-sub1 10 10) ;; evaluates to (values 11 9)

The function `join*` takes a function and joins it with itself repeatedly

    (define add1-each (join* add1))
    (add1-each 1 2 3) ;; evaluates to (values 2 3 4)

On its own this function is rarely useful, but it can be combined elegantly with `compose`. Here's a point-free function that finds the hypotenuse of a right triangle (with `sqr` being a function that squares a number)

    (define pythagoras (compose sqrt + (join* sqr)))
    (pythagoras 3 4) ;; evaluates to 5
    (pythagoras 5 12) ;; evaluates to 13

Another included primitive composition function is `thrush`, which is the reverse of `compose` - the first function given to `thrush` gets inputs first, then gives its output to the second, which gives its output to the third, etc.:

    (define symbol-length-even?
      (thrush symbol->string
              string->number
              even?))
    (symbol-length-even? 'foo) ;; #f
    (symbol-length-even? 'barbaz) ;; #t

Some functions that combine these primitive composition operators together are included, including `wind*`, which takes three functions and essentially "wraps" the first function - all inputs to it are transformed with the second function, and all outputs from the first are transformed with the third:

    (define pythagoras (wind* + sqr sqrt))
    (pythagoras 3 4) ;; evaluates to 5
    (pythagoras 5 12) ;; evaluates to 13

Variations on this function are also provided, as well as a more general `wind` function that can transform different inputs and outputs to the wound function with different transformer functions.

A few macros for defining point-free functions with these composition operators are also included:

    (define/compose first-even?
      even? first)
    (define/thrush symbol-length-even?
      symbol->string string->number even?)
    (define/wind* pythagoras
      + sqr sqrt)
    
    (first-even? '(2 3 4)) ;; #t
    (symbol-length-even? 'foo) ;; #f
    (pythagoras? 3 4) ;; 5

This package also supplies a way to compose functions that know how many arguments they have. The `arg-count` form takes an expression that produces a function and an identifier, and binds that identifier to contain the number of arguments given to the produced function in the expression:

    (define num-args-received
      (arg-count n (const n)))
    (num-args-received 'foo 'bar 'baz) ;; evaluates to 3

A definition form is also included:

    (define/arg-count num-args-received n
      (const n))

Combining this with syntax extensions for defining anonymous functions such as [`fancy-app`](https://github.com/samth/fancy-app) yields very succinct function definitions:

    (define/arg-count average n
      (compose (/ _ n) +))
    (average 8 10 12) ;; evaluates to 10

This package can be installed by running `raco pkg install point-free`, and can be used in a module with `(require point-free)`.
