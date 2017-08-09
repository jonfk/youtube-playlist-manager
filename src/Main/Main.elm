import Html exposing (Html, button, div, text, h2)
import Html.Events exposing (onClick)
import Html.Attributes
import Http
import Maybe

import Navigation exposing (Location)

import Youtube.Playlist exposing (PlaylistItemListResponse, PlaylistItem, Part(..), Filter(..))
import Youtube.Authorize exposing (parseTokenFromRedirectUri)
import PouchDB


main : Program Flags Model Msg
main =
  Html.programWithFlags
      { init = initWithFlags
      , update = update
      , subscriptions = subscriptions
      , view = view
      }

initWithFlags : Flags -> (Model, Cmd Msg)
initWithFlags flags =
    ({ playlistItems = [], playlistResponses = [], err = Nothing, token = Nothing }
    , PouchDB.fetchVideos PouchDB.defaultFetchVideosArgs)

type alias Flags =
    {}


-- MODEL

type alias Model =
    { playlistItems : List PouchDB.Document
    , playlistResponses : List PlaylistItemListResponse
    , err : Maybe Http.Error
    , token : Maybe String
    }

-- UPDATE

type Msg = FetchNewPlaylistItems
         | NewPlaylistItems (Result Http.Error PlaylistItemListResponse)
         | AuthorizeYoutube Bool
         | AuthorizedRedirectUri Navigation.Location
         | DeleteDatabase
         | FetchedVideos (List PouchDB.Document)
         | FetchVideos PouchDB.FetchVideosArgs

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
      FetchNewPlaylistItems ->
          let
              mapfetch = Maybe.map (\token ->fetchPlaylistItems token) model.token
              fetchIfTokenExists = Maybe.withDefault Cmd.none mapfetch
          in
              (model, fetchIfTokenExists)
      NewPlaylistItems (Ok playlistItemResp) ->
          let
              token = Maybe.withDefault "" model.token
              documents = PouchDB.fromYoutubePlaylistItems playlistItemResp.items
              commands = Cmd.batch [fetchAllPlaylistItemsAndRefreshPage token playlistItemResp, PouchDB.storeVideos documents]
          in
              ({ model
                   | playlistResponses = playlistItemResp :: model.playlistResponses
               }
              , commands)
      NewPlaylistItems (Err httpErr) ->
          ({ model | err = Just httpErr }, Cmd.none)
      AuthorizeYoutube interactive ->
          (model, Youtube.Authorize.authorize interactive)
      AuthorizedRedirectUri redirectUri ->
          let
              a = Debug.log "redirectUri received" redirectUri
              parsedToken = Debug.log "parsed token" <| parseTokenFromRedirectUri redirectUri
          in
              ({ model | token =  parsedToken }, Cmd.none)
      DeleteDatabase ->
          (model, PouchDB.deleteDatabase True)
      FetchVideos args ->
          (model, PouchDB.fetchVideos args)
      FetchedVideos videoDocuments ->
          ({ model | playlistItems = videoDocuments}, Cmd.none)

-- PORTS and SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ Youtube.Authorize.authorizedRedirectUri AuthorizedRedirectUri
              , PouchDB.fetchedVideos FetchedVideos]

-- VIEW

view : Model -> Html Msg
view model =
    let
        authorizeButton = div []
                    [ button [ onClick <| AuthorizeYoutube True ] [ text "Authorize login to youtube" ] ]

        syncYoutubeButton =
            let
                buttonAttr = Maybe.withDefault (Html.Attributes.disabled True) <| Maybe.map (\token -> onClick <| FetchNewPlaylistItems) model.token
            in
                div [] [ button [ buttonAttr ] [ text "Sync Youtube"]]

        deleteDatabaseButton =
            div [] [ button [ onClick DeleteDatabase ] [ text "Debug Delete Database"] ]

        nextAndPrevButtons =
            div [] [ button [ onClick <| FetchVideos { startKey = Maybe.map .id (List.head model.playlistItems)
                                                   , endKey = Nothing
                                                   , descending = True
                                                   , limit = PouchDB.defaultVideosLimitArg } ] [ text "Prev"]
                   , button [ onClick <| FetchVideos { startKey = Maybe.map .id (List.head <| List.reverse model.playlistItems)
                                                   , endKey = Nothing
                                                   , descending = False
                                                   , limit = PouchDB.defaultVideosLimitArg } ] [ text "Next"]]

        playlistItemsHtml = List.map viewPlaylistItem model.playlistItems

        debug = [ Html.p [] [ h2 [] [ text "Playlist Response" ]
                            , text (toString model.playlistResponses) ]
                , Html.p [] [ h2 [] [ text "Debug Error" ]
                            , text (toString model.err) ]
                ]
    in
        div [] ([authorizeButton] ++ [syncYoutubeButton] ++ [deleteDatabaseButton] ++ [nextAndPrevButtons] ++ playlistItemsHtml ++ debug)

viewPlaylistItem : PouchDB.Document -> Html Msg
viewPlaylistItem item =
    div []
        [ Html.ul [] [ Html.li [] [ text <| "_id: " ++ item.id ]
                     , Html.li [] [ text <| "publishedAt: " ++ item.video.publishedAt ]
                     , Html.li [] [ text <| "videoId: " ++ item.video.videoId ]
                     , Html.li [] [ text <| "channelId: " ++ item.video.channelId ]
                     , Html.li [] [ text <| "title: " ++ item.video.title ]
                     , Html.li [] [ text <| "description: " ++ item.video.description ]
                     , Html.li [] [ text <| "channelTitle: " ++ item.video.channelTitle ]
                     , Html.li [] [ text <| "playlistId: " ++ item.video.playlistId ]
                     , Html.li [] [ text <| "position: " ++ toString item.video.position ]
                     ] ]

-- Playlist

fetchPlaylistItems : String -> Cmd Msg
fetchPlaylistItems token =
    fetchNextPlaylistItems token Nothing

fetchAllPlaylistItemsAndRefreshPage : String -> PlaylistItemListResponse -> Cmd Msg
fetchAllPlaylistItemsAndRefreshPage token resp =
    let
        fetchPlaylistItems = fetchNextPlaylistItems token resp.nextPageToken
        fetchVideosFromPouchDB = PouchDB.fetchVideos PouchDB.defaultFetchVideosArgs
    in
    case resp.nextPageToken of
        Just nextPageToken -> Cmd.batch [ fetchPlaylistItems, fetchVideosFromPouchDB ]
        Nothing -> fetchVideosFromPouchDB


fetchNextPlaylistItems : String -> Maybe String -> Cmd Msg
fetchNextPlaylistItems token nextPageToken =
    Http.send NewPlaylistItems <|
        Youtube.Playlist.getPlaylistItems token [ IdPart, SnippetPart ] (PlaylistId "PLjcCiIbRzHcDHKqqcOghMQUFGv5wdE96F") (Just 10) Nothing nextPageToken Nothing
