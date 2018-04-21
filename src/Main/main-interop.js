// DB Stuff
import db, { YOUTUBE_DATA_DOC_TYPE, YOUTUBE_VIDEO_DOC_TYPE, YOUTUBE_PLAYLIST_DOC_TYPE } from '../PouchDB/db';
import app from './elm-app';
import '../PouchDB/videos';
import '../PouchDB/youtube';
import '../PouchDB/playlists';

/*
 * Ports
 */

// chrome web auth
var redirectUri = chrome.identity.getRedirectURL();
let clientId = "1022327474530-ij2unslv94d4hjcrdh4toijljd17kt4g.apps.googleusercontent.com";
let scope = "https://www.googleapis.com/auth/youtube.readonly";
let uri = 'https://accounts.google.com/o/oauth2/v2/auth?client_id=' +
    encodeURIComponent(clientId) +
    '&response_type=token&scope=' +
    encodeURIComponent(scope) +
    '&include_granted_scopes=true&state=state_parameter_passthrough' +
    '&redirect_uri=' + encodeURIComponent(redirectUri);

app.ports.authorize.subscribe(function(interactive) {
    chrome.identity.launchWebAuthFlow({
        'interactive': interactive,
        'url': uri
    }, function(redirectUrl) {
        if (chrome.runtime.lastError) {
            console.log(chrome.runtime.lastError);
        } else {
            if (redirectUrl) {
                let url = document.createElement('a');
                url.href = redirectUrl;
                url.port_ = url.port;
                app.ports.authorizedRedirectUri.send(url);
            }
        }
    });
});

// PouchDB Search

let searchableFields = ['video.title', 'video.description', 'tags', 'notes'];

db.search({
    fields: searchableFields,
    build: true
}).then(function(info) {
    console.log('search index build successfully');
    console.log(info);
}).catch(function(err) {
    console.log('search index build failure');
    console.log(err);
});

app.ports.searchVideos.subscribe(function(arg) {
    db.search({
        query: arg,
        fields: searchableFields,
        include_docs: true,
        mm: '100%'
    }).then(function(result) {
        let docs = [];
        for (let i = 0; i < result.rows.length; i++) {
            docs.push(result.rows[i].doc);
        }
        app.ports.searchedVideos.send(docs);
    });
});
