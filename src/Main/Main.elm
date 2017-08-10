import Html exposing (Html, button, div, text, h2)
import Html.Events exposing (onClick)
import Html.Attributes
import Http
import Maybe
import Json.Decode

import Navigation exposing (Location)

import Youtube.Playlist exposing (PlaylistItemListResponse, PlaylistItem, Part(..), Filter(..))
import Youtube.Authorize exposing (parseTokenFromRedirectUri)
import PouchDB
import PouchDB.Search


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
    ({ viewMode = ViewVideos
     , playlistItems = []
     , searchResults = []
     , searchTerms = Nothing
     , playlistResponses = []
     , err = Nothing
     , token = Nothing
     }
    , PouchDB.fetchVideos PouchDB.defaultFetchVideosArgs)

type alias Flags =
    {}


-- MODEL

type ViewMode = ViewVideos
              | ViewSearchResults

type alias Model =
    { viewMode : ViewMode
    , playlistItems : List PouchDB.Document
    , searchResults : List PouchDB.Document
    , searchTerms : Maybe String
    , playlistResponses : List PlaylistItemListResponse
    , err : Maybe Http.Error
    , token : Maybe String
    }

-- UPDATE

type Msg = NoOp
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

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
      NoOp -> (model, Cmd.none)
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
      StartSearch ->
          let
              searchCmd = Maybe.withDefault Cmd.none <| Maybe.map PouchDB.Search.searchVideos model.searchTerms
          in
              ({ model | viewMode = ViewSearchResults }, searchCmd)
      UpdateSearch arg ->
          if arg == "" then ({ model | searchTerms = Nothing, viewMode = ViewVideos }, Cmd.none) else ({ model | searchTerms = Just arg }, Cmd.none)
      SearchedVideos videos ->
          ({ model | searchResults = videos }, Cmd.none)

-- PORTS and SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ Youtube.Authorize.authorizedRedirectUri AuthorizedRedirectUri
              , PouchDB.fetchedVideos FetchedVideos
              , PouchDB.Search.searchedVideos SearchedVideos]

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


        mainContent = if model.viewMode == ViewVideos then viewVideos model else viewSearchResults model

        debug = [ Html.p [] [ h2 [] [ text "Playlist Response" ]
                            , text (toString model.playlistResponses) ]
                , Html.p [] [ h2 [] [ text "Debug Error" ]
                            , text (toString model.err) ]
                ]
    in
        div [] ([ authorizeButton, syncYoutubeButton, deleteDatabaseButton, searchInputField, mainContent ] ++ debug)

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

viewVideos : Model -> Html Msg
viewVideos model =
    let
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
    in
        div [] ([nextAndPrevButtons] ++ playlistItemsHtml)

searchInputField : Html Msg
searchInputField =
    let
        -- send search on enter pressed
        handleKeyCode keyCode = if keyCode == 13 then StartSearch else NoOp
        onKeyPress = Html.Events.on "keypress" (Json.Decode.map handleKeyCode Html.Events.keyCode)
        onInput = Html.Events.onInput UpdateSearch
    in
    div [] [
         Html.label [] [ text "Search: "
                       , Html.input [ Html.Attributes.type_ "search", onKeyPress, onInput ] []
             ]
        ]

viewSearchResults : Model -> Html Msg
viewSearchResults model =
    div [] <| List.map viewPlaylistItem model.searchResults

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
