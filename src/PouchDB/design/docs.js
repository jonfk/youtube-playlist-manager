import {
    isEqual
} from 'lodash';
import db, {
    YOUTUBE_DATA_DOC_TYPE,
    YOUTUBE_VIDEO_DOC_TYPE,
    YOUTUBE_PLAYLIST_DOC_TYPE
} from '../db';
import videos from './videos';

// TODO: create port for design docs
function sendError(context, err) {
    console.error(context);
    console.error(err);
}

export function checkAndUpdateDesignDoc(designDoc) {
    return db.get(designDoc['_id']).then(function(oldDoc) {
        let rev = oldDoc['_rev'];
        delete oldDoc['_rev'];
        if (!isEqual(oldDoc, designDoc)) {
            console.log('updating Design Doc');
            designDoc['_rev'] = rev;
            putDesignDoc(designDoc);
        }
    }).catch(function(err) {
        if (err.status === 404) {
            putDesignDoc(designDoc);
        }
        sendError('updateDesignDoc', err);
    });
}

function updateDesignDoc(designDoc) {
    return db.get(designDoc['_id']).then(function(oldDoc) {
        designDoc['_rev'] = oldDoc['_rev'];
        putDesignDoc(designDoc);
    }).catch(function(err) {
        if (err.status === 404) {
            putDesignDoc(designDoc);
        }
        sendError('updateDesignDoc', err);
    });
}

function putDesignDoc(designDoc) {
    db.put(designDoc).then(function() {}).catch(function(err) {
        sendError('putDesignDoc', err);
    });
}

const designDocs = [videos];

export function checkAndUpdateAllDesignDocs() {
    return Promise.all(designDocs.map(doc => checkAndUpdateDesignDoc(doc)));
}
