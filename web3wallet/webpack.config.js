const path = require('path');

module.exports = {
    entry: './src/index.js', // 入口文件
    output: {
        path: path.resolve(__dirname, 'dist'),
        filename: 'bundle.js' // 输出文件名
    },
    mode: 'development'
};
