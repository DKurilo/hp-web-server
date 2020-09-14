{-# LANGUAGE OverloadedStrings #-}
module Main where

import           Consumer
import           Control.Concurrent          (forkFinally)
import           Control.Concurrent.STM.TVar (TVar (..), modifyTVar', newTVarIO,
                                              readTVar)
import           Control.Monad.STM           (atomically, check)
import           Data.Text                   (Text)
import           HttpAsync
import           Kafka.Consumer
import           Producer
import           Types

brokerAddress :: BrokerAddress
brokerAddress = BrokerAddress "127.0.0.1:9092"

consumerGroupId :: ConsumerGroupId
consumerGroupId = ConsumerGroupId "stream_server_group"

serverTopic :: ServerTopic
serverTopic = "server_1"

builderTopic :: BuilderTopic
builderTopic = "builder"

requestTimeout :: HttpAsync.Timeout
requestTimeout = 8

cleanerDelay :: Int
cleanerDelay = 500

main :: IO ()
main = do
    gen <- mkSharedSessionIDGen
    sessions <- mkSharedPool
    done <- newTVarIO (3 :: Int)
    let finishProc _ = atomically $ modifyTVar' done (\x -> x - 1)
    let listenerApp = runListenerAsync gen requestTimeout sessions $ sendRequest brokerAddress builderTopic serverTopic
    _ <- forkFinally listenerApp finishProc
    let responder = responseAsync sessions
    let responderApp = runResponderAsync brokerAddress consumerGroupId serverTopic responder
    _ <- forkFinally responderApp finishProc
    let cleanerApp = runCleanerAsync cleanerDelay sessions genErr503
    _ <- forkFinally cleanerApp finishProc
    atomically $
        do
            x <- readTVar done
            check (x == 0)
    putStrLn "Done"
