{-# LANGUAGE OverloadedStrings #-}
module Consumer
  ( Consumer.runConsumer
  , parseMessage
  , parseWord
  ) where

import           Control.Exception (bracket)
import           Control.Monad     (forever, join, liftM2, (>>=))
import qualified Data.ByteString   as B
import           Data.Word8        (isSpace)
import           Kafka.Consumer
import           Types

-- consumer properties
consumerProps :: BrokerAddress -> ConsumerGroupId -> ConsumerProperties
consumerProps a g = brokersList [a]
                 <> groupId g
                 <> noAutoCommit
                 <> logLevel KafkaLogInfo

-- Subscription to topics
consumerSub :: BuilderTopic -> Subscription
consumerSub t = topics [TopicName t]
           <> offsetReset Earliest

runConsumer :: BrokerAddress -> ConsumerGroupId -> BuilderTopic -> (InputMessage -> IO ()) -> IO ()
runConsumer a g t sender = do
    res <- bracket mkConsumer clConsumer runHandler
    print res
    where
      mkConsumer = newConsumer (consumerProps a g) (consumerSub t)
      clConsumer (Left err) = return (Left err)
      clConsumer (Right kc) = maybe (Right ()) Left <$> closeConsumer kc
      runHandler (Left err) = return (Left err)
      runHandler (Right kc) = processMessages sender kc

-------------------------------------------------------------------
processMessages ::  (InputMessage -> IO ()) -> KafkaConsumer -> IO (Either KafkaError ())
processMessages sender kafka = do
    forever $ do
      ekmsg <- pollMessage kafka (Timeout 1000)
      _ <- case ekmsg of
             Left err -> print err
             Right kmsg -> case crValue kmsg of
                   Just msg -> sender msg
                   Nothing  -> putStrLn "Wrong message"
      _ <- commitAllOffsets OffsetCommit kafka
      return ()
    return $ Right ()

parseMessage :: InputMessage -> Maybe ParsedMessage
parseMessage message = do
  let (mbtopic, m1) = parseWord message
  topic <- mbtopic
  let (mbsessionid, m2) = parseWord . B.tail $ m1
  sessionid <- mbsessionid
  let (mburi, m3) = parseWord . B.tail $ m2
  uri <- mburi
  let (mbmethod, body) = parseWord . B.tail $ m3
  method <- mbmethod
  return $ pmtopic topic <> pmsessionid sessionid <> pmuri uri <> pmmethod method <> (pmbody . B.tail) body

parseWord :: InputMessage -> (Maybe B.ByteString, InputMessage)
parseWord im
  | B.null im' = (Nothing, "")
  | otherwise = (Just topic, im')
  where (topic, im') = B.break isSpace im
