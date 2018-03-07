{-# OPTIONS_GHC -fno-warn-type-defaults #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TemplateHaskell #-}

-- | Template-Haskell-based combinators that let you select on constructors.

module CaseOf
  (isCaseOf
  ,maybeCaseOf
  ,mapCaseOf
  ,caseOf)
  where

import Language.Haskell.TH
import Language.Haskell.TH.Syntax

-- | Create a predicate that returns true if its argument is the given constructor.
isCaseOf :: Name -> Q Exp
isCaseOf input = do
  name <- nameAsValue input
  pure
    (LamCaseE
       [ Match (RecP name []) (NormalB (ConE 'True)) []
       , Match WildP (NormalB (ConE 'False)) []
       ])

-- | Return Just (x, y, ..) for the constructor C x y .., or Nothing.
maybeCaseOf :: Name -> Q Exp
maybeCaseOf input = do
  name <- nameAsValue input
  info <- reify name
  case info of
    DataConI _ ty _ ->
      pure
        (LamCaseE
           [ Match
               (ConP name (map patI [1 .. arity ty]))
               (NormalB (AppE (ConE 'Just) (TupE (map varI [1 .. arity ty]))))
               []
           , Match WildP (NormalB (ConE 'Nothing)) []
           ])
    _ -> fail ("Invalid data constructor " ++ pprint input)
  where
    varI i = VarE (mkName ("v" ++ show i))
    patI i = VarP (mkName ("v" ++ show i))
    arity (ForallT _ _ t) = arity t
    arity (AppT (AppT ArrowT _) y) = 1 + arity y
    arity _ = 0

-- | Apply a function to the slots of a constructor, if it matches,
-- otherwise identity.
mapCaseOf :: Name -> Q Exp
mapCaseOf input = do
  name <- nameAsValue input
  info <- reify name
  case info of
    DataConI _ ty _ ->
      pure
        (LamE
           [VarP f]
           (LamCaseE
              [ Match
                  (ConP name (map patI [1 .. arity ty]))
                  (NormalB
                     (AppE
                        (ConE name)
                        (foldl AppE (VarE f) (map varI [1 .. arity ty]))))
                  []
              , Match (VarP this) (NormalB (VarE this)) []
              ]))
    _ -> fail ("Invalid data constructor " ++ pprint input)
  where
    f = mkName "f"
    this = mkName "this"
    varI i = VarE (mkName ("v" ++ show i))
    patI i = VarP (mkName ("v" ++ show i))
    arity (ForallT _ _ t) = arity t
    arity (AppT (AppT ArrowT _) y) = 1 + arity y
    arity _ = 0

-- | Call a function with arguments from the constructor if it
-- matches, or pass it to the wildcard function.
caseOf :: Name -> Q Exp
caseOf input = do
  name <- nameAsValue input
  info <- reify name
  case info of
    DataConI _ ty _ ->
      pure
        (LamE [VarP f, VarP nil]
           (LamCaseE
              [ Match
                  (ConP name (map patI [1 .. arity ty]))
                  (NormalB (foldl AppE (VarE f) (map varI [1 .. arity ty])))
                  []
              , Match (VarP this) (NormalB (AppE (VarE nil) (VarE this))) []
              ]))
    _ -> fail ("Invalid data constructor " ++ pprint input)
  where
    f = mkName "f"
    this = mkName "this"
    nil = mkName "nil"
    varI i = VarE (mkName ("v" ++ show i))
    patI i = VarP (mkName ("v" ++ show i))
    arity (ForallT _ _ t) = arity t
    arity (AppT (AppT ArrowT _) y) = 1 + arity y
    arity _ = 0

-- | Return the name if it is a value constructor, otherwise lookup a
-- value name.
nameAsValue :: Name -> Q Name
nameAsValue name =
  if nameSpace name == Just DataName
    then pure name
    else do
      mname <- lookupValueName (nameBase name)
      case mname of
        Nothing -> fail ("Not in scope constructor " ++ pprint name)
        Just n -> pure n
