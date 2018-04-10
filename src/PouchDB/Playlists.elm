port module PouchDB.Playlists exposing (..)


type alias Doc =
    { id : String
    , rev : Maybe String
    , title : String
    }


port storePlaylist : Doc -> Cmd msg


port removePlaylist : Doc -> Cmd msg


port fetchPlaylist : String -> Cmd msg


port fetchAllPlaylists : () -> Cmd msg


port fetchedPlaylist : (Doc -> msg) -> Sub msg


port fetchedAllPlaylists : (List Doc -> msg) -> Sub msg


port playlistsErr : (String -> msg) -> Sub msg
