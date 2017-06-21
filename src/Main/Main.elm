import Html exposing (Html, button, div, text, h2)
import Html.Events exposing (onClick)
import Http

import Youtube.Playlist exposing (PlaylistItemListResponse, getPlaylistItems, Part(..), Filter(..))


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
    ({ playlistResp = Nothing, err = Nothing }, getPlaylistItems flags.token)

type alias Flags =
    { token : String
    }

-- MODEL

type alias Model =
    { playlistResp : Maybe PlaylistItemListResponse
    , err : Maybe Http.Error
    }


-- UPDATE

type Msg = NewPlaylistItems (Result Http.Error PlaylistItemListResponse)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
      NewPlaylistItems (Ok playlistItemResp) ->
          ({ model | playlistResp = Just playlistItemResp }, Cmd.none)
      NewPlaylistItems (Err httpErr) ->
          ({ model | err = Just httpErr }, Cmd.none)


-- VIEW

view : Model -> Html Msg
view model =
  div []
    [ Html.p [] [ h2 [] [ text "Playlist Response" ]
                , text (toString model.playlistResp) ]
    , Html.p [] [ h2 [] [ text "Error" ]
                , text (toString model.err)
                ]
    ]

-- Subscriptions

subscriptions : Model -> Sub Msg
subscriptions model = Sub.none

-- Playlist

getPlaylistItems : String -> Cmd Msg
getPlaylistItems token =
    Http.send NewPlaylistItems <|
        Youtube.Playlist.getPlaylistItems token [ IdPart, SnippetPart ] (PlaylistId "PLjcCiIbRzHcDHKqqcOghMQUFGv5wdE96F") (Just 10) Nothing Nothing Nothing
