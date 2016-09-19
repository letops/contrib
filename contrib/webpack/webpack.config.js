// Explore https://goo.gl/qoLZP3
// to get a better understanding of the following code

var path = require('path');
var webpack = require('webpack');
var BundleTracker = require('webpack-bundle-tracker');
var CleanWebpackPlugin = require('clean-webpack-plugin');
var ExtractTextPlugin = require('extract-text-webpack-plugin');
var _ = require('lodash');
var fs = require('fs');

var PROD = (process.env.DJANGO_ENV === 'production');
console.log('PRODUCTION: ' + PROD);

var entries = {
  // canvasCSS: './built/css/canvas.scss',
  // canvasJS: './built/js/canvas/canvas.jsx',
  // pollCSS: './built/css/poll.scss',
  // pollJS: './built/js/poll/poll.jsx',
  // shareCSS: './built/css/share.scss',
  // shareJS: './built/js/share/share.jsx',
};

var outputDir = PROD ?
    path.join(__dirname, 'webpack', 'production') :
    path.join(__dirname, 'webpack', 'bundles');

function setCssExt(ext) {
  return ext.replace(/\.js$/, '.css');
};

var cleanPlugin = new CleanWebpackPlugin(['bundles'], {
  root: path.resolve('./webpack'),
  verbose: true,
  dry: false,
});

var cssLoaders = ['style', 'css', 'autoprefixer-loader?browsers=last 2 versions'];
var styleModLoaders = [
  { test: /\.scss$/, loaders: cssLoaders.concat([
      'sass?config=sassLoader',
    ]), },
  { test: /\.css$/, loaders: cssLoaders },
];
var styleModLoaders = styleModLoaders.map(function (e) {
  return {
    test: e.test,
    loader: ExtractTextPlugin.extract(e.loaders.slice(1).join('!')),
  };
});

var scriptModLoaders = [
  { test: /\.js$/, exclude: /node_modules/, loader: 'babel' },
  { test: /\.jsx$/, exclude: /node_modules/, loader: 'babel', query: { presets: ['react'], } },
];

var extractPlugin = new ExtractTextPlugin('[name].css', allChunks = true);

var generateManifestPlugin = function (compiler) {
  return this.plugin('done', function (stats) {
    stats = stats.toJson();
    var assetStats = stats.assetsByChunkName;

    for (var entryName in assetStats) {
      var entryPath = assetStats[entryName];
      if (/\.(?:scss|sass|css)$/.test(entries[entryName])) {
        if (_.isArray(entryPath)) {
          assetStats[entryName] = entryPath.map(function (ass) {
            return setCssExt(ass);
          });
        } else {
          assetStats[entryName] = setCssExt(entryPath);
        }
      }
    }

    // return fs.writeFileSync(
    //   path.join(outputDir,
    //   'asset-stats.json'), JSON.stringify(stats.assetsByChunkName, null, 2)
    // );
  });
};

var webpackConfiguration = {
  target: 'web',
  cache: true,
  debug: true,
  watch: false,
  devtool: 'source-map',

  entry: entries,
  output: {
    path: outputDir,
    filename: PROD ? '[name]-[hash].min.js' : '[name]-[hash].js',
    chunkFilename:  PROD ? '[name].[id].[chunkhash].min.js' : '[name].[id].[chunkhash].js',
  },

  externals: {
    jquery: 'jQuery',
  },

  plugins: [
    cleanPlugin,
    new webpack.DefinePlugin({
      __PRODUCTION__: PROD ? JSON.stringify(false) : JSON.stringify(true),
      __DEVTOOLS__: PROD ? false : true,
      'process.env': {
        NODE_ENV: JSON.stringify(process.env.DJANGO_ENV),
      },
    }),
    extractPlugin,
    generateManifestPlugin,
    new BundleTracker({
      filename: PROD ? './webpack/prod-stats.json' : './webpack/dev-stats.json',
    }),
  ],

  module: {
    loaders: styleModLoaders.concat(scriptModLoaders).concat([
      { test: /\.(jpeg|tiff)$/, loader: 'file' },
      { test: /\.eot$/, loader: 'file?mimetype=application/x-font-ttf' },
      { test: /\.gif$/, loader: 'url?limit=10000&mimetype=image/gif' },
      { test: /\.jpg$/, loader: 'url?limit=10000&mimetype=image/jpg' },
      { test: /\.png$/, loader: 'url?limit=10000&mimetype=image/png' },
      { test: /\.svg$/, loader: 'file?mimetype=image/svg+xml' },
      { test: /\.ttf$/, loader: 'file?mimetype=application/vnd.ms-fontobject' },
      { test: /\.woff$/,
        loader: 'url-loader?limit=10000&mimetype=application/font-woff&name=[path][name].[ext]', },
      { test: /\.woff2$/,
        loader: 'url-loader?limit=10000&mimetype=application/font-woff2&name=[path][name].[ext]', },
    ]),
  },

  resolve: {
    modulesDirectories: ['node_modules', 'bower_components'],
    extensions: ['', '.js', '.jsx', '.css', '.scss'],
  },

  sassLoader: {
    precision: 10,
    outputStyle: 'expanded',
    sourceMap: true,
    includePaths: [
      'node_modules/bootstrap-sass',
      'node_modules/hopscotch',
      'node_modules/breakpoint-sass/stylesheets',
      'node_modules/normalize-scss/sass',
      'node_modules/support-for/sass',
      'node_modules/susy/sass',
    ],
  },
};

if (PROD) {
  cleanPlugin.paths = ['production'];
  cleanPlugin.options = {
    root: path.resolve('./webpack'),
    verbose: true,
    dry: false,
  };
  extractPlugin.filename = '[name]-[hash].css';
  webpackConfiguration.debug = false;
  webpackConfiguration.watch = false;
  webpackConfiguration.devtool = null;
  webpackConfiguration.plugins.push(
    new webpack.optimize.OccurenceOrderPlugin(true),
    new webpack.optimize.UglifyJsPlugin({
      compress: {
        warnings: PROD ? false : true,
      },
    })
  );
}

module.exports = webpackConfiguration;
