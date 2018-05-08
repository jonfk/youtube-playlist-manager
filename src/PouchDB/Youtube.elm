port module PouchDB.Youtube exposing (..)

import Youtube.Authorize


type alias YoutubeDataDoc =
    { token : Maybe String
    }


defaultYoutubeDataDoc : YoutubeDataDoc
defaultYoutubeDataDoc =
    { token = Nothing
    }


unwrap : Maybe YoutubeDataDoc -> YoutubeDataDoc
unwrap doc =
    Maybe.withDefault defaultYoutubeDataDoc doc


fromRedirectData : Youtube.Authorize.YoutubeRedirectData -> YoutubeDataDoc
fromRedirectData data =
    { token = data.accessToken
    }


port updateYoutubeData : YoutubeDataDoc -> Cmd msg


port fetchYoutubeData : () -> Cmd msg


port fetchedYoutubeData : (Maybe YoutubeDataDoc -> msg) -> Sub msg


port youtubeDataPortErr : (String -> msg) -> Sub msg
