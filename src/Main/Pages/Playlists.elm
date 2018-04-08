module Main.Pages.Playlists exposing (..)

import Html exposing (Html, button, div, text)
import PouchDB.Youtube


type alias Model =
    {}


type Msg
    = NoOp
    | FetchedYoutubeData (Maybe PouchDB.Youtube.YoutubeDataDoc)
    | PouchDBError String


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
        [ PouchDB.Youtube.fetchedYoutubeData FetchedYoutubeData
        , PouchDB.Youtube.youtubeDataPortErr PouchDBError
        ]


cmdOnPageLoad : Cmd Msg
cmdOnPageLoad =
    Cmd.none
