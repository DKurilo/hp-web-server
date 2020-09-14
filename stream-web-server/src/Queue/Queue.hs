module Queue.Queue (Queue(..), removeWhile) where

import           Prelude hiding (head, tail)

class Queue q where
    empty :: q a
    isEmpty :: q a -> Bool

    snoc :: q a -> a -> q a
    head :: q a -> Maybe a
    tail :: q a -> Maybe (q a)

removeWhile :: (Queue q) => (a -> Bool) -> q a -> ([a], q a)
removeWhile p q = case head q of
                    Just x | p x -> (x : xs, q'')
                    _            -> ([], q)
    where (Just q') = tail q
          (xs, q'') = removeWhile p q'
