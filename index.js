(function(){
  'use strict';
  var SpriteBrunch, assign, crypto, fs, templater, spritesmith, sysPath, mkdirp;

  assign = require('lodash.assign');
  fs = require('fs');
  sysPath = require('path');
  spritesmith = require('spritesmith');
  templater = require('spritesheet-templates');
  crypto = require('crypto');
  mkdirp = require('mkdirp');

  SpriteBrunch = function(config) {
    this.config = config;
    this.options = assign({
      path: 'app/assets/images/sprites',
      destCSS: 'app/css/sprites.css',
      destSprites: 'app/assets',
      algorithm: 'top-down',
      cssFormat: 'css',
      engine: 'pixelsmith',
      imgOpts: {
        format: 'auto',
        quality: 90
      }
    }, this.config.plugins.sprites);
    this.spritePath = sysPath.resolve(this.options.path);
    this.formats = this.png.concat(this.jpegs);
    this.type = 'stylesheet';
    this.pattern = /./;
  }

  SpriteBrunch.prototype.brunchPlugin = true;
  SpriteBrunch.prototype.png = [".png", ".gif"];
  SpriteBrunch.prototype.jpegs = [".jpg", "jpeg"];

  SpriteBrunch.prototype.compile = function(changedFiles) {
    var alldone, spriteFolders;
    if (!fs.existsSync(this.spritePath)) {
      return;
    }
    spriteFolders = fs.readdirSync(this.spritePath);
    alldone = [];
    if (spriteFolders) {
      spriteFolders.forEach(folder => {
        var format, hasJpg, imagePath, images, spriteImages, stat;
        hasJpg = false;
        imagePath = sysPath.join(this.options.path, folder);
        stat = fs.statSync(imagePath);
        if (stat.isFile()) {
          return;
        }
        images = fs.readdirSync(imagePath);
        spriteImages = [];
        images.forEach(image => {
          if (!hasJpg) {
            hasJpg = !!~this.jpegs.indexOf(sysPath.extname(image).toLowerCase());
          }
          if (!!~this.formats.indexOf(sysPath.extname(image).toLowerCase())) {
            spriteImages.push(sysPath.join(imagePath, image));
          }
        });
        format = this.options.imgOpts.format;
        if (this.options.imgOpts.format === 'auto') {
          format = hasJpg === true ? 'jpg' : 'png';
        }
        if (spriteImages.length > 0) {
          alldone.push(this.generateSprites(spriteImages, folder, format));
        }
      });
      return Promise.all(alldone).then(sprites => {
        var styles, totalWidth, totalHeight;
        styles = '';
        totalWidth = 0;
        totalHeight = 0;
        sprites.forEach(sprite => {          
          sprite.coordinates.forEach(function(coordinate) {
            totalWidth += coordinate.width;
            totalHeight += coordinate.height;
          });
          styles += templater({
            sprites: sprite.coordinates,
            spritesheet: {
              width: totalWidth,
              height: totalHeight,
              image: sprite.imageFile
            }
          },{
            format: this.options.cssFormat
          });
        });
        this.writeStyles(styles);
      });
    }
  };

  SpriteBrunch.prototype.generateSprites = function(files, foldername, format) {
    var spritesmithParams;
    spritesmithParams = {
      src: files,
      engine: this.options.engine,
      algorithm: this.options.algorithm,
      exportOpts: {
        format: format,
        quality: this.options.imgOpts.quality
      }
    };
    return new Promise((resolve, reject) => {
      spritesmith.run(spritesmithParams, (err, result) => {
        var allImages, hash, imageFile, imageFilePath;
        if (err) {
          console.error('Error generating sprites in folder: ', foldername, err);
          return;
        }
        hash = crypto.createHash('sha1').update(result.image).digest('hex');
        imageFile = foldername + '-' + hash + '.' + format;
        imageFilePath = sysPath.join(sysPath.resolve(this.options.destSprites), imageFile);
        if (!fs.existsSync(imageFilePath)) {
          allImages = fs.readdirSync(this.spritePath);
          allImages.forEach(function(singleImage) {
            var existingFile;
            if (singleImage.match(foldername + '-(.{40})\.(png|jpg)')) {
              existingFile = sysPath.join(this.spritePath, singleImage);
              fs.unlinkSync(existingFile);
            }
          });
          mkdirp(imageFilePath.slice(0, imageFilePath.lastIndexOf("/")), function(err){
              if (err) {
                console.error('Could not write directories for sprite files', err);
              } else {
                fs.writeFile(imageFilePath, result.image, 'binary', function(err){
                  if (err) {
                    console.error('Could not write sprite files', err);
                  }
                });
              }
          });
        }
        resolve({
          coordinates: this.processCoordinates(result.coordinates, foldername, imageFile),
          imageFile: imageFile,
          foldername: foldername
        });
      });
    });
  };

  SpriteBrunch.prototype.writeStyles = function(cssStr) {
    var currentFile, sha, sha2, spritePath;
    spritePath = this.options.destCSS;
    sha = crypto.createHash('sha1').update(cssStr).digest('hex');
    sha2 = '';
    if (fs.existsSync(spritePath)) {
      currentFile = fs.readFileSync(spritePath, 'utf8');
      sha2 = crypto.createHash('sha1').update(currentFile).digest('hex');
    }
    if (sha !== sha2) {
      mkdirp(spritePath.slice(0,spritePath.lastIndexOf("/")), function(err) {
        if (err) {
          console.error('Could not write directories for stylesheet', err);
        } else {
          fs.writeFile(spritePath, cssStr, 'utf8', function(err) {
            if (err) {
              console.error('Could not write stylesheet', err);
            }
          });
        }
      });
    }
  };

  SpriteBrunch.prototype.processCoordinates = function(coordinates, foldername, imageFile) {
    var newCoordinates;
    newCoordinates = [];
    Object.keys(coordinates).forEach(function(key) {
      var stylename;
      stylename = key.split('/');
      stylename = stylename.pop();
      stylename = stylename.replace(/\.[^\/.]+$/, '');
      coordinates[key].image = imageFile;
      coordinates[key].name = stylename;
      newCoordinates.push(coordinates[key]);
      delete coordinates[key];
    });
    return newCoordinates;
  };

  module.exports = SpriteBrunch;
})();