{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Html
    ( usersPage
    , userPage
    , rootPage
    ) where

import Data.Monoid ((<>))
import Types
import Routes
import Data.Maybe (fromMaybe, isJust)
import qualified Data.Map.Strict as Map
import Data.ByteString.Lazy (toStrict)
import Data.ByteString.Base16 (encode)
import Control.Monad (forM_, unless)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.Text.Lazy as LT
import Text.Blaze.Html5 as H
import Text.Blaze.Html5.Attributes as A
import Text.Blaze.Html.Renderer.Utf8 (renderHtml)
import Text.Markdown (markdown, def)
import qualified Data.Aeson as JSON
import qualified Crypto.Hash.MD5 as MD5
import Utils

data Page = Home | Timer | Users | Records deriving (Eq)

navigationItems :: [Page]
navigationItems = [Home, Timer, Users, Records]

navigationText :: Page -> T.Text
navigationText Home = "Home"
navigationText Timer = "Timer"
navigationText Users = "Users"
navigationText Records = "Records"

navigationLink :: Page -> T.Text
navigationLink Home = "/"
navigationLink Timer = "/puzzles/3x3x3/timer"
navigationLink Users = usersLink Nothing
navigationLink Records = "/puzzles/3x3x3/records"


withLayout :: Maybe (LoggedInUser) -> Page -> T.Text -> Html -> Html
withLayout currentUser currentPage title' inner =
    let
      selectedClass item' = if item' == currentPage then "selected" else ""
      navigationItem item' = li ! class_ (toValue $ (selectedClass item' :: T.Text)) $ a ! href (toValue $ navigationLink item') $ toHtml $ navigationText item'
      sessionNavigation =
          case currentUser of
              Just (LoggedIn u) -> do
                  li ! class_ "session" $ a ! href "/logout" $ "Logout"
                  li ! class_ "session" $ a ! href (toValue $ userLink (userSlug u)) $ toHtml (userName u <> "'s Profile")
              Nothing ->
                  li ! class_ "session" $ a ! href "/login" $ "Login"
      navigation = nav ! class_ "main" $ ul $ (mapM_ navigationItem navigationItems) <> sessionNavigation
      footer' =
        footer $ p $ do
            "Founded by"
            space
            a ! href "http://cubemania.org/users/tim" $ "Tim Habermaas"
            ","
            space
            a ! href "http://www.patrickstadler.de" ! A.title "Patrick Stadler's Website" $ "Patrick Stadler"
            space
            "and Simon Wacker."
    in
      docTypeHtml $ do
          H.head $ do
              meta ! httpEquiv "content-type" ! content "text/html;charset=utf-8"
              link ! rel "apple-touch-icon" ! href "apple-touch-icon.png"
              H.title $ toHtml $ title' `T.append` " · Cubemania"
              link ! href "/assets/app.css" ! media "screen" ! rel "stylesheet" ! type_ "text/css"
              script ! src "/assets/app.js" ! type_ "text/javascript" $ mempty
              preEscapedToHtml ("<!--[if lt IE 9]><script src=\"http://html5shim.googlecode.com/svn/trunk/html5.js\"></script><![endif]-->" :: String)
              meta ! content "authenticity_token" ! name "csrf-param"
              meta ! content "iF91XiNQPByT6XXpFtx7BmWSt3k5unBNNs1F7NMni1c=" ! name "csrf-token"
              script ! type_ "text/javascript" $ "var _gaq = _gaq || [];\n      _gaq.push(['_setAccount', 'UA-28649455-1']);\n      _gaq.push(['_setDomainName', 'cubemania.org']);\n      _gaq.push(['_trackPageview']);\n\n      (function() {\n        var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;\n        ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';\n        var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);\n      })();"
          body $ do
              header ! class_ "main" $ H.div ! class_ "center" $ do
                  h1 $ a ! href "/" $ "Cubemania"
                  q "Save The World - Solve The Puzzle"
              navigation
              H.div ! A.id "flash" ! class_ "flash notice" ! A.style "display:none" $ p mempty
              section ! A.id "content" $ H.div ! class_ "center" $ inner
              footer'
              script ! type_ "text/javascript" $ "var uvOptions = {};\n  (function() {\n    var uv = document.createElement('script'); uv.type = 'text/javascript'; uv.async = true;\n    uv.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + 'widget.uservoice.com/XmjQy7dHIjHW3AR0O50Cyw.js';\n    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(uv, s);\n  })();"

usersPage :: Maybe LoggedInUser -> [SimpleUser] -> Int -> PageNumber -> Maybe T.Text -> Html
usersPage currentUser users maxSinglesCount currentPageNumber query = withLayout currentUser Users "Users" $
    H.div ! class_ "users-container" $ do
        H.form ! acceptCharset "UTF-8" ! action (toValue (usersLink Nothing)) ! A.id "users-search" ! method "get" $
            input ! A.id "q" ! required "required" ! name "q" ! placeholder "Search" ! type_ "search" ! value (toValue (fromMaybe "" query))
        ul ! A.id "users" ! class_ "users" $ forM_ users (\u -> userLi u >> space)
        unless (isJust query) $
            H.div ! class_ "pagination" $ a ! href (toValue (usersLink (Just (nextPage currentPageNumber)))) $ "Show more"
  where
    userLi user@SimpleUser{..} = li ! A.style (stringValue $ "font-size: " ++ show (fontSize user maxSinglesCount) ++ "em") $ do
        a ! href (stringValue ("/users/" ++ simpleUserSlug)) $ toHtml simpleUserName
        space
        small ! class_ "singles" $ toHtml $ show simpleUserSinglesCount
    fontSize :: SimpleUser -> Int -> Float
    fontSize SimpleUser{..} maxSinglesCount' = fromIntegral simpleUserSinglesCount / fromIntegral maxSinglesCount' * 1.4 + 0.6

userPage :: Maybe (LoggedIn User) -> User -> Map.Map (Puzzle, Kind) (Map.Map RecordType DurationInMs) -> Activity -> Html
userPage cu user@User{..} records activity = withLayout cu Users "User" $
    H.div ! A.id "user" $ do
        H.div ! class_ "admin" $ mempty
        h1 $ do
            profileImage
            space
            toHtml userName
            small "has spent 16 days solving puzzles."
        wcaLinkSection cu
        h3 "Activity"
        section ! A.id "activity" ! dataAttribute "activity" activityJSON $ mempty
        h3 "Records"
        ul ! class_ "records" $ sequence_ $ Map.elems $ Map.mapWithKey recordWidget records

  where
    recordEntry :: RecordType -> Maybe DurationInMs -> Html
    recordEntry type' (Just time) =
        tr $ do
            th ! class_ "type" $ toHtml type'
            td $ strong $ toHtml $ formatTime time
    recordEntry type' Nothing =
        tr $ do
            th ! class_ "type" $ toHtml type'
            td $ small "None"

    recordWidget :: (Puzzle, Kind) -> Map.Map RecordType DurationInMs -> Html
    recordWidget (puzzle, kind) records =
        li ! class_ "record" $ do
            H.div ! class_ "puzzle" $ do
                H.div ! class_ (toValue $ "puzzle-image " <> posClass (puzzleCssPosition puzzle)) $ H.div ! class_ (toValue $ "kind-image " <> posClass (kindCssPosition kind)) $ mempty
                H.span $ do
                    toHtml $ puzzleName puzzle
                    space
                    small $ toHtml $ fromMaybe "" $ kindShortName kind
            table $ do
                thead $ tr mempty
                tbody $ sequence_ $ fmap (\type' -> recordEntry type' (Map.lookup type' records)) allRecordTypes
    posClass :: Int -> String
    posClass n = "pos" <> (show n)
    profileImage =
      let url email = "http://gravatar.com/avatar/" <> hash email <> ".png?s=60"
          hash email = TE.decodeUtf8 $ encode $ MD5.hash (TE.encodeUtf8 email)
      in
          img ! class_ "profile-image" ! src (toValue $ url userEmail)
    wcaLinkSection :: Maybe (LoggedIn User) -> Html
    wcaLinkSection currentUser =
        case userWca of
            Just wid ->
                H.div ! A.id "wca" $ do
                    a ! href "http://www.worldcubeassociation.org" ! class_ "logo" $ mempty
                    a ! href (toValue $ wcaLink wid) $ toHtml $ userName <> "'s World Cube Association Profile"
            Nothing -> if isSelf currentUser then
                H.div ! A.id "wca" $ do
                    a ! href "http://www.worldcubeassociation.org" ! class_ "logo" $ mempty
                    a ! href (toValue $ "/users/" <> (fromSlug userSlug) <> "/edit") $ "Link your World Cube Association profile!"
                       else
                return ()
    isSelf (Just (LoggedIn cu)) = cu == user
    isSelf _ = False

    activityJSON = toValue $ TE.decodeUtf8 $ toStrict $ JSON.encode activity

rootPage :: Maybe LoggedInUser -> Maybe Announcement -> Html
rootPage currentUser post = withLayout currentUser Home "Home" $ do
    fromMaybe noAnnouncement $ announcementHtml <$> post
    p ! class_ "introduction" $ do
        "You want to keep track of your times, compare yourself with others and become the best?\n  If so, Cubemania is the right place for you: "
        a ! href "/register" $ "Register"
        " now and get the record!"
    ul ! A.id "features" $ do
        li ! class_ "odd" $ do
            a ! href "/puzzles/3x3x3/timer" ! class_ "image" $ img ! alt "Timer" ! src "/assets/images/screenshots/timer.jpg"
            br
            p "Stop your times and submit your averages."
        li $ do
            a ! href "/users/tim" ! class_ "image" $ img ! alt "Puzzles" ! src "/assets/images/screenshots/puzzles.jpg"
            br
            p "Organize your times properly."
        li ! class_ "odd" $ do
            a ! href "/puzzles/3x3x3/timer" ! class_ "image" $ img ! alt "Chart" ! src "/assets/images/screenshots/chart.jpg"
            p "Keep track of your progress and compare yourself with other cubers."
        li $ do
            a ! href "/puzzles/3x3x3/records" ! class_ "image" $ img ! alt "Records" ! src "/assets/images/screenshots/records.jpg"
            p "Get the record!"
  where
    noAnnouncement = return ()
    announcementHtml Announcement{..} =
        article ! class_ "announcement" $ do
            strong $ toHtml announcementTitle
            space
            preEscapedToHtml $ renderInlineMarkdown announcementContent
            space
            a ! href (toValue $ postLinkToComments announcementId) $ "76 Comments »"

-- Type annotation necessary for ToMarkup class
space :: Html
space = toHtml (" " :: T.Text)

renderInlineMarkdown :: T.Text -> T.Text
renderInlineMarkdown = T.replace "</p>" "" . T.replace "<p>" "" . TE.decodeUtf8 . toStrict . renderHtml . markdown def . LT.fromStrict
