module Main.Pages.Videos exposing (..)

import Html exposing (Html, button, div, text)

type alias Model = {}

type Msg = NoOp

initialModel : Model
initialModel =
    {}

view : Model -> Html Msg
view model =
    div [] [ text "Videos Page" ]


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    model ! []
