{-# LANGUAGE OverloadedStrings #-}
module Types
  ( BuilderTopic
  , InputMessage
  , Topic
  , SessionID
  , URI
  , Method
  , Body
  , PageBody
  , OutputMessage (..)
  , ParsedMessage (..)
  , PageBuilderId
  , KafkaMessage
  , KafkaKey
  , pmpagebuilderid
  , pmtopic
  , pmsessionid
  , pmuri
  , pmmethod
  , pmbody
  ) where

import           Data.ByteString (ByteString)
import           Data.Semigroup
import           Data.Text       (Text)

type InputMessage = ByteString

type BuilderTopic = Text

type PageBuilderId = ByteString

type Topic = ByteString
type SessionID = ByteString
type URI = ByteString
type Method = ByteString
type Body = ByteString
type PageBody = ByteString

data OutputMessage = OutputMessage { omTopic     :: Topic
                                   , omSessionId :: SessionID
                                   , omBody      :: PageBody
                                   }

data ParsedMessage = ParsedMessage { pmPageBuilderId :: PageBuilderId
                                   , pmTopic         :: Topic
                                   , pmSessionID     :: SessionID
                                   , pmURI           :: URI
                                   , pmMethod        :: Method
                                   , pmBody          :: Body
                                   } deriving (Show)

instance Semigroup ParsedMessage where
  x <> y = ParsedMessage (pmPageBuilderId x)
                         (pmTopic x <> pmTopic y)
                         (pmSessionID x <> pmSessionID y)
                         (pmURI x <> pmURI y)
                         (pmMethod x <> pmMethod y)
                         (pmBody x <> pmBody y)

instance Monoid ParsedMessage where
  mempty = ParsedMessage "" "" "" "" "" ""

pmpagebuilderid :: PageBuilderId -> ParsedMessage
pmpagebuilderid pb = ParsedMessage pb "" "" "" "" ""

pmtopic :: Topic -> ParsedMessage
pmtopic t = ParsedMessage "" t "" "" "" ""

pmsessionid :: SessionID -> ParsedMessage
pmsessionid s = ParsedMessage "" "" s "" "" ""

pmuri :: URI -> ParsedMessage
pmuri u = ParsedMessage "" "" "" u "" ""

pmmethod :: Method -> ParsedMessage
pmmethod m = ParsedMessage "" "" "" "" m ""

pmbody :: Body -> ParsedMessage
pmbody = ParsedMessage "" "" "" "" ""

type KafkaMessage = ByteString
type KafkaKey = ByteString
