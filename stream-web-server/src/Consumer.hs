{-# LANGUAGE OverloadedStrings #-}
module Consumer
    ( runResponderAsync
    ) where

import           Control.Exception     (bracket)
import           Control.Monad         (forever, join, (>>=))
import           Data.ByteString       as B (break, length, tail)
import           Data.ByteString.Char8 (pack)
import           Data.UUID             (fromASCIIBytes)
import           Data.Word8            (isSpace)
import           HttpAsync
import           Kafka.Consumer
import           Network.HTTP          (Header (..), HeaderName (..),
                                        Response (..))
import           Types

-- consumer properties
consumerProps :: BrokerAddress -> ConsumerGroupId -> ConsumerProperties
consumerProps a g = brokersList [a]
                 <> groupId g
                 <> noAutoCommit
                 <> logLevel KafkaLogInfo

-- Subscription to topics
consumerSub :: ServerTopic -> Subscription
consumerSub t = topics [TopicName t]
           <> offsetReset Earliest

runResponderAsync :: BrokerAddress -> ConsumerGroupId -> ServerTopic -> (SessionID -> Responder) -> IO ()
runResponderAsync a g t responder = do
    res <- bracket mkConsumer clConsumer runHandler
    print res
    where
      mkConsumer = newConsumer (consumerProps a g) (consumerSub t)
      clConsumer (Left err) = return (Left err)
      clConsumer (Right kc) = maybe (Right ()) Left <$> closeConsumer kc
      runHandler (Left err) = return (Left err)
      runHandler (Right kc) = processMessages responder kc

-------------------------------------------------------------------
processMessages ::  (SessionID -> Responder) -> KafkaConsumer -> IO (Either KafkaError ())
processMessages responder kafka = do
    forever $ do
      ekmsg <- pollMessage kafka (Timeout 1000)
      _ <- case ekmsg of
             Left err -> print err
             Right kmsg -> do
                 let mbmsg = crValue kmsg
                 case fmap ((\(x, y) -> (fromASCIIBytes x, B.tail y)) . B.break isSpace) mbmsg of
                   Just (Just sid, msg) -> responder sid $
                       Response (2, 0, 0) "OK" [ Header HdrContentLength (show . (+1) . B.length $ msg)
                                               , Header HdrConnection "close"
                                               ] (msg <> "\n")
                   Just (Nothing, msg)  -> putStrLn $ "Wrong SID: " <> show msg
                   Nothing  -> putStrLn "Wrong message"
      _ <- commitAllOffsets OffsetCommit kafka
      return ()
    return $ Right ()
