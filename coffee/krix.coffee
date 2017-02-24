
#   000   000  00000000   000  000   000
#   000  000   000   000  000   000 000 
#   0000000    0000000    000    00000  
#   000  000   000   000  000   000 000 
#   000   000  000   000  000  000   000

fs     = require 'fs'
path   = require 'path'
walk   = require 'walkdir'
childp = require 'child_process'
_      = require 'lodash'
log    = require './tools/log'
Tile   = require './tile'
Play   = require './play'
tags   = require './tags' 
post   = require './post'

MIN_TILE_SIZE = 50
MAX_TILE_SIZE = 500

class Krix
    
    constructor: (@view) ->

        @tiles = @view.firstChild
        @tiles.classList.add 'krixTiles'
        
        @play = new Play

        @setTileNum @tilesWidth() / 120
        
        @tiles.addEventListener "dblclick", @onDblClick
        
        @style '.krixTile', "display: inline-block; padding: 0; margin: 0;"
        @style '.krixTilePad', "display: inline-block; padding: 10px; padding-bottom: 6px; border: 1px solid transparent; border-radius: 3px;"
        @style '.krixTilePadFocus', "background-color: #44a;"
        @style '.krixTilePadFocus .krixTileSqrCover', "opacity: 1.0;"
        @style '.krixTilePadDir', "border-radius: 8px;"
        @style '.krixTilePadFocus.krixTilePadDir', "background-color: #333;"
        @style '.krixTileSqrDir', "padding:  5px; overflow: hidden; border-radius: 0px; background-color: rgba(0,0,0,0.7); "
        @style '.krixTileSqrCover', "opacity: 0;"
        @style '.krixTileImgDir', "border-radius: 5px;"
        @style '.krixTileSqrFile', "padding:5px; overflow: hidden; background-color: rgba(0,0,100,0.7);"
  
        post.on 'tileFocus', @onTileFocus
        post.on 'unfocus',   @onUnfocus
        post.on 'loadDir',   @loadDir
        post.on 'openFile',  @openFile
        
        @tiles.addEventListener "scroll", @onScroll
                
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
            new Tile musicPath, @tiles, 
                isFile: true
                musicDir: @musicDir
            
        @walker.on 'directory', (dir) =>
            dirname = path.basename(dir)
            return if dirname.startsWith('.') or dirname == 'iTunes'
            musicPath = dir.substr @musicDir.length+1
            tile = new Tile musicPath, @tiles, musicDir: @musicDir
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
        @style '.krixTileImg', "width: #{@tileSize}px; height: #{@tileSize}px;"
        
    setTileNum: (num) ->
        @tileNum = Math.min Math.floor(@tilesWidth()/MIN_TILE_SIZE), Math.max(1, Math.floor(num))
        @setTileSize (@tilesWidth() / @tileNum)-22
        
    style: (selector, rule) ->
        for i in [0...document.styleSheets[0].cssRules.length]
            r = document.styleSheets[0].cssRules[i]
            if r?.selectorText == selector
                document.styleSheets[0].deleteRule i
        document.styleSheets[0].insertRule "#{selector} { #{rule} }", document.styleSheets[0].cssRules.length
    
    onDblClick: (event) =>
        if event.target.classList.contains 'krixTiles'
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
            when 'n'         then post.emit 'nextSong'
            when 'p'         then post.emit 'prevSong'
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

        # log "down", mod, key, combo

    modKeyComboEventUp: (mod, key, combo, event) -> # log "up", mod, key, combo

module.exports = Krix


