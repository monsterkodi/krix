#   0000000    00000000   000   000   0000000
#   000   000  000   000  000 0 000  000     
#   0000000    0000000    000000000  0000000 
#   000   000  000   000  000   000       000
#   0000000    000   000  00     00  0000000 
{
resolve,
style
}      = require './tools/tools'
fs     = require 'fs'
path   = require 'path'
walk   = require 'walkdir'
childp = require 'child_process'
_      = require 'lodash'
log    = require './tools/log'
Tile   = require './tile'
tags   = require './tags' 
post   = require './post'

MIN_TILE_SIZE = 50
MAX_TILE_SIZE = 500

class Brws
    
    constructor: (@view) ->
        
        @tiles = document.createElement 'div'
        @tiles.style.position = 'absolute'
        @tiles.style.top = '200px'
        @tiles.style.left = '0'
        @tiles.style.right = '0'
        @tiles.style.bottom = '0'
        @tiles.style.background = "#000"
        @tiles.style.overflow = "scroll"
        @tiles.classList.add 'tiles'
        @view.appendChild @tiles
        
        @musicDir = resolve "~/Music"
        Tile.musicDir = @musicDir
        # log "Brws.constructor @musicDir:#{@musicDir}"
        
        @setTileNum @tilesWidth() / 120
        
        @tiles.addEventListener "dblclick", @onDblClick
        @tiles.addEventListener "scroll",   @onScroll
        
        style '.tile',                       "display: inline-block; padding: 0; margin: 0;"
        style '.tilePad',                    "display: inline-block; padding: 10px; padding-bottom: 6px; border: 1px solid transparent; border-radius: 3px;"
        style '.tilePadFocus',               "background-color: #44a;"
        style '.tilePadFocus .tileSqrCover', "opacity: 1.0;"
        style '.tilePadDir',                 "border-radius: 8px;"
        style '.tilePadFocus.tilePadDir',    "background-color: #333;"
        style '.tileSqrDir',                 "padding:  5px; overflow: hidden; border-radius: 0px; background-color: rgba(0,0,0,0.7);"
        style '.tileSqrCover',               "opacity: 0;"
        style '.tileArtist',                 "color: #88f;"
        style '.tileImgDir',                 "border-radius: 5px;"
        style '.tileSqrFile',                "padding:5px; overflow: hidden; background-color: rgba(0,0,100,0.7);"
        
        post.on 'tileFocus', @onTileFocus
        post.on 'unfocus',   @onUnfocus
        post.on 'loadDir',   @loadDir
        
    # 000       0000000    0000000   0000000  
    # 000      000   000  000   000  000   000
    # 000      000   000  000000000  000   000
    # 000      000   000  000   000  000   000
    # 0000000   0000000   000   000  0000000  

    loadDir: (dir) =>
        @walker?.stop()
        tags.clearQueue()
        post.emit 'unfocus'
        for node in @tiles.childNodes
            node.tile.del()
        @tiles.removeChild @tiles.lastChild while @tiles.lastChild
        @tilesDir = path.join @musicDir, dir
        if dir.length and dir != '.'
            tile = new Tile path.dirname(dir), @tiles, musicDir: @musicDir, krixDir: @tilesDir, isUp: true
            tile.setText path.dirname(dir), path.basename(dir)
            tile.setFocus()
            
        @walker = walk @tilesDir, max_depth: 1
        
        @walker.on 'file', (file) =>
            return if path.basename(file).startsWith '.'
            musicPath = file.substr @musicDir.length+1
            new Tile musicPath, @tiles, isFile: true
            
        @walker.on 'directory', (dir) =>
            dirname = path.basename(dir)
            return if dirname.startsWith('.') or dirname == 'iTunes'
            musicPath = dir.substr @musicDir.length+1
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

    setTileSize: (size) ->
        @tileSize = Math.floor size
        @tileSize = MIN_TILE_SIZE if @tileSize < MIN_TILE_SIZE
        @tileSize = MAX_TILE_SIZE if @tileSize > MAX_TILE_SIZE
        style '.tiles .tileImg', "width: #{@tileSize}px; height: #{@tileSize}px;"

    setTileNum: (num) ->
        @tileNum = Math.min Math.floor(@tilesWidth()/MIN_TILE_SIZE), Math.max(1, Math.floor(num))
        @setTileSize (@tilesWidth() / @tileNum)-22
            
    onDblClick: (event) =>
        if event.target.classList.contains 'tiles'
            if @tilesDir.length > @musicDir.length
                @loadDir path.dirname @tilesDir.substr @musicDir.length + 1

    onScroll: =>
        Tile.scrollLock = true
        unlock = () -> 
            Tile.scrollLock = false
        clearTimeout @scrollTimer
        @scrollTimer = setTimeout unlock, 100

    # 000   000  00000000  000   000
    # 000  000   000        000 000 
    # 0000000    0000000     00000  
    # 000  000   000          000   
    # 000   000  00000000     000   
    
    modKeyComboEventDown: (mod, key, combo, event) ->
        switch key
            when '-'         then @setTileNum @tileNum + 1
            when '='         then @setTileNum @tileNum - 1
            when 'home'      then @getFirstTile().setFocus()
            when 'end'       then @getLastTile().setFocus()
            when 'space'     then @getFocusTile().add()
            when 'backspace' then @getFocusTile().delete()
            when 'left', 'right', 'up', 'down', 'page up', 'page down'  
                @getFocusTile().focusNeighbor key
            when 'enter' 
                if @getFocusTile().isDir()
                    if combo == 'enter' then @getFocusTile().open()
                    else @getFocusTile().play()
                else
                    if combo == 'enter' then @getFocusTile().play()
                    else @getFocusTile().open()
        
module.exports = Brws
