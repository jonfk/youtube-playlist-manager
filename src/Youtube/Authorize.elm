port module Youtube.Authorize exposing (..)

import Http
import Navigation

type Scope = ManageAccount
           | ManageAccountForceSSL
           | ReadOnly
           | Upload
           | Partner
           | PartnerChannelAudit

scopeToString : Scope -> String
scopeToString scope =
    case scope of
        ManageAccount -> "https://www.googleapis.com/auth/youtube"
        ManageAccountForceSSL -> "https://www.googleapis.com/auth/youtube.force-ssl"
        ReadOnly -> "https://www.googleapis.com/auth/youtube.readonly"
        Upload -> "https://www.googleapis.com/auth/youtube.upload"
        Partner -> "https://www.googleapis.com/auth/youtubepartner"
        PartnerChannelAudit -> "https://www.googleapis.com/auth/youtubepartner-channel-audit"

buildUri : String -> String -> Scope -> String -> String
buildUri clientId redirectUri scope stateParam =
    "https://accounts.google.com/o/oauth2/v2/auth?" ++ "client_id=" ++ Http.encodeUri clientId ++
        "&redirect_uri=" ++ Http.encodeUri redirectUri ++
        "&response_type=token" ++
        "&scope=" ++ Http.encodeUri (scopeToString scope) ++
        "&include_granted_scopes=true" ++
        "&state=" ++ stateParam

parseTokenFromRedirectUri : Navigation.Location -> Maybe String
parseTokenFromRedirectUri redirectUri =
    let
        splitOnToken = List.head <| List.reverse <| String.split "access_token=" redirectUri.hash
        accessTokenInHead = Maybe.map (String.split "&") splitOnToken
        accessToken = Maybe.andThen (List.head) accessTokenInHead
    in
        accessToken

port authorize : Bool -> Cmd msg

port authorizedRedirectUri : (Navigation.Location -> msg) -> Sub msg
