
# 000000000  000  000      00000000
#    000     000  000      000     
#    000     000  000      0000000 
#    000     000  000      000     
#    000     000  0000000  00000000
{
resolve,
last
}     = require './tools/tools'
log   = require './tools/log'
post  = require './post'
tags  = require './tags'
imgs  = require './imgs'
walk  = require './walk'
prefs = require './prefs'
path  = require 'path'
fs    = require 'fs'

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
        img.style.display = 'inline-block'
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
            img.style.backgroundColor = "rgba(0,0,100,0.5)"
            sqr.classList.add "tileSqrFile"
        else
            tit.innerHTML = path.basename @file
            tit.classList.add 'tileName'
            img.style.backgroundColor = "rgba(0,0,0,0.5)"
            img.classList.add "tileImgDir"
            sqr.classList.add "tileSqrDir"
            @pad.classList.add "tilePadDir"
             
        @pad.appendChild img
        elem.appendChild @div

        if @isFile() and path.extname(@file).toLowerCase() not in [".wav", ".aif"]
            tags.enqueue @ 
        else
            imgs.enqueue @
            
        @div.addEventListener "click", @onClick
        @div.addEventListener "dblclick", @onDblClick
        @div.addEventListener "mouseenter", @onEnter

    del: ->
        if @div?
            @div.removeEventListener "click", @onClick
            @div.removeEventListener "dblclick", @onDblClick
        @unFocus() if @hasFocus()
        @div?.remove()
        
    #    0000000   0000000   000   000  00000000  00000000 
    #   000       000   000  000   000  000       000   000
    #   000       000   000   000 000   0000000   0000000  
    #   000       000   000     000     000       000   000
    #    0000000   0000000       0      00000000  000   000
        
    setCover: (coverFile) ->
        @pad.firstChild.style.backgroundImage = "url('file://#{encodeURI(coverFile)}')"
        @pad.firstChild.style.backgroundSize = "100% 100%"
        @pad.firstChild.firstChild.classList.add 'tileSqrCover' if not @opt?.isUp

    setText: (top, sub) -> 
        artist = @pad.firstChild.firstChild.firstChild
        title = artist.nextSibling
        if sub
            artist.innerHTML = top
            title.innerHTML = sub
        else
            title.innerHTML = top
        
    setTag: (@tag) =>
        sqr = @pad.firstChild.firstChild
        @setText @tag.artist, @tag.title
        if @tag.cover?
            coverURI = encodeURI @tag.cover 
            coverURI = coverURI.replace /\#/g, "%23"
            coverURI = coverURI.replace /\&/g, "%26"
            coverURI = coverURI.replace /\'/g, "%27"
            @pad.firstChild.style.backgroundImage = "url('file://#{coverURI}')"
            @pad.firstChild.style.backgroundSize = "100% 100%"
            sqr.classList.add 'tileSqrCover'

    #   00000000  000  000      00000000
    #   000       000  000      000     
    #   000000    000  000      0000000 
    #   000       000  000      000     
    #   000       000  0000000  00000000
   
    absFilePath: -> path.join Tile.musicDir, @file
    isFile: -> @opt?.isFile
    isDir: -> not @isFile()
    krixDir:   -> 
        if @isFile()
            path.join path.dirname(@absFilePath()), '.krix'
        else
            path.join @absFilePath(), ".krix" 
    coverFile: -> path.join @krixDir(), "cover.jpg" 

    delete: -> 
        fs.rename @absFilePath(), path.join(resolve('~/.Trash'), path.basename(@absFilePath())), (err) => 
            if err
                log "[ERROR] trashing file #{@absFilePath()} failed!", err
            else
                if @div.parentNode.classList.contains "song"
                    post.emit 'nextSong' 
                else
                    @focusNeighbor 'right'
                @del()
                
    #   00000000   0000000    0000000  000   000   0000000
    #   000       000   000  000       000   000  000     
    #   000000    000   000  000       000   000  0000000 
    #   000       000   000  000       000   000       000
    #   000        0000000    0000000   0000000   0000000 
            
    hasFocus: -> @pad.classList.contains 'tilePadFocus'
        
    unFocus: => 
        @pad?.classList.remove 'tilePadFocus'
        post.removeListener 'unfocus', @unFocus
    
    setFocus: =>
        if not @hasFocus()
            post.emit 'unfocus'
            @pad.classList.add 'tilePadFocus'
            post.on 'unfocus', @unFocus
            @pad.scrollIntoViewIfNeeded()
            post.emit 'tileFocus', @
       
    focusNeighbor: (nb) ->
        tile = @neighbor nb
        tile?.setFocus()  

    neighbor: (dir) ->
        div = switch dir
            when 'right' then @div.nextSibling
            when 'left'  then @div.previousSibling
            when 'up', 'down' 
                sib = dir == 'up' and 'previousSibling' or 'nextSibling'
                cols = Math.floor @div.parentNode.clientWidth / @div.clientWidth
                div = @div
                while cols > 0 and div[sib]
                    cols -= 1
                    div = div[sib]
                div
            when 'page up', 'page down' 
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

    #   00000000  000   000  00000000    0000000   000   000  0000000  
    #   000        000 000   000   000  000   000  0000  000  000   000
    #   0000000     00000    00000000   000000000  000 0 000  000   000
    #   000        000 000   000        000   000  000  0000  000   000
    #   00000000  000   000  000        000   000  000   000  0000000  

    isExpanded: -> @children?.length

    expand: ->
        return if @isFile() or @isExpanded() or @opt?.isUp
        @doExpand()
            
    collapse: ->
        return if @isFile() or not @isExpanded() or @opt?.isUp
        @doCollapse()

    doExpand: =>
        @div.classList.add 'tileExpanded'
        @children = []
        @walker?.stop()
        @walker = new walk @absFilePath()
        
        @walker.on 'file', (file) =>
            return if path.basename(file).startsWith '.'
            @addChild new Tile file, @div.parentNode, isFile: true
            
        @walker.on 'directory', (dir) =>
            dirname = path.basename(dir)
            return if dirname.startsWith('.') or dirname == 'iTunes'
            @addChild new Tile dir, @div.parentNode, openDir: dir
            
        @walker.on 'done', =>
            if @children.length == 1
                @focusNeighbor 'right'
                @del()
    
    addChild: (child) ->
        @div.parentNode.insertBefore child.div, last(@children)?.div?.nextSibling or @div.nextSibling
        @children.push child
        
    doCollapse: ->
        @div.classList.remove 'tileExpanded'
        while child = @children?.pop()
            child.del()
        
    play: -> post.emit 'playFile', @file
    open: -> 
        if @isDir()
            post.emit 'loadDir', (@opt?.openDir or @file), @file
        
    showInFinder: -> post.emit 'showFile', @file
            
    add:  -> post.emit 'addFile',  @file
       
    #   00     00   0000000   000   000   0000000  00000000
    #   000   000  000   000  000   000  000       000     
    #   000000000  000   000  000   000  0000000   0000000 
    #   000 0 000  000   000  000   000       000  000     
    #   000   000   0000000    0000000   0000000   00000000
       
    onEnter: =>
        return if Tile.scrollLock
        @setFocus()
       
    onDblClick: => 
        if @isDir()
            @open()
        else
            @play()
            
    onClick: => 
        @setFocus()
        if event.shiftKey
            @add()
                
module.exports = Tile
