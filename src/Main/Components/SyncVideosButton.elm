module Main.Components.SyncVideosButton exposing (..)

import Html exposing (Html, button, div, text)
import Http
import Material
import Material.Button as Button
import Material.Options as Options


type alias Model =
    { mdl : Material.Model
    }


initialModel : Model
initialModel =
    { mdl = Material.model
    }


type Msg
    = NoOp
    | Mdl (Material.Msg Msg)
    | TriggerSync (List String)


view : Maybe String -> List String -> Model -> Html Msg
view token playlistIds model =
    div []
        [ Button.render Mdl
            [ 0 ]
            model.mdl
            [ Button.raised
            , Button.ripple
            , Options.onClick <| TriggerSync playlistIds
            ]
            [ text "Sync" ]
        ]


update : Maybe String -> Msg -> Model -> ( Model, Cmd Msg )
update token msg model =
    case msg of
        NoOp ->
            model ! []

        Mdl msg_ ->
            Material.update Mdl msg_ model

        TriggerSync playlistIds ->
            model ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch []


cmdOnLoad : Cmd Msg
cmdOnLoad =
    Cmd.none
