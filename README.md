## sprite-brunch
Sprite Generator for [brunch](http://brunch.io).
It uses [Spritesmith](https://github.com/Ensighten/spritesmith) and [spritesheet-templates](https://github.com/twolfson/spritesheet-templates) to generate sprites and language agnostic styles.
Currently supports CSS, Less, SASS, SCSS, and Stylus.

## Installation
To improve speed, consider and engine such as [canvassmith](https://github.com/twolfson/canvassmith) or [gmsmith](https://github.com/twolfson/gmsmith).
Check out the [Spritesmith](https://github.com/Ensighten/spritesmith#engines) website for details

## Config
```javascript
sprites: {
	path: 'app/assets/images/sprites', // Path to your sprites folder
	destCSS: 'app/css/sprites.css', // Destination sass/less/stylus files
	destSprites: 'app/assets' // Destination of generated sprite files
	cssFormat: 'css', // less, sass, scss, stylus
	algorithm: 'top-down', // algorithm: top-down, left-right, diagonal (\ format), alt-diagonal
	engine: 'pixelsmith', // pixelsmith, canvassmith, gmsmith
	imgOpts: {
		format: 'auto', // auto, jpg, png (If auto is used and there is png and jpg in a folder the sprite will be jpg)
		quality: 90 // Quality of the output image
	}
}
```

## Usage
It expects the following folder structure and uses the folder name as first value and the filename as the second

```
app/assets/images/sprites/icons
	icona.png
	iconb.png
app/assets/images/sprites/backgrounds
```

# Less Example

```less
.icon-name {
  .sprite(@icon-name);
}
```

Add `"sprite-brunch": "0.1.3"` to `package.json` of your brunch app.

Pick a plugin version that corresponds to your minor (y) brunch version.

If you want to use git version of plugin, add
`"sprite-brunch": "git+ssh://git@github.com:aedryan/sprite-brunch.git"`.
