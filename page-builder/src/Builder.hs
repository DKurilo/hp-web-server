{-# LANGUAGE OverloadedStrings #-}
module Builder where

import           Types

buildPage :: ParsedMessage -> OutputMessage
buildPage pm = OutputMessage (pmTopic pm) s ("<html>\n<head>\n<title>Hello World!</title>\n</head>\n<body>\n<h1>Hello World!</h1>\n<p>"
                                             <> s <> "</p><p>Hi there!</p>\n</body>\n</html>\n")
    where s = pmSessionID pm
