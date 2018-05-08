module Main.Route exposing (..)

import Dict
import Http
import Navigation
import Youtube.Authorize
import UrlParser exposing ((</>), (<?>), int, intParam, map, oneOf, parseHash, s, string, stringParam, top)


type Route
    = Home
    | Settings
    | YoutubeRedirect Youtube.Authorize.YoutubeRedirectData


type alias Model =
    Maybe Route


pathParser : UrlParser.Parser (Route -> a) a
pathParser =
    oneOf
        [ map Home (s "")
        , map Settings (s "settings")
        ]


init : Maybe Route -> List (Maybe Route)
init location =
    case location of
        Nothing ->
            [ Just Home ]

        something ->
            [ something ]


urlFor : Route -> String
urlFor loc =
    case loc of
        Home ->
            "#/"

        Settings ->
            "#settings"

        YoutubeRedirect data ->
            "#/"


locFor : Navigation.Location -> Maybe Route
locFor location =
    let
        parsedRedirect =
            Youtube.Authorize.redirectStringParser location
    in
    case parsedRedirect of
        Just ytRedir ->
            Just <| YoutubeRedirect ytRedir

        Nothing ->
            parseHash pathParser (Debug.log "location " location)
