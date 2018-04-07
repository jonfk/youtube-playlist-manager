module Youtube.Playlist exposing (..)

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


getPlaylist : Token -> List Part -> Filter -> Maybe OptionalParams -> Http.Request YoutubePlaylistsListResponse
getPlaylist token parts filter optionalParams =
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
    "https://www.googleapis.com/youtube/v3/playlistItems?"
        ++ partsToParam parts
        ++ "&"
        ++ filterToParam filter
        ++ optionalParamsToParams optionalParams


partsToParam : List Part -> String
partsToParam parts =
    String.concat <| List.intersperse "," (List.map partToString parts)


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
    let
        idFiltersToString ids =
            String.concat <| List.intersperse "," ids
    in
    case filter of
        ChannelId channelId ->
            "channelId=" ++ channelId

        Id id ->
            "id=" ++ id

        Mine mine ->
            "mine=" ++ toString mine


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
    , nextPageToken : String
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
    , thumbnails : YoutubePlaylistSnippetThumbnails
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
        |> Json.Decode.Pipeline.required "thumbnails" decodeYoutubePlaylistSnippetThumbnails
        |> Json.Decode.Pipeline.required "channelTitle" Json.Decode.string
        |> Json.Decode.Pipeline.required "localized" decodeYoutubePlaylistSnippetLocalized


decodeYoutubePlaylistContentDetails : Json.Decode.Decoder YoutubePlaylistContentDetails
decodeYoutubePlaylistContentDetails =
    Json.Decode.Pipeline.decode YoutubePlaylistContentDetails
        |> Json.Decode.Pipeline.required "itemCount" Json.Decode.int


encodeYoutubePlaylist : YoutubePlaylist -> Json.Encode.Value
encodeYoutubePlaylist record =
    Json.Encode.object
        [ ( "kind", Json.Encode.string <| record.kind )
        , ( "etag", Json.Encode.string <| record.etag )
        , ( "id", Json.Encode.string <| record.id )
        , ( "snippet", encodeYoutubePlaylistSnippet <| record.snippet )
        , ( "contentDetails", encodeYoutubePlaylistContentDetails <| record.contentDetails )
        ]


encodeYoutubePlaylistSnippetThumbnail : YoutubePlaylistSnippetThumbnail -> Json.Encode.Value
encodeYoutubePlaylistSnippetThumbnail record =
    Json.Encode.object
        [ ( "url", Json.Encode.string <| record.url )
        , ( "width", Json.Encode.int <| record.width )
        , ( "height", Json.Encode.int <| record.height )
        ]


encodeYoutubePlaylistSnippetThumbnails : YoutubePlaylistSnippetThumbnails -> Json.Encode.Value
encodeYoutubePlaylistSnippetThumbnails record =
    Json.Encode.object
        [ ( "default", encodeYoutubePlaylistSnippetThumbnail <| record.default )
        , ( "medium", encodeYoutubePlaylistSnippetThumbnail <| record.medium )
        , ( "high", encodeYoutubePlaylistSnippetThumbnail <| record.high )
        , ( "standard", encodeYoutubePlaylistSnippetThumbnail <| record.standard )
        , ( "maxres", encodeYoutubePlaylistSnippetThumbnail <| record.maxres )
        ]


encodeYoutubePlaylistSnippetLocalized : YoutubePlaylistSnippetLocalized -> Json.Encode.Value
encodeYoutubePlaylistSnippetLocalized record =
    Json.Encode.object
        [ ( "title", Json.Encode.string <| record.title )
        , ( "description", Json.Encode.string <| record.description )
        ]


encodeYoutubePlaylistSnippet : YoutubePlaylistSnippet -> Json.Encode.Value
encodeYoutubePlaylistSnippet record =
    Json.Encode.object
        [ ( "publishedAt", Json.Encode.string <| record.publishedAt )
        , ( "channelId", Json.Encode.string <| record.channelId )
        , ( "title", Json.Encode.string <| record.title )
        , ( "description", Json.Encode.string <| record.description )
        , ( "thumbnails", encodeYoutubePlaylistSnippetThumbnails <| record.thumbnails )
        , ( "channelTitle", Json.Encode.string <| record.channelTitle )
        , ( "localized", encodeYoutubePlaylistSnippetLocalized <| record.localized )
        ]


encodeYoutubePlaylistContentDetails : YoutubePlaylistContentDetails -> Json.Encode.Value
encodeYoutubePlaylistContentDetails record =
    Json.Encode.object
        [ ( "itemCount", Json.Encode.int <| record.itemCount )
        ]


decodeYoutubePlaylistsListResponse : Json.Decode.Decoder YoutubePlaylistsListResponse
decodeYoutubePlaylistsListResponse =
    Json.Decode.Pipeline.decode YoutubePlaylistsListResponse
        |> Json.Decode.Pipeline.required "kind" Json.Decode.string
        |> Json.Decode.Pipeline.required "etag" Json.Decode.string
        |> Json.Decode.Pipeline.required "nextPageToken" Json.Decode.string
        |> Json.Decode.Pipeline.required "pageInfo" decodeYoutubePlaylistsListResponsePageInfo
        |> Json.Decode.Pipeline.required "items" (Json.Decode.list decodeYoutubePlaylist)


decodeYoutubePlaylistsListResponsePageInfo : Json.Decode.Decoder YoutubePlaylistsListResponsePageInfo
decodeYoutubePlaylistsListResponsePageInfo =
    Json.Decode.Pipeline.decode YoutubePlaylistsListResponsePageInfo
        |> Json.Decode.Pipeline.required "totalResults" Json.Decode.int
        |> Json.Decode.Pipeline.required "resultsPerPage" Json.Decode.int


encodeYoutubePlaylistsListResponse : YoutubePlaylistsListResponse -> Json.Encode.Value
encodeYoutubePlaylistsListResponse record =
    Json.Encode.object
        [ ( "kind", Json.Encode.string <| record.kind )
        , ( "etag", Json.Encode.string <| record.etag )
        , ( "nextPageToken", Json.Encode.string <| record.nextPageToken )
        , ( "pageInfo", encodeYoutubePlaylistsListResponsePageInfo <| record.pageInfo )
        , ( "items", Json.Encode.list <| List.map encodeYoutubePlaylist <| record.items )
        ]


encodeYoutubePlaylistsListResponsePageInfo : YoutubePlaylistsListResponsePageInfo -> Json.Encode.Value
encodeYoutubePlaylistsListResponsePageInfo record =
    Json.Encode.object
        [ ( "totalResults", Json.Encode.int <| record.totalResults )
        , ( "resultsPerPage", Json.Encode.int <| record.resultsPerPage )
        ]
