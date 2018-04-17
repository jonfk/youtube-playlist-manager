module Errors exposing (..)

import Http exposing (Error(..))

extractBody : Http.Error -> String
extractBody error =
    case error of
        BadUrl err ->
            toString error
        Timeout ->
            toString error

        NetworkError ->
            toString error

        BadStatus errResp ->
            errResp.body

        BadPayload err errResp ->
            err ++ ": " ++ errResp.body
