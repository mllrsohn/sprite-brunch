_ = require 'underscore'
fs = require 'fs'
sysPath = require 'path'
spritesmith = require 'spritesmith'
json2css = require 'json2css'
crypto = require 'crypto'
_when = require 'when'
path = require "path"

module.exports = class SpriteBrunch
	brunchPlugin: yes
	png : [".png", ".gif"]
	jpegs : [".jpg", "jpeg"]
	constructor: (@config) ->
		@options = _.extend
			path: 'app/assets/images/sprites'
			destCSS: 'app/sass/_sprites.sass'
			algorithm: 'top-down'
			cssFormat: 'sass'
			engine: 'canvas'
			imgOpts:
				format: 'auto'
				quality: 90

			, @config.sprites

		@spritePath = sysPath.resolve @options.path
		@formats = @png.concat(@jpegs)

	onCompile: (changedFiles) ->
		return unless fs.existsSync(@spritePath)
		spriteFolders = fs.readdirSync(@spritePath)
		alldone = []
		if spriteFolders
			spriteFolders.forEach (folder) =>
				hasJpg = false

				# Only Folders
				imagePath = sysPath.join @options.path, folder
				stat = fs.statSync imagePath
				return if stat.isFile()

				images = fs.readdirSync(imagePath)
				spriteImages = []
				images.forEach (image) =>
					hasJpg = !!~@jpegs.indexOf(path.extname(image).toLowerCase()) unless hasJpg
					spriteImages.push(sysPath.join(imagePath, image)) if !!~@formats.indexOf(path.extname(image).toLowerCase())

				# Set auto Format
				format = @options.imgOpts.format
				if @options.imgOpts.format is 'auto'
					format = if hasJpg is true then 'jpg' else 'png'

				alldone.push @generateSprites(spriteImages, folder, format) if spriteImages.length > 0

				# Generate Styles when everything is done
				_when.all(alldone).then (sprites) =>
					# Add Template
					@addTemplate(@options.cssFormat)

					# Generate Functions
					styles = ''
					sprites.forEach (sprite) =>
						formatOpts =
							sprites: true
							spriteImage: sprite.foldername
							spritePath: '../' + @options.path + '/' + sprite.imageFile

						styles += json2css(sprite.coordinates, { format: @options.cssFormat, formatOpts: formatOpts})

					styles += json2css({}, { format: @options.cssFormat, formatOpts: {functions: true}})
					@writeStyles(styles)

	generateSprites: (files, foldername, format) ->
		done = _when.defer()

		spritesmithParams =
			src: files
			engine: @options.engine
			algorithm: @options.algorithm
			exportOpts:
				format: format
				quality: @options.imgOpts.quality

		# Generate Sprites
		spritesmith spritesmithParams, (err, result) =>
			if err
				console.error('Error generating sprites in folder: ', foldername, err)
				return false

			# Generate md5 hash from image
			hash = crypto.createHash('sha1').update(result.image).digest('hex')

			imageFile = foldername + '-' + hash + '.' + format
			imageFilePath = sysPath.join @spritePath, imageFile

			# Return if file exits
			unless fs.existsSync(imageFilePath)

				# Cleanup other sprite images
				allImages = fs.readdirSync(@spritePath)
				allImages.forEach (singleImage) =>
					if singleImage.match(foldername + '-(.{40})\.(png|jpg)')
						existingFile = sysPath.join @spritePath, singleImage
						fs.unlinkSync(existingFile)

				# Write File to Disk
				fs.writeFileSync(imageFilePath, result.image, 'binary')

			# Get coordinates and resolove, need all coordinates not only changed
			done.resolve {coordinates: @processCoordinates(result.coordinates, foldername), imageFile: imageFile, foldername: foldername}

		# Return a promise
		done.promise

	writeStyles: (cssStr) ->
		spritePath = sysPath.join @config.paths.app, @options.destCSS
		sha = crypto.createHash('sha1').update(cssStr).digest('hex')
		sha2 = ''

		if fs.existsSync(spritePath)
			currentFile = fs.readFileSync(spritePath, 'utf8');
			sha2 = crypto.createHash('sha1').update(currentFile).digest('hex')

		if sha isnt sha2
			fs.writeFile spritePath, cssStr, 'utf8', (err) ->
				console.log('Could not write stylesheet, please make sure the path exists') if err

	addTemplate: (template) ->
		templatePath = sysPath.join __dirname, '..', 'templates', template + '.template.mustache'
		currentTemplate = fs.readFileSync(templatePath, 'utf8');
		json2css.addMustacheTemplate(template, currentTemplate);

	processCoordinates: (coordinates, foldername) ->

		Object.keys(coordinates).forEach (key) ->
			stylename = key.split '/'
			stylename = stylename.pop()
			stylename = stylename.replace(/\.[^/.]+$/, '')
			coordinates[stylename] = coordinates[key]
			delete coordinates[ key ]

		coordinates