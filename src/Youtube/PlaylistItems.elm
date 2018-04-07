module Youtube.PlaylistItems exposing (..)

import Dict
import Http
import Json.Decode exposing (Decoder, dict, float, int, list, nullable, string)
import Json.Decode.Pipeline exposing (decode, optional, required)
import List
import Maybe
import Youtube exposing (Token, tokenToHeader)


type Part
    = ContentDetails
    | IdPart
    | SnippetPart
    | Status


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


partsToString : List Part -> String
partsToString parts =
    String.concat <| List.intersperse "," (List.map partToString parts)


type Filter
    = IdFilter (List String)
    | PlaylistId String


filterToParam : Filter -> String
filterToParam filter =
    let
        idFiltersToString ids =
            String.concat <| List.intersperse "," ids
    in
    case filter of
        IdFilter ids ->
            "id=" ++ idFiltersToString ids

        PlaylistId id ->
            "playlistId=" ++ id


type alias MaxResults =
    Maybe Int


type alias OnBehalfOfContentOwner =
    Maybe String


type alias PageToken =
    Maybe String


type alias VideoId =
    Maybe String


buildUrl : List Part -> Filter -> MaxResults -> OnBehalfOfContentOwner -> PageToken -> VideoId -> String
buildUrl parts filter maxResults onBehalfOfContentOwner pageToken videoId =
    let
        maxResultsParam =
            Maybe.withDefault "" <| Maybe.map (\x -> "&maxResults=" ++ toString x) maxResults

        onBehalfOfContentOwnerParam =
            Maybe.withDefault "" <| Maybe.map (\x -> "&onBehalfOfContentOwner=" ++ x) onBehalfOfContentOwner

        pageTokenParam =
            Maybe.withDefault "" <| Maybe.map (\x -> "&pageToken=" ++ x) pageToken

        videoIdParam =
            Maybe.withDefault "" <| Maybe.map (\x -> "&videoId=" ++ x) videoId
    in
    "https://www.googleapis.com/youtube/v3/playlistItems?"
        ++ "part="
        ++ partsToString parts
        ++ "&"
        ++ filterToParam filter
        ++ maxResultsParam
        ++ onBehalfOfContentOwnerParam
        ++ pageTokenParam
        ++ videoIdParam


getPlaylistItems : Token -> List Part -> Filter -> MaxResults -> OnBehalfOfContentOwner -> PageToken -> VideoId -> Http.Request PlaylistItemListResponse
getPlaylistItems token parts filter maxResults onBehalfOfContentOwner pageToken videoId =
    Http.request
        { method = "GET"
        , headers =
            [ tokenToHeader token
            ]
        , url = buildUrl parts filter maxResults onBehalfOfContentOwner pageToken videoId
        , body = Http.emptyBody
        , expect = Http.expectJson playlistItemListResponseDecoder
        , timeout = Nothing
        , withCredentials = False
        }


type alias PlaylistItemListResponse =
    { kind : String
    , etag : String
    , nextPageToken : Maybe String
    , prevPageToken : Maybe String
    , pageInfo : PageInfo
    , items : List PlaylistItem
    }


type alias PageInfo =
    { totalResults : Int
    , resultsPerPage : Int
    }


type alias PlaylistItem =
    { kind : String
    , etag : String
    , id : Maybe String
    , snippet : Maybe Snippet
    }


type alias ResourceId =
    { kind : String
    , videoId : String
    }


type alias Snippet =
    { publishedAt : String
    , channelId : String
    , title : String
    , description : String
    , channelTitle : String
    , playlistId : String
    , position : Int
    , thumbnails : Dict.Dict String Thumbnail
    , resourceId : ResourceId
    }


type alias Thumbnail =
    { url : String
    , width : Int
    , height : Int
    }


playlistItemListResponseDecoder : Decoder PlaylistItemListResponse
playlistItemListResponseDecoder =
    decode PlaylistItemListResponse
        |> required "kind" string
        |> required "etag" string
        |> optional "nextPageToken" (nullable string) Nothing
        |> optional "prevPageToken" (nullable string) Nothing
        |> required "pageInfo" pageInfoDecoder
        |> required "items" (list playlistItemDecoder)


pageInfoDecoder : Decoder PageInfo
pageInfoDecoder =
    decode PageInfo
        |> required "totalResults" int
        |> required "resultsPerPage" int


playlistItemDecoder : Decoder PlaylistItem
playlistItemDecoder =
    decode PlaylistItem
        |> required "kind" string
        |> required "etag" string
        |> required "id" (nullable string)
        |> required "snippet" (nullable snippetDecoder)


snippetDecoder : Decoder Snippet
snippetDecoder =
    decode Snippet
        |> required "publishedAt" string
        |> required "channelId" string
        |> required "title" string
        |> required "description" string
        |> required "channelTitle" string
        |> required "playlistId" string
        |> required "position" int
        |> required "thumbnails" (dict thumbnailDecoder)
        |> required "resourceId" resourceIdDecoder


resourceIdDecoder : Decoder ResourceId
resourceIdDecoder =
    decode ResourceId
        |> required "kind" string
        |> required "videoId" string


thumbnailDecoder : Decoder Thumbnail
thumbnailDecoder =
    decode Thumbnail
        |> required "url" string
        |> required "width" int
        |> required "height" int


test =
    Json.Decode.decodeString
        playlistItemListResponseDecoder
        """{
    "kind": "youtube#playlistItemListResponse",
    "etag": "\\"m2yskBQFythfE4irbTIeOgYYfBU/9AVqzq--edMVetJiYD1gASozev4\\"",
    "nextPageToken": "CDIQAA",
    "pageInfo": {
        "totalResults": 71,
        "resultsPerPage": 50
    },
    "items": [
        {
            "kind": "youtube#playlistItem",
            "etag": "\\"m2yskBQFythfE4irbTIeOgYYfBU/LTlV1sDzVhvB2FSqeJJreWcP9pk\\"",
            "id": "UExqY0NpSWJSekhjREhLcXFjT2doTVFVRkd2NXdkRTk2Ri41NkI0NEY2RDEwNTU3Q0M2",
            "snippet": {
                "publishedAt": "2017-05-24T23:59:49.000Z",
                "channelId": "UCxp3KT49rjbwgx_FDJely4g",
                "title": "Quick Cured Salmon - How to Cure Salmon in 3 Minutes",
                "description": "Learn how to make Quick Cured Salmon! Go to http://foodwishes.blogspot.com/2014/04/quick-cured-salmon-3-minutes-but-i-want.html for the ingredient amounts, extra information, and many, many more video recipes! I hope you enjoy this easy, \\"How to Cure Salmon in 3 Minutes\\" demo!",
                "thumbnails": {
                    "default": {
                        "url": "https://i.ytimg.com/vi/bFoIJCDEqGw/default.jpg",
                        "width": 120,
                        "height": 90
                    },
                    "medium": {
                        "url": "https://i.ytimg.com/vi/bFoIJCDEqGw/mqdefault.jpg",
                        "width": 320,
                        "height": 180
                    },
                    "high": {
                        "url": "https://i.ytimg.com/vi/bFoIJCDEqGw/hqdefault.jpg",
                        "width": 480,
                        "height": 360
                    },
                    "standard": {
                        "url": "https://i.ytimg.com/vi/bFoIJCDEqGw/sddefault.jpg",
                        "width": 640,
                        "height": 480
                    },
                    "maxres": {
                        "url": "https://i.ytimg.com/vi/bFoIJCDEqGw/maxresdefault.jpg",
                        "width": 1280,
                        "height": 720
                    }
                },
                "channelTitle": "jfk",
                "playlistId": "PLjcCiIbRzHcDHKqqcOghMQUFGv5wdE96F",
                "position": 0,
                "resourceId": {
                    "kind": "youtube#video",
                    "videoId": "bFoIJCDEqGw"
                }
            },
            "contentDetails": {
                "videoId": "bFoIJCDEqGw",
                "videoPublishedAt": "2014-04-14T16:23:09.000Z"
            },
            "status": {
                "privacyStatus": "public"
            }
        }
    ]
        }"""
