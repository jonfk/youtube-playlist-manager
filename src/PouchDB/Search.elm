port module PouchDB.Search exposing (..)

import PouchDB exposing (Document)

port searchVideos : String -> Cmd msg

port searchedVideos : (List Document -> msg) -> Sub msg
