
import db, { YOUTUBE_DATA_DOC_TYPE, YOUTUBE_VIDEO_DOC_TYPE, YOUTUBE_PLAYLIST_DOC_TYPE } from '../PouchDB/db';
import app from '../Main/elm-app';

function sendPlaylistPortError(err) {
    console.log("playlist err");
    console.log(err);
    app.ports.playlistsErr.send(JSON.stringify(err));
}

app.ports.storePlaylist.subscribe(function(ytPlaylist) {
    ytPlaylist['_id'] = ytPlaylist.id;
    ytPlaylist['_rev'] = ytPlaylist.rev;
    ytPlaylist.type = YOUTUBE_PLAYLIST_DOC_TYPE;
    console.log("storePlaylist");
    console.log(ytPlaylist);

    db.put(ytPlaylist, {
        force: true
    }).then(function() {
        //success
        fetchYtPlaylistDoc(ytPlaylist.id);
    }).catch(function(err) {
        sendPlaylistPortError(err);
    });
});

app.ports.removePlaylist.subscribe(function(ytPlaylist) {
    db.remove(ytPlaylist.id, ytPlaylist.rev).then(function() {
        //success
    }).catch(function(err) {
        sendPlaylistPortError(err);
    });
});

function fetchYtPlaylistDoc(id) {
    console.log("fetchPlaylist " + id);
    db.get(id).then(function(doc) {
        doc.id = doc['_id'];
        doc.rev = doc['_rev'];
        console.log(doc);

        app.ports.fetchedPlaylist.send(doc);
    }).catch(function(err) {
        sendPlaylistPortError(err);
    });
}

app.ports.fetchPlaylist.subscribe(function(id) {
    fetchYtPlaylistDoc(id);
});

app.ports.fetchAllPlaylists.subscribe(function() {

    db.find({
        selector: {
            type: {
                $eq: YOUTUBE_PLAYLIST_DOC_TYPE
            }
        }
    }).then(function(result) {
        let docs = [];
        for (let i = 0; i < result.docs.length; i++) {
            result.docs[i].rev = result.docs[i]['_rev'];
            docs.push(result.docs[i]);
        }
        app.ports.fetchedAllPlaylists.send(docs);
    }).catch(function(err) {
        sendPlaylistPortError(err);
    });

});
