module Main.Components.SyncVideosButton exposing (..)

import Errors
import Html exposing (Html, button, div, text)
import Http
import Material
import Material.Button as Button
import Material.Options as Options
import PouchDB.Videos as VideoDB
import PouchDB.Playlists as DBPlaylists
import Task
import Youtube.PlaylistItems as YTPlaylistItems


type alias Model =
    Material.Model


type Msg
    = NoOp
    | Mdl (Material.Msg Msg)
    | TriggerSync (List DBPlaylists.Doc)
    | FetchedPlaylistItems (Result Http.Error FetchedPlaylistRespWrapper)
    | VideoDBErrors String


type alias FetchedPlaylistRespWrapper =
    { playlistId : String
    , resp : YTPlaylistItems.PlaylistItemListResponse
    }


view : List Int -> Maybe String -> List DBPlaylists.Doc -> Model -> Html Msg
view mdlIdx token playlistIds model =
    div []
        [ Button.render Mdl
            mdlIdx
            model
            [ Button.raised
            , Button.ripple
            , Options.onClick <| TriggerSync playlistIds
            ]
            [ text "Sync" ]
        ]


update : Maybe String -> Msg -> Model -> ( Model, Cmd Msg, Maybe String )
update token msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none, Nothing )

        Mdl msg_ ->
            let
                ( model_, cmd ) =
                    Material.update_ Mdl msg_ model
            in
            ( Maybe.withDefault model model_, cmd, Nothing )

        TriggerSync playlists ->
            let
                fetchItems playlist =
                    Maybe.map (\tkn -> Cmd.batch [fetchPlaylistItems playlist.id tkn Nothing, DBPlaylists.storePlaylist playlist]) token

                cmds =
                    List.map (\playlist -> fetchItems playlist |> Maybe.withDefault Cmd.none) playlists
            in
            ( model, Cmd.batch cmds, Nothing )

        FetchedPlaylistItems respWrapperRes ->
            case respWrapperRes of
                Ok wrapper ->
                    let
                        playlistItemsResp =
                            wrapper.resp

                        playlistId =
                            wrapper.playlistId

                        nextPageToken =
                            playlistItemsResp.nextPageToken

                        docsToSave =
                            VideoDB.fromYoutubePlaylistItems playlistItemsResp.items

                        fetchNextItems =
                            Maybe.map (fetchPlaylistItems playlistId) token

                        fetchNextItemsCmd =
                            case nextPageToken of
                                Just _ ->
                                    Maybe.map2 (\f x -> f <| Just x) fetchNextItems nextPageToken
                                        |> Maybe.withDefault Cmd.none

                                Nothing ->
                                    Cmd.none

                        cmds =
                            Cmd.batch [ VideoDB.saveOrUpdateVideos docsToSave, fetchNextItemsCmd ]
                    in
                    ( model, cmds, Nothing )

                Err error ->
                    ( model, Cmd.none, Errors.extractBody error |> Just )

        VideoDBErrors error ->
            (model, Cmd.none, Just error)



subscriptions : Sub Msg
subscriptions =
    Sub.batch [VideoDB.pouchdbVideoErr VideoDBErrors]


cmdOnLoad : Cmd Msg
cmdOnLoad =
    Cmd.none


fetchPlaylistItems : String -> String -> Maybe String -> Cmd Msg
fetchPlaylistItems playlistId token nextPageToken =
    let
        request =
            YTPlaylistItems.getPlaylistItems token
                [ YTPlaylistItems.IdPart, YTPlaylistItems.SnippetPart ]
                (YTPlaylistItems.PlaylistId playlistId)
                (Just 10)
                Nothing
                nextPageToken
                Nothing

        task =
            Http.toTask request
                |> Task.map (\resp -> { playlistId = playlistId, resp = resp })
    in
    Task.attempt FetchedPlaylistItems task
