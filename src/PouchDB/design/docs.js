import {
    isEqual
} from 'lodash';
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
            fetchVideosDdoc['_rev'] = rev;
            putDesignDoc(fetchVideosDdoc);
        }
    }).catch(function(err) {
        if (err.status === 404) {
            putDesignDoc(fetchVideosDdoc);
        }
        sendErr('updateDesignDoc', err);
    });
}

function updateDesignDoc(designDoc) {
    return db.get(designDoc['_id']).then(function(oldDoc) {
        fetchVideosDdoc['_rev'] = oldDoc['_rev'];
        putDesignDoc(fetchVideosDdoc);
    }).catch(function(err) {
        if (err.status === 404) {
            putDesignDoc(fetchVideosDdoc);
        }
        sendErr('updateDesignDoc', err);
    });
}

function putDesignDoc(designDoc) {
    db.put(designDoc).then(function() {}).catch(function(err) {
        sendErr('putDesignDoc', err);
    });
}

const designDocs = [videos];

export function checkAndUpdateAllDesignDocs() {
    return Promise.all(designDocs.map(doc => checkAndUpdateDesignDoc(doc)));
}
