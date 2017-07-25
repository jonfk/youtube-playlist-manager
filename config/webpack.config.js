const path = require('path');
const ClosureCompilerPlugin = require('webpack-closure-compiler');

module.exports = {
    entry: {
        main: path.join(__dirname, '../target/main.js'),
        interop: path.join(__dirname, '../src/main/main-interop.js')
    },
    output: {
        path: path.join(__dirname, '../temp_build/webpack'),
        filename: '[name].min.js'
    },
    plugins: [
        new ClosureCompilerPlugin({
            compiler: {
                jar: '/Users/jonfk_/Code/web/youtube-playlist-manager/tools/closure-compiler-v20170626.jar', //optional
                language_in: 'ECMASCRIPT6',
                language_out: 'ECMASCRIPT5',
                compilation_level: 'SIMPLE'
            },
            concurrency: 1,
        })
    ],
};
