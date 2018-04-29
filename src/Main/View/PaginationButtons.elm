module Main.View.PaginationButtons exposing (..)

import Html exposing (Html, button, div, text)
import Material
import Material.Button as Button
import Material.Options as Options
import Maybe.Extra


type alias Model =
    { mdl : Material.Model
    , currentIndex : Int
    , limitPerPage : Int
    , total : Maybe Int
    }


prevButton : Model -> (Material.Msg msg -> msg) -> (Int -> msg) -> Html msg
prevButton model mdlMsg fetchMsg =
    Button.render mdlMsg
        [ 1, 0 ]
        model.mdl
        [ Button.raised
        , Options.when (model.currentIndex <= 0 || Maybe.Extra.isNothing model.total) Button.disabled
        , Options.onClick <| fetchMsg (model.currentIndex - model.limitPerPage)
        ]
        [ text "Prev" ]


nextButton : Model -> (Material.Msg msg -> msg) -> (Int -> msg) -> Html msg
nextButton model mdlMsg fetchMsg =
    Button.render mdlMsg
        [ 1, 1 ]
        model.mdl
        [ Button.raised
        , Options.when (Maybe.map (\total -> model.currentIndex >= total) model.total |> Maybe.withDefault True) Button.disabled
        , Options.onClick <| fetchMsg (model.currentIndex + model.limitPerPage)
        ]
        [ text "Next" ]


view : Model -> (Material.Msg msg -> msg) -> (Int -> msg) -> Html msg
view model mdlMsg fetchMsg =
    div []
        [ prevButton model mdlMsg fetchMsg
        , nextButton model mdlMsg fetchMsg
        ]
