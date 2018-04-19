module Main.Components.SyncVideosButton exposing (..)

import Errors
import Html exposing (Html, button, div, text)
import Http
import Material
import Material.Button as Button
import Material.Options as Options
import PouchDB.Videos as VideoDB
import Task
import Youtube.PlaylistItems as YTPlaylistItems


type alias Model =
    { mdl : Material.Model
    }


initialModel : Model
initialModel =
    { mdl = Material.model
    }


type Msg
    = NoOp
    | Mdl (Material.Msg Msg)
    | TriggerSync (List String)
    | FetchedPlaylistItems (Result Http.Error FetchedPlaylistRespWrapper)


type alias FetchedPlaylistRespWrapper =
    { playlistId : String
    , resp : YTPlaylistItems.PlaylistItemListResponse
    }


view : Maybe String -> List String -> Model -> Html Msg
view token playlistIds model =
    div []
        [ Button.render Mdl
            [ 0 ]
            model.mdl
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
                    Material.update Mdl msg_ model
            in
            ( model_, cmd, Nothing )

        TriggerSync playlistIds ->
            let
                fetchItems playlistId =
                    Maybe.map (\tkn -> fetchPlaylistItems playlistId tkn Nothing) token

                cmds =
                    List.map (\playlistId -> fetchItems playlistId |> Maybe.withDefault Cmd.none) playlistIds
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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch []


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
