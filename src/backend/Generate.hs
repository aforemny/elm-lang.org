{-# LANGUAGE OverloadedStrings #-}
module Generate (serverHtml, userHtml, js) where

import Control.Monad (when)
import qualified Text.Blaze as Blaze
import Text.Blaze.Html5 ((!))
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A


-- JS

js :: Either String (String,String) -> String
js result =
  case result of
    Left msg ->
        "{ \"error\": " ++ show msg ++ " }"

    Right (moduleName, jsSource) ->
        "{ \"name\": " ++ show moduleName ++
        ", \"success\": " ++ show jsSource ++
        " }"


-- HTML

serverHtml :: String -> String -> H.Html
serverHtml name jsSource =
    htmlSkeleton False name $
      do  H.script $ Blaze.preEscapedToMarkup jsSource
          H.script "var runningElmModule = Elm.fullscreen(Elm.Main);"


userHtml :: Either String (String, String) -> H.Html
userHtml compilerResult =
  case compilerResult of
    Right (moduleName, jsSource) ->
        htmlSkeleton True moduleName (scripts moduleName jsSource)

    Left err ->
        htmlSkeleton True "Oops!" $
            H.pre ! A.style "margin: 0; padding: 8px;" $
                  Blaze.toMarkup err


scripts :: H.ToMarkup a => String -> a -> H.Html
scripts moduleName jsSource =
  do  H.script ! A.src "/editor/everything.js" $ ""
      H.script $ Blaze.preEscapedToMarkup jsSource
      H.script $ Blaze.preEscapedToMarkup $
          "var runningElmModule = Elm.fullscreen(Elm." ++  moduleName ++ ");"


-- CREATE HTML DOCUMENTS

htmlSkeleton :: Bool -> String -> H.Html -> H.Html
htmlSkeleton userGenerated title scripts =
  H.docTypeHtml $ do
    H.head $ do
      H.meta ! A.charset "UTF-8"
      H.title (H.toHtml title)
      favicon
      H.link ! A.rel "stylesheet" ! A.href "/assets/style.css"
      when (not userGenerated) $
        do  googleAnalytics
            H.link ! A.rel "stylesheet" ! A.href "/highlight/styles/default.css"
            H.script ! A.src "/highlight/highlight.pack.js" $ ""

    H.body scripts


favicon :: H.Html
favicon =
  H.link
    ! A.rel "shortcut icon"
    ! A.size "16x16, 32x32, 48x48, 64x64, 128x128, 256x256"
    ! A.href "/favicon.ico"


googleAnalytics :: H.Html
googleAnalytics =
    H.script ! A.type_ "text/javascript" $
        "(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){\n\
        \(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),\n\
        \m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)\n\
        \})(window,document,'script','//www.google-analytics.com/analytics.js','ga');\n\
        \\n\
        \ga('create', 'UA-25827182-1', 'auto');\n\
        \ga('send', 'pageview');\n"
