port module Youtube.Authorize exposing (..)

import Dict
import Http
import Navigation


type Scope
    = ManageAccount
    | ManageAccountForceSSL
    | ReadOnly
    | Upload
    | Partner
    | PartnerChannelAudit


scopeToString : Scope -> String
scopeToString scope =
    case scope of
        ManageAccount ->
            "https://www.googleapis.com/auth/youtube"

        ManageAccountForceSSL ->
            "https://www.googleapis.com/auth/youtube.force-ssl"

        ReadOnly ->
            "https://www.googleapis.com/auth/youtube.readonly"

        Upload ->
            "https://www.googleapis.com/auth/youtube.upload"

        Partner ->
            "https://www.googleapis.com/auth/youtubepartner"

        PartnerChannelAudit ->
            "https://www.googleapis.com/auth/youtubepartner-channel-audit"


buildUri : String -> String -> Scope -> String -> String
buildUri clientId redirectUri scope stateParam =
    "https://accounts.google.com/o/oauth2/v2/auth?"
        ++ "client_id="
        ++ Http.encodeUri clientId
        ++ "&redirect_uri="
        ++ Http.encodeUri redirectUri
        ++ "&response_type=token"
        ++ "&scope="
        ++ Http.encodeUri (scopeToString scope)
        ++ "&include_granted_scopes=true"
        ++ "&state="
        ++ stateParam


parseTokenFromRedirectUri : Navigation.Location -> Maybe String
parseTokenFromRedirectUri redirectUri =
    let
        splitOnToken =
            List.head <| List.reverse <| String.split "access_token=" redirectUri.hash

        accessTokenInHead =
            Maybe.map (String.split "&") splitOnToken

        accessToken =
            Maybe.andThen List.head accessTokenInHead
    in
    accessToken


type alias YoutubeRedirectData =
    { state : Maybe String
    , accessToken : Maybe String
    , tokenType : Maybe String
    , expiresIn : Maybe Int
    , scope : Maybe String
    }



-- http://localhost:9000/#state=stateparam2&access_token=ya29.Gly1BQRwr012Gw3Gd30D4jb5fSJz5C3FnRe92kgu5PrKT2u_nIK2JYfLX9p89seI3g6mygs4MbpfG_dfOUqTFeB7Y4RbiOwGfw7iOxZJvtaq-wJxE1Tg7VxdAfqViQ&token_type=Bearer&expires_in=3600&scope=https://www.googleapis.com/auth/youtube.readonly


redirectStringParser : Navigation.Location -> Maybe YoutubeRedirectData
redirectStringParser location =
    let
        updateDictWithPair pair dict =
            case pair of
                [ k, v ] ->
                    Dict.insert k v dict

                _ ->
                    dict

        dictHash =
            String.dropLeft 1 location.hash
                |> String.split "&"
                |> List.map (\s -> String.split "=" s)
                |> List.foldl updateDictWithPair Dict.empty
    in
    if String.startsWith "#state" location.hash then
        Just
            { state = Dict.get "state" dictHash
            , accessToken = Dict.get "access_token" dictHash
            , tokenType = Dict.get "token_type" dictHash
            , expiresIn = Dict.get "expires_in" dictHash |> Maybe.andThen (\s -> String.toInt s |> Result.toMaybe)
            , scope = Dict.get "scope" dictHash
            }
    else
        Nothing


port authorize : Bool -> Cmd msg


port authorizedRedirectUri : (Navigation.Location -> msg) -> Sub msg
