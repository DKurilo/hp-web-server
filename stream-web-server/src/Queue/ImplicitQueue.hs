module Queue.ImplicitQueue
    ( ImplicitQueue (..) ) where

import           Prelude     hiding (head, tail)
import           Queue.Queue

data Digit a = Zero | One a | Two a a
data ImplicitQueue a = Shallow (Digit a)
                     | Deep (Digit a) (ImplicitQueue (a, a)) (Digit a)

instance Queue ImplicitQueue where
    empty = Shallow Zero
    isEmpty (Shallow Zero) = True
    isEmpty _              = False

    snoc (Shallow Zero) y      = Shallow (One y)
    snoc (Shallow (One x)) y   = Deep (Two x y) empty Zero
    snoc (Deep f m Zero) y     = Deep f m (One y)
    snoc (Deep  f m (One x)) y = Deep f (snoc m (x, y)) Zero

    head (Shallow Zero)       = Nothing
    head (Shallow (One x))    = Just x
    head (Deep (One x) m r)   = Just x
    head (Deep (Two x y) m r) = Just x

    tail (Shallow Zero) = Nothing
    tail (Shallow (One x)) = Just empty
    tail (Deep (Two x y) m r) = Just $ Deep (One y) m r
    tail (Deep (One x) m r)
        | isEmpty m = Just $ Shallow r
        | otherwise = Just $ Deep (Two y z) m' r
        where (Just (y,z)) = head m
              (Just m') = tail m
