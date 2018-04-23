import db, {
    YOUTUBE_DATA_DOC_TYPE,
    YOUTUBE_VIDEO_DOC_TYPE,
    YOUTUBE_PLAYLIST_DOC_TYPE
} from '../PouchDB/db';
import appPromise from '../Main/elm-app';

appPromise.then(function(app) {
    const YOUTUBE_DATA_DOC_ID = "YOUTUBE_DATA_DOC_ID";

    app.ports.storeYoutubeData.subscribe(function(youtubeDataDoc) {
        youtubeDataDoc['_id'] = YOUTUBE_DATA_DOC_ID;
        youtubeDataDoc.type = YOUTUBE_DATA_DOC_TYPE;
        youtubeDataDoc['_rev'] = youtubeDataDoc.rev;

        db.put(youtubeDataDoc, {
            force: true
        }).then(function() {
            console.log("successfully saved youtubedata");
            // success
            fetchYoutubeDataDoc();
        }).catch(function(err) {
            console.log(err);
            app.ports.youtubeDataPortErr.send(JSON.stringify(err));
        });
    });

    app.ports.fetchYoutubeData.subscribe(function() {
        fetchYoutubeDataDoc();
    });

    function fetchYoutubeDataDoc() {
        db.get(YOUTUBE_DATA_DOC_ID).then(function(doc) {
            doc.rev = doc['_rev'];
            app.ports.fetchedYoutubeData.send(doc);
        }).catch(function(err) {
            console.log(err);
            if (err.status === 404) {
                app.ports.fetchedYoutubeData.send(null);
            } else {
                app.ports.youtubeDataPortErr.send(JSON.stringify(err));
            }
        });
    }
});
