#   0000000    00000000   000   000   0000000
#   000   000  000   000  000 0 000  000     
#   0000000    0000000    000000000  0000000 
#   000   000  000   000  000   000       000
#   0000000    000   000  00     00  0000000 
{
resolve,
style,
queue
}      = require './tools/tools'
fs     = require 'fs'
path   = require 'path'
childp = require 'child_process'
_      = require 'lodash'
log    = require './tools/log'
Tile   = require './tile'
Play   = require './play'
prefs  = require './prefs'
tags   = require './tags' 
imgs   = require './imgs'
walk   = require './walk'
post   = require './post'

MIN_TILE_SIZE = 50
MAX_TILE_SIZE = 500

class Brws
    
    constructor: (@view) ->
        
        @tiles = document.createElement 'div'
        @tiles.classList.add 'tiles'
        @view.appendChild @tiles
        
        @musicDir = resolve "~/Music"
        @tilesDir = @musicDir
        Tile.musicDir = @musicDir
        
        @setTileNum prefs.get "tileNum:#{@musicDir}", 8
        
        @tiles.addEventListener "dblclick", @onDblClick
        @tiles.addEventListener "scroll",   @onScroll
                
        post.on 'tileFocus', @onTileFocus
        post.on 'unfocus',   @onUnfocus
        post.on 'playlist',  @showPlaylist
        post.on 'song',      @showSong
        post.on 'loadDir',   @loadDir
        post.on 'showFile',  @showFile
        post.on 'home',      @goHome
        post.on 'up',        @goUp
        
    del: -> @tiles.remove()
        
    # 000       0000000    0000000   0000000  
    # 000      000   000  000   000  000   000
    # 000      000   000  000000000  000   000
    # 000      000   000  000   000  000   000
    # 0000000   0000000   000   000  0000000  

    goUp:   => @loadDir path.dirname(@dir), @dir
    goHome: => @loadDir ''

    clear: ->
        @walker?.stop()
        tags.clearQueue()
        post.emit 'unfocus'
        @tiles.lastChild.tile.del() while @tiles.lastChild

    showFile: (file) =>
        absPath = path.join @musicDir, file
        stat = fs.statSync absPath 
        args = [
            '-e', 'tell application "Finder"', 
            '-e', "reveal POSIX file \"#{absPath}\"",
            '-e', 'activate',
            '-e', 'end tell']
        childp.spawn 'osascript', args
        
    loadDir: (@dir, highlightFile) =>
        
        @clear()
        @tilesDir = path.join @musicDir, @dir
        @focusTile = null
        
        num = prefs.get "tileNum:#{@tilesDir}", 0
        if num != 0 and @tileNum != num
            @setTileNum num
        
        if @dir.length and @dir != '.'
            tile = new Tile @dir, @tiles, 
                openDir:  path.dirname @dir
                isUp: true
            tile.setText path.dirname(@dir), path.basename(@dir)
            tile.setFocus()

        @walker = new walk @tilesDir
        
        @walker.on 'file', (file) =>
            return if path.basename(file).startsWith '.'
            musicPath = file.substr @musicDir.length+1
            tile = new Tile musicPath, @tiles, isFile: true
            if musicPath == highlightFile
                tile.setFocus()
            
        @walker.on 'directory', (dir) =>
            dirname = path.basename(dir)
            return if dirname.startsWith('.') or dirname == 'iTunes'
            musicPath = dir.substr @musicDir.length+1
            tile = new Tile musicPath, @tiles
            tile.setFocus() if not @focusTile
            if musicPath == highlightFile
                tile.setFocus()
                
        @walker.on 'done', =>
            if prefs.get "expanded:#{@dir}", false
                @expandAllTiles()
                # setTimeout @expandAllTiles, 100
     
    showSong: (song) => if song?.file then @loadDir path.dirname(song.file), song.file
    
    #   00000000   000       0000000   000   000  000      000   0000000  000000000
    #   000   000  000      000   000   000 000   000      000  000          000   
    #   00000000   000      000000000    00000    000      000  0000000      000   
    #   000        000      000   000     000     000      000       000     000   
    #   000        0000000  000   000     000     0000000  000  0000000      000   
        
    showPlaylist: (song) =>
        @clear()
        Play.instance.mpc 'playlistinfo', (playlist) =>
            queue playlist, timeout: 1, cb: (file) =>
                tile = new Tile file, @tiles, isFile: true
                if file == song?.file
                    tile.setFocus()
        
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
    getTiles: -> (t.tile for t in @tiles.childNodes)
    tilesWidth: -> @tiles.clientWidth
    tilesHeight: -> @tiles.clientHeight

    setTileSize: (size) ->
        @tileSize = Math.floor size
        @tileSize = MIN_TILE_SIZE if @tileSize < MIN_TILE_SIZE
        @tileSize = MAX_TILE_SIZE if @tileSize > MAX_TILE_SIZE
        
        fontSize = Math.max 8, Math.min 18, @tileSize / 10
        style '.tiles .tileSqr', "font-size: #{fontSize}px"
        style '.tiles .tileImg', "width: #{@tileSize}px; height: #{@tileSize}px;"

    setTileNum: (num) ->
        @tileNum = Math.min Math.floor(@tilesWidth()/MIN_TILE_SIZE), Math.max(1, Math.floor(num))
        tileSize = parseInt (@tilesWidth()-8)/@tileNum-12
        prefs.set "tileNum:#{@tilesDir}", @tileNum
        @setTileSize tileSize
    
    resized: => @setTileNum @tileNum
            
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

    collapseAllTiles: -> 
        tiles = @getTiles()
        tile.collapse() for tile in tiles
            
    expandAllTiles: -> 
        tiles = @getTiles()
        tile.expand() for tile in tiles

    # 000   000  00000000  000   000
    # 000  000   000        000 000 
    # 0000000    0000000     00000  
    # 000  000   000          000   
    # 000   000  00000000     000   
    
    modKeyComboEventDown: (mod, key, combo, event) ->
        focusTile = @getFocusTile()
        switch combo
            when 'command+u' 
                tags.pruneCache()
                imgs.pruneCache()
                @loadDir @dir
        switch key
            when '-'         then @setTileNum @tileNum + 1
            when '='         then @setTileNum @tileNum - 1
            when 'esc'       then @goUp()
            when 'home'      then @getFirstTile().setFocus()
            when 'end'       then @getLastTile().setFocus()
            when 'space'     then focusTile.add()
            when 'backspace' 
                if mod == 'command' 
                    focusTile.delete()
            when 'left', 'right', 'up', 'down', 'page up', 'page down'  
                if combo == 'command+left'
                    focusTile.collapse()
                else if combo == 'command+right'
                    focusTile.expand()
                else if combo == 'command+down'
                    @expandAllTiles()
                else if combo == 'command+up'
                    @collapseAllTiles()
                else
                    focusTile.focusNeighbor key
            when 'enter' 
                if focusTile.isDir()
                    if combo == 'enter' then focusTile.open()
                    else focusTile.play()
                else
                    if combo == 'enter' then focusTile.play()
                    else focusTile.showInFinder()
        
module.exports = Brws
