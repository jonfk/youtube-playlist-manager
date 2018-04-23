import PouchDB from 'pouchdb-browser';
import PouchDBFind from 'pouchdb-find';
import PouchDBSearch from 'pouchdb-quick-search';

PouchDB.plugin(PouchDBFind);
PouchDB.plugin(PouchDBSearch);

var db = new PouchDB('youtube-manager');

db.on('error', function(err) {
    console.log('db error');
    console.log(err);
});

db.createIndex({
    index: {
        fields: ['type']
    }
});

export const YOUTUBE_DATA_DOC_TYPE = "YOUTUBE_DATA_DOC_TYPE";
export const YOUTUBE_VIDEO_DOC_TYPE = "YOUTUBE_VIDEO_DOC_TYPE";
export const YOUTUBE_PLAYLIST_DOC_TYPE = "YOUTUBE_PLAYLIST_DOC_TYPE";

export default db;
