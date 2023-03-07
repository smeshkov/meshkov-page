const webpack = require('webpack');
const path = require('path');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');
const CopyPlugin = require("copy-webpack-plugin");
const HtmlWebPackPlugin = require("html-webpack-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const pakcageJson = require('./package.json');

const { NODE_ENV = 'development' } = process.env;
const isDevelopment = NODE_ENV === 'development';
const isStaging = NODE_ENV === 'staging';

const babelOptions = {
  presets: [
    '@babel/preset-env',
    '@babel/preset-react',
    '@babel/preset-typescript'
  ],
  plugins: [
    '@babel/plugin-transform-runtime',
    '@babel/plugin-proposal-class-properties'
  ],
};

module.exports = (env) => {
  return {
    entry: path.join(__dirname, 'src', 'index.js'),
    output: {
      path: path.resolve(__dirname, 'dist'),
      filename: '[name].js',
    },
    devtool: isDevelopment ? 'inline-source-map' : false,
    mode: isDevelopment ? 'development' : 'production',
    module: {
      rules: [
        {
          test: /\.[jt]sx?$/,
          exclude: /node_modules/,
          use: [
            {
              loader: 'babel-loader',
              options: babelOptions
            }
          ]
        },
        {
          test: /\.html$/,
          use: [
            {
              loader: "html-loader",
              options: { minimize: true }
            }
          ]
        },
        {
          test: /\.(png|jpe?g|gif)$/i,
          use: [
            {
              loader: 'file-loader',
            },
          ],
        },
        {
          test: /\.svg$/,
          use: [
            {
              loader: '@svgr/webpack',
              options: {
                titleProp: true,
              },
            },
          ],
        },
        {
          test: /\.css$/,
          use: [MiniCssExtractPlugin.loader, "css-loader"]
        }
      ]
    },
    resolve: {
      extensions: ['.wasm', '.mjs', '.js', '.json', '.ts', '.tsx']
    },
    devServer: {
      historyApiFallback: true,
      allowedHosts: 'all',
    },
    plugins: [
      // clean the build folder
      new CleanWebpackPlugin({ cleanBeforeEveryBuildPatterns: ['dist'] }),
      new HtmlWebPackPlugin({
        template: "./src/index.html",
        filename: "./index.html"
      }),
      new MiniCssExtractPlugin({
        filename: "[name].css",
        chunkFilename: "[id].css"
      }),
      new webpack.DefinePlugin({
        __DEV__: isDevelopment,
        __STG__: isStaging,
        __PROD__: !isDevelopment && !isStaging,
        __APP_VERSION__: JSON.stringify(pakcageJson.version),
      }),
      new CopyPlugin({
        patterns: [
          { from: './src/assets/*', flatten: true },
          /* {
            from: './src/assets/tutorial/**', to({ context, absoluteFilename }) {
              return `${path.relative(context, absoluteFilename.replace('src/assets', 'assets'))}`;
            },
          }, */
        ]
      }),
    ]
  }
};
