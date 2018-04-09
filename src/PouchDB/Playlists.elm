port module PouchDB.Playlists exposing (..)


type alias Doc =
    { id : String
    , rev : String
    , title : String
    }


port storePlaylist : Doc -> Cmd msg


port fetchAllPlaylists : () -> Cmd msg


port fetchedAllPlaylists : (List Doc -> msg) -> Sub msg


port playlistsErr : (String -> msg) -> Sub msg
