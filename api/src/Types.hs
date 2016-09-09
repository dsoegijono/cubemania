{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Types where

import Prelude hiding (id)
import GHC.Generics
import Data.Aeson (ToJSON(..), FromJSON(..), Value(..), (.=), object, (.:), (.:?))
import Servant (FromHttpApiData(..))
import Web.HttpApiData (ToHttpApiData, toQueryParam)
import Data.Text (Text)
import Data.Char (chr)
import Data.Time.LocalTime (LocalTime, localTimeToUTC, utc)
import Data.Time.Format (defaultTimeLocale, formatTime)
import Data.Time.Clock (UTCTime)
import Data.Word (Word8)
import Database.PostgreSQL.Simple.FromRow
import Database.PostgreSQL.Simple.FromField
import Database.PostgreSQL.Simple.ToField
import qualified Data.ByteString as BS
import Control.Monad (mzero)

type DurationInMs = Int

newtype PageNumber = PageNumber Int
fromPageNumber :: Num a => PageNumber -> a
fromPageNumber (PageNumber x) = fromIntegral x
nextPage :: PageNumber -> PageNumber
nextPage (PageNumber x) = PageNumber (succ x)

instance ToHttpApiData PageNumber where
    toQueryParam (PageNumber i) = toQueryParam i
instance FromHttpApiData PageNumber where
    parseUrlPiece t = PageNumber <$> parseUrlPiece t--parseInt t

newtype PuzzleId = PuzzleId Int deriving (Generic)
instance FromHttpApiData PuzzleId where
    parseUrlPiece t = PuzzleId <$> parseUrlPiece t
instance ToJSON PuzzleId
instance FromField PuzzleId where
    fromField f s = PuzzleId <$> fromField f s

newtype Limit = Limit Int deriving (Generic)
instance FromField Limit where
    fromField f s = Limit <$> fromField f s
instance FromHttpApiData Limit where
  parseUrlPiece t = Limit <$> parseUrlPiece t

newtype AnnouncementId = AnnouncementId Int deriving (Eq)
instance Show AnnouncementId where
    show (AnnouncementId x) = show x
instance FromField AnnouncementId where
    fromField f s = AnnouncementId <$> fromField f s

newtype SingleId = SingleId Int deriving (Generic, Show, Eq)
instance FromField SingleId where
    fromField f s = SingleId <$> fromField f s
instance FromHttpApiData SingleId where
  parseUrlPiece s = SingleId <$> parseUrlPiece s
instance ToJSON SingleId

--newtype SlugOrId a b = SlugOrId (Either a b)
data SlugOrId a b = Slug a | Id b deriving (Show)
instance (FromHttpApiData a, FromHttpApiData b) => FromHttpApiData (SlugOrId a b) where
    parseUrlPiece u =
      case parseId u of
        Right r -> Right $ Id r
        Left _ ->
          case parseSlug u of
            Right r -> Right $ Slug r
            Left text -> Left text
      where
        parseSlug :: Text -> Either Text a
        parseSlug = parseUrlPiece
        parseId :: Text -> Either Text b
        parseId = parseUrlPiece

slugOrIdToEither :: SlugOrId a b -> Either a b
slugOrIdToEither (Slug s) = Left s
slugOrIdToEither (Id i) = Right i

newtype UserId = UserId Int deriving (Generic, Show, Eq, Ord)
instance FromField UserId where
    fromField f s = UserId <$> fromField f s
instance FromRow UserId
instance ToJSON UserId
instance ToField UserId where
    toField (UserId id) = toField id
instance FromHttpApiData UserId where
    parseUrlPiece u = UserId <$> parseUrlPiece u
newtype UserSlug = UserSlug Text deriving (Show)
instance ToField UserSlug where
    toField (UserSlug slug) = toField slug
instance FromHttpApiData UserSlug where
    parseUrlPiece u = UserSlug <$> parseUrlPiece u


data Penalty = Plus2 | Dnf deriving (Show, Eq)
instance ToJSON Penalty where
    toJSON Plus2 = String "plus2"
    toJSON Dnf   = String "dnf"
instance ToField Penalty where
    toField Plus2 = Escape $ "plus2"
    toField Dnf = Escape $ "dnf"
instance FromJSON Penalty where
    parseJSON (String "dnf") = pure Dnf
    parseJSON (String "plus2") = pure Plus2
    parseJSON _ = fail "foo"

word8ToString :: [Word8] -> String
word8ToString = Prelude.map (chr . fromIntegral)

instance FromField Penalty where
    fromField f dat =
        case BS.unpack <$> dat of
          Nothing -> returnError UnexpectedNull f ""
          Just v -> case word8ToString v of
            "plus2" -> return Plus2
            "dnf"   -> return Dnf
            x       -> returnError ConversionFailed f x

data Announcement = Announcement
    { announcementId :: AnnouncementId
    , announcementTitle :: Text
    , announcementContent :: Text
    , announcementUserId :: UserId
    }

instance FromRow Announcement where
    fromRow = Announcement <$> field <*> field <*> field <*> field

data Single = Single
    { singleId :: SingleId
    , singleTime :: DurationInMs
    , singleComment :: Maybe String
    , singleScramble :: String
    , singlePenalty :: Maybe Penalty
    , singleCreatedAt :: UTCTime
    , singleUserId :: UserId
    } deriving (Show, Eq)

isDnf :: Single -> Bool
isDnf (Single _ _ _ _ (Just Dnf) _ _) = True
isDnf _ = False

instance Ord Single where
    compare (Single _ _ _ _ (Just Dnf) _ _) (Single _ _ _ _ (Just Dnf) _ _) = EQ
    compare (Single _ _ _ _ (Just Dnf) _ _) (Single _ _ _ _ _ _ _) = GT
    compare (Single _ _ _ _ _ _ _) (Single _ _ _ _ (Just Dnf) _ _) = LT
    compare s1 s2 = (singleTime s1) `compare` (singleTime s2)

instance ToJSON Single where
    toJSON (Single {..}) = object
      [ "id" .= singleId
      , "time" .= singleTime
      , "comment" .= singleComment
      , "scramble" .= singleScramble
      , "penalty" .= singlePenalty
      , "created_at" .= singleCreatedAt
      ]



instance FromRow Single where
    fromRow = Single <$> field <*> field <*> field <*> field <*> field <*> ((localTimeToUTC utc) <$> field) <*> field

-- TODO: Add prefix and use custom FromJSON instance.
data SubmittedSingle = SubmittedSingle
    { submittedSingleScramble :: String
    , submittedSingleTime :: DurationInMs
    , submittedSinglePenalty :: Maybe Penalty
    } deriving (Show)

instance FromJSON SubmittedSingle where
    parseJSON (Object v) = SubmittedSingle <$>
                             v .: "scramble" <*>
                             v .: "time" <*>
                             v .:? "penalty"
    parseJSON _          = mempty

data RecordSingle = RecordSingle
    { recordSingleId :: SingleId
    , recordSingleTime :: DurationInMs
    , recordSingleScramble :: String
    }

instance FromRow RecordSingle where
    fromRow = RecordSingle <$> field <*> field <*> field

instance ToJSON RecordSingle where
    toJSON (RecordSingle{..}) = object
      [ "id" .= recordSingleId
      , "time" .= recordSingleTime
      , "scramble" .= recordSingleScramble
      ]

data SimpleUser = SimpleUser
    { simpleUserId :: UserId
    , simpleUserSlug :: String
    , simpleUserName :: String
    , simpleUserSinglesCount :: Int
    }

instance ToJSON SimpleUser where
    toJSON SimpleUser{..} = object
      [ "id" .= simpleUserId
      , "slug" .= simpleUserSlug
      , "name" .= simpleUserName
      , "singles_count" .= simpleUserSinglesCount
      ]

instance FromRow SimpleUser where
    fromRow = SimpleUser <$> field <*> field <*> field <*> field

data User = User
    { userId :: UserId
    , userName :: Text
    , userSlug :: Text
    , userEmail :: Text
    , userRole :: Text -- TODO: Use sum type
    , userWca :: Maybe Text
    , userIgnored :: Bool
    , userWastedTime :: Integer
    }

instance FromRow User where
    fromRow = User <$> field <*> field <*> field <*> field <*> field <*> field <*> field <*> field
-- TODO get rid of Type prefix
data RecordType = TypeSingle | TypeAverage5 | TypeAverage12

instance FromField RecordType where
    fromField f s = do
        a <- fromField f s
        case (a :: Int) of
          1  -> return TypeSingle
          5  -> return TypeAverage5
          12 -> return TypeAverage12
          _  -> mzero

instance ToJSON RecordType where
    toJSON TypeSingle = String "Single"
    toJSON TypeAverage5 = String "Average of 5"
    toJSON TypeAverage12 = String "Average of 12"

data Record = Record
    { recordId :: Int
    , recordTime :: DurationInMs
    , recordComment :: String
    , recordPuzzleId :: PuzzleId
    , recordType :: RecordType
    , recordSingles :: [RecordSingle]
    }

instance FromRow Record where
    fromRow = Record <$> field <*> field <*> field <*> field <*> field <*> pure []

instance ToJSON Record where
    toJSON Record{..} = object
        [ "id" .= recordId
        , "time" .= recordTime
        , "set_at" .= (0 :: Int)
        , "comment" .=  recordComment
        , "puzzle_id" .= recordPuzzleId
        , "type_full_name" .= recordType
        , "singles" .= recordSingles
        ]

data ChartData = ChartData
    { chartTime :: Double
    , chartComment :: Maybe String
    , chartCreatedAt :: UTCTime
    }

instance FromRow ChartData where
    fromRow = ChartData <$> (fromRational <$> field) <*> field <*> (localTimeToUTC utc <$> field)
instance ToJSON ChartData where
    toJSON ChartData{..} = object
        [ "time" .= chartTime
        , "created_at" .= chartCreatedAt
        , "created_at_timestamp" .= utcTimeToEpoch chartCreatedAt
        ]
      where
        utcTimeToEpoch :: UTCTime -> Int
        utcTimeToEpoch time = read $ formatTime defaultTimeLocale "%s" time

data ChartGroup = Month | Week | Day

newtype LocalTimeWithFromRow = LocalTimeWithFromRow LocalTime deriving (Generic)
instance FromRow LocalTimeWithFromRow

localTimeToUTCTime :: LocalTimeWithFromRow -> UTCTime
localTimeToUTCTime (LocalTimeWithFromRow t) = localTimeToUTC utc t
