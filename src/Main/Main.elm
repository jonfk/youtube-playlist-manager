import Html exposing (Html, button, div, text, h2)
import Html.Events exposing (onClick)
import Http
import Maybe

import Navigation exposing (Location)

import Youtube.Playlist exposing (PlaylistItemListResponse, PlaylistItem, getPlaylistItems, Part(..), Filter(..))
import Youtube.Authorize exposing (parseTokenFromRedirectUri)


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
    let
        token = flags.redirectUri
    in
        ({ playlistItems = [], playlistResponses = [], err = Nothing, token = token }
        , Cmd.none)

type alias Flags =
    { redirectUri : String
    }

-- MODEL

type alias Model =
    { playlistItems : List PlaylistItem
    , playlistResponses : List PlaylistItemListResponse
    , err : Maybe Http.Error
    , token : String
    }

-- UPDATE

type Msg = NewPlaylistItems (Result Http.Error PlaylistItemListResponse)
         | AuthorizeYoutube Bool
         | AuthorizedRedirectUri Navigation.Location

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
      NewPlaylistItems (Ok playlistItemResp) ->
          ({ model
               | playlistResponses = playlistItemResp :: model.playlistResponses
               , playlistItems = List.append model.playlistItems playlistItemResp.items
           }
          , fetchAllPlaylistItems model.token playlistItemResp)
      NewPlaylistItems (Err httpErr) ->
          ({ model | err = Just httpErr }, Cmd.none)
      AuthorizeYoutube interactive ->
          (model, Youtube.Authorize.authorize interactive)
      AuthorizedRedirectUri redirectUri ->
          let
              a = Debug.log "redirectUri received" redirectUri
              parsedToken = Debug.log "parsed token" <| parseTokenFromRedirectUri redirectUri
          in
              ({ model | token = Maybe.withDefault "" parsedToken }, Cmd.none)

-- PORTS and SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
    Youtube.Authorize.authorizedRedirectUri AuthorizedRedirectUri

-- VIEW

view : Model -> Html Msg
view model =
    let
        authorizeButton = div []
                    [ button [ onClick <| AuthorizeYoutube True ] [ text "Authorize login to youtube" ] ]
        playlistItemsHtml = List.map viewPlaylistItem model.playlistItems

        debug = [ Html.p [] [ h2 [] [ text "Playlist Response" ]
                            , text (toString model.playlistResponses) ]
                , Html.p [] [ h2 [] [ text "Debug Error" ]
                            , text (toString model.err) ]
                ]
    in
        div [] (authorizeButton :: playlistItemsHtml ++ debug)

viewPlaylistItem : PlaylistItem -> Html Msg
viewPlaylistItem item =
    let
        getWithDefault prop value = Maybe.withDefault "" <| Maybe.map (\x -> prop x) value.snippet
    in
        div []
            [ Html.ul [] [ Html.li [] [ text <| "publishedAt: " ++ getWithDefault (\x -> x.publishedAt) item ]
                         , Html.li [] [ text <| "channelId: " ++ getWithDefault (\x -> x.channelId) item ]
                         , Html.li [] [ text <| "title: " ++ getWithDefault (\x -> x.title) item ]
                         , Html.li [] [ text <| "description: " ++ getWithDefault (\x -> x.description) item ]
                         , Html.li [] [ text <| "channelTitle: " ++ getWithDefault (\x -> x.channelTitle) item ]
                         , Html.li [] [ text <| "playlistId: " ++ getWithDefault (\x -> x.playlistId) item ]
                         , Html.li [] [ text <| "position: " ++ getWithDefault (\x -> toString x.position) item ]
                         ] ]

-- Playlist

getPlaylistItems : String -> Cmd Msg
getPlaylistItems token =
    Http.send NewPlaylistItems <|
        Youtube.Playlist.getPlaylistItems token [ IdPart, SnippetPart ] (PlaylistId "PLjcCiIbRzHcDHKqqcOghMQUFGv5wdE96F") (Just 10) Nothing Nothing Nothing


fetchAllPlaylistItems : String -> PlaylistItemListResponse -> Cmd Msg
fetchAllPlaylistItems token resp =
    Maybe.withDefault Cmd.none <| Maybe.map (fetchNextPlaylistItems token) resp.nextPageToken

fetchNextPlaylistItems : String -> String -> Cmd Msg
fetchNextPlaylistItems token nextPageToken =
    Http.send NewPlaylistItems <|
        Youtube.Playlist.getPlaylistItems token [ IdPart, SnippetPart ] (PlaylistId "PLjcCiIbRzHcDHKqqcOghMQUFGv5wdE96F") (Just 10) Nothing (Just nextPageToken) Nothing
