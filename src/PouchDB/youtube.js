import db, {
    YOUTUBE_DATA_DOC_TYPE,
    YOUTUBE_VIDEO_DOC_TYPE,
    YOUTUBE_PLAYLIST_DOC_TYPE
} from '../PouchDB/db';
import appPromise from '../Main/elm-app';

appPromise.then(function(app) {
    const YOUTUBE_DATA_DOC_ID = "YOUTUBE_DATA_DOC_ID";

    app.ports.updateYoutubeData.subscribe(function(youtubeDataDoc) {
        youtubeDataDoc['_id'] = YOUTUBE_DATA_DOC_ID;
        youtubeDataDoc.type = YOUTUBE_DATA_DOC_TYPE;

        db.get(YOUTUBE_DATA_DOC_ID).then(function(doc) {
            youtubeDataDoc['_rev'] = doc['_rev'];
            db.put(youtubeDataDoc, {
                force: true
            }).then(function() {
                // success
                console.log("successfully saved youtubedata");
                fetchYoutubeDataDoc();
            }).catch(function(err) {
                console.log(err);
                app.ports.youtubeDataPortErr.send(JSON.stringify(err));
            });
        }).catch(function(err) {
            if (err.status === 404) {
                db.put(youtubeDataDoc, {force: true}).then(function() {
                    // success
                    console.log("successfully saved youtubedata");
                    fetchYoutubeDataDoc();
                });
            } else {
                console.log(err);
                app.ports.youtubeDataPortErr.send(JSON.stringify(err));
            }
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
