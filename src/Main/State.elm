module Main.State exposing (..)

import Http
import Main.Route as Route exposing (..)
import Navigation
import PouchDB
import PouchDB.Search
import Youtube.Authorize exposing (parseTokenFromRedirectUri)
import Youtube.Playlist exposing (Filter(..), Part(..), PlaylistItem, PlaylistItemListResponse)


-- MODEL


type ViewMode
    = ViewVideos
    | ViewSearchResults


type alias Model =
    { location : Maybe Route.Route
    , viewMode : ViewMode
    , playlistItems : List PouchDB.Document
    , searchResults : List PouchDB.Document
    , searchTerms : Maybe String
    , playlistResponses : List PlaylistItemListResponse
    , err : Maybe Http.Error
    , token : Maybe String
    }



-- UPDATE


type Msg
    = NoOp
    | NavigateTo Navigation.Location
    | FetchNewPlaylistItems
    | NewPlaylistItems (Result Http.Error PlaylistItemListResponse)
    | AuthorizeYoutube Bool
    | AuthorizedRedirectUri Navigation.Location
    | DeleteDatabase
    | FetchedVideos (List PouchDB.Document)
    | FetchVideos PouchDB.FetchVideosArgs
    | StartSearch
    | UpdateSearch String
    | SearchedVideos (List PouchDB.Document)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        NavigateTo location ->
            location
                |> Route.locFor
                |> urlUpdate model

        FetchNewPlaylistItems ->
            let
                mapfetch =
                    Maybe.map (\token -> fetchPlaylistItems token) model.token

                fetchIfTokenExists =
                    Maybe.withDefault Cmd.none mapfetch
            in
            ( model, fetchIfTokenExists )

        NewPlaylistItems (Ok playlistItemResp) ->
            let
                token =
                    Maybe.withDefault "" model.token

                documents =
                    PouchDB.fromYoutubePlaylistItems playlistItemResp.items

                commands =
                    Cmd.batch [ fetchAllPlaylistItemsAndRefreshPage token playlistItemResp, PouchDB.storeVideos documents ]
            in
            ( { model
                | playlistResponses = playlistItemResp :: model.playlistResponses
              }
            , commands
            )

        NewPlaylistItems (Err httpErr) ->
            ( { model | err = Just httpErr }, Cmd.none )

        AuthorizeYoutube interactive ->
            ( model, Youtube.Authorize.authorize interactive )

        AuthorizedRedirectUri redirectUri ->
            let
                a =
                    Debug.log "redirectUri received" redirectUri

                parsedToken =
                    Debug.log "parsed token" <| parseTokenFromRedirectUri redirectUri
            in
            ( { model | token = parsedToken }, Cmd.none )

        DeleteDatabase ->
            ( model, PouchDB.deleteDatabase True )

        FetchVideos args ->
            ( model, PouchDB.fetchVideos args )

        FetchedVideos videoDocuments ->
            ( { model | playlistItems = videoDocuments }, Cmd.none )

        StartSearch ->
            let
                searchCmd =
                    Maybe.withDefault Cmd.none <| Maybe.map PouchDB.Search.searchVideos model.searchTerms
            in
            ( { model | viewMode = ViewSearchResults }, searchCmd )

        UpdateSearch arg ->
            if arg == "" then
                ( { model | searchTerms = Nothing, viewMode = ViewVideos }, Cmd.none )
            else
                ( { model | searchTerms = Just arg }, Cmd.none )

        SearchedVideos videos ->
            ( { model | searchResults = videos }, Cmd.none )


urlUpdate : Model -> Maybe Route -> ( Model, Cmd Msg )
urlUpdate model route =
    let
        newModel =
            { model | location = route }
    in
    newModel ! []



--Pages.cmdOnNewLocation route ]
-- Playlist


fetchPlaylistItems : String -> Cmd Msg
fetchPlaylistItems token =
    fetchNextPlaylistItems token Nothing


fetchAllPlaylistItemsAndRefreshPage : String -> PlaylistItemListResponse -> Cmd Msg
fetchAllPlaylistItemsAndRefreshPage token resp =
    let
        fetchPlaylistItems =
            fetchNextPlaylistItems token resp.nextPageToken

        fetchVideosFromPouchDB =
            PouchDB.fetchVideos PouchDB.defaultFetchVideosArgs
    in
    case resp.nextPageToken of
        Just nextPageToken ->
            Cmd.batch [ fetchPlaylistItems, fetchVideosFromPouchDB ]

        Nothing ->
            fetchVideosFromPouchDB


fetchNextPlaylistItems : String -> Maybe String -> Cmd Msg
fetchNextPlaylistItems token nextPageToken =
    Http.send NewPlaylistItems <|
        Youtube.Playlist.getPlaylistItems token [ IdPart, SnippetPart ] (PlaylistId "PLjcCiIbRzHcDHKqqcOghMQUFGv5wdE96F") (Just 10) Nothing nextPageToken Nothing



-- PORTS and SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Youtube.Authorize.authorizedRedirectUri AuthorizedRedirectUri
        , PouchDB.fetchedVideos FetchedVideos
        , PouchDB.Search.searchedVideos SearchedVideos
        ]
