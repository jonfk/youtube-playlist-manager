port module PouchDB.Search exposing (..)

import PouchDB.Video exposing (Document)

port searchVideos : String -> Cmd msg

port searchedVideos : (List Document -> msg) -> Sub msg
