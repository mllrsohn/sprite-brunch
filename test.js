var Plugin = require("./index.js");
var expect = require('chai').expect;

describe('Plugin', function() {
  var plugin;

  beforeEach(function() {
    plugin = new Plugin({
      plugins: {
        sprites: {
          
        }
      }
    });
  });

  it('should be an object', function() {
    expect(plugin).to.be.ok;
  });
});