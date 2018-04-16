port module PouchDB.Playlists exposing (..)

import Youtube.Playlist as YTPlaylists


type alias Doc =
    { id : String
    , rev : Maybe String
    , title : String
    }


fromYT : YTPlaylists.YoutubePlaylist -> Doc
fromYT playlist =
    { id = playlist.id
    , rev = Nothing
    , title = playlist.snippet.title
    }


port storePlaylist : Doc -> Cmd msg


port removePlaylist : Doc -> Cmd msg


port fetchPlaylist : String -> Cmd msg


port fetchAllPlaylists : () -> Cmd msg


port fetchedPlaylist : (Doc -> msg) -> Sub msg


port fetchedAllPlaylists : (List Doc -> msg) -> Sub msg


port playlistsErr : (String -> msg) -> Sub msg
