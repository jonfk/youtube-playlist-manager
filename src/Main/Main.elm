import Html exposing (Html, button, div, text, h2)
import Html.Events exposing (onClick)
import Http
import Maybe

import Youtube.Playlist exposing (PlaylistItemListResponse, PlaylistItem, getPlaylistItems, Part(..), Filter(..))


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
    ({ playlistItems = [], playlistResponses = [], err = Nothing, token = flags.token }, getPlaylistItems flags.token)

type alias Flags =
    { token : String
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


-- VIEW

view : Model -> Html Msg
view model =
    let
        debug = [ Html.p [] [ h2 [] [ text "Playlist Response" ]
                            , text (toString model.playlistResponses) ]
                , Html.p [] [ h2 [] [ text "Debug Error" ]
                            , text (toString model.err) ]
                ]
        playlistItemsHtml = List.map viewPlaylistItem model.playlistItems
    in
        div [] (playlistItemsHtml ++ debug)

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

-- Subscriptions

subscriptions : Model -> Sub Msg
subscriptions model = Sub.none

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
