port module PouchDB.Youtube exposing (..)


type alias YoutubeDataDoc =
    { rev : String
    , token : Maybe String
    }


defaultYoutubeDataDoc : YoutubeDataDoc
defaultYoutubeDataDoc =
    { rev = ""
    , token = Nothing
    }

unwrap : Maybe YoutubeDataDoc -> YoutubeDataDoc
unwrap doc =
    Maybe.withDefault defaultYoutubeDataDoc doc


type alias YoutubePlaylistDoc =
    { id : String
    , type_ : String
    , publishedAt : String
    , channelId : String
    }


port storeYoutubeData : YoutubeDataDoc -> Cmd msg


port fetchYoutubeData : String -> Cmd msg


port fetchedYoutubeData : (Maybe YoutubeDataDoc -> msg) -> Sub msg


port youtubeDataPortErr : (String -> msg) -> Sub msg
