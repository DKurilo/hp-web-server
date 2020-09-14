{-# LANGUAGE OverloadedStrings #-}
module HttpAsync where

import           Control.Concurrent          (forkIO, threadDelay)
import           Control.Concurrent.STM.TVar (TVar, modifyTVar', newTVarIO,
                                              readTVar, readTVarIO, writeTVar)
import           Control.Monad               (forM_, forever, (>>=))
import           Control.Monad.STM           (atomically)
import qualified Data.ByteString             as B
import           Data.ByteString.Char8       (pack)
import qualified Data.Map.Strict             as Map
import           Data.Monoid                 ((<>))
import           Data.Time.Clock             (NominalDiffTime (..),
                                              UTCTime (..), addUTCTime,
                                              getCurrentTime)
import           Data.UUID                   (UUID, toText)
import           Data.UUID.V4                (nextRandom)
import           Debug.Trace                 (trace)
import           Network.HTTP
import           Network.Socket
import           Network.URI
import qualified Queue                       as Q

type SessionID = UUID
type SessionIDGen = IO SessionID
type Timeout = NominalDiffTime

type Responder = Response B.ByteString -> IO ()

class SessionsPool a where
    empty :: a
    lookupDelete :: SessionID -> a -> (Maybe Responder, a)
    delete :: SessionID -> a -> a
    insert :: SessionTime -> Responder -> a -> a
    removeOutdated :: UTCTime -> a -> ([(SessionID, Responder)], a)
    size :: a -> Int

data SessionStorage = Stor { ssst :: Q.ImplicitQueue SessionTime
                           , ssm  :: Map.Map SessionID Responder
                           }
instance SessionsPool SessionStorage where
    empty = Stor Q.empty Map.empty
    lookupDelete sid (Stor q m) = let (mbs, m') = Map.updateLookupWithKey (\_ _ -> Nothing) sid m in (mbs, Stor q m')
    delete sid (Stor q m) = Stor q (Map.delete sid m)
    insert st r (Stor q m) = Stor (Q.snoc q st) (Map.insert (stimeSessionID st) r m)
    removeOutdated timestamp (Stor q m) = foldl (\(rs, s) (SessionTime sid _) -> case lookupDelete sid s of
                                                      (Just r, s') -> ((sid, r) : rs, s')
                                                      _            -> (rs, s)) ([], Stor q' m) sts
        where (sts, q') = Q.removeWhile (\st -> stimeTimestamp st < timestamp) q
    size (Stor _ m) = Map.size m

data SessionTime = SessionTime { stimeSessionID :: SessionID
                               , stimeTimestamp :: UTCTime
                               }

mkSessionTime :: Timeout -> SessionID -> IO SessionTime
mkSessionTime t s = SessionTime s . addUTCTime t <$> getCurrentTime

mkSharedPool :: IO (TVar SessionStorage)
mkSharedPool = newTVarIO empty

mkSharedSessionIDGen :: IO (TVar SessionIDGen)
mkSharedSessionIDGen = newTVarIO nextRandom

type Listener = SessionID -> Request B.ByteString -> IO ()
runListenerAsync :: (SessionsPool sp) => TVar SessionIDGen -> Timeout -> TVar sp -> Listener -> IO ()
runListenerAsync tgen timeout tsp listener = do
    lsock <- socket AF_INET Stream defaultProtocol
    bind lsock (SockAddrInet 8080 $ tupleToHostAddress (127, 0, 0, 1))
    listen lsock 10
    forever $ do
      (csock, _) <- accept lsock
      hs <- socketConnection "" 8080 csock
      req <- receiveHTTP hs
      case req of
        Left _ -> do
            Network.HTTP.close hs
            return ()
        Right req -> do
            _ <- forkIO $ do
                sidgen <- readTVarIO tgen
                sid <- sidgen
                print $ "received request: " <> show req
                st <- mkSessionTime timeout sid
                _ <- atomically $
                    modifyTVar' tsp $ insert st (\r -> do
                        respondHTTP hs r
                        Network.HTTP.close hs)
                listener sid req
            return ()

responseAsync :: (SessionsPool sp) => TVar sp -> (SessionID -> Responder)
responseAsync tsp sid resp = do
    _ <- forkIO $ do
        mbr <- atomically $
            do
                sp <- readTVar tsp
                let (mbr, sp') = lookupDelete sid sp
                writeTVar tsp sp'
                return mbr
        case mbr of
          Just r  -> r resp
          Nothing -> putStrLn $ "Session lost: " <> show sid
    return ()

runCleanerAsync :: (SessionsPool sp) => Int -> TVar sp -> ((SessionID, Responder) -> IO ()) -> IO ()
runCleanerAsync delay tsp genErr = forever $ do
    threadDelay delay
    now <- getCurrentTime
    srs <- atomically $
        do
            sp <- readTVar tsp
            let (srs', sp') = (if size sp > 0 then trace ("map size: " <> (show . size) sp) else id) $ removeOutdated now sp
            writeTVar tsp sp'
            return srs'
    forM_ srs $ \sr -> forkIO . genErr $ sr

genErr503 :: (SessionID, Responder) -> IO ()
genErr503 (sid, responder) = responder $ Response (5, 0, 3) "Service Unavailable"
                                                  [ Header HdrContentLength (show . B.length $ msg)
                                                  ]
                                                  msg
    where msg = "Sorry! Try again later\nSession ID: " <> (pack . show) sid <> "\n"
