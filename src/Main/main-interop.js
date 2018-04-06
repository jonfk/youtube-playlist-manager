
// DB Stuff
var db = new PouchDB('youtube-manager');


var node = document.getElementById('main');
var token = "ya29.GluGBLNCL8dK5PVKHc50rlj_RsFcPoafRypzUM7X-J2flXpvQ5QL4Z6s3Ar6YIfDp47Z3YP_d1La31FFGQvdydU-nGOKFJcIHKhoGwxwt2X3OJWYcY3aInp7Vnaq";
var app = Elm.Main.embed(node, {
    redirectUri: token,
    extensionId: chrome.runtime.id
});

// Note move out to a seperate file
// Ref: https://github.com/google/closure-compiler/wiki/Managing-Dependencies

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

const YOUTUBE_DATA_DOC_TYPE = "YOUTUBE_DATA_DOC_TYPE";
const YOUTUBE_VIDEO_DOC_TYPE = "YOUTUBE_VIDEO_DOC_TYPE";

// PouchDB
app.ports.storeVideos.subscribe(function(documents) {
    documents.forEach(function(doc) {
        doc['_id'] = doc.id;
        doc.type = YOUTUBE_VIDEO_DOC_TYPE;
    });

    db.bulkDocs(documents).then(function () {
        // success
    }).catch(function (err) {
        if (err.name === 'conflict') {
            console.log('storeVideos conflict error');
            console.log(err);
        } else {
            console.log('storeVideos unknown error');
            console.log(err);
        }
    });;
});

// TODO: filter by doc type. Maybe used mango queries: https://pouchdb.com/guides/mango-queries.html
app.ports.fetchVideos.subscribe(function(args) {
    console.log(args);
    let allDocsArgs = {};
    allDocsArgs.limit = args.limit;
    allDocsArgs.include_docs = true;
    allDocsArgs.descending = args.descending;
    if (args.startKey !== null) {
        allDocsArgs.startkey = args.startKey;
    }
    if (args.endKey !== null) {
        allDocsArgs.endkey = args.endKey;
    }

    db.allDocs(allDocsArgs).then(function(result) {
        let docs = [];
        console.log(result);
        // Reverse document order if descending since pouch will return in reverse order
        if (args.descending) {
            for (let i = result.rows.length - 1; i > 0; i--) {
                docs.push(result.rows[i].doc);
            }
        } else {
            for (let i = 0; i < result.rows.length; i++) {
                docs.push(result.rows[i].doc);
            }
        }
        app.ports.fetchedVideos.send(docs);
    }).catch(function(err) {
        console.log('fetchVideos error');
        console.log(err);
    });
});

app.ports.deleteDatabase.subscribe(function(args) {
    db.destroy().then(function(response) {
        // success
        console.log('Deleted Database');
    }).catch(function(err) {
        console.log('deleteDatabase error');
        console.log(err);
    });
});

// PouchDB Search

let searchableFields = ['video.title', 'video.description', 'tags', 'notes'];

db.search({
    fields: searchableFields,
    build: true
}).then(function (info) {
    console.log('search index build successfully');
    console.log(info);
}).catch(function (err) {
    console.log('search index build failure');
    console.log(err);
});

app.ports.searchVideos.subscribe(function(arg) {
    db.search({ query : arg
                , fields : searchableFields
                , include_docs: true
                , mm: '100%'
              }).then(function(result) {
                  let docs = [];
                  for (let i = 0; i < result.rows.length; i++) {
                      docs.push(result.rows[i].doc);
                  }
                  app.ports.searchedVideos.send(docs);
              });
});


// PouchDB.Youtube ports

const YOUTUBE_DATA_DOC_ID = "YOUTUBE_DATA_DOC_ID";
app.ports.storeYoutubeData.subscribe(function(youtubeDataDoc) {
    youtubeDataDoc['_id'] = YOUTUBE_DATA_DOC_ID;
    youtubeDataDoc.type = YOUTUBE_DATA_DOC_TYPE;
    db.put(youtubeDataDoc, {force: true}).then(function() {
        console.log("successfully saved youtubedata");
        // success
    }).catch(function(err) {
        console.log(err);
        app.ports.youtubeDataPortErr.send(JSON.stringify(err));
    });
});

app.ports.fetchYoutubeData.subscribe(function() {
    db.get(YOUTUBE_DATA_DOC_ID).then(function(doc) {
        app.ports.fetchedYoutubeData.send(doc);
    }).catch(function(err) {
        console.log(err);
        if (err.status === 404) {
            app.ports.fetchedYoutubeData.send(null);
        } else {
            app.ports.youtubeDataPortErr.send(JSON.stringify(err));
        }
    });
});
