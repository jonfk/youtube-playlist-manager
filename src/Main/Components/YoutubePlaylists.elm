module Main.Components.YoutubePlaylists exposing (..)

import Dict
import Html exposing (Html, button, div, text)
import Http
import Main.Errors as Errors
import Main.View.ErrorCard as ErrorCard
import Main.View.YoutubePlaylistsTable as YoutubePlaylistsTable
import Material
import Material.Button as Button
import Material.Options as Options
import Maybe.Extra
import PouchDB.Playlists as DBPlaylists
import Youtube.Playlist as YTPlaylists


type alias Model =
    { mdl : Material.Model
    , allYoutubePlaylists : List YTPlaylists.YoutubePlaylist
    , selectedPlaylists : Dict.Dict String DBPlaylists.Doc
    , error : Maybe String
    }


type Msg
    = NoOp
    | Mdl (Material.Msg Msg)
    | FetchedPlaylistsListResp (Result Http.Error YTPlaylists.YoutubePlaylistsListResponse)
    | FetchAllPlaylists
    | TogglePlaylist YTPlaylists.YoutubePlaylist
    | DismissError
    | FetchedDBPlaylist DBPlaylists.Doc
    | FetchedDBPlaylists (List DBPlaylists.Doc)
    | DBPlaylistsErr String


initialModel : Model
initialModel =
    { mdl = Material.model
    , allYoutubePlaylists = []
    , selectedPlaylists = Dict.empty
    , error = Nothing
    }


selectedPlaylist : Model -> String -> Bool
selectedPlaylist model id =
    Dict.member id model.selectedPlaylists


view : Maybe String -> Model -> Html Msg
view token model =
    div []
        [ text "Playlists Component"
        , ErrorCard.view model.mdl model.error DismissError Mdl
        , viewFetchPlaylistsButton token model
        , YoutubePlaylistsTable.view model.allYoutubePlaylists (selectedPlaylist model) model.mdl Mdl TogglePlaylist
        ]


viewFetchPlaylistsButton : Maybe String -> Model -> Html Msg
viewFetchPlaylistsButton token model =
    div []
        [ Button.render Mdl
            [ 0 ]
            model.mdl
            [ Button.raised
            , Button.ripple
            , Button.disabled |> Options.when (Maybe.Extra.isNothing token)
            , Options.onClick FetchAllPlaylists
            ]
            [ text "Fetch Playlists" ]
        ]


update : Maybe String -> Msg -> Model -> ( Model, Cmd Msg )
update token msg model =
    case msg of
        NoOp ->
            model ! []

        Mdl msg_ ->
            Material.update Mdl msg_ model

        FetchedPlaylistsListResp playlistsRespResult ->
            case playlistsRespResult of
                Ok playlistsResp ->
                    let
                        newAllYtPlaylists =
                            List.append model.allYoutubePlaylists playlistsResp.items

                        nextCmd =
                            Maybe.map2 (\tkn nextPageTkn -> fetchPlaylists tkn (Just nextPageTkn)) token playlistsResp.nextPageToken
                    in
                    { model | allYoutubePlaylists = newAllYtPlaylists } ! [ Maybe.withDefault Cmd.none (Debug.log "next command " nextCmd) ]

                Err httpErr ->
                    { model | error = Just <| Errors.extractBody httpErr } ! []

        FetchAllPlaylists ->
            let
                fetchCmd =
                    Maybe.map (\tkn -> fetchPlaylists tkn Nothing) token
            in
            model ! [ Maybe.withDefault Cmd.none fetchCmd ]

        DismissError ->
            { model | error = Nothing } ! []

        TogglePlaylist playlist ->
            let
                ( cmd, newSelectedPlaylists ) =
                    if not <| selectedPlaylist model playlist.id then
                        ( DBPlaylists.storePlaylist { id = playlist.id, rev = Nothing, title = playlist.snippet.title }
                        , model.selectedPlaylists
                        )
                    else
                        ( Dict.get playlist.id model.selectedPlaylists |> Maybe.map DBPlaylists.removePlaylist |> Maybe.withDefault Cmd.none
                        , Dict.remove playlist.id model.selectedPlaylists
                        )
            in
            { model | selectedPlaylists = newSelectedPlaylists } ! [ cmd ]

        FetchedDBPlaylist playlistDoc ->
            let
                newSelectedPlaylists =
                    Dict.insert playlistDoc.id playlistDoc model.selectedPlaylists
            in
            { model | selectedPlaylists = Debug.log "selected playlists " newSelectedPlaylists } ! []

        FetchedDBPlaylists playlists ->
            let
                selectedPlaylists =
                    List.map (\playlist -> ( playlist.id, playlist )) playlists |> Dict.fromList
            in
            { model | selectedPlaylists = selectedPlaylists } ! []

        DBPlaylistsErr err ->
            { model | error = Just err } ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ DBPlaylists.fetchedPlaylist FetchedDBPlaylist
        , DBPlaylists.fetchedAllPlaylists FetchedDBPlaylists
        , DBPlaylists.playlistsErr DBPlaylistsErr
        ]


fetchPlaylists : String -> Maybe String -> Cmd Msg
fetchPlaylists token nextPageToken =
    Http.send FetchedPlaylistsListResp <|
        YTPlaylists.getPlaylists token
            [ YTPlaylists.ContentDetails, YTPlaylists.SnippetPart ]
            (YTPlaylists.Mine True)
            (Just
                { hl = Nothing
                , maxResults = Just 50
                , onBehalfOfContentOwner = Nothing
                , onBehalfOfContentOwnerChannel = Nothing
                , pageToken = nextPageToken
                }
            )


cmdOnLoad : Cmd Msg
cmdOnLoad =
    DBPlaylists.fetchAllPlaylists ()
