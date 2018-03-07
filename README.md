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

There is a "map" over a constructor:

``` haskell
> $(mapCaseOf 'Left) succ (Left 3)
Left 4
```

There is a combinator which calls your function with n arguments, or
passes the whole value to an "else" clause.

``` haskell
> $(caseOf 'Woo) (\x y -> show x ++ show y) (const "") (Wibble 5)
""
```

## Use in your project

In your stack.yaml, put:

```
extra-deps:
- git: https://github.com/chrisdone/caseof.git
  commit: 9a7f6bb
```

## Lens prisms

For me, the `lens` approach (aside from being a big dependency) has
these downsides: a complicated set of types and a requirement to
derive prisms for the types, which enter the namespace. The downside
for `caseof` is the TH requirement, but it is dead simple. You just
read this README in 20 seconds.
