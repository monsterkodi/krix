
#   000   000  00000000   000  000   000
#   000  000   000   000  000   000 000 
#   0000000    0000000    000    00000  
#   000  000   000   000  000   000 000 
#   000   000  000   000  000  000   000

_    = require 'lodash'
fs   = require 'fs'
path = require 'path'
tags = require 'jsmediatags'
log  = require '/Users/kodi/s/ko/js/tools/log'
Tile = require './tile'
Play = require './play'
post = require './post'

class Krix
    
    constructor: (@view) ->
    
        @tiles = @view.firstChild
        @play = new Play
    
        @setTileSize 120
        
        @setStyleRule '.krixTile', "display: inline-block; padding: 0; margin: 0;"
        @setStyleRule '.krixTilePad', "display: inline-block; padding: 10px; padding-bottom: 6px; border: 1px solid transparent; border-radius: 10px;  "
        @setStyleRule '.krixTilePadFocus', "background-color: #444;"
        @setStyleRule '.krixTilePad:hover', "border-color: #444;"
  
        post.on 'tileFocus', @onTileFocus
                
        musicDir = "/Users/kodi/Music/"
        
        # for dir in ["dubby", "deep"]
        for dir in ["likes"]
            files = fs.readdirSync musicDir + dir
                
            addTile = (f, tag) =>
                new Tile f, tag, @tiles
                    
            for f in files
                fp = path.join dir, f
                cb = (fp) -> (tag) -> addTile fp, tag
                tags.read path.join(musicDir, fp), onSuccess: cb fp
        
    #   00     00   0000000   000   000   0000000  00000000
    #   000   000  000   000  000   000  000       000     
    #   000000000  000   000  000   000  0000000   0000000 
    #   000 0 000  000   000  000   000       000  000     
    #   000   000   0000000    0000000   0000000   00000000
    
    onTileFocus: (tile) => @focusTile = tile
    getFocusTile: -> @focusTile or @getFirstTile()
    getFirstTile: -> @tiles.firstChild.tile
    getLastTile:  -> @tiles.lastChild.tile
    
    # tileForElem: (elem) ->
        # if elem.classList.contains 'krixTile'
            # return elem
        # return @tileForElem elem.parentNode if elem.parentNode != document
        # return null
              
    #    0000000  000  0000000  00000000
    #   000       000     000   000     
    #   0000000   000    000    0000000 
    #        000  000   000     000     
    #   0000000   000  0000000  00000000
    
    resized: (w,h) -> @aspect = w/h
          
    setTileSize: (size) ->
        @tileSize = size
        @tileSize = 50 if @tileSize < 50
        @tileSize = 500 if @tileSize > 500
        @setStyleRule '.krixTileImg', "width: #{@tileSize}px; height: #{@tileSize}px;"
        
    setStyleRule: (selector, rule) ->
        for i in [0...document.styleSheets[0].cssRules.length]
            r = document.styleSheets[0].cssRules[i]
            if r?.selectorText == selector
                document.styleSheets[0].deleteRule i
        document.styleSheets[0].insertRule "#{selector} { #{rule} }", document.styleSheets[0].cssRules.length
        
    #   000   000  00000000  000   000
    #   000  000   000        000 000 
    #   0000000    0000000     00000  
    #   000  000   000          000   
    #   000   000  00000000     000   
    
    modKeyComboEventDown: (mod, key, combo, event) ->
        switch key
            when '-'    then @setTileSize @tileSize - 10
            when '='    then @setTileSize @tileSize + 10
            when 'home' then @getFirstTile().setFocus()
            when 'end'  then @getLastTile().setFocus()
            when 'left', 'right', 'up', 'down', 'page up', 'page down'  
                @getFocusTile().focusNeighbor key

        # log "down", key, combo

    modKeyComboEventUp: (mod, key, combo, event) -> # log "up", mod, key, combo

module.exports = Krix


