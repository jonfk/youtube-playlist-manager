import db, {
    YOUTUBE_DATA_DOC_TYPE,
    YOUTUBE_VIDEO_DOC_TYPE,
    YOUTUBE_PLAYLIST_DOC_TYPE
} from '../PouchDB/db';
import 'pouchdb-browser';
import appPromise from '../Main/elm-app';

appPromise.then(function(app) {
    function sendErr(context, err) {
        console.error(context);
        console.error(err);
        app.ports.pouchdbVideoErr.send(JSON.stringify(err));
    }

    function mapItemToDocIdRev(doc) {
        doc['_id'] = doc.id;
        doc['_rev'] = doc.rev;
        return doc;
    }

    function mapReverseIdRev(doc) {
        doc.id = doc['_id'];
        doc.rev = doc['_rev'];
        return doc;
    }

    function containsById(arr, elem) {
        return;
    }

    function updateVideo(oldDoc, newDoc) {
        let containsById = (arr, elem) => arr.findIndex(x => x.id === elem.id) > -1;
        let channelsToAdd = [];
        let playlistsToAdd = [];
        newDoc.channels.forEach(channel => {
            if (containsById(oldDoc.channels, channel)) {
                channelsToAdd.push(channel);
            }
        });

        newDoc.playlists.forEach(playlist => {
            if (containsById(oldDoc.playlists, playlist)) {
                playlistsToAdd.push(playlist);
            }
        });
    }

    app.ports.saveOrUpdateVideos.subscribe(function(documents) {
        documents.forEach(function(doc) {
            doc = mapItemToDocIdRev(doc);
            doc.type = YOUTUBE_VIDEO_DOC_TYPE;
        });

        documents.forEach(doc => {
            db.get(doc.id).then(function(oldDoc) {
                let newDoc = updateVideo(oldDoc, doc);
                db.put(newDoc).then(function() {
                    // success
                }).catch(function(err) {
                    sendErr('saveOrUpdateVideos', err);
                });
            }).catch(function(err) {
                if (err.status === 404) {
                    db.put(doc).then(function() {
                        // success
                    }).catch(function(err) {
                        sendErr('saveOrUpdateVideos', err);
                    });
                } else {
                    sendErr('saveOrUpdateVideos', err);
                }
            });
        });
    });

    // TODO: Fix sorting. May require changing the format of the document
    // TODO: Add pagination
    app.ports.fetchVideos.subscribe(function(args) {
        console.log(args);

        db.query('videos_index/by_publishedAt', {
            limit: args.limit,
            skip: args.skip,
            include_docs: true,
        }).then(function(result) {
            console.log('result fetchVideos');
            console.log(result);
            let docs = [];
            for (let i = 0; i < result.rows.length; i++) {
                let doc = mapReverseIdRev(result.rows[i].doc);
                docs.push(doc);
            }
            app.ports.fetchedVideos.send({docs: docs, totalRows: result.total_rows});
        }).catch(function(err) {
            console.log('fetchVideos error');
            console.log(err);
            app.ports.pouchdbVideoErr.send(JSON.stringify(err));
        });
    });

    function fetchVideoDoc(id) {
        console.log("fetchVideoDoc " + id);
        db.get(id).then(function(doc) {
            doc = mapReverseIdRev(doc);
            console.log(doc);

            app.ports.fetchedVideo.send(doc);
        }).catch(function(err) {
            if (err.status === 404) {
                app.ports.fetchedYoutubeData.send(null);
            } else {
                app.ports.pouchdbVideoErr.send(JSON.stringify(err));
            }
        });
    }

    app.ports.fetchVideo.subscribe(function(videoId) {
        fetchVideoDoc(videoId);
    });

});
