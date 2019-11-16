module Main.Pages.Videos exposing (Model, Msg(..), cmdOnPageLoad, initialModel, subscriptions, update, view)

import Html exposing (Html, button, div, text)
import Main.View.ErrorCard
import Main.View.PaginationButtons as PaginationButtons
import Main.View.VideosList as VideosList
import Material
import Material.Button as Button
import Material.Options as Options
import PouchDB.Videos as VideoDB


type alias Model =
    {}


type Msg
    = NoOp


initialModel : Model
initialModel =
    {}



-- TODO Add error card to page


view : Model -> Html Msg
view model =
    div []
        [ text "Videos Page"
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
