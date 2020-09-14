{-# LANGUAGE OverloadedStrings #-}
module Producer
    ( sendRequest
    ) where

import           Control.Exception     (bracket)
import           Control.Monad         (forM_)
import qualified Data.ByteString       as B
import           Data.ByteString.Char8 (pack)
import           Data.Text.Encoding    (encodeUtf8)
import           Data.UUID             (toASCIIBytes)
import           HttpAsync
import           Kafka.Producer
import           Network.HTTP          (Request (..))
import           Types

type Message = B.ByteString

type Key = B.ByteString

message :: ServerTopic -> SessionID -> Request B.ByteString -> Message
message replyto sid r = B.intercalate "\n" [ encodeUtf8 replyto
                                           , toASCIIBytes sid
                                           , (pack . show . rqURI) r
                                           , (pack . show . rqMethod) r
                                           , rqBody r
                                           ]

sendRequest :: BrokerAddress -> BuilderTopic -> ServerTopic -> Listener
sendRequest a sendto replyto s r = bracket mkProducer clProducer runHandler >>= print
    where
      mkProducer = newProducer (producerProps a)
      clProducer (Left _)     = return ()
      clProducer (Right prod) = closeProducer prod
      runHandler (Left err)   = return $ Left err
      runHandler (Right prod) = sendMessage sendto (message replyto s r) prod

-- producer properties
producerProps :: BrokerAddress -> ProducerProperties
producerProps a = brokersList [a]
               <> logLevel KafkaLogDebug

-- Topic to send messages to
targetTopic :: BuilderTopic -> TopicName
targetTopic = TopicName

sendMessage :: BuilderTopic -> Message -> KafkaProducer -> IO (Either KafkaError ())
sendMessage sendto m prod = do
  err1 <- produceMessage prod (mkMessage sendto Nothing (Just m) )
  forM_ err1 print
  return $ Right ()

mkMessage :: BuilderTopic -> Maybe Key -> Maybe Message -> ProducerRecord
mkMessage t k m = ProducerRecord
                    { prTopic = targetTopic t
                    , prPartition = UnassignedPartition
                    , prKey = k
                    , prValue = m
                    }
