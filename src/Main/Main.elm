module Main exposing (..)

import Html exposing (Html, button, div, text, h2)
import Html.Events exposing (onClick)
import Html.Attributes exposing (class, classList)
import Maybe
import Json.Decode
import Main.State exposing (..)
import PouchDB


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = initWithFlags
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- VIEW


view : Model -> Html Msg
view model =
    let
        mainContent =
            if model.viewMode == ViewVideos then
                viewVideos2 model
            else
                viewSearchResults model

        debug =
            [ Html.p []
                [ h2 [] [ text "Playlist Response" ]
                , text (toString model.playlistResponses)
                ]
            , Html.p []
                [ h2 [] [ text "Debug Error" ]
                , text (toString model.err)
                ]
            ]
    in
        div [ class "columns" ]
            [ div [ classList [ ( "column", True ), ( "is-2", True ) ] ] [ viewMenu model ]
            , div [ class "column" ] ([ mainContent ] ++ debug)
            ]


viewPlaylistItem : PouchDB.Document -> Html Msg
viewPlaylistItem item =
    div []
        [ Html.ul []
            [ Html.li [] [ text <| "_id: " ++ item.id ]
            , Html.li [] [ text <| "title: " ++ item.video.title ]
            , Html.li [] [ Html.a [ Html.Attributes.target "_blank", Html.Attributes.href <| PouchDB.youtubeVideoUrl item ] [ text "link" ] ]
            , Html.li [] [ text <| "channelTitle: " ++ item.video.channelTitle ]
            , Html.li [] [ text <| "publishedAt: " ++ item.video.publishedAt ]
            , Html.li [] [ text <| "description: " ++ item.video.description ]
            , Html.li [] [ text <| "videoId: " ++ item.video.videoId ]
            , Html.li [] [ text <| "channelId: " ++ item.video.channelId ]
            , Html.li [] [ text <| "playlistId: " ++ item.video.playlistId ]
            , Html.li [] [ text <| "position: " ++ toString item.video.position ]
            ]
        ]


viewVideoItem : PouchDB.Document -> Html Msg
viewVideoItem item =
    let
        videoThumbnailUrl =
            Maybe.withDefault "" <|
                Maybe.map (\( name, thumb ) -> thumb.url) <|
                    List.head <|
                        List.filter (\( name, thumbnail ) -> name == "medium") item.video.thumbnails
    in
        div [ class "card" ]
            [ div [ class "card-image" ]
                  [ Html.img [ Html.Attributes.src videoThumbnailUrl, Html.Attributes.alt item.video.title, Html.Attributes.width 320] []
                , div [class "card-content"] [ Html.p [class "title is-6"] [text item.video.title]
                                             , Html.p [class "subtitle is-6"] [text item.video.publishedAt]
                                             , div [class "content"] [text item.video.description]
                                             ]
                ]
            ]


viewVideos : Model -> Html Msg
viewVideos model =
    let
        nextAndPrevButtons =
            div []
                [ button
                    [ onClick <|
                        FetchVideos
                            { startKey = Maybe.map .id (List.head model.playlistItems)
                            , endKey = Nothing
                            , descending = True
                            , limit = PouchDB.defaultVideosLimitArg
                            }
                    ]
                    [ text "Prev" ]
                , button
                    [ onClick <|
                        FetchVideos
                            { startKey = Maybe.map .id (List.head <| List.reverse model.playlistItems)
                            , endKey = Nothing
                            , descending = False
                            , limit = PouchDB.defaultVideosLimitArg
                            }
                    ]
                    [ text "Next" ]
                ]

        playlistItemsHtml =
            List.map viewPlaylistItem model.playlistItems

        playlistItemsDivs = List.map insertPlaylistItemColumn playlistItemsHtml

        insertPlaylistItemColumn item = div [class "column is-2 is-narrow"] [item]

    in
        div [] [ nextAndPrevButtons
                , div [class "columns"] playlistItemsDivs
               ]

viewVideos2 : Model -> Html Msg
viewVideos2 model =
    let
        nextAndPrevButtons =
            div []
                [ button
                    [ onClick <|
                        FetchVideos
                            { startKey = Maybe.map .id (List.head model.playlistItems)
                            , endKey = Nothing
                            , descending = True
                            , limit = PouchDB.defaultVideosLimitArg
                            }
                    ]
                    [ text "Prev" ]
                , button
                    [ onClick <|
                        FetchVideos
                            { startKey = Maybe.map .id (List.head <| List.reverse model.playlistItems)
                            , endKey = Nothing
                            , descending = False
                            , limit = PouchDB.defaultVideosLimitArg
                            }
                    ]
                    [ text "Next" ]
                ]

        playlistItemsHtml =
            List.map viewVideoItem model.playlistItems
    in
        div [] ([ nextAndPrevButtons ] ++ playlistItemsHtml)


viewMenu : Model -> Html Msg
viewMenu model =
    let
        authorizeYoutubeMenuItem =
            Html.li [] [ Html.a [ onClick <| AuthorizeYoutube True ] [ text "Authorize Youtube Login" ] ]

        generalMenuItems =
            [ searchInputMenuItem, authorizeYoutubeMenuItem ]
                ++ (Maybe.withDefault [] <| Maybe.map (\x -> [ x ]) <| syncYoutubeMenuItem model.token)
                ++ [ deleteDatabase ]

        deleteDatabase =
            Html.li [] [ Html.a [ onClick DeleteDatabase ] [ text "Debug Delete Database" ] ]
    in
        Html.aside [ class "menu" ]
            [ Html.p [ class "menu-label" ] [ text "General" ]
            , Html.ul [ class "menu-list" ] generalMenuItems
            ]


syncYoutubeMenuItem : Maybe String -> Maybe (Html Msg)
syncYoutubeMenuItem token =
    Maybe.map (\_ -> Html.li [] [ Html.a [ onClick FetchNewPlaylistItems ] [ text "Sync Youtube Playlists" ] ]) token


searchInputMenuItem : Html Msg
searchInputMenuItem =
    div [ class "field" ]
        [ div [ class "field-body" ]
            [ div [ class "field" ]
                [ div [ class "control" ] [ searchInputField ]
                ]
            ]
        ]


searchInputField : Html Msg
searchInputField =
    let
        -- send search on enter pressed
        handleKeyCode keyCode =
            if keyCode == 13 then
                StartSearch
            else
                NoOp

        onKeyPress =
            Html.Events.on "keypress" (Json.Decode.map handleKeyCode Html.Events.keyCode)

        onInput =
            Html.Events.onInput UpdateSearch
    in
        Html.input [ Html.Attributes.type_ "search", onKeyPress, onInput, class "input", Html.Attributes.placeholder "Search Youtube" ] []


viewSearchResults : Model -> Html Msg
viewSearchResults model =
    div [] <| List.map viewPlaylistItem model.searchResults
