module Main.Pages.Videos exposing (..)

import Html exposing (Html, button, div, text)
import Main.View.VideosList as VideosList
import Material
import Material.Button as Button
import Material.Options as Options
import PouchDB.Videos as VideoDB


type alias Model =
    { mdl : Material.Model
    , playlistItems : List VideoDB.Doc
    , totalVideos : Maybe Int
    , currentIndex : Int
    , searchResults : List VideoDB.Doc
    , searchTerms : Maybe String
    }


type Msg
    = NoOp
    | FetchedVideos VideoDB.VideosResult
    | FetchVideos Int
    | Mdl (Material.Msg Msg)


initialModel : Model
initialModel =
    { mdl = Material.model
    , playlistItems = []
    , totalVideos = Nothing
    , currentIndex = 0
    , searchResults = []
    , searchTerms = Nothing
    }



-- TODO Add error card to page


view : Model -> Html Msg
view model =
    div []
        [ text "Videos Page"
        , nextButton model
        , VideosList.view model.playlistItems
        , text <| toString model
        ]


nextButton : Model -> Html Msg
nextButton model =
    Button.render Mdl
        [ 0 ]
        model.mdl
        [ Button.raised
        , Options.onClick <| FetchVideos (model.currentIndex + VideoDB.defaultVideosLimitArg)
        ]
        [ text "Next Videos" ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        FetchedVideos videosResult ->
            ( { model | playlistItems = videosResult.docs, totalVideos = Just videosResult.totalRows }, Cmd.none )

        FetchVideos nextIndex ->
            { model | currentIndex = nextIndex } ! [ VideoDB.fetchVideosArgs nextIndex |> VideoDB.fetchVideos ]

        Mdl msg_ ->
            Material.update Mdl msg_ model


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ VideoDB.fetchedVideos FetchedVideos
        ]


cmdOnPageLoad : Cmd Msg
cmdOnPageLoad =
    VideoDB.fetchVideos VideoDB.defaultFetchVideosArgs
