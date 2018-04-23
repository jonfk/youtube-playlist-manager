
import { checkAndUpdateAllDesignDocs } from '../PouchDB/design/docs';

export default checkAndUpdateAllDesignDocs().then(function() {
    var node = document.getElementById('main');
    return Elm.Main.embed(node, {});
});
