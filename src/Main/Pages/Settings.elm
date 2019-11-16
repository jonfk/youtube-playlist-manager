module Main.Pages.Settings exposing (Model, Msg(..), cmdOnPageLoad, initialModel, subscriptions, update, view)

import Html exposing (Html, div, text)


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


cmdOnPageLoad : Model -> Cmd Msg
cmdOnPageLoad model =
    Cmd.none
