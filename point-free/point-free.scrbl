#lang scribble/manual

@(require scribble/eval
          (for-label "main.rkt"))

@title{point-free}

@defmodule[point-free]

@author[@author+email["Jack Firth" "jackhfirth@gmail.com"]]

Tools for defining point-free functions with very little
syntactic overhead.

source code: @url["https://github.com/jackfirth/point-free"]

@section{thrush}

The @italic{thrush combinator} is a higher order function that
reverses the order of application. It can be seen as the reverse
of function composition.