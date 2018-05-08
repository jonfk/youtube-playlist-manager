module Main.State exposing (..)

import Http
import Main.Pages.Settings
import Main.Pages.Videos
import Main.Route as Route exposing (..)
import Material
import Navigation
import PouchDB
import PouchDB.Search
import PouchDB.Youtube
import Youtube.Authorize exposing (parseTokenFromRedirectUri)
import Youtube.PlaylistItems exposing (Filter(..), Part(..), PlaylistItem, PlaylistItemListResponse)


-- MODEL


type alias Model =
    { location : Maybe Route.Route
    , mdl : Material.Model
    , videosPage : Main.Pages.Videos.Model
    , settingsPage : Main.Pages.Settings.Model
    }



-- UPDATE


type Msg
    = NoOp
    | NavigateTo Navigation.Location
    | Mdl (Material.Msg Msg)
    | NewUrl String
    | VideosMsg Main.Pages.Videos.Msg
    | SettingsMsg Main.Pages.Settings.Msg


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


urlUpdate : Model -> Maybe Route -> ( Model, Cmd Msg )
urlUpdate model route =
    let
        newModel =
            { model | location = route }

    in
    newModel ! [ cmdOnNewLocation model route ]


cmdOnNewLocation : Model -> Maybe Route.Route -> Cmd Msg
cmdOnNewLocation model route =
    case route of
        Nothing ->
            Cmd.none

        Just Route.Home ->
            Cmd.map VideosMsg Main.Pages.Videos.cmdOnPageLoad

        Just Route.Settings ->
            Cmd.map SettingsMsg <| Main.Pages.Settings.cmdOnPageLoad model.settingsPage

        Just (Route.YoutubeRedirect data) ->
            PouchDB.Youtube.updateYoutubeData <| PouchDB.Youtube.fromRedirectData data



-- PORTS and SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map VideosMsg <| Main.Pages.Videos.subscriptions model.videosPage
        , Sub.map SettingsMsg <| Main.Pages.Settings.subscriptions model.settingsPage
        ]
