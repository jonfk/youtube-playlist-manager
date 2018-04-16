module Main.View.YoutubePlaylistsTable exposing (..)

import Html exposing (Html, button, div, text)
import Material
import Material.Options as Options
import Material.Table as Table
import Material.Toggles as Toggles
import Youtube.Playlist as YTPlaylists
import PouchDB.Playlists as DBPlaylists
import Dict


view : List DBPlaylists.Doc -> (String -> Bool) -> Material.Model -> (Material.Msg msg -> msg) -> (DBPlaylists.Doc -> msg) -> Html msg
view model isSelected mdlModel mdlMsg selectItem =
    div []
        [ Table.table []
            [ Table.thead []
                [ Table.tr []
                    [ Table.th [] [ text "Selected" ]
                    , Table.th [] [ text "Id" ]
                    , Table.th [] [ text "Title" ]
                    --, Table.th [] [ text "Description" ]
                    ]
                ]
            , Table.tbody []
                (model
                    |> List.indexedMap
                        (\idx item ->
                            Table.tr []
                                [ Table.td []
                                    [ Toggles.checkbox mdlMsg
                                        [ idx ]
                                        mdlModel
                                        [ Options.onToggle (selectItem item)
                                        , Toggles.value <| isSelected item.id
                                        ]
                                        []
                                    ]
                                , Table.td [] [ text item.id ]
                                , Table.td [] [ text item.title ]
                                --, Table.td [] [ text item.snippet.description ]
                                ]
                        )
                )
            ]
        ]
