port module PouchDB.Youtube exposing (..)

import Date

type alias Document =
    { id : String
    , token : String
    , lastSynced: Maybe Date
    }
