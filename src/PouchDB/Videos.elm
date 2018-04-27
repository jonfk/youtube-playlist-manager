port module PouchDB.Videos exposing (..)

import Dict
import Maybe
import Set
import Youtube.PlaylistItems


type alias Thumbnail =
    { url : String
    , width : Int
    , height : Int
    }


type alias YoutubePlaylistVideo =
    { videoId : String
    , publishedAt : String
    , title : String
    , description : String
    , channels : List Channel
    , playlists : List Playlist
    , thumbnails : List ( String, Thumbnail )
    }


type alias Channel =
    { id : String
    , title : String
    }


type alias Playlist =
    { id : String
    , position : Int
    }


type alias Doc =
    { id : String
    , rev : Maybe String
    , videoId : String
    , publishedAt : String
    , title : String
    , description : String
    , channels : List Channel
    , playlists : List Playlist
    , thumbnails : List ( String, Thumbnail )
    }


type alias FetchVideosArgs =
    { limit : Int
    , skip : Int
    }


defaultVideosLimitArg : Int
defaultVideosLimitArg =
    10


defaultFetchVideosArgs : FetchVideosArgs
defaultFetchVideosArgs =
    { limit = defaultVideosLimitArg, skip = 0 }


fetchVideosArgs : Int -> FetchVideosArgs
fetchVideosArgs skip =
    { limit = defaultVideosLimitArg, skip = skip }


newFromYoutubePlaylistItem : Youtube.PlaylistItems.PlaylistItem -> Maybe Doc
newFromYoutubePlaylistItem item =
    let
        fromSnippet snippet =
            let
                videoId =
                    snippet.resourceId.videoId

                position =
                    snippet.position

                playlistId =
                    snippet.playlistId
            in
            { id = videoId
            , rev = Nothing
            , videoId = videoId
            , publishedAt = snippet.publishedAt
            , title = snippet.title
            , description = snippet.description
            , channels = [ { id = snippet.channelId, title = snippet.channelTitle } ]
            , playlists = [ { id = playlistId, position = position } ]
            , thumbnails = Dict.toList snippet.thumbnails
            }
    in
    Maybe.map fromSnippet item.snippet


fromYoutubePlaylistItems : List Youtube.PlaylistItems.PlaylistItem -> List Doc
fromYoutubePlaylistItems items =
    let
        maybeToList x =
            case x of
                Just a ->
                    [ a ]

                Nothing ->
                    []
    in
    List.concatMap (\x -> maybeToList <| newFromYoutubePlaylistItem x) items


youtubeVideoUrl : Doc -> String
youtubeVideoUrl doc =
    "https://youtu.be/" ++ doc.videoId


type alias VideosResult =
    { docs : List Doc
    , totalRows : Int
    }


port saveOrUpdateVideos : List Doc -> Cmd msg


port fetchVideos : FetchVideosArgs -> Cmd msg


port fetchedVideos : (VideosResult -> msg) -> Sub msg


port fetchVideo : String -> Cmd msg


port fetchedVideo : (Maybe Doc -> msg) -> Sub msg


port pouchdbVideoErr : (String -> msg) -> Sub msg
