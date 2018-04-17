module Main.View.ErrorCard exposing (..)

import Html exposing (Html, div, text)
import Material
import Material.Button as Button
import Material.Card as Card
import Material.Color as Color
import Material.Icon as Icon
import Material.Options as Options


view : Material.Model -> List String -> msg -> (Material.Msg msg -> msg) -> Html msg
view mdlModel errorsModel dismissMsg mdlMsg =
    let
        whiteText =
            Color.text Color.white
    in
    case errorsModel of
        [] ->
            div [] []

        errors ->
            Card.view
                [ Color.background (Color.color Color.Red Color.S400)
                , Options.css "width" "100%"

                --, Options.css "height" "192px"
                ]
                [ Card.title [] [ Card.head [ whiteText ] [ text "Error" ] ]
                , Card.text [ whiteText ] [ text <| String.join ", " errors ]
                , Card.actions
                    [ Card.border, Options.css "vertical-align" "center", Options.css "text-align" "right", whiteText ]
                    [ Button.render mdlMsg
                        [ 8, 1 ]
                        mdlModel
                        [ Button.icon
                        , Button.ripple
                        , Options.onClick dismissMsg
                        ]
                        [ Icon.i "close" ]
                    ]
                ]
