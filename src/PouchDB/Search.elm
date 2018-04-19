port module PouchDB.Search exposing (..)

import PouchDB.Videos exposing (Doc)

port searchVideos : String -> Cmd msg

port searchedVideos : (List Doc -> msg) -> Sub msg
