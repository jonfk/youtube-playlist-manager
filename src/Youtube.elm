module Youtube exposing (..)

import Http

type alias Token
    = String

tokenToHeader : Token -> Http.Header
tokenToHeader token =
    let
        bearer = "Bearer " ++ token
    in
    Http.header "Authorization" bearer
