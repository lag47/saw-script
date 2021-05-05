{- |
Module      : Verifier.SAW.Simulator.MonadLazy
Copyright   : Galois, Inc. 2012-2015
License     : BSD3
Maintainer  : huffman@galois.com
Stability   : experimental
Portability : non-portable (language extensions)
-}
module Verifier.SAW.Simulator.MonadLazy where

import Control.Monad (liftM)
import Control.Monad.IO.Class
import Data.IORef

newtype Lazy m a = Lazy (m a)

class MonadIO m => MonadLazy m where
  delay :: m a -> m (Lazy m a)

force :: Lazy m a -> m a
force (Lazy m) = m

ready :: Monad m => a -> Lazy m a
ready x = Lazy (return x)

instance MonadLazy IO where
  delay = delayIO

delayIO :: MonadIO m => m a -> m (Lazy m a)
delayIO m = liftM pull (liftIO (newIORef Nothing))
  where
    pull ref = Lazy $ do
      r <- liftIO (readIORef ref)
      case r of
        Nothing -> do
          x <- m
          liftIO (writeIORef ref (Just x))
          return x
        Just x -> return x
