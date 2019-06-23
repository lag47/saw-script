{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RankNTypes #-}

{- |
Module      : Verifier.SAW.Translation.Coq
Copyright   : Galois, Inc. 2018
License     : BSD3
Maintainer  : atomb@galois.com
Stability   : experimental
Portability : portable
-}

module Verifier.SAW.Translation.Coq.Monad where

import qualified Control.Monad.Except as Except
import Control.Monad.Reader hiding (fail)
import Control.Monad.State hiding (fail, state)
import Prelude hiding (fail)

import Verifier.SAW.SharedTerm
-- import Verifier.SAW.Term.CtxTerm
--import Verifier.SAW.Term.Pretty
-- import qualified Verifier.SAW.UntypedAST as Un

data TranslationError a
  = NotSupported a
  | NotExpr a
  | NotType a
  | LocalVarOutOfBounds a
  | BadTerm a

instance {-# OVERLAPPING #-} Show (TranslationError Term) where
  show = showError showTerm

instance {-# OVERLAPPABLE #-} Show a => Show (TranslationError a) where
  show = showError show

showError :: (a -> String) -> TranslationError a -> String
showError printer err = case err of
  NotSupported a -> "Not supported: " ++ printer a
  NotExpr a      -> "Expecting an expression term: " ++ printer a
  NotType a      -> "Expecting a type term: " ++ printer a
  LocalVarOutOfBounds a -> "Local variable reference is out of bounds: " ++ printer a
  BadTerm a -> "Malformed term: " ++ printer a

data TranslationConfiguration = TranslationConfiguration
  { translateVectorsAsCoqVectors :: Bool -- ^ when `False`, translate vectors as Coq lists
  , traverseConsts               :: Bool
  }

type TranslationMonad s m =
  ( Except.MonadError (TranslationError Term)  m
  , MonadReader       TranslationConfiguration m
  , MonadState        s                        m
  )

runTranslationMonad ::
  TranslationConfiguration ->
  s ->
  (forall m. TranslationMonad s m => m a) ->
  Either (TranslationError Term) (a, s)
runTranslationMonad configuration state m = runStateT (runReaderT m configuration) state
