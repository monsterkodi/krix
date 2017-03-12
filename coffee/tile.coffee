
# 000000000  000  000      00000000
#    000     000  000      000     
#    000     000  000      0000000 
#    000     000  000      000     
#    000     000  0000000  00000000
{
childIndex,
encodePath,
escapePath,
resolve,
last,
$}      = require './tools/tools'
log     = require './tools/log'
prefs   = require './tools/prefs'
post    = require './post'
tags    = require './tags'
imgs    = require './imgs'
popup   = require './popup'
childp  = require 'child_process'
path    = require 'path'
fs      = require 'fs'
        
class Tile
    
    @scrollLock = false
    @musicDir = null
    
    constructor: (@file, elem, @opt) ->
        
        @file = @file.substr(Tile.musicDir.length+1) if @file.startsWith Tile.musicDir
            
        @id = @file
        @div = document.createElement 'div'
        @div.tile = @
        @div.id = @id
        @div.className = "tile"
        
        @pad = document.createElement 'div'
        @pad.className = "tilePad"
        @div.appendChild @pad

        img = document.createElement 'div'
        img.classList.add "tileImg"
        img.style.overflow = "hidden"

        sqr = document.createElement 'div'
        art = document.createElement 'div'
        tit = document.createElement 'div'
        sqr.appendChild art
        sqr.appendChild tit
        img.appendChild sqr
        
        sqr.classList.add 'tileSqr'
    
        if @isFile()
            art.classList.add 'tileArtist'
            art.innerHTML = path.basename @file
            sqr.classList.add "tileSqrFile"
        else if @isDir()
            tit.innerHTML = path.basename @file
            tit.classList.add 'tileName'
            img.classList.add "tileImgDir"
            sqr.classList.add "tileSqrDir"
            @pad.classList.add "tilePadDir"
        else if @isPlaylist()
            art.addEventListener 'click', @onNameClick
            art.classList.add 'playlistName'
            art.innerHTML = @file
            inf = document.createElement 'div'
            inf.classList.add 'playlistInfo'
            img.appendChild inf
            
            img.classList.add "tileImgPlaylist"
            sqr.classList.add "tileSqrPlaylist"
            @pad.classList.add "tilePadPlaylist"
             
        @pad.appendChild img
        elem.appendChild @div

        if @opt?.item?
            @setTag @opt.item
            tags.enqueue @ if not @opt.item.cover?
        else if @isFile() and path.extname(@file).toLowerCase() not in [".wav", ".aif"]
            tags.enqueue @
        else if @isPlaylist()
            # post.emit "playlistInfo", @file
        else
            imgs.enqueue @
            
    del: =>
        @unFocus() if @hasFocus()
        @div?.remove()
        
    #  0000000   0000000   000   000  00000000  00000000 
    # 000       000   000  000   000  000       000   000
    # 000       000   000   000 000   0000000   0000000  
    # 000       000   000     000     000       000   000
    #  0000000   0000000       0      00000000  000   000
        
    setCover: (coverFile) ->
        @pad.firstChild.style.backgroundImage = "url(\"file://#{encodePath(coverFile)}\")"
        @pad.firstChild.style.backgroundSize = "100% 100%"
        @pad.firstChild.firstChild.classList.add 'tileSqrCover' if not @isUp()
        @opt.item.cover = coverFile if @opt?.item?

    setText: (top, sub, info) -> 
        artist = @pad.firstChild.firstChild.firstChild
        title = artist.nextSibling
        artist.innerHTML = top
        if sub?
            title.innerHTML = sub
        if info?
            inf = @pad.firstChild.lastChild
            inf.innerHTML = info
        
    setTag: (@tag) =>
        @setText @tag.artist, @tag.title
        if @isCurrentSong()
            post.emit 'titleSong', @tag
        if @tag.cover?
            @setCover @tag.cover

    # 00000000  000  000      00000000
    # 000       000  000      000     
    # 000000    000  000      0000000 
    # 000       000  000      000     
    # 000       000  0000000  00000000
   
    isFile:         -> true
    isPlaylist:     -> false
    isDir:          -> false
    isPlaylistItem: -> @opt?.item?
    isUp:           -> @opt?.openDir?
    
    absFilePath:      -> path.join Tile.musicDir, @file
    isParentClipping: -> @div.parentNode?.clientHeight < @div.clientHeight  
    isCurrentSong:    -> @div.parentNode?.classList.contains "song"

    delete: (opt) => 
        return if @isDir() and not opt?.trashDir
        if @isPlaylist()
            @focusNeighbor 'right', 'left'
            post.emit 'delPlaylist', @file, @del
            return
        fs.rename @absFilePath(), path.join(resolve('~/.Trash'), path.basename(@absFilePath())), (err) => 
            if err
                log "[ERROR] trashing file #{@absFilePath()} failed!", err
            else
                post.emit 'trashed', @file

    enter: ->
        if @isFile() then @play()
        else @open()
                
    fileChanged: -> 
        log 'Tile.fileChanged', @file
        if @isFile()
            tags.enqueue @
        else if @isDir()
            imgs.enqueue @
                
    # 00000000   0000000    0000000  000   000   0000000
    # 000       000   000  000       000   000  000     
    # 000000    000   000  000       000   000  0000000 
    # 000       000   000  000       000   000       000
    # 000        0000000    0000000   0000000   0000000 
            
    hasFocus: -> @pad.classList.contains 'tilePadFocus'
        
    unFocus: => 
        @pad?.classList.remove 'tilePadFocus'
        post.removeListener 'unfocus', @unFocus
    
    setFocus: =>
        if not @hasFocus() 
            post.emit 'unfocus'
            @pad.classList.add 'tilePadFocus'
            post.on 'unfocus', @unFocus
            @pad.scrollIntoViewIfNeeded() if not @isParentClipping()
        post.emit 'tileFocus', @
        $("main").focus()
       
    focusNeighbor: (nb, bn) ->
        tile = @neighbor nb
        if tile == @ and bn
            tile = @neighbor bn
        tile?.setFocus()  

    neighbor: (dir) ->
        div = switch dir
            when 'right' then @div.nextSibling
            when 'left'  then @div.previousSibling
            when 'up', 'down'
                if @div.parentNode?
                    sib = dir == 'up' and 'previousSibling' or 'nextSibling'
                    cols = Math.floor @div.parentNode.clientWidth / @div.clientWidth
                    div = @div
                    while (cols > 0) and div[sib]
                        cols -= 1
                        div = div[sib]
                    div
            when 'page up', 'page down' 
                if @div.parentNode?
                    sib = dir == 'page up' and 'previousSibling' or 'nextSibling'
                    cols = Math.floor @div.parentNode.clientWidth / @div.clientWidth
                    rows = Math.floor @div.parentNode.clientHeight / @div.clientHeight
                    num = rows * cols
                    div = @div
                    while num > 0 and div[sib]
                        num -= 1
                        div = div[sib]
                    div
        div?.tile or @

    play: => 
        if @isPlaylist() then post.emit 'playPlaylist', @file
        else                  post.emit 'playFile',     @file
        
    open: =>
        if @opt?.openDir      then post.emit 'loadDir',  @opt.openDir, @file
        else if @isPlaylist() then post.emit 'playlist', @file
        else if @isDir()      then post.emit 'loadDir',  @file, @file
        
    showInFinder: => 
        if @isPlaylist()
            post.emit 'showFile', resolve "~/.mpd/playlists/#{escapePath @opt.playlist}.m3u"
        else
            post.emit 'showFile', @file

    openInMeta: =>
        childp.spawn "open", ['-a', "Meta.app", escapePath @absFilePath()]
                   
    # 00     00   0000000   000   000   0000000  00000000
    # 000   000  000   000  000   000  000       000     
    # 000000000  000   000  000   000  0000000   0000000 
    # 000 0 000  000   000  000   000       000  000     
    # 000   000   0000000    0000000   0000000   00000000
       
    onHover: =>
        return if Tile.scrollLock
        @setFocus()
       
    onDblClick: => 
        if @isFile() then @play()
        else @open()
            
    onClick: => 
        @setFocus()
        if event.shiftKey
            @add()
    
    #  0000000   0000000   000   000  000000000  00000000  000   000  000000000   
    # 000       000   000  0000  000     000     000        000 000      000      
    # 000       000   000  000 0 000     000     0000000     00000       000      
    # 000       000   000  000  0000     000     000        000 000      000      
    #  0000000   0000000   000   000     000     00000000  000   000     000     
    
    onContextMenu: (event) => @showContextMenu x:event.clientX, y:event.clientY
              
    showContextMenu: (opt={}) =>
        
        opt.x ?= @div.getBoundingClientRect().left
        opt.y ?= @div.getBoundingClientRect().top
        opt.items = [ # ⇧⌥⌘⏎
            text:  'Add to Queue'
            combo: 'Q' 
            cb:    @addToCurrent
        ,
            text:  'Add to Playlist ...'
            combo: 'A' 
            cb:    => @showPlaylistMenu opt
        ,
            text:  'Play'
            combo: '⌘⏎' 
            cb:    @play
        ,
            text:  'Show in Finder'
            combo: '⌘F'
            cb:    @showInFinder
        ,
            text:  'Open in Meta'
            combo: '%M'
            cb:    @openInMeta
        ,
            text:  'New Playlist'
            combo: '⌘N'
            hide:  @isUp() or path.dirname(@file) != '.'
            cb:    -> post.emit 'newPlaylist'
        ,
            text:  'Edit Playlist Name'
            combo: 'E'
            hide:  not @isPlaylist()
            cb:    @editName
        , 
            text:  'Remove from Playlist'
            combo: '⌫'
            hide:  not @isPlaylistItem()
            cb:    @delFromPlaylist
        ,
            text:  @isPlaylist() and 'Delete Playlist' or 'Move to Trash'
            combo: @isDir() and '⌥⌘⌫' or '⌘⌫'
            hide:  @isDir() and path.dirname(@file) == '.'
            cb:    @delete
        ]
        popup.menu opt

    # 00000000   000       0000000   000   000  000      000   0000000  000000000  
    # 000   000  000      000   000   000 000   000      000  000          000     
    # 00000000   000      000000000    00000    000      000  0000000      000     
    # 000        000      000   000     000     000      000       000     000     
    # 000        0000000  000   000     000     0000000  000  0000000      000     
    
    showPlaylistMenu: (opt={}) =>
        
        opt.x ?= @div.getBoundingClientRect().left
        opt.y ?= @div.getBoundingClientRect().top
        opt.items = []
        
        post.emit 'mpc', 'listplaylists', (playlists) =>
            
            for list in playlists
                opt.items.push text: list, cb: @addToPlaylist
        
            popup.menu opt

    addToCurrent: (opt) => 
        post.emit 'addToCurrent', @file
        @focusNeighbor opt.focusNeighbor if opt?.focusNeighbor?

    addToPlaylist: (playlist) => post.emit 'addToPlaylist', @file, playlist

    delFromPlaylist: =>
        return if childIndex(@div) < 2
        post.emit 'mpc', 'playlistdelete', [@opt.playlist, childIndex(@div) - 1]
        @focusNeighbor 'right', 'left'
        @del()
                
module.exports = Tile
