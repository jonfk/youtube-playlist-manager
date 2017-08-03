port module PouchDB exposing (..)

import Dict
import Maybe
import Youtube.Playlist


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
    , channelId : String
    , channelTitle : String
    , playlistId : String
    , position : Int
    , thumbnails : List ( String, Thumbnail )
    }


fromYoutubePlaylistItem : Youtube.Playlist.PlaylistItem -> Maybe Document
fromYoutubePlaylistItem item =
    let
        fromSnippet snippet =
            let
                videoId =
                    snippet.resourceId.videoId

                position =
                    snippet.position
                playlistId = snippet.playlistId
            in
                { id = playlistId ++ "__" ++ toString position ++ "__"++ videoId
                , video =
                    { videoId = videoId
                    , publishedAt = snippet.publishedAt
                    , title = snippet.title
                    , description = snippet.description
                    , channelId = snippet.channelId
                    , channelTitle = snippet.channelTitle
                    , playlistId = playlistId
                    , position = position
                    , thumbnails = Dict.toList snippet.thumbnails
                    }
                , tags = []
                , notes = ""
                }
    in
        Maybe.map fromSnippet item.snippet

fromYoutubePlaylistItems : List Youtube.Playlist.PlaylistItem -> List Document
fromYoutubePlaylistItems items =
    let
        maybeToList x = case x of
                            Just a -> [a]
                            Nothing -> []
    in
        List.concatMap (\x -> maybeToList <| fromYoutubePlaylistItem x) items


type alias Document =
    { id : String
    , video : YoutubePlaylistVideo
    , tags : List String
    , notes : String
    }


port storeVideo : Document -> Cmd msg


port storeVideos : List Document -> Cmd msg


port fetchVideos : Bool -> Cmd msg


port fetchedVideos : (List Document -> msg) -> Sub msg
