module Main.View.VideosList exposing (..)

import Html exposing (Html, button, div, text)
import Material
import Material.List as Lists
import Material.Options as Options
import PouchDB.Videos as VideoDB


view : List VideoDB.Doc -> Html msg
view model =
    div []
        [ Lists.ul []
            (model
                |> List.indexedMap viewRow
            )
        ]


viewRow : Int -> VideoDB.Doc -> Html msg
viewRow index doc =
    Lists.li [ Lists.withBody ]
        -- NB! Required on every Lists.li containing body.
        [ Lists.content []
            [ text doc.video.title
            , Lists.body []
                [ Options.span [ Options.css "font-weight" "600" ] [ text doc.id ]
                , Options.span [] [ text " - " ]
                , Options.span [] [ text doc.video.description ]
                ]
            ]
        ]
