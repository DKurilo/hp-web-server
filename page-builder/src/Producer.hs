{-# LANGUAGE OverloadedStrings #-}
module Producer (sendResponse) where

import           Control.Exception  (bracket)
import           Control.Monad      (forM_)
import qualified Data.ByteString    as B
import           Data.Text.Encoding (decodeUtf8)
import           Kafka.Producer
import           Types

message :: OutputMessage -> KafkaMessage
message om = B.intercalate "\n" [ omSessionId om
                                , omBody om
                                ]

sendResponse :: BrokerAddress -> Maybe OutputMessage -> IO ()
sendResponse _ Nothing = return ()
sendResponse a (Just m) =  bracket mkProducer clProducer runHandler >>= print
    where
      mkProducer = newProducer (producerProps a)
      clProducer (Left _)     = return ()
      clProducer (Right prod) = closeProducer prod
      runHandler (Left err)   = return $ Left err
      runHandler (Right prod) = sendMessage (omTopic m) (message m) prod

-- producer properties
producerProps :: BrokerAddress -> ProducerProperties
producerProps a = brokersList [a]
               <> logLevel KafkaLogDebug

-- Topic to send messages to
targetTopic :: Topic -> TopicName
targetTopic = TopicName . decodeUtf8

sendMessage :: Topic -> KafkaMessage -> KafkaProducer -> IO (Either KafkaError ())
sendMessage sendto m prod = do
  err1 <- produceMessage prod (mkMessage sendto Nothing (Just m) )
  forM_ err1 print
  return $ Right ()

mkMessage :: Topic -> Maybe KafkaKey -> Maybe KafkaMessage -> ProducerRecord
mkMessage t k m = ProducerRecord
                    { prTopic = targetTopic t
                    , prPartition = UnassignedPartition
                    , prKey = k
                    , prValue = m
                    }
