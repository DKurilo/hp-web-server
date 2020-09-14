{-# LANGUAGE OverloadedStrings #-}
module Main where

import           Builder
import           Consumer       as C
import           Kafka.Consumer
import           Producer
import           Types

brokerAddress :: BrokerAddress
brokerAddress = BrokerAddress "127.0.0.1:9092"

consumerGroupId :: ConsumerGroupId
consumerGroupId = ConsumerGroupId "stream_server_group"

builderTopic :: BuilderTopic
builderTopic = "builder"

main :: IO ()
main = C.runConsumer brokerAddress consumerGroupId builderTopic $ sendResponse brokerAddress . fmap buildPage . parseMessage
