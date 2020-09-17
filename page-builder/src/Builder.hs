{-# LANGUAGE OverloadedStrings #-}
module Builder where

import           Types

buildPage :: ParsedMessage -> OutputMessage
buildPage pm = OutputMessage (pmTopic pm) s ("<html>\n<head>\n<title>Hello World!</title>\n</head>\n<body>\n<h1>Hello World!</h1>\n"
                                             <> "<p>SessionID: " <> s <> "</p>\n"
                                             <> "<p>Built by: " <> pb <> "</p>\n"
                                             <> "<p>Server topic: " <> topic <> "</p>\n"
                                             <> "</body>\n</html>\n")
    where s = pmSessionID pm
          pb = pmPageBuilderId pm
          topic = pmTopic pm
