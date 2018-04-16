module Main.Pages.Settings exposing (..)

import Html exposing (Html, div, text)
import Main.Components.YoutubePlaylists
import Main.View.ErrorCard
import Material
import Material.Button as Button
import Material.Icon as Icon
import Material.List as Lists
import Material.Options as Options
import Navigation
import PouchDB
import PouchDB.Youtube
import Youtube.Authorize


type alias Model =
    { mdl : Material.Model
    , youtubeData : Maybe PouchDB.Youtube.YoutubeDataDoc
    , error : Maybe String
    , ytPlaylistsComp : Main.Components.YoutubePlaylists.Model
    }


type Msg
    = NoOp
    | Mdl (Material.Msg Msg)
    | AuthorizeYoutube
    | AuthorizedRedirectUri Navigation.Location
    | FetchedYoutubeData (Maybe PouchDB.Youtube.YoutubeDataDoc)
    | DeleteYoutubeToken
    | PouchDBError String
    | DismissError
    | YTPlaylistsComponentMsg Main.Components.YoutubePlaylists.Msg
    | DeletePouchDB


initialModel : Model
initialModel =
    { mdl = Material.model
    , youtubeData = Nothing
    , error = Nothing
    , ytPlaylistsComp = Main.Components.YoutubePlaylists.initialModel
    }


view : Model -> Html Msg
view model =
    let
        token =
            Maybe.andThen .token model.youtubeData
    in
    div []
        [ text "Settings Page"
        , Main.View.ErrorCard.view model.mdl model.error DismissError Mdl
        , viewSettingsActionsList model
        , Main.Components.YoutubePlaylists.view token model.ytPlaylistsComp |> Html.map YTPlaylistsComponentMsg
        , text <| toString model
        ]


viewSettingsActionsList : Model -> Html Msg
viewSettingsActionsList model =
    let
        signInButton =
            [ Lists.content [] [ text "Sign In" ]
            , Button.render Mdl
                [ 1 ]
                model.mdl
                [ Button.icon
                , Options.onClick AuthorizeYoutube
                ]
                [ Icon.i "account_circle" ]
            ]

        tokenView token =
            [ Lists.content [] [ text <| "Signed In Token: " ++ token ]
            , Button.render Mdl
                [ 1 ]
                model.mdl
                [ Button.icon
                , Options.onClick DeleteYoutubeToken
                ]
                [ Icon.i "cancel" ]
            ]

        signInOrToken =
            Maybe.andThen .token model.youtubeData |> Maybe.map tokenView |> Maybe.withDefault signInButton
    in
    Lists.ul []
        [ Lists.li []
            signInOrToken
        , Lists.li []
            [ Lists.content [] [ text "Delete DB" ]
            , Button.render Mdl
                [ 2 ]
                model.mdl
                [ Button.icon
                , Options.onClick DeletePouchDB
                ]
                [ Icon.i "delete_forever" ]
            ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        token =
            Maybe.andThen .token model.youtubeData
    in
    case msg of
        NoOp ->
            model ! []

        Mdl msg_ ->
            Material.update Mdl msg_ model

        AuthorizeYoutube ->
            ( model, Youtube.Authorize.authorize True )

        AuthorizedRedirectUri redirectUri ->
            let
                a =
                    Debug.log "redirectUri received" redirectUri

                parsedToken =
                    Debug.log "parsed token" <| Youtube.Authorize.parseTokenFromRedirectUri redirectUri

                youtubeData =
                    PouchDB.Youtube.unwrap model.youtubeData

                newYoutubeData =
                    { youtubeData | token = parsedToken }
            in
            { model | youtubeData = Just newYoutubeData } ! [ PouchDB.Youtube.storeYoutubeData newYoutubeData ]

        DeleteYoutubeToken ->
            let
                ytData =
                    PouchDB.Youtube.unwrap model.youtubeData

                newYoutubeData =
                    { ytData | token = Nothing }
            in
            { model | youtubeData = Just newYoutubeData } ! [ PouchDB.Youtube.storeYoutubeData newYoutubeData ]

        FetchedYoutubeData ytDataDoc ->
            ( { model | youtubeData = ytDataDoc }, Cmd.none )

        PouchDBError error ->
            { model | error = Just error } ! []

        DismissError ->
            { model | error = Nothing } ! []

        YTPlaylistsComponentMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    Main.Components.YoutubePlaylists.update token subMsg model.ytPlaylistsComp
            in
            { model | ytPlaylistsComp = subModel } ! [ Cmd.map YTPlaylistsComponentMsg subCmd ]

        DeletePouchDB ->
            model ! [ PouchDB.deleteDatabase ()]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Youtube.Authorize.authorizedRedirectUri AuthorizedRedirectUri
        , PouchDB.Youtube.fetchedYoutubeData FetchedYoutubeData
        , PouchDB.Youtube.youtubeDataPortErr PouchDBError
        , Sub.map YTPlaylistsComponentMsg <| Main.Components.YoutubePlaylists.subscriptions model.ytPlaylistsComp
        ]


cmdOnPageLoad : Cmd Msg
cmdOnPageLoad =
    Cmd.batch
        [ PouchDB.Youtube.fetchYoutubeData ()
        , Cmd.map YTPlaylistsComponentMsg Main.Components.YoutubePlaylists.cmdOnLoad
        ]
