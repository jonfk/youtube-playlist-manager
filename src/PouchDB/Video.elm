port module PouchDB.Video exposing (..)

import Dict
import Maybe
import Set
import String exposing (padLeft)
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


type alias Document =
    { id : String
    , rev : Maybe String
    , video : YoutubePlaylistVideo
    , tags : List String
    , notes : String
    }


type alias FetchVideosArgs =
    { startKey : Maybe String
    , endKey : Maybe String
    , descending : Bool
    , limit : Int
    }


defaultVideosLimitArg : Int
defaultVideosLimitArg =
    20


defaultFetchVideosArgs : FetchVideosArgs
defaultFetchVideosArgs =
    { startKey = Nothing, endKey = Nothing, descending = False, limit = 20 }


newFromYoutubePlaylistItem : Youtube.PlaylistItems.PlaylistItem -> Maybe Document
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
            , video =
                { videoId = videoId
                , publishedAt = snippet.publishedAt
                , title = snippet.title
                , description = snippet.description
                , channels = [ { id = snippet.channelId, title = snippet.channelTitle } ]
                , playlists = [ { id = playlistId, position = position } ]
                , thumbnails = Dict.toList snippet.thumbnails
                }
            , tags = []
            , notes = ""
            }
    in
    Maybe.map fromSnippet item.snippet


fromYoutubePlaylistItems : List Youtube.PlaylistItems.PlaylistItem -> List Document
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


updateDocFromYTItem : Youtube.PlaylistItems.PlaylistItem -> Document -> Maybe Document
updateDocFromYTItem ytItem doc =
    let
        fromSnippet snippet =
            let
                oldVideo =
                    doc.video

                oldChannels =
                    List.map .id oldVideo.channels |> Set.fromList

                newChannel =
                    { id = snippet.channelId, title = snippet.channelTitle }

                newChannels =
                    if Set.member snippet.channelId oldChannels then
                        oldVideo.channels
                    else
                        newChannel :: oldVideo.channels

                oldPlaylists =
                    List.map .id oldVideo.playlists |> Set.fromList

                newPlaylists =
                    if Set.member snippet.playlistId oldPlaylists then
                        oldVideo.playlists
                    else
                        { id = snippet.playlistId, position = snippet.position } :: oldVideo.playlists

                newVideo =
                    { oldVideo | channels = newChannels, playlists = newPlaylists }
            in
            { doc | video = newVideo }
    in
    Maybe.map fromSnippet ytItem.snippet


syncFromYTPlaylisItem : Youtube.PlaylistItems.PlaylistItem -> Maybe Document -> Maybe Document
syncFromYTPlaylisItem ytItem doc =
    case doc of
        Nothing ->
            newFromYoutubePlaylistItem ytItem

        Just oldDoc ->
            updateDocFromYTItem ytItem oldDoc


youtubeVideoUrl : Document -> String
youtubeVideoUrl doc =
    "https://youtu.be/" ++ doc.video.videoId


port saveOrUpdateVideos : List Document -> Cmd msg


port fetchVideos : FetchVideosArgs -> Cmd msg


port fetchedVideos : (List Document -> msg) -> Sub msg


port fetchVideo : String -> Cmd msg


port fetchedVideo : (Maybe Document -> msg) -> Sub msg


port pouchdbVideoErr : (String -> msg) -> Sub msg
