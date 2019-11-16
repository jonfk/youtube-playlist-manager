module Main exposing (Flags, MenuItem, Model, Msg(..), cmdOnNewLocation, initWithFlags, main, menuItems, subscriptions, update, urlUpdate, view, viewBody)

import Html exposing (Html, button, div, h2, text)
import Main.Pages.Settings
import Main.Pages.Videos
import Main.Route as Route
import Maybe
import Navigation


main : Program Flags Model Msg
main =
    Navigation.programWithFlags NavigateTo
        { init = initWithFlags
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


initWithFlags : Flags -> Navigation.Location -> ( Model, Cmd Msg )
initWithFlags flags location =
    let
        initModel =
            { location = Route.locFor location
            , mdl = Material.model
            , videosPage = Main.Pages.Videos.initialModel
            , settingsPage = Main.Pages.Settings.initialModel
            }
    in
    location
        |> Route.locFor
        |> urlUpdate initModel


type alias Flags =
    {}


view : Model -> Html Msg
view model =
    div [] [ text "placeholder", viewBody model ]


type alias MenuItem =
    { text : String
    , iconName : String
    , route : Maybe Route.Route
    }


menuItems : List MenuItem
menuItems =
    [ { text = "Home", iconName = "home", route = Just Route.Home }
    , { text = "Settings", iconName = "settings", route = Just Route.Settings }
    ]


viewBody : Model -> Html Msg
viewBody model =
    case model.location of
        Nothing ->
            Main.Pages.Videos.view model.videosPage |> Html.map VideosMsg

        --text "404"
        Just Route.Home ->
            Main.Pages.Videos.view model.videosPage |> Html.map VideosMsg

        Just Route.Settings ->
            Main.Pages.Settings.view model.settingsPage |> Html.map SettingsMsg

        Just (Route.YoutubeRedirect data) ->
            -- TODO implement history and redirect to last in history
            Main.Pages.Settings.view model.settingsPage |> Html.map SettingsMsg



--text "youtube redirect"


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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map VideosMsg <| Main.Pages.Videos.subscriptions model.videosPage
        , Sub.map SettingsMsg <| Main.Pages.Settings.subscriptions model.settingsPage
        ]
