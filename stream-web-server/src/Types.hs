module Types
  ( ServerTopic (..)
  , BuilderTopic (..)
  , Port(..)
  ) where

import           Data.Text (Text)

type ServerTopic = Text
type BuilderTopic = Text
type Port = Int
