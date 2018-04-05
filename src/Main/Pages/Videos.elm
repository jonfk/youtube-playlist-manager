module Main.Pages.Videos exposing (..)

import Html exposing (Html, button, div, text)
import PouchDB


type alias Model =
    { playlistItems : List PouchDB.Document
    , searchResults : List PouchDB.Document
    , searchTerms : Maybe String
    }


type Msg
    = NoOp


initialModel : Model
initialModel =
    { playlistItems = []
    , searchResults = []
    , searchTerms = Nothing
    }


view : Model -> Html Msg
view model =
    div [] [ text "Videos Page" ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    model ! []

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch []
