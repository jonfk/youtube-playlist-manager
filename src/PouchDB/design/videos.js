
function fetchVideosMapFunc(doc) {
    if (doc.type === 'YOUTUBE_VIDEO_DOC_TYPE') {
        emit([doc.publishedAt, doc.videoId]);
    }
}

const ddocId = '_design/videos_index';

export default {
    _id: ddocId,
    views: {
        by_publishedAt: {
            map: fetchVideosMapFunc.toString()
        }
    }
};
