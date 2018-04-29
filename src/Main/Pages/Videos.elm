module Main.Pages.Videos exposing (..)

import Html exposing (Html, button, div, text)
import Main.View.ErrorCard
import Main.View.PaginationButtons as PaginationButtons
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
    , errors : List String
    }


type Msg
    = NoOp
    | Mdl (Material.Msg Msg)
    | FetchedVideos VideoDB.VideosResult
    | FetchVideos Int
    | DismissError
    | VideosDBErr String


initialModel : Model
initialModel =
    { mdl = Material.model
    , playlistItems = []
    , totalVideos = Nothing
    , currentIndex = 0
    , searchResults = []
    , searchTerms = Nothing
    , errors = []
    }



-- TODO Add error card to page


view : Model -> Html Msg
view model =
    let
        paginationModel =
            { mdl = model.mdl, currentIndex = model.currentIndex, limitPerPage = VideoDB.defaultVideosLimitArg, total = model.totalVideos }
    in
    div []
        [ text "Videos Page"
        , Main.View.ErrorCard.view model.mdl model.errors DismissError Mdl
        , PaginationButtons.view paginationModel Mdl FetchVideos
        , VideosList.view model.playlistItems
        , PaginationButtons.view paginationModel Mdl FetchVideos

        --, text <| toString model
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        Mdl msg_ ->
            Material.update Mdl msg_ model

        FetchedVideos videosResult ->
            ( { model | playlistItems = videosResult.docs, totalVideos = Just videosResult.totalRows }, Cmd.none )

        FetchVideos nextIndex ->
            { model | currentIndex = nextIndex } ! [ VideoDB.fetchVideosArgs nextIndex |> VideoDB.fetchVideos ]

        DismissError ->
            { model | errors = [] } ! []

        VideosDBErr error ->
            { model | errors = List.append model.errors [ error ] } ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ VideoDB.fetchedVideos FetchedVideos
        , VideoDB.pouchdbVideoErr VideosDBErr
        ]


cmdOnPageLoad : Cmd Msg
cmdOnPageLoad =
    VideoDB.fetchVideos VideoDB.defaultFetchVideosArgs
