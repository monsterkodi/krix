#   0000000    00000000   000   000   0000000
#   000   000  000   000  000 0 000  000     
#   0000000    0000000    000000000  0000000 
#   000   000  000   000  000   000       000
#   0000000    000   000  00     00  0000000 
{
resolve,
style,
$ }      = require './tools/tools'
fs       = require 'fs'
path     = require 'path'
childp   = require 'child_process'
_        = require 'lodash'
log      = require './tools/log'
elem     = require './tools/elem'
prefs    = require './tools/prefs'
Playlist = require './playlist'
Folder   = require './folder'
Tile     = require './tile'
Play     = require './play'
cache    = require './cache'
tags     = require './tags' 
imgs     = require './imgs'
walk     = require './walk'
post     = require './post'

MIN_TILE_SIZE = 50
MAX_TILE_SIZE = 500

class Brws
    
    constructor: (@view, @musicDir) ->
        
        @tiles = elem class: 'tiles'
        @view.appendChild @tiles

        @dirLoaded = false
        @tilesDir = @musicDir
        Tile.musicDir = @musicDir
        
        @tiles.addEventListener "click",       @onClick
        @tiles.addEventListener "dblclick",    @onDblClick
        @tiles.addEventListener "mouseover",   @onHover
        @tiles.addEventListener "contextmenu", @onContextMenu
        @tiles.addEventListener "scroll",      @onScroll
                
        post.on 'tileFocus',   @onTileFocus
        post.on 'unfocus',     @onUnfocus
        post.on 'playlist',    @showPlaylist
        post.on 'newPlaylist', @newPlaylist
        post.on 'loadDir',     @loadDir
        post.on 'showFile',    @showFile
        post.on 'home',        @goHome
        post.on 'up',          @goUp
        post.on 'connected',   @connected
        post.on 'trashed',     @onTrashed
        post.on 'adjustTiles', @adjustTiles
        post.on 'playlistLoaded', @onPlaylistLoaded
        
    del: -> @tiles.remove()
        
    # 000       0000000    0000000   0000000  
    # 000      000   000  000   000  000   000
    # 000      000   000  000000000  000   000
    # 000      000   000  000   000  000   000
    # 0000000   0000000   000   000  0000000  

    goUp: =>
        if @playlist?
            @loadDir '', @playlist
        else if @dir in ['', '.']
            if @focusTile?
                post.emit 'focusSong'
            else
                @getFirstTile()?.setFocus()
        else
            @loadDir path.dirname(@dir), @dir
        
    goHome: => @loadDir ''

    beforeClear: ->
        key = @playlist ? @dir
        prefs.set "tileHint:#{key}", @tileNum
        cache.del "#{key}:page"
        
    clear: ->
        @walker?.stop()
        tags.clearQueue()
        imgs.clearQueue()
        post.emit 'unfocus'
        if @inMusicDir() 
            tile.del() for tile in @getTiles()
        else
            @tiles.firstChild?.tile.del()
        @tiles.innerHTML = ''
        @focusTile = null
        
        key = @playlist ? @dir 
        num = prefs.get "tileNum:#{key}", prefs.get "tileHint:#{key}"
        log "clear #{num}"
        if num then @setTileNum num, false

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

    # 000       0000000    0000000   0000000    0000000    000  00000000   
    # 000      000   000  000   000  000   000  000   000  000  000   000  
    # 000      000   000  000000000  000   000  000   000  000  0000000    
    # 000      000   000  000   000  000   000  000   000  000  000   000  
    # 0000000   0000000   000   000  0000000    0000000    000  000   000  
             
    loadDir: (dir, @highlight) =>
        @beforeClear()
        @dir = dir
        cache.watch @dir
        delete @playlist
        delete @tileSize
        @dirLoaded = false
        @clear()
        @tilesDir = path.join @musicDir, @dir
        
        @expanded = prefs.get "expanded:#{@dir}", false
                            
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
            tile.expand() if @expanded
            if musicPath == @highlight
                tile.setFocus()
                
        @walker.on 'end', =>                
            @dirLoaded = true
            if @inMusicDir() 
                if Play.isConnected()
                    @loadPlaylists()
            @adjustTiles()            

    inMusicDir: => @tilesDir == @musicDir

    # 00000000   000       0000000   000   000  000      000   0000000  000000000
    # 000   000  000      000   000   000 000   000      000  000          000   
    # 00000000   000      000000000    00000    000      000  0000000      000   
    # 000        000      000   000     000     000      000       000     000   
    # 000        0000000  000   000     000     0000000  000  0000000      000   
        
    showPlaylist: (playlist, @highlight) =>
        @beforeClear()
        @playlist = playlist
        cache.unwatch()
        delete @dir        
        @clear()
                
        tile = new Playlist @playlist, @tiles, playlist: @playlist, openDir: '.', highlight: @highlight
        tile.setFocus()

    onPlaylistLoaded: => @adjustTiles()
        
    connected: () =>
        post.removeListener 'connected', @connected
        @loadPlaylists() if @dirLoaded
        
    loadPlaylists: ->
        Play.mpc 'listplaylists', (playlists) =>
            for list in playlists
                tile = new Playlist list, @tiles, playlist: list
                if @highlight == list
                    tile.setFocus()
            @adjustTiles()

    newPlaylist: =>
        return if not @inMusicDir()
        Play.newPlaylist 'new playlist', (playlist) =>
            tile = new Playlist playlist, @tiles, playlist: playlist
            tile.setFocus()

    delPlaylistItem: ->
        return if not @playlist?
        return if not @focusTile?
        @focusTile.delFromPlaylist()
                    
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
    getFirstTile:  -> @tiles.firstChild?.tile
    getLastTile:   -> @tiles.lastChild?.tile
    getTiles:      -> (t.tile for t in @tiles.childNodes)
    tilesWidth:    -> @tiles.clientWidth
    tilesHeight:   -> @tiles.clientHeight

    onTrashed: (file) =>
        if file == @focusTile?.file
            @focusTile.focusNeighbor 'right', 'left'
        document.querySelector(".tiles .tile[file='#{file.hash()}']")?.tile?.del()

    collapseFocusTile: =>
        return if not @focusTile?
        return if not @focusTile.expanded?
        collapse = @focusTile.expanded
            
        tile = new Folder @focusTile.expanded, @tiles
        @tiles.insertBefore tile.div, @focusTile.div
        tile.setFocus()
        
        for tile in @getTiles()
            if tile.expanded == collapse
                tile.del()

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

    setTileNum: (num, save=true) ->
        @tileNum = Math.max 1, Math.min Math.floor(@tilesWidth()/MIN_TILE_SIZE), num
        if save then prefs.set "tileNum:#{@playlist ? @dir}", @tileNum
        @setTileSize parseInt (@tilesWidth()-12)/@tileNum-12
        
    #  0000000   0000000          000  000   000   0000000  000000000  
    # 000   000  000   000        000  000   000  000          000     
    # 000000000  000   000        000  000   000  0000000      000     
    # 000   000  000   000  000   000  000   000       000     000     
    # 000   000  0000000     0000000    0000000   0000000      000     
    
    adjustTiles: =>
        num = prefs.get "tileNum:#{@playlist ? @dir}"
        if num
            @setTileNum num, false
        else if not @tileSize? or @tileSize > MIN_TILE_SIZE
            @adjustTileNum() 

    resized: => @adjustTiles()
        
    adjustTileNum: ->
        
        x = @tilesWidth()-12
        y = @tilesHeight()-12
        n = @tiles.childNodes.length

        px = Math.ceil Math.sqrt n*x/y
        if Math.floor(px*y/x)*px < n
            sx = y / Math.ceil px*y/x 
        else
            sx = x / px
        
        py = Math.ceil Math.sqrt n*y/x
        if Math.floor(py*x/y)*py < n
            sy = x / Math.ceil x*py/y
        else
            sy = y / py

        sx  = Math.max sx, sy
        num = x/sx
        if num % 1 > 0.25 then num = Math.ceil num
        else num = Math.floor num

        @setTileNum num
        key = @playlist ? @dir
        prefs.del "tileNum:#{key}"
        prefs.set "tileHint:#{key}", num
                
    onScroll: =>
        Tile.scrollLock = true
        unlock = () -> 
            Tile.scrollLock = false
        clearTimeout @scrollTimer
        @scrollTimer = setTimeout unlock, 100

    collapseAllTiles: -> 
        return if not @dir?
        prefs.del "expanded:#{@dir}"
        @loadDir @dir, @focusTile?.file
            
    expandAllTiles: -> 
        prefs.set "expanded:#{@dir}", true
        tiles = @getTiles()
        tile.expand?() for tile in tiles
        setTimeout @adjustTiles, 300
    
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
        electron = require 'electron'
        clipboard = electron.clipboard
        jpg = clipboard.readImage()?.toJPEG 95
        if tile?.isDir()
            imgs.setDirTileImageData tile, jpg
        else if tile?.isFile()
            tags.saveJpgData tile, jpg

    copyCover: ->
        tile = @activeTile
        if cache.get "#{tile.file}:cover"
            electron = require 'electron'
            nativeImage = electron.nativeImage
            clipboard = electron.clipboard
            image = nativeImage.createFromPath imgs.coverForHash cache.get "#{tile.file}:cover"
            clipboard.writeImage image

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
            when 'command+c'             then @copyCover()
            when 'command+n'             then @newPlaylist()
            when 'command+down'          then @expandAllTiles()
            when 'command+up'            then @collapseAllTiles()
            when 'backspace', 'delete'   then @delPlaylistItem()
            when 'home'                  then @getFirstTile().setFocus()
            when 'end'                   then @getLastTile().setFocus()
            when '0', 'o'                then @adjustTileNum()
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
            when 'command+left'          then @collapseFocusTile()
            when 'command+backspace'     then @activeTile?.delete()
            when 'command+alt+backspace' then if not @inMusicDir() then @focusTile?.delete(trashDir:true)
            when '.'                     then @focusTile?.focusNeighbor 'page down'
            when ','                     then @focusTile?.focusNeighbor 'page up'
            when 'left', 'right', 'up', 'down', 'page up', 'page down'  
                @focusTile?.focusNeighbor key
            when 'command+u' 
                cache.prune @dir
                @loadDir @dir
        
module.exports = Brws
