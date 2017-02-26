
# 000000000  000  000      00000000
#    000     000  000      000     
#    000     000  000      0000000 
#    000     000  000      000     
#    000     000  0000000  00000000
{
resolve
}    = require './tools/tools'
fs   = require 'fs'
path = require 'path'
log  = require './tools/log'
post = require './post'
tags = require './tags'
imgs = require './imgs'

class Tile
    
    @scrollLock = false
    @musicDir = null
    
    constructor: (@file, elem, @opt) ->
            
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
        art.classList.add 'tileArtist'
        sqr.appendChild art
        tit = document.createElement 'div'
        tit.classList.add 'tileTrack'
        sqr.appendChild tit
        img.appendChild sqr
    
        if @isFile()
            art.innerHTML = path.basename @file
            img.style.backgroundColor = "rgba(0,0,100,0.5)"
            sqr.classList.add "tileSqrFile"
        else
            tit.innerHTML = path.basename @file
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
        art = @pad.firstChild.firstChild.firstChild
        tit = art.nextSibling
        if sub
            art.innerHTML = top
            tit.innerHTML = sub
        else
            tit.innerHTML = top
        
    setTag: (@tag) =>
        sqr = @pad.firstChild.firstChild
        @setText @tag.tags.artist, @tag.tags.title
        if @tag.tags.cover?
            @pad.firstChild.style.backgroundImage = "url('file://#{@tag.tags.cover}')"
            @pad.firstChild.style.backgroundSize = "100% 100%"
            sqr.classList.add 'tileSqrCover'
        else if @tag.tags.picture?
            pic = @tag.tags.picture
            data = new Buffer(pic.data).toString('base64')
            @pad.firstChild.style.backgroundImage = "url('data:#{pic.format};base64,#{data}')"
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

    coverDir:  -> @opt?.krixDir or @absFilePath()
    krixDir:   -> 
        if @isFile()
            path.join path.dirname(@absFilePath()), '.krix'
        else
            path.join @coverDir(), ".krix" 
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
        
    play: -> post.emit 'playFile', @file
    open: -> post.emit 'openFile', @file
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
            post.emit 'loadDir', @file
        else
            @play()
            
    onClick: => 
        @setFocus()
        if event.shiftKey
            @add()
                
module.exports = Tile
