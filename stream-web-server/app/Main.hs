{-# LANGUAGE OverloadedStrings #-}
module Main where

import           Consumer
import           Control.Concurrent          (forkFinally)
import           Control.Concurrent.STM.TVar (TVar (..), modifyTVar', newTVarIO,
                                              readTVar)
import           Control.Monad               (join, (=<<))
import           Control.Monad.STM           (atomically, check)
import           Data.Maybe                  (fromMaybe)
import           Data.Text                   (Text, pack)
import           Data.Text.Encoding          (encodeUtf8)
import           Data.Time.Clock             (NominalDiffTime)
import           Data.UUID                   (toText)
import           Data.UUID.V4                (nextRandom)
import           HttpAsync
import           Kafka.Consumer
import           Producer
import           System.Environment          (lookupEnv)
import           Text.Read                   (readMaybe)
import           Types

brokerAddress :: IO BrokerAddress
brokerAddress = do
   addr <- pack . fromMaybe "127.0.0.1" <$> lookupEnv "KAFKA_HOST"
   port <- pack . fromMaybe "9092" <$> lookupEnv "KAFKA_PORT"
   (return . BrokerAddress) (addr <> ":" <> port)

consumerGroupId :: IO ConsumerGroupId
consumerGroupId = ConsumerGroupId . pack . fromMaybe "stream_web_server_group" <$> lookupEnv "STREAM_WEB_SERVER_GROUP"

builderTopic :: IO BuilderTopic
builderTopic = pack . fromMaybe "builder" <$> lookupEnv "PAGE_BUILDER_TOPIC"

serverTopic :: IO ServerTopic
serverTopic =  toText <$> nextRandom

serverPort :: IO Port
serverPort = do
    mbPortString <- lookupEnv "STREAM_WEB_SERVER_PORT"
    (return . fromMaybe 8080) (readMaybe =<< mbPortString)

requestTimeout :: IO HttpAsync.Timeout
requestTimeout = do
    mbTimeoutString <- lookupEnv "REQUEST_TIMEOUT"
    (return . fromMaybe 60) (fromInteger <$> (readMaybe =<< mbTimeoutString))

cleanerDelay :: IO Int
cleanerDelay = do
    mbDelayString <- lookupEnv "CLEANER_DELAY"
    (return . fromMaybe 500) (readMaybe =<< mbDelayString)

main :: IO ()
main = do
    ba <- brokerAddress
    cgid <- consumerGroupId
    bt <- builderTopic
    st <- serverTopic
    port <- serverPort
    timeout <- requestTimeout
    delay <- cleanerDelay
    gen <- mkSharedSessionIDGen
    sessions <- mkSharedPool
    done <- newTVarIO (3 :: Int)
    let finishProc _ = atomically $ modifyTVar' done (\x -> x - 1)
    let listenerApp = runListenerAsync port gen timeout sessions $ sendRequest ba bt st
    _ <- forkFinally listenerApp finishProc
    let responder = responseAsync sessions
    let responderApp = runResponderAsync ba cgid st responder
    _ <- forkFinally responderApp finishProc
    let cleanerApp = runCleanerAsync delay sessions (genErr503 ("Server Topic: " <> encodeUtf8 st))
    _ <- forkFinally cleanerApp finishProc
    atomically $
        do
            x <- readTVar done
            check (x == 0)
    putStrLn "Done"
