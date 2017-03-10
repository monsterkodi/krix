#   0000000    00000000   000   000   0000000
#   000   000  000   000  000 0 000  000     
#   0000000    0000000    000000000  0000000 
#   000   000  000   000  000   000       000
#   0000000    000   000  00     00  0000000 
{
resolve,
style,
queue,
$ }      = require './tools/tools'
fs       = require 'fs'
path     = require 'path'
mkpath   = require 'mkpath'
childp   = require 'child_process'
_        = require 'lodash'
log      = require './tools/log'
Playlist = require './playlist'
Folder   = require './folder'
Tile     = require './tile'
Play     = require './play'
prefs    = require './prefs'
cache    = require './cache'
tags     = require './tags' 
imgs     = require './imgs'
walk     = require './walk'
post     = require './post'

MIN_TILE_SIZE = 50
MAX_TILE_SIZE = 500

class Brws
    
    constructor: (@view, @musicDir) ->
        
        @tiles = document.createElement 'div'
        @tiles.classList.add 'tiles'
        @view.appendChild @tiles
                
        @tilesDir = @musicDir
        Tile.musicDir = @musicDir
        
        @setTileNum prefs.get "tileNum:#{@musicDir}", 8
        
        @tiles.addEventListener "click",       @onClick
        @tiles.addEventListener "dblclick",    @onDblClick
        @tiles.addEventListener "mouseover",   @onHover
        @tiles.addEventListener "contextmenu", @onContextMenu
        @tiles.addEventListener "scroll",      @onScroll
                
        post.on 'tileFocus',   @onTileFocus
        post.on 'unfocus',     @onUnfocus
        post.on 'playlist',    @showPlaylist
        post.on 'newPlaylist', @newPlaylist
        post.on 'song',        @showSong
        post.on 'loadDir',     @loadDir
        post.on 'showFile',    @showFile
        post.on 'home',        @goHome
        post.on 'up',          @goUp
        post.on 'connected',   @connected
        
    del: -> @tiles.remove()
        
    # 000       0000000    0000000   0000000  
    # 000      000   000  000   000  000   000
    # 000      000   000  000000000  000   000
    # 000      000   000  000   000  000   000
    # 0000000   0000000   000   000  0000000  

    goUp: =>
        if @playlist?
            @loadDir '.', @playlist
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
        @tiles.firstChild?.tile.del()
        @tiles.innerHTML = ''
        @focusTile = null

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
        cache.unwatch()
        delete @dir        
        @clear()
        
        num = prefs.get "tileNum:#{@playlist}", -1
        if num != -1 and @tileNum != num
            @setTileNum num
        
        tile = new Playlist @playlist, @tiles, playlist: @playlist, openDir: '.', highlight: @highlight
        tile.setFocus()
        
    connected: () =>
        post.removeListener 'connected', @loadPlaylists
        @loadPlaylists()
        
    loadPlaylists: ->
        Play.mpc 'listplaylists', (playlists) =>
            for list in playlists
                tile = new Playlist list, @tiles, playlist: list
                if @highlight == list
                    tile.setFocus()

    newPlaylist: (name='new playlist') =>
        return if @dir != ''
        Play.newPlaylist name, (playlist) =>
            tile = new Tile playlist, @tiles, playlist: playlist
            tile.setFocus()

    delPlaylistItem: ->
        return if not @playlist?
        return if not @focusTile?
        @focusTile.delFromPlaylist()
        
    # 000       0000000    0000000   0000000    0000000    000  00000000   
    # 000      000   000  000   000  000   000  000   000  000  000   000  
    # 000      000   000  000000000  000   000  000   000  000  0000000    
    # 000      000   000  000   000  000   000  000   000  000  000   000  
    # 0000000   0000000   000   000  0000000    0000000    000  000   000  
    
    loadDir: (@dir, @highlight) =>
        cache.unwatch()
        cache.watch @dir
        delete @playlist
        @clear()
        @tilesDir = path.join @musicDir, @dir
        
        num = prefs.get "tileNum:#{@tilesDir}", -1
        if num != -1 and @tileNum != num
            @setTileNum num
        
        if @dir.length and @dir != '.'
            tile = new Folder @dir, @tiles, openDir: path.dirname @dir
            tile.setText path.dirname(@dir), path.basename(@dir)
            tile.setFocus()

        @walker = new walk @tilesDir
        
        @walker.on 'file', (file) =>
            return if path.basename(file).startsWith '.'
            musicPath = file.substr @musicDir.length+1
            tile = new Tile musicPath, @tiles
            if musicPath == @highlight
                tile.setFocus()
            
        @walker.on 'directory', (dir) =>
            dirname = path.basename(dir)
            return if dirname.startsWith('.') or dirname == 'iTunes'
            musicPath = dir.substr @musicDir.length+1
            tile = new Folder musicPath, @tiles
            tile.setFocus() if not @focusTile
            if musicPath == @highlight
                tile.setFocus()
                
        @walker.on 'done', =>
            if prefs.get "expanded:#{@dir}", false
                @expandAllTiles()
                
            if @inMusicDir() then @loadPlaylists()

    inMusicDir: => @tilesDir == @musicDir
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

    #  0000000  000  0000000  00000000  
    # 000       000     000   000       
    # 0000000   000    000    0000000   
    #      000  000   000     000       
    # 0000000   000  0000000  00000000  
    
    setTileSize: (size) ->
        @tileSize = Math.floor size
        @tileSize = MIN_TILE_SIZE if @tileSize < MIN_TILE_SIZE
        @tileSize = MAX_TILE_SIZE if @tileSize > MAX_TILE_SIZE
        
        fontSize = Math.max 8, Math.min 18, @tileSize / 10
        style '.tiles .playlistInfo', "font-size: #{fontSize-2}px"
        style '.tiles .tileSqr',      "font-size: #{fontSize}px"
        style '.tiles .tileInput',    "font-size: #{fontSize}px; width: #{@tileSize-12}px;"
        style '.tiles .tileImg',      "width: #{@tileSize}px; height: #{@tileSize}px;"

    setTileNum: (num) ->
        @tileNum = Math.max 1, Math.min Math.floor(@tilesWidth()/MIN_TILE_SIZE), num
        # log "setTileNum #{@tileNum} #{@tilesWidth()} #{num}"
        tileSize = parseInt (@tilesWidth()-8)/@tileNum-12
        prefs.set "tileNum:#{@playlist ? @tilesDir}", @tileNum
        @setTileSize tileSize
    
    resized: => @setTileNum @tileNum
            
    onScroll: =>
        Tile.scrollLock = true
        unlock = () -> 
            Tile.scrollLock = false
        clearTimeout @scrollTimer
        @scrollTimer = setTimeout unlock, 100

    collapseAllTiles: -> 
        prefs.del "expanded:#{@dir}"
        @loadDir @dir, @focusTile?.file
            
    expandAllTiles: -> 
        prefs.set "expanded:#{@dir}", true
        tiles = @getTiles()
        tile.expand?() for tile in tiles
    
    # 00     00   0000000   000   000   0000000  00000000  
    # 000   000  000   000  000   000  000       000       
    # 000000000  000   000  000   000  0000000   0000000   
    # 000 0 000  000   000  000   000       000  000       
    # 000   000   0000000    0000000   0000000   00000000  

    onDblClick: (event) =>
        if event.target.classList.contains 'tiles'
            if not @inMusicDir()
                @loadDir path.dirname @tilesDir.substr @musicDir.length + 1
        else 
            @tileForEvent(event)?.onDblClick event

    onHover: (event) => @tileForEvent(event)?.onHover event
    onClick: => @tileForEvent(event)?.onClick event
    onContextMenu: (event) => @focusTile?.onContextMenu event

    tileForEvent: (event) -> @tileForElem event.target
    tileForElem: (elem) -> 
        if elem.tile? then return elem.tile
        if elem.parentNode? then return @tileForElem elem.parentNode

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
                coverFile = imgs.coverForTile tile
                fs.writeFile coverFile, data, (err) =>
                    if !err?
                        cache.set "#{tile.file}:cover", coverFile
                        tile.setCover coverFile

    # 000   000  00000000  000   000
    # 000  000   000        000 000 
    # 0000000    0000000     00000  
    # 000  000   000          000   
    # 000   000  00000000     000   
    
    modKeyComboEventDown: (mod, key, combo, event) ->
        stop = -> event.preventDefault()
        switch combo
            when 'esc'                   then @goUp()
            when 'command+v'             then @pasteCover()
            when 'command+n'             then @newPlaylist()
            when 'command+down'          then @expandAllTiles()
            when 'command+up'            then @collapseAllTiles()
            when 'backspace', 'delete'   then @delPlaylistItem()
            when 'home'                  then @getFirstTile().setFocus()
            when 'end'                   then @getLastTile().setFocus()
            when '-'                     then @setTileNum @tileNum + 1
            when '='                     then @setTileNum @tileNum - 1
            when 'command+enter'         then @activeTile?.play()
            when 'command+f'             then @activeTile?.showInFinder()
            when 'command+m'             then @activeTile?.openInMeta()
            when 'space'                 then @activeTile.showContextMenu()
            when 'e'                     then @focusTile?.editName?(); stop()
            when 'a'                     then @focusTile?.showPlaylistMenu()
            when 'q'                     then @focusTile?.addToCurrent(focusNeighbor: @focusTile.isFile() and 'right' or null)
            when 'enter'                 then @focusTile?.enter()
            when 'command+right'         then @focusTile?.expand()
            when 'command+backspace'     then @activeTile?.delete()
            when 'command+alt+backspace' then if not @inMusicDir() then @focusTile?.delete(trashDir:true)
            when 'left', 'right', 'up', 'down', 'page up', 'page down'  
                @focusTile?.focusNeighbor key
            when 'command+u' 
                cache.prune()
                @loadDir @dir
        
module.exports = Brws
