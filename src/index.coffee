_ = require 'underscore'
fs = require 'fs'
sysPath = require 'path'
spritesmith = require 'spritesmith'
json2css = require 'json2css'
crypto = require 'crypto'
path = require "path"

module.exports = class SpriteBrunch
	brunchPlugin: yes
	png : [".png", ".gif"]
	jpegs : [".jpg", "jpeg"]
	constructor: (@config) ->
		@options = _.extend
			path: 'images/sprites'
			destCSS: 'sass/_sprites.sass'
			algorithm: 'top-down'
			cssFormat: 'sass'
			engine: 'canvas'
			imgOpts:
				format: 'auto'
				quality: 90

			, @config.sprites

		@spritePath = sysPath.join @config.paths.assets, @options.path
		@formats = @png.concat(@jpegs)

	onCompile: () ->
		spriteFolders = fs.readdirSync(@spritePath)
		if spriteFolders
			spriteFolders.forEach (folder) =>
				hasJpg = false

				# Only Folders
				imagePath = sysPath.join @config.paths.assets, @options.path, folder
				stat = fs.statSync imagePath
				return if stat.isFile()

				images = fs.readdirSync(imagePath)
				spriteImages = []
				images.forEach (image) =>
					hasJpg = !!~@jpegs.indexOf(path.extname(image).toLowerCase()) unless hasJpg
					spriteImages.push(sysPath.join(imagePath, image)) if !!~@formats.indexOf(path.extname(image).toLowerCase())

				# Set auto Format
				format = if @options.imgOpts.format is 'auto' and hasJpg then 'jpg' else 'png'
				console.log(format)
				@generateSprites(spriteImages, folder, format) if spriteImages.length > 0

	generateSprites: (files, foldername, format) ->
		spritesmithParams =
			src: files
			engine: @options.engine
			algorithm: @options.algorithm
			exportOpts: @options.exportOpts

		# Generate Sprites
		spritesmith spritesmithParams, (err, result) =>
			if err
				console.error('Error generating sprites in folder: ', foldername, err)
				return false

			# Generate md5 hash from image
			hash = crypto.createHash('md5').update(result.image).digest('hex')

			imageFile = foldername + '-' + hash + '.' + format
			imageFilePath = sysPath.join @spritePath, imageFile

			# Return if file exits
			unless fs.existsSync(imageFilePath)

				# Cleanup other sprite images
				allImages = fs.readdirSync(@spritePath)
				allImages.forEach (singleImage) =>
					if singleImage.match(foldername + '-(.{32})\.(png|jpg)')
						existingFile = sysPath.join @spritePath, singleImage
						fs.unlinkSync(existingFile)

				# Write File to Disk
				fs.writeFileSync(imageFilePath, result.image, 'binary')

				# Get coordinates and write style
				coordinates = @processCoordinates(result.coordinates, foldername)
				@generateStyles(coordinates, imageFile)

		null

	generateStyles: (coordinates, imageFile) ->
		formatOpts =
			spritePath: '../' + @options.path + '/' + imageFile

		cssStr = json2css(coordinates, { format: @options.cssFormat, formatOpts: formatOpts})
		spritePath = sysPath.join @config.paths.app, @options.destCSS
		fs.writeFileSync(spritePath, cssStr, 'utf8')


	processCoordinates: (coordinates, foldername) ->

		Object.keys(coordinates).forEach (key) ->
			stylename = key.split '/'
			stylename = stylename.pop()
			stylename = foldername + '_' + stylename.replace(/\.[^/.]+$/, '')
			coordinates[stylename] = coordinates[key]
			delete coordinates[ key ]

		coordinates