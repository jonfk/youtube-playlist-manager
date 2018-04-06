module Main.State exposing (..)

import Http
import Main.Pages.Settings
import Main.Pages.Videos
import Main.Route as Route exposing (..)
import Material
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
    , mdl : Material.Model
    , videosPage : Main.Pages.Videos.Model
    , settingsPage : Main.Pages.Settings.Model
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
    | Mdl (Material.Msg Msg)
    | NewUrl String
    | VideosMsg Main.Pages.Videos.Msg
    | SettingsMsg Main.Pages.Settings.Msg
      -- OLD
    | FetchNewPlaylistItems
    | NewPlaylistItems (Result Http.Error PlaylistItemListResponse)
    | DeleteDatabase
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

        Mdl msg_ ->
            Material.update Mdl msg_ model

        NewUrl url ->
            model ! [ Navigation.newUrl url ]

        VideosMsg videosMsg_ ->
            let
                ( subModel, subCmd ) =
                    Main.Pages.Videos.update videosMsg_ model.videosPage
            in
            { model | videosPage = subModel } ! [ Cmd.map VideosMsg subCmd ]

        SettingsMsg subMsg_ ->
            let
                ( subModel, subCmd ) =
                    Main.Pages.Settings.update subMsg_ model.settingsPage
            in
            { model | settingsPage = subModel } ! [ Cmd.map SettingsMsg subCmd ]

        -- OLD
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

        DeleteDatabase ->
            ( model, PouchDB.deleteDatabase True )

        FetchVideos args ->
            ( model, PouchDB.fetchVideos args )

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
    newModel ! [ cmdOnNewLocation route ]


cmdOnNewLocation : Maybe Route.Route -> Cmd Msg
cmdOnNewLocation route =
    case route of
        Nothing ->
            Cmd.none

        Just Route.Home ->
            Cmd.map VideosMsg Main.Pages.Videos.cmdOnPageLoad

        Just Route.Settings ->
            Cmd.map SettingsMsg Main.Pages.Settings.cmdOnPageLoad



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
        [ PouchDB.Search.searchedVideos SearchedVideos
        , Sub.map VideosMsg <| Main.Pages.Videos.subscriptions model.videosPage
        , Sub.map SettingsMsg <| Main.Pages.Settings.subscriptions model.settingsPage
        ]
