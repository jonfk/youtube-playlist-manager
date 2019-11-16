module Main.Pages.Playlists exposing (Model, Msg(..), cmdOnPageLoad, initialModel, subscriptions, update, view)

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
        [ text "Plalists Page" ]


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
