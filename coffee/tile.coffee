
# 000000000  000  000      00000000
#    000     000  000      000     
#    000     000  000      0000000 
#    000     000  000      000     
#    000     000  0000000  00000000
{
encodePath,
escapePath,
resolve,
last,
$}      = require './tools/tools'
keyinfo = require './tools/keyinfo'
log     = require './tools/log'
post    = require './post'
tags    = require './tags'
imgs    = require './imgs'
walk    = require './walk'
prefs   = require './prefs'
popup   = require './popup'
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
            tit.classList.add 'tileTrack'
            sqr.classList.add "tileSqrFile"
        else if @isDir()
            tit.innerHTML = path.basename @file
            tit.classList.add 'tileName'
            img.classList.add "tileImgDir"
            sqr.classList.add "tileSqrDir"
            @pad.classList.add "tilePadDir"
        else if @isPlaylist()
            tit.innerHTML = @file
            tit.classList.add 'tileName'
            tit.addEventListener 'click', @onTitleClick
            img.classList.add "tileImgPlaylist"
            sqr.classList.add "tileSqrPlaylist"
            @pad.classList.add "tilePadPlaylist"
             
        @pad.appendChild img
        elem.appendChild @div

        if @isFile() and path.extname(@file).toLowerCase() not in [".wav", ".aif"]
            tags.enqueue @ 
        else
            imgs.enqueue @
            
        @div.addEventListener "click",       @onClick
        @div.addEventListener "dblclick",    @onDblClick
        @div.addEventListener "mouseenter",  @onHover
        @div.addEventListener "contextmenu", @onContextMenu

    del: =>
        if @div?
            @div.removeEventListener "click",       @onClick
            @div.removeEventListener "dblclick",    @onDblClick
            @div.removeEventListener "mouseenter",  @onHover
            @div.removeEventListener "contextmenu", @onContextMenu
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

    setText: (top, sub) -> 
        artist = @pad.firstChild.firstChild.firstChild
        title = artist.nextSibling
        if sub
            artist.innerHTML = top
            title.innerHTML = sub
        else
            title.innerHTML = top
        
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
   
    isFile:     -> @opt?.isFile
    isPlaylist: -> @opt?.playlist?
    isDir:      -> not @isFile() and not @isPlaylist()
    isUp:       -> @opt?.isUp
    
    absFilePath:      -> path.join Tile.musicDir, @file
    isParentClipping: -> @div.parentNode.clientHeight < @div.clientHeight  
    isCurrentSong:    -> @div.parentNode.classList.contains "song"
    krixDir: -> 
        if @isFile()
            path.join path.dirname(@absFilePath()), '.krix'
        else
            path.join @absFilePath(), ".krix" 
    coverFile: -> path.join @krixDir(), "cover.jpg" 

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
                if @isCurrentSong()
                    post.emit 'nextSong' 
                else
                    @focusNeighbor 'right', 'left'
                    @del()

    enter: ->
        if @isFile() then @play()
        else @open()
                
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

    # 00000000  000   000  00000000    0000000   000   000  0000000  
    # 000        000 000   000   000  000   000  0000  000  000   000
    # 0000000     00000    00000000   000000000  000 0 000  000   000
    # 000        000 000   000        000   000  000  0000  000   000
    # 00000000  000   000  000        000   000  000   000  0000000  

    isExpanded: -> @children?.length

    expand: ->
        return if not @isDir() or @isExpanded() or @isUp()
        @doExpand()
            
    collapse: ->
        return if not @isDir() or not @isExpanded() or @isUp()
        @doCollapse()

    doExpand: =>
        @div.classList.add 'tileExpanded'
        @children = []
        @walker?.stop()
        @walker = new walk @absFilePath()
        
        @walker.on 'file', (file) =>
            return if not @div.parentNode?
            return if path.basename(file).startsWith '.'
            @addChild new Tile file, @div.parentNode, isFile: true
            
        @walker.on 'directory', (dir) =>
            return if not @div.parentNode?
            dirname = path.basename(dir)
            return if dirname.startsWith('.') or dirname == 'iTunes'
            @addChild new Tile dir, @div.parentNode, openDir: dir
            
        @walker.on 'done', =>
            # if @children.length == 1
            @focusNeighbor 'right' if @hasFocus()
            @del()
    
    addChild: (child) ->
        @div.parentNode.insertBefore child.div, last(@children)?.div?.nextSibling or @div.nextSibling
        @children.push child
        
    doCollapse: ->
        @div.classList.remove 'tileExpanded'
        while child = @children?.pop()
            child.del()
        
    play: -> 
        if @isPlaylist() then post.emit 'playPlaylist', @file
        else                  post.emit 'playFile',    @file
        
    open: ->
        if @opt?.openDir      then post.emit 'loadDir',  @opt.openDir, @file
        else if @isPlaylist() then post.emit 'playlist', @file
        else if @isDir()      then post.emit 'loadDir',  @file, @file
        
    showInFinder: => 
        if @isPlaylist()
            post.emit 'showFile', resolve "~/.mpd/playlists/#{escapePath @opt.playlist}.m3u"
        else
            post.emit 'showFile', @file
            
    add: => post.emit 'addFile', @file
       
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
        
    showContextMenu: (opt={}) ->
        opt.x ?= @div.getBoundingClientRect().left
        opt.y ?= @div.getBoundingClientRect().top
        opt.items = [
            text: 'Show in Finder'
            cb:   @showInFinder
        ,
            text: 'Move to Trash'
            cb:   @delete
        ]
        popup.menu opt
    
    # 000000000  000  000000000  000      00000000  
    #    000     000     000     000      000       
    #    000     000     000     000      0000000   
    #    000     000     000     000      000       
    #    000     000     000     0000000  00000000  
            
    onTitleClick: (event) =>
        event.preventDefault()
        event.stopPropagation()
        event.stopImmediatePropagation()
        return if @input
        @editTitle()
        
    editTitle: ->
        return if @input? 
        return if not @isPlaylist()
        return if @file == ""
        title = $('.tileName', @div)
        title.textContent = ""
        @input = document.createElement 'input'
        @input.classList.add 'tileInput'
        @input.value = @file
        title.appendChild @input
        @input.addEventListener 'change', @onTitleChange
        @input.addEventListener 'keydown', @onTitleKeyDown
        @input.addEventListener 'focusout', @onTitleFocusOut
        @input.focus()

    onTitleKeyDown: (event) =>
        {mod, key, combo} = keyinfo.forEvent event
        switch combo
            when 'enter', 'esc'
                if @input.value == @file or combo != 'enter'
                    @input.value = @file
                    event.preventDefault()
                    event.stopPropagation()
                    event.stopImmediatePropagation()
                    @onTitleFocusOut()
        event.stopPropagation()

    onTitleFocusOut: (event) =>
        title = $('.tileName', @div)
        title.textContent = @file
        @removeInput()
        
    removeInput: ->
        return if not @input?
        @input.removeEventListener 'focusout', @onTitleFocusOut
        @input.removeEventListener 'change',   @onTitleChange
        @input.removeEventListener 'keydown',  @onTitleKeyDown
        @input.remove()
        delete @input
        @input = null
        if not document.activeElement? or document.activeElement == document.body
            @setFocus()
    
    onTitleChange: (event) =>
        if @input.value.length
            post.emit 'renamePlaylist', @file, @input.value
            @file = @input.value
            title = $('.tileName', @div)
            title.textContent = @file
        @removeInput()
                
module.exports = Tile
