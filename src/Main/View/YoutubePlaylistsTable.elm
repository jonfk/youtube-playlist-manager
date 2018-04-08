module Main.View.YoutubePlaylistsTable exposing (..)

import Html exposing (Html, button, div, text)
import Material
import Material.Options as Options
import Material.Table as Table
import Youtube.Playlist as YTPlaylists


view : List YTPlaylists.YoutubePlaylist -> Html msg
view model =
    div []
        [ Table.table []
            [ Table.thead []
                [ Table.tr []
                    [ Table.th [] [ text "Id" ]
                    , Table.th [] [ text "Title" ]
                    , Table.th [] [ text "Description" ]
                    ]
                ]
            , Table.tbody []
                (model
                    |> List.map
                        (\item ->
                            Table.tr []
                                [ Table.td [] [ text item.id ]
                                , Table.td [] [ text item.snippet.title ]
                                , Table.td [] [ text item.snippet.description ]
                                ]
                        )
                )
            ]
        ]
