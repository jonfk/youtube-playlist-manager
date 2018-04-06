module Main.Pages.Settings exposing (..)

import Html exposing (Html, button, div, text)
import Material
import Material.Icon as Icon
import Material.List as Lists
import Material.Options as Options
import Material.Button as Button


type alias Model =
    { mdl : Material.Model
    }


type Msg
    = NoOp
    | Mdl (Material.Msg Msg)


initialModel : Model
initialModel =
    { mdl = Material.model
    }


view : Model -> Html Msg
view model =
    div []
        [ text "Settings Page"
        , viewSettingsActionsList model
        , text <| toString model
        ]


viewSettingsActionsList : Model -> Html Msg
viewSettingsActionsList model =
    Lists.ul []
        [ Lists.li []
            [ Lists.content [] [ text "Sign In" ]
            , Button.render Mdl
                [ 1 ]
                model.mdl
                [ Button.icon
                , Options.onClick NoOp
                ]
                [ Icon.i "account_circle" ]
            ]
        , Lists.li []
            [ Lists.content [] [ text "Sync" ]
            , Button.render Mdl
                [ 2 ]
                model.mdl
                [ Button.icon
                , Options.onClick NoOp
                ]
                [ Icon.i "sync" ]
            ]
        , Lists.li []
            [ Lists.content [] [ text "Delete DB" ]
            , Button.render Mdl
                [ 2 ]
                model.mdl
                [ Button.icon
                , Options.onClick NoOp
                ]
                [ Icon.i "delete_forever" ]
            ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        Mdl msg_ ->
            Material.update Mdl msg_ model


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        []


cmdOnPageLoad : Cmd Msg
cmdOnPageLoad =
    Cmd.none
