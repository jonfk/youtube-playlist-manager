
// DB Stuff
var db = new PouchDB('youtube-manager');

var node = document.getElementById('main');
var token = "ya29.GluGBLNCL8dK5PVKHc50rlj_RsFcPoafRypzUM7X-J2flXpvQ5QL4Z6s3Ar6YIfDp47Z3YP_d1La31FFGQvdydU-nGOKFJcIHKhoGwxwt2X3OJWYcY3aInp7Vnaq";
var app = Elm.Main.embed(node, {
    redirectUri: token
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
        }
        let url = document.createElement('a');
        url.href = redirectUrl;
        url.port_ = url.port;
        app.ports.authorizedRedirectUri.send(url);
    });
});

// PouchDB
app.ports.storeVideos.subscribe(function(documents) {
    documents.forEach(function(doc) {
        doc['_id'] = doc.id;
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
