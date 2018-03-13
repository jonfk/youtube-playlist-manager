module Main.Route exposing (..)

import Http
import Navigation
import UrlParser exposing ((</>), (<?>), int, map, oneOf, parseHash, s, string, top)


type Route
    = Home
    | Settings


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


locFor : Navigation.Location -> Maybe Route
locFor path =
    parseHash pathParser path
