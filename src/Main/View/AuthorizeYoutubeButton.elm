module Main.View.AuthorizeYoutubeButton exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes exposing (href)
import Material
import Material.Button as Button
import Material.Icon as Icon
import Material.Options as Options
import Navigation
import Youtube.Authorize


view : (Material.Msg msg -> msg) -> Material.Model -> Html msg
view mdlMsg mdlModel =
    let
        youtubeAuthorizeUrl =
            Youtube.Authorize.buildUri "1022327474530-ij2unslv94d4hjcrdh4toijljd17kt4g.apps.googleusercontent.com"
                "http://localhost:9000/test"
                Youtube.Authorize.ReadOnly
                "stateparam"
    in
    Html.a [ href youtubeAuthorizeUrl ]
        [ Button.render mdlMsg
            [ 1 ]
            mdlModel
            [ Button.icon
            ]
            [ Icon.i "account_circle" ]
        ]
