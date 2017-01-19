## sprite-brunch
Sprite Generator for [brunch](http://brunch.io).
It uses [Spritesmith](https://github.com/Ensighten/spritesmith) and [spritesheet-templates](https://github.com/twolfson/spritesheet-templates) to generate sprites in language agnostic styles.

## Installation
If using Less, SASS, etc., this should be ordered before their brunch compilers in package.json so that sprite styles compile before other styles.
To improve speed, consider an engine such as [canvassmith](https://github.com/twolfson/canvassmith) or [gmsmith](https://github.com/twolfson/gmsmith).
Check out the [Spritesmith](https://github.com/Ensighten/spritesmith#engines) website for details.

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

For CSS languages/preprocessors, the plugin only generates the variables and the mixins. The mixins have to be called from another stylesheet to be included in your project.

# Less Example

```less
.icon-name {
  .sprite(@icon-name);
}
```

If you want to use git version of plugin, add
`"sprite-brunch": "git+ssh://git@github.com:aedryan/sprite-brunch.git"`.
