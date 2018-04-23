import appPromise from '../Main/elm-app';
import db from './db';

appPromise.then(function(app) {
    app.ports.deleteDatabase.subscribe(function(args) {
        db.destroy().then(function(response) {
            // success
            console.log('Deleted Database');
        }).catch(function(err) {
            console.log('deleteDatabase error');
            console.log(err);
        });
    });
});
