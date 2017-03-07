#   0000000    00000000   000   000   0000000
#   000   000  000   000  000 0 000  000     
#   0000000    0000000    000000000  0000000 
#   000   000  000   000  000   000       000
#   0000000    000   000  00     00  0000000 
{
resolve,
style,
queue,
$ }    = require './tools/tools'
fs     = require 'fs'
path   = require 'path'
mkpath = require 'mkpath'
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
        post.on 'connected', @connected
        
    del: -> @tiles.remove()
        
    # 000       0000000    0000000   0000000  
    # 000      000   000  000   000  000   000
    # 000      000   000  000000000  000   000
    # 000      000   000  000   000  000   000
    # 0000000   0000000   000   000  0000000  

    goUp: =>
        if @playlist
            @loadDir '', @playlist
        else if @dir in ['', '.']
            if @focusTile?
                post.emit 'focusSong'
            else
                @getFirstTile()?.setFocus()
        else
            @loadDir path.dirname(@dir), @dir
        
    goHome: => @loadDir ''

    clear: ->
        @walker?.stop()
        tags.clearQueue()
        post.emit 'unfocus'
        @tiles.lastChild.tile.del() while @tiles.lastChild

    showFile: (file) =>
        if not path.isAbsolute file
            file = path.join @musicDir, file
        stat = fs.statSync file 
        args = [
            '-e', 'tell application "Finder"', 
            '-e', "reveal POSIX file \"#{file}\"",
            '-e', 'activate',
            '-e', 'end tell']
        childp.spawn 'osascript', args

    # 00000000   000       0000000   000   000  000      000   0000000  000000000
    # 000   000  000      000   000   000 000   000      000  000          000   
    # 00000000   000      000000000    00000    000      000  0000000      000   
    # 000        000      000   000     000     000      000       000     000   
    # 000        0000000  000   000     000     0000000  000  0000000      000   
        
    showPlaylist: (@playlist, @highlight) =>
        delete @dir        
        @clear()
        @focusTile = null
        
        num = prefs.get "tileNum:#{@playlist}", -1
        if num != -1 and @tileNum != num
            @setTileNum num
        
        tile = new Tile @playlist, @tiles, 
            playlist: @playlist
            openDir:  '.'
            isUp:     true
        tile.setFocus()
        
        if @playlist == ''
            
            $('.tileName', tile.div).innerHTML = "<span class=\"fa fa-bars fa-1\"></span>"
            
            Play.instance.mpc 'playlistinfo', (playlist) =>
                queue playlist, timeout: 1, cb: (file) =>
                    tile = new Tile file, @tiles, isFile: true
                    if file == @highlight
                        tile.setFocus()
        else
            Play.instance.mpc 'listplaylist', [@playlist], (playlist) =>
                queue playlist, timeout: 1, cb: (file) =>
                    tile = new Tile file, @tiles, isFile: true
                    if file == @highlight
                        tile.setFocus()

    connected: () =>
        post.removeListener 'connected', @loadPlaylists
        @loadPlaylists()
        
    loadPlaylists: ->
        Play.mpc 'listplaylists', (playlists) =>
            for list in playlists
                tile = new Tile list, @tiles, playlist: list
                if @highlight == list
                    tile.setFocus()

    createPlaylist: (name='new playlist') ->
        return if @dir != ''
        Play.newPlaylist name, (playlist) =>
            tile = new Tile playlist, @tiles, playlist: playlist
            tile.setFocus()

    delPlaylistItem: ->
        return if not @playlist?
        return if not @focusTile?
        
    # 000       0000000    0000000   0000000    0000000    000  00000000   
    # 000      000   000  000   000  000   000  000   000  000  000   000  
    # 000      000   000  000000000  000   000  000   000  000  0000000    
    # 000      000   000  000   000  000   000  000   000  000  000   000  
    # 0000000   0000000   000   000  0000000    0000000    000  000   000  
    
    loadDir: (@dir, @highlight) =>
        # log "Brws.loadDir @dir:#{@dir} highlightFile:#{highlightFile}"
        delete @playlist
        @clear()
        @tilesDir = path.join @musicDir, @dir
        @focusTile = null
        
        num = prefs.get "tileNum:#{@tilesDir}", -1
        if num != -1 and @tileNum != num
            @setTileNum num
        
        if @dir.length and @dir != '.'
            tile = new Tile @dir, @tiles, 
                openDir: path.dirname @dir
                isUp:    true
            tile.setText path.dirname(@dir), path.basename(@dir)
            tile.setFocus()

        @walker = new walk @tilesDir
        
        @walker.on 'file', (file) =>
            return if path.basename(file).startsWith '.'
            musicPath = file.substr @musicDir.length+1
            tile = new Tile musicPath, @tiles, isFile: true
            if musicPath == @highlight
                tile.setFocus()
            
        @walker.on 'directory', (dir) =>
            dirname = path.basename(dir)
            return if dirname.startsWith('.') or dirname == 'iTunes'
            musicPath = dir.substr @musicDir.length+1
            tile = new Tile musicPath, @tiles
            tile.setFocus() if not @focusTile
            if musicPath == @highlight
                tile.setFocus()
                
        @walker.on 'done', =>
            if prefs.get "expanded:#{@dir}", false
                @expandAllTiles()
                
            if @tilesDir == @musicDir
                @loadPlaylists()

    showSong: (song) => if song?.file then @loadDir path.dirname(song.file), song.file
            
    # 000000000  000  000      00000000   0000000
    #    000     000  000      000       000     
    #    000     000  000      0000000   0000000 
    #    000     000  000      000            000
    #    000     000  0000000  00000000  0000000 
    
    onTileFocus: (tile) => 
        @activeTile = tile
        if tile?.div.parentNode == @tiles
            @focusTile = tile
        else
            @focusTile = null
            
    onUnfocus:     => @focusTile = null
    getFirstTile:  -> @tiles.firstChild.tile
    getLastTile:   -> @tiles.lastChild.tile
    getTiles:      -> (t.tile for t in @tiles.childNodes)
    tilesWidth:    -> @tiles.clientWidth
    tilesHeight:   -> @tiles.clientHeight

    setTileSize: (size) ->
        @tileSize = Math.floor size
        @tileSize = MIN_TILE_SIZE if @tileSize < MIN_TILE_SIZE
        @tileSize = MAX_TILE_SIZE if @tileSize > MAX_TILE_SIZE
        
        fontSize = Math.max 8, Math.min 18, @tileSize / 10
        style '.tiles .tileSqr',   "font-size: #{fontSize}px"
        style '.tiles .tileInput', "font-size: #{fontSize}px; width: #{@tileSize-12}px;"
        style '.tiles .tileImg',   "width: #{@tileSize}px; height: #{@tileSize}px;"

    setTileNum: (num) ->
        @tileNum = Math.max 1, Math.min Math.floor(@tilesWidth()/MIN_TILE_SIZE), num
        # log "setTileNum #{@tileNum} #{@tilesWidth()} #{num}"
        tileSize = parseInt (@tilesWidth()-8)/@tileNum-12
        prefs.set "tileNum:#{@playlist ? @tilesDir}", @tileNum
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
        prefs.del "expanded:#{@dir}"
            
    expandAllTiles: -> 
        tiles = @getTiles()
        tile.expand() for tile in tiles
        prefs.set "expanded:#{@dir}", true

    #  0000000   0000000   000   000  00000000  00000000   
    # 000       000   000  000   000  000       000   000  
    # 000       000   000   000 000   0000000   0000000    
    # 000       000   000     000     000       000   000  
    #  0000000   0000000       0      00000000  000   000  
    
    pasteCover: ->
        tile = @focusTile
        if tile?.isDir()
            electron = require 'electron'
            clipboard = electron.clipboard
            image = clipboard.readImage()
            data = image.toJPEG 95
            if data.length
                mkpath tile.krixDir(), (err) =>
                    if err?
                        log "[ERROR] can't create .krix folder for", tile.file
                    else
                        coverFile = path.join(tile.krixDir(), 'cover.jpg')
                        fs.writeFile coverFile, data, (err) =>
                            if !err?
                                delete imgs.cache[coverFile]
                                tile.setCover coverFile

    # 000   000  00000000  000   000
    # 000  000   000        000 000 
    # 0000000    0000000     00000  
    # 000  000   000          000   
    # 000   000  00000000     000   
    
    modKeyComboEventDown: (mod, key, combo, event) ->
        
        switch combo
            when 'esc'                   then @goUp()
            when 'command+v'             then @pasteCover()
            when 'command+n'             then @createPlaylist()
            when 'command+down'          then @expandAllTiles()
            when 'command+up'            then @collapseAllTiles()
            when 'backspace'             then @delPlaylistItem()
            when 'home'                  then @getFirstTile().setFocus()
            when 'end'                   then @getLastTile().setFocus()
            when '-'                     then @setTileNum @tileNum + 1
            when '='                     then @setTileNum @tileNum - 1
            when 'command+enter'         then @activeTile?.play()
            when 'command+f'             then @activeTile?.showInFinder()
            when 'space'                 then @activeTile.showContextMenu()
            when 'command+e'             then @focusTile?.editTitle()
            when 'command+a'             then @focusTile?.add()
            when 'enter'                 then @focusTile?.enter()
            when 'command+left'          then @focusTile?.collapse()
            when 'command+right'         then @focusTile?.expand()
            when 'command+backspace'     then @activeTile?.delete()
            when 'command+alt+backspace' then @focusTile?.delete(trashDir:true)
            when 'left', 'right', 'up', 'down', 'page up', 'page down'  
                @focusTile?.focusNeighbor key
            when 'command+u' 
                tags.pruneCache()
                imgs.pruneCache()
                @loadDir @dir
        
module.exports = Brws
