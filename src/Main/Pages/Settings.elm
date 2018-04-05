module Main.Pages.Settings exposing (..)

import Html exposing (Html, button, div, text)


type alias Model =
    {}


type Msg
    = NoOp


initialModel : Model
initialModel =
    {}


view : Model -> Html Msg
view model =
    div []
        [ text "Settings Page"
        , text <| toString model
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        []


cmdOnPageLoad : Cmd Msg
cmdOnPageLoad =
    Cmd.none
