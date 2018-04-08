module Youtube.Playlist exposing (..)

import Dict
import Http
import Json.Decode
import Json.Decode.Pipeline
import Json.Encode
import Youtube exposing (Token, tokenToHeader)


type Part
    = ContentDetails
    | Localizations
    | Player
    | IdPart
    | SnippetPart
    | Status


type Filter
    = ChannelId String
    | Id String
    | Mine Bool


type alias OptionalParams =
    { hl : Maybe String
    , maxResults : Maybe Int
    , onBehalfOfContentOwner : Maybe String
    , onBehalfOfContentOwnerChannel : Maybe String
    , pageToken : Maybe String
    }


getPlaylists : Token -> List Part -> Filter -> Maybe OptionalParams -> Http.Request YoutubePlaylistsListResponse
getPlaylists token parts filter optionalParams =
    Http.request
        { method = "GET"
        , headers =
            [ tokenToHeader token
            ]
        , url = buildUrl parts filter optionalParams
        , body = Http.emptyBody
        , expect = Http.expectJson decodeYoutubePlaylistsListResponse
        , timeout = Nothing
        , withCredentials = False
        }


buildUrl : List Part -> Filter -> Maybe OptionalParams -> String
buildUrl parts filter optionalParams =
    "https://www.googleapis.com/youtube/v3/playlists?"
        ++ partsToParam parts
        ++ "&"
        ++ filterToParam filter
        ++ optionalParamsToParams optionalParams


partsToParam : List Part -> String
partsToParam parts =
    "part=" ++ (String.concat <| List.intersperse "," (List.map partToString parts))


partToString : Part -> String
partToString part =
    case part of
        ContentDetails ->
            "contentDetails"

        IdPart ->
            "id"

        SnippetPart ->
            "snippet"

        Status ->
            "status"

        Localizations ->
            "localizations"

        Player ->
            "player"


filterToParam : Filter -> String
filterToParam filter =
    case filter of
        ChannelId channelId ->
            "channelId=" ++ channelId

        Id id ->
            "id=" ++ id

        Mine mine ->
            "mine=" ++ (String.toLower <| toString mine)


optionalParamsToParams : Maybe OptionalParams -> String
optionalParamsToParams optionalParams =
    let
        optParamToParam paramKey param =
            Maybe.withDefault "" <| Maybe.map (\x -> "&" ++ paramKey ++ "=" ++ x) param

        intOptParamToParam paramKey param =
            Maybe.withDefault "" <| Maybe.map (\x -> "&" ++ paramKey ++ "=" ++ toString x) param
    in
    case optionalParams of
        Just optParams ->
            optParamToParam "hl" optParams.hl
                ++ intOptParamToParam "maxResults" optParams.maxResults
                ++ optParamToParam "onBehalfOfContentOwner" optParams.onBehalfOfContentOwner
                ++ optParamToParam "onBehalfOfContentOwnerChannel" optParams.onBehalfOfContentOwnerChannel
                ++ optParamToParam "pageToken" optParams.pageToken

        Nothing ->
            ""


type alias YoutubePlaylistsListResponse =
    { kind : String
    , etag : String
    , nextPageToken : Maybe String
    , pageInfo : YoutubePlaylistsListResponsePageInfo
    , items : List YoutubePlaylist
    }


type alias YoutubePlaylistsListResponsePageInfo =
    { totalResults : Int
    , resultsPerPage : Int
    }


type alias YoutubePlaylist =
    { kind : String
    , etag : String
    , id : String
    , snippet : YoutubePlaylistSnippet
    , contentDetails : YoutubePlaylistContentDetails
    }


type alias YoutubePlaylistSnippetThumbnail =
    { url : String
    , width : Int
    , height : Int
    }


type alias YoutubePlaylistSnippetThumbnails =
    { default : YoutubePlaylistSnippetThumbnail
    , medium : YoutubePlaylistSnippetThumbnail
    , high : YoutubePlaylistSnippetThumbnail
    , standard : YoutubePlaylistSnippetThumbnail
    , maxres : YoutubePlaylistSnippetThumbnail
    }


type alias YoutubePlaylistSnippetLocalized =
    { title : String
    , description : String
    }


type alias YoutubePlaylistSnippet =
    { publishedAt : String
    , channelId : String
    , title : String
    , description : String
    , thumbnails : Dict.Dict String YoutubePlaylistSnippetThumbnail
    , channelTitle : String
    , localized : YoutubePlaylistSnippetLocalized
    }


type alias YoutubePlaylistContentDetails =
    { itemCount : Int
    }


decodeYoutubePlaylist : Json.Decode.Decoder YoutubePlaylist
decodeYoutubePlaylist =
    Json.Decode.Pipeline.decode YoutubePlaylist
        |> Json.Decode.Pipeline.required "kind" Json.Decode.string
        |> Json.Decode.Pipeline.required "etag" Json.Decode.string
        |> Json.Decode.Pipeline.required "id" Json.Decode.string
        |> Json.Decode.Pipeline.required "snippet" decodeYoutubePlaylistSnippet
        |> Json.Decode.Pipeline.required "contentDetails" decodeYoutubePlaylistContentDetails


decodeYoutubePlaylistSnippetThumbnail : Json.Decode.Decoder YoutubePlaylistSnippetThumbnail
decodeYoutubePlaylistSnippetThumbnail =
    Json.Decode.Pipeline.decode YoutubePlaylistSnippetThumbnail
        |> Json.Decode.Pipeline.required "url" Json.Decode.string
        |> Json.Decode.Pipeline.required "width" Json.Decode.int
        |> Json.Decode.Pipeline.required "height" Json.Decode.int


decodeYoutubePlaylistSnippetThumbnails : Json.Decode.Decoder YoutubePlaylistSnippetThumbnails
decodeYoutubePlaylistSnippetThumbnails =
    Json.Decode.Pipeline.decode YoutubePlaylistSnippetThumbnails
        |> Json.Decode.Pipeline.required "default" decodeYoutubePlaylistSnippetThumbnail
        |> Json.Decode.Pipeline.required "medium" decodeYoutubePlaylistSnippetThumbnail
        |> Json.Decode.Pipeline.required "high" decodeYoutubePlaylistSnippetThumbnail
        |> Json.Decode.Pipeline.required "standard" decodeYoutubePlaylistSnippetThumbnail
        |> Json.Decode.Pipeline.required "maxres" decodeYoutubePlaylistSnippetThumbnail


decodeYoutubePlaylistSnippetLocalized : Json.Decode.Decoder YoutubePlaylistSnippetLocalized
decodeYoutubePlaylistSnippetLocalized =
    Json.Decode.Pipeline.decode YoutubePlaylistSnippetLocalized
        |> Json.Decode.Pipeline.required "title" Json.Decode.string
        |> Json.Decode.Pipeline.required "description" Json.Decode.string


decodeYoutubePlaylistSnippet : Json.Decode.Decoder YoutubePlaylistSnippet
decodeYoutubePlaylistSnippet =
    Json.Decode.Pipeline.decode YoutubePlaylistSnippet
        |> Json.Decode.Pipeline.required "publishedAt" Json.Decode.string
        |> Json.Decode.Pipeline.required "channelId" Json.Decode.string
        |> Json.Decode.Pipeline.required "title" Json.Decode.string
        |> Json.Decode.Pipeline.required "description" Json.Decode.string
        |> Json.Decode.Pipeline.required "thumbnails" (Json.Decode.dict decodeYoutubePlaylistSnippetThumbnail)
        --decodeYoutubePlaylistSnippetThumbnails
        |> Json.Decode.Pipeline.required "channelTitle" Json.Decode.string
        |> Json.Decode.Pipeline.required "localized" decodeYoutubePlaylistSnippetLocalized


decodeYoutubePlaylistContentDetails : Json.Decode.Decoder YoutubePlaylistContentDetails
decodeYoutubePlaylistContentDetails =
    Json.Decode.Pipeline.decode YoutubePlaylistContentDetails
        |> Json.Decode.Pipeline.required "itemCount" Json.Decode.int


decodeYoutubePlaylistsListResponse : Json.Decode.Decoder YoutubePlaylistsListResponse
decodeYoutubePlaylistsListResponse =
    Json.Decode.Pipeline.decode YoutubePlaylistsListResponse
        |> Json.Decode.Pipeline.required "kind" Json.Decode.string
        |> Json.Decode.Pipeline.required "etag" Json.Decode.string
        |> Json.Decode.Pipeline.optional "nextPageToken" (Json.Decode.nullable Json.Decode.string) Nothing
        |> Json.Decode.Pipeline.required "pageInfo" decodeYoutubePlaylistsListResponsePageInfo
        |> Json.Decode.Pipeline.required "items" (Json.Decode.list decodeYoutubePlaylist)


decodeYoutubePlaylistsListResponsePageInfo : Json.Decode.Decoder YoutubePlaylistsListResponsePageInfo
decodeYoutubePlaylistsListResponsePageInfo =
    Json.Decode.Pipeline.decode YoutubePlaylistsListResponsePageInfo
        |> Json.Decode.Pipeline.required "totalResults" Json.Decode.int
        |> Json.Decode.Pipeline.required "resultsPerPage" Json.Decode.int
