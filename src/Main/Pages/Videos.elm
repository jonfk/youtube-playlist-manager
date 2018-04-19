module Main.Pages.Videos exposing (..)

import Html exposing (Html, button, div, text)
import PouchDB.Videos as VideoDB
import Main.View.VideosList as VideosList


type alias Model =
    { playlistItems : List VideoDB.Doc
    , searchResults : List VideoDB.Doc
    , searchTerms : Maybe String
    }


type Msg
    = NoOp
    | FetchedVideos (List VideoDB.Doc)


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
        , VideosList.view model.playlistItems
        , text <| toString model
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        FetchedVideos videoDocs ->
            ( { model | playlistItems = videoDocs }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ VideoDB.fetchedVideos FetchedVideos
        ]


cmdOnPageLoad : Cmd Msg
cmdOnPageLoad =
    VideoDB.fetchVideos VideoDB.defaultFetchVideosArgs
