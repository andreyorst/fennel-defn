# defn.fnl

Clojure's `defn` macro for Fennel.

## Installation

Quick way to add this dependency to your project is just to get the file directly into your project's source tree:

    curl -fsSL https://gitlab.com/andreyorst/fennel-defn/-/raw/main/defn.fnl -o defn.fnl

## Features

Some differences from Clojure probably exist, but overall the macro should be pretty similar to what you'd expect.

- support for `&` destructuring:
  ``` fennel
  (defn foo "docstring" [_ & xs] xs)
  ```
- Support for arity overloading:
  ``` fennel
  (defn add
    "adds arbitrary amount of numbers"
    ([] 0)
    ([a] a)
    ([a b] (+ a b))
    ([a b & cs]
     (add (+ a b) ((or _G.unpack table.unpack) cs))))
  ```
- Various compile-time checks:
  ``` fennel
  ;; Can't have same arity overloads
  (defn foo
    ([a] 1)
    ([b] 2))
  ;; Overloads must be sorted
  (defn foo
    ([a b] (+ a b))
    ([a] a))
  ;; Can't have more than one variadic overload
  (defn foo
    ([& a] a)
    ([a & b] b))
  ;; Lua-style variadic arglist is not allowed
  (defn foo [a b ...] ...)
  ```
- Proper documentation generation in the REPL:
  ``` fennel
  >> ,doc add
  (add ([]) ([a]) ([a b]) ([a b & cs]))
    adds arbitrary amount of numbers
  ```
