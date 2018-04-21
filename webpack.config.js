const path = require('path');

// Add closure compile to build

module.exports = {
    mode: 'development',
    entry: './src/Main/main-interop.js',
    output: {
        path: path.resolve(__dirname, 'build/main'),
        filename: 'main-interop.js'
    },
    devtool: 'cheap-module-source-map'
};
