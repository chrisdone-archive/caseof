# caseof

A simple way to query constructors, like cases but slightly more
concise.

Aimed at sum types with many constructors:

``` haskell
data Wiggle = Woo Int Char | Wibble Int deriving Show
```

There is a case predicate:

``` haskell
> $(isCaseOf 'Woo) (Woo 5 'a')
True
```

There is a `Maybe`-based matcher:

``` haskell
> $(maybeCaseOf 'Woo) (Woo 1 'a')
Just (1,'a')
```

There is a combinator which calls your function with n arguments, or
passes the whole value to an "else" clause.

``` haskell
> $(caseOf 'Woo) (\x y -> show x ++ show y) (const "") (Wibble 5)
""
```

This allows them to be nested:

```haskell
> $(caseOf 'Woo) (\x y -> show x ++ show y) (const "") (Woo 5 'a')
"5'a'"
> $(caseOf 'Woo) (\x y -> show x ++ show y) ($(caseOf 'Wibble) show (const "")) (Woo 5 'a')
"5'a'"
```

What's the point of `caseOf`? To more easily dispatch on functions:

```haskell
handleHuman name age = ...
handleMachine id = ..
handleWithDefault def =
   $(caseOf 'Human) handleHuman .
   $(caseOf 'Machine) handleMachine def
```

This applies to any kind of "case" that you'd like to refactor into a function.

## Use in your project

In your stack.yaml, put:

```
extra-deps:
- git: https://github.com/chrisdone/caseof.git
  commit: 9a7f6bb
```
