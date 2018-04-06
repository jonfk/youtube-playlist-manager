port module PouchDB.Youtube exposing (..)

import Date


type alias YoutubeDataDoc =
    { token : Maybe String
    }


type alias YoutubePlaylistDoc =
    { id : String
    , type_ : String
    , publishedAt : String
    , channelId : String
    }


port storeYoutubeData : YoutubeDataDoc -> Cmd msg


port fetchYoutubeData : String -> Cmd msg


port fetchedYoutubeData : (YoutubeDataDoc -> msg) -> Sub msg


port youtubeDataPortErr : (String -> msg) -> Sub msg
