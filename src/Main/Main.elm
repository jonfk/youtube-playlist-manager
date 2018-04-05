module Main exposing (..)

import Html exposing (Html, button, div, h2, text)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)
import Json.Decode
import Main.Route as Route
import Main.State exposing (..)
import Material
import Material.Color as Color
import Material.Dialog as Dialog
import Material.Icon as Icon
import Material.Layout as Layout
import Material.Options as Options exposing (cs, css, when)
import Material.Scheme
import Maybe
import Navigation
import PouchDB
import Main.Pages.Videos
import Main.Pages.Settings


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
    ( { location = Route.locFor location
      , mdl = Material.model
      , videosPage = Main.Pages.Videos.initialModel
      , settingsPage = Main.Pages.Settings.initialModel

      , viewMode = ViewVideos
      , playlistItems = []
      , searchResults = []
      , searchTerms = Nothing
      , playlistResponses = []
      , err = Nothing
      , token = Nothing
      }
    , PouchDB.fetchVideos PouchDB.defaultFetchVideosArgs
    )


type alias Flags =
    { extensionId : String
    }



-- VIEW


view : Model -> Html Msg
view model =
    Material.Scheme.top <|
        Layout.render Mdl
            model.mdl
            [ Layout.fixedHeader
            , Options.css "display" "flex !important"
            , Options.css "flex-direction" "row"
            , Options.css "align-items" "center"
            ]
            { header = [ viewHeader model ]
            , drawer = [ viewDrawer model ]
            , tabs = ( [], [] )
            , main =
                [ viewBody model
                ]
            }



-- let
--     mainContent =
--         if model.viewMode == ViewVideos then
--             viewVideos2 model
--         else
--             viewSearchResults model
--     debug =
--         [ Html.p []
--             [ h2 [] [ text "Playlist Response" ]
--             , text (toString model.playlistResponses)
--             ]
--         , Html.p []
--             [ h2 [] [ text "Debug Error" ]
--             , text (toString model.err)
--             ]
--         ]
-- in
-- div [ class "columns" ]
--     [ div [ classList [ ( "column", True ), ( "is-2", True ) ] ] [ viewMenu model ]
--     , div [ class "column" ] ([ mainContent ] ++ debug)
--     ]


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


viewDrawerMenuItem : Model -> MenuItem -> Html Msg
viewDrawerMenuItem model menuItem =
    let
        isCurrentLocation =
            model.location == menuItem.route

        onClickCmd =
            case ( isCurrentLocation, menuItem.route ) of
                ( False, Just route ) ->
                    route |> Route.urlFor |> NewUrl |> Options.onClick

                _ ->
                    Options.nop
    in
    Layout.link
        [ onClickCmd
        , when isCurrentLocation (Color.background <| Color.color Color.BlueGrey Color.S600)
        , Options.css "color" "rgba(255, 255, 255, 0.56)"
        , Options.css "font-weight" "500"
        ]
        [ Icon.view menuItem.iconName
            [ Color.text <| Color.color Color.BlueGrey Color.S500
            , Options.css "margin-right" "32px"
            ]
        , text menuItem.text
        ]


viewDrawer : Model -> Html Msg
viewDrawer model =
    Layout.navigation
        [ Color.background <| Color.color Color.BlueGrey Color.S800
        , Color.text <| Color.color Color.BlueGrey Color.S50
        , Options.css "flex-grow" "1"
        ]
    <|
        List.map (viewDrawerMenuItem model) menuItems
            ++ [ Layout.spacer
               , Layout.link
                    [ Dialog.openOn "click"
                    ]
                    [ Icon.view "help"
                        [ Color.text <| Color.color Color.BlueGrey Color.S500
                        ]
                    ]
               ]


viewHeader : Model -> Html Msg
viewHeader model =
    Layout.row
        []
        [ Layout.title [] [ text "PMedia Org" ] ]


viewBody : Model -> Html Msg
viewBody model =
    case model.location of
        Nothing ->
            text "404"

        Just Route.Home ->
            Main.Pages.Videos.view model.videosPage |> Html.map VideosMsg

        Just Route.Settings ->
            Main.Pages.Settings.view model.settingsPage |> Html.map SettingsMsg

