{-# LANGUAGE OverloadedStrings #-}
module Main where

import           Builder
import           Consumer           as C
import           Data.Maybe         (fromMaybe)
import           Data.Text          (pack)
import           Data.Text.Encoding (encodeUtf8)
import           Data.UUID          (toText)
import           Data.UUID.V4       (nextRandom)
import           Kafka.Consumer
import           Producer
import           System.Environment (lookupEnv)
import           Types

brokerAddress :: IO BrokerAddress
brokerAddress = do
   addr <- pack . fromMaybe "127.0.0.1" <$> lookupEnv "KAFKA_HOST"
   port <- pack . fromMaybe "9092" <$> lookupEnv "KAFKA_PORT"
   (return . BrokerAddress) (addr <> ":" <> port)

consumerGroupId :: IO ConsumerGroupId
consumerGroupId = ConsumerGroupId . pack . fromMaybe "page_builder_group" <$> lookupEnv "PAGE_BUILDER_GROUP"

builderTopic :: IO BuilderTopic
builderTopic = pack . fromMaybe "builder" <$> lookupEnv "PAGE_BUILDER_TOPIC"

pbId :: IO PageBuilderId
pbId =  encodeUtf8 . toText <$> nextRandom

main :: IO ()
main = do
    ba <- brokerAddress
    bt <- builderTopic
    cgid <- consumerGroupId
    pb <- pbId
    C.runConsumer ba cgid bt $ sendResponse ba . fmap (buildPage . (pmpagebuilderid pb <>)) . parseMessage
