module Main.View.YoutubePlaylistsTable exposing (..)

import Html exposing (Html, button, div, text)
import List
import Main.Components.SyncVideosButton as SyncPlaylistButton
import Material
import Material.Button as Button
import Material.List as Lists
import Material.Options as Options
import Material.Toggles as Toggles
import PouchDB.Playlists as DBPlaylists
import Youtube.Playlist as YTPlaylists


type alias Model =
    { mdl : Material.Model
    , playlists : List DBPlaylists.Doc
    , token : Maybe String
    }


view : Model -> (Material.Msg msg -> msg) -> (SyncPlaylistButton.Msg -> msg) -> Html msg
view model mdlMsg syncMsg =
    div []
        [ Lists.ul [] <|
            List.indexedMap (\idx playlist -> viewRow idx playlist model.token model.mdl mdlMsg syncMsg) model.playlists
        ]


viewRow : Int -> DBPlaylists.Doc -> Maybe String -> Material.Model -> (Material.Msg msg -> msg) -> (SyncPlaylistButton.Msg -> msg) -> Html msg
viewRow idx playlist token mdlModel mdlMsg syncMsg =
    Lists.li [ Lists.withSubtitle ]
        [ Lists.content []
            [ text playlist.title
            , Lists.subtitle []
                [ text playlist.id ]
            ]
        , Lists.content2 []
            [ Html.map syncMsg <| SyncPlaylistButton.view [ 65, 1, idx ] token [ playlist ] mdlModel
            ]
        ]
