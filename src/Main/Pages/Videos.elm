module Main.Pages.Videos exposing (..)

import Html exposing (Html, button, div, text)
import PouchDB.Video as VideoDB


type alias Model =
    { playlistItems : List VideoDB.Document
    , searchResults : List VideoDB.Document
    , searchTerms : Maybe String
    }


type Msg
    = NoOp
    | FetchedVideos (List VideoDB.Document)


initialModel : Model
initialModel =
    { playlistItems = []
    , searchResults = []
    , searchTerms = Nothing
    }


view : Model -> Html Msg
view model =
    div []
        [ text "Videos Page"
        , text <| toString model
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        FetchedVideos videoDocuments ->
            ( { model | playlistItems = videoDocuments }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ VideoDB.fetchedVideos FetchedVideos
        ]


cmdOnPageLoad : Cmd Msg
cmdOnPageLoad =
    VideoDB.fetchVideos VideoDB.defaultFetchVideosArgs
