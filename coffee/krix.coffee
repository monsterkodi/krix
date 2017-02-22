
#   000   000  00000000   000  000   000
#   000  000   000   000  000   000 000 
#   0000000    0000000    000    00000  
#   000  000   000   000  000   000 000 
#   000   000  000   000  000  000   000

_      = require 'lodash'
fs     = require 'fs'
path   = require 'path'
tags   = require 'jsmediatags'
log    = require '/Users/kodi/s/ko/js/tools/log'
Tile   = require './tile'
Play   = require './play'
post   = require './post'
walk   = require 'walkdir'
childp = require 'child_process'

MIN_TILE_SIZE = 50
MAX_TILE_SIZE = 500

class Krix
    
    constructor: (@view) ->

        @tiles = @view.firstChild
        @tiles.classList.add 'krixTiles'
        
        @play = new Play

        @setTileNum @tilesWidth() / 120
        
        @tiles.addEventListener "dblclick", @onDblClick
        
        @setStyleRule '.krixTile', "display: inline-block; padding: 0; margin: 0;"
        @setStyleRule '.krixTilePad', "display: inline-block; padding: 10px; padding-bottom: 6px; border: 1px solid transparent; border-radius: 3px; "
        @setStyleRule '.krixTilePadFocus', "background-color: #444;"
        @setStyleRule '.krixTilePad:hover', "border-color: #444;"
  
        post.on 'tileFocus', @onTileFocus
        post.on 'unfocus',   @onUnfocus
        post.on 'loadDir',   @loadDir
        post.on 'openFile',  @openFile
        
        @musicDir = "/Users/kodi/Music"
        @loadDir ""
    
    openFile: (file) =>
        absPath = path.join @musicDir, file
        stat = fs.statSync absPath 
        if stat.isDirectory()
            @loadDir file
        else
            args = [
                '-e', 'tell application "Finder"', 
                '-e', "reveal POSIX file \"#{absPath}\"",
                '-e', 'activate',
                '-e', 'end tell']
            childp.spawn 'osascript', args
    
    # 000       0000000    0000000   0000000  
    # 000      000   000  000   000  000   000
    # 000      000   000  000000000  000   000
    # 000      000   000  000   000  000   000
    # 0000000   0000000   000   000  0000000  

    loadDir: (dir) =>
        # log "Krix.loadDir dir:#{dir}"
        @walker?.stop()
        post.emit 'unfocus'
        for node in @tiles.childNodes
            node.tile.del()
        @tiles.removeChild @tiles.lastChild while @tiles.lastChild
        @tilesDir = path.join @musicDir, dir
        if dir.length and dir != '.'
            tile = new Tile path.dirname(dir), @tiles
            tile.setFocus()
        @walker = walk @tilesDir, max_depth: 1
        @walker.on 'file', (file) =>
            musicPath = file.substr @musicDir.length+1
            addTile = (f, tag) =>
                # log 'addTile', f
                new Tile f, @tiles, tag
            fp = path.join dir, file
            # console.log "Krix.loadDir file:#{file} musicPath #{musicPath}"
            cb = (fp) -> (tag) -> addTile fp, tag
            tags.read file, onSuccess: cb musicPath
        @walker.on 'directory', (d) =>
            musicPath = d.substr @musicDir.length+1
            # console.log "Krix.loadDir d:#{d} musicPath: #{musicPath}"
            tile = new Tile musicPath, @tiles
            tile.setFocus() if not @focusTile
        
    # 000000000  000  000      00000000   0000000
    #    000     000  000      000       000     
    #    000     000  000      0000000   0000000 
    #    000     000  000      000            000
    #    000     000  0000000  00000000  0000000 
    
    onTileFocus: (tile) => @focusTile = tile
    onUnfocus: => @focusTile = null
    getFocusTile: -> @focusTile or @getFirstTile()
    getFirstTile: -> @tiles.firstChild.tile
    getLastTile:  -> @tiles.lastChild.tile
    tilesWidth: -> @tiles.clientWidth
    tilesHeight: -> @tiles.clientHeight
    
    # tileForElem: (elem) ->
        # if elem.classList.contains 'krixTile'
            # return elem
        # return @tileForElem elem.parentNode if elem.parentNode != document
        # return null
              
    #  0000000  000  0000000  00000000
    # 000       000     000   000     
    # 0000000   000    000    0000000 
    #      000  000   000     000     
    # 0000000   000  0000000  00000000
    
    resized: (w,h) -> @aspect = w/h
          
    setTileSize: (size) ->
        @tileSize = Math.floor size
        @tileSize = MIN_TILE_SIZE if @tileSize < MIN_TILE_SIZE
        @tileSize = MAX_TILE_SIZE if @tileSize > MAX_TILE_SIZE
        # log "setTileSize", @tileSize
        @setStyleRule '.krixTileImg', "width: #{@tileSize}px; height: #{@tileSize}px;"
        
    setTileNum: (num) ->
        @tileNum = Math.min Math.floor(@tilesWidth()/MIN_TILE_SIZE), Math.max(1, Math.floor(num))
        # log "setTileNum", @tileNum
        @setTileSize (@tilesWidth() / @tileNum)-22
        
    setStyleRule: (selector, rule) ->
        for i in [0...document.styleSheets[0].cssRules.length]
            r = document.styleSheets[0].cssRules[i]
            if r?.selectorText == selector
                document.styleSheets[0].deleteRule i
        document.styleSheets[0].insertRule "#{selector} { #{rule} }", document.styleSheets[0].cssRules.length
    
    onDblClick: (event) =>
        if event.target.classList.contains 'krixTiles'
            if @tilesDir.length > @musicDir.length
                @loadDir path.dirname @tilesDir.substr @musicDir.length + 1
        
    # 000   000  00000000  000   000
    # 000  000   000        000 000 
    # 0000000    0000000     00000  
    # 000  000   000          000   
    # 000   000  00000000     000   
    
    modKeyComboEventDown: (mod, key, combo, event) ->
        switch key
            when '-'     then @setTileNum @tileNum + 1
            when '='     then @setTileNum @tileNum - 1
            when 'home'  then @getFirstTile().setFocus()
            when 'end'   then @getLastTile().setFocus()
            when 'space' then @getFocusTile().add()
            when 'enter' 
                if not combo then @getFocusTile().play()
                else @getFocusTile().open()
            when 'n'     then post.emit 'nextSong'
            when 'p'     then post.emit 'prevSong'
            when 'left', 'right', 'up', 'down', 'page up', 'page down'  
                @getFocusTile().focusNeighbor key

        log "down", mod, key, combo

    modKeyComboEventUp: (mod, key, combo, event) -> # log "up", mod, key, combo

module.exports = Krix


