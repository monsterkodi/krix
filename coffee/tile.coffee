
# 000000000  000  000      00000000
#    000     000  000      000     
#    000     000  000      0000000 
#    000     000  000      000     
#    000     000  0000000  00000000

fs   = require 'fs'
path = require 'path'
log  = require './tools/log'
post = require './post'
tags = require './tags'
imgs = require './imgs'

class Tile
    
    @scrollLock = false
    
    constructor: (@file, elem, @opt) ->
            
        @id = @file
        @div = document.createElement 'div'
        @div.tile = @
        @div.id = @id
        @div.className = "krixTile"
        @pad = document.createElement 'div'
        @pad.className = "krixTilePad"
        @div.appendChild @pad

        img = document.createElement 'div'
        img.classList.add "krixTileImg"
        img.style.display = 'inline-block'
        img.style.overflow = "hidden"

        sqr = document.createElement 'div'
        img.appendChild sqr
    
        if @isFile()
            img.style.backgroundColor = "rgba(0,0,100,0.5)"
            sqr.classList.add "krixTileSqrFile"
            sqr.innerHTML = path.basename @file
        else
            img.style.backgroundColor = "rgba(0,0,0,0.5)"
            img.classList.add "krixTileImgDir"
            sqr.classList.add "krixTileSqrDir"
            sqr.innerHTML = path.basename @file
            @pad.classList.add "krixTilePadDir"
             
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
        
    #    0000000   0000000   000   000  00000000  00000000 
    #   000       000   000  000   000  000       000   000
    #   000       000   000   000 000   0000000   0000000  
    #   000       000   000     000     000       000   000
    #    0000000   0000000       0      00000000  000   000
        
    setCover: (coverFile) ->
        @pad.firstChild.style.backgroundImage = "url('file://#{encodeURI(coverFile)}')"
        @pad.firstChild.style.backgroundSize = "100% 100%"
        @pad.firstChild.firstChild.classList.add 'krixTileSqrCover' if not @opt?.isUp

    setText: (title, sub) -> @pad.firstChild.firstChild.innerHTML = title + '<br>' + sub
        
    setTag: (@tag) =>
        sqr = @pad.firstChild.firstChild
        sqr.innerHTML = @tag.tags.artist + "<br>" + @tag.tags.title
        if @tag.tags.picture?
            pic = @tag.tags.picture
            data = new Buffer(pic.data).toString('base64')
            @pad.firstChild.style.backgroundImage = "url('data:#{pic.format};base64,#{data}')"
            @pad.firstChild.style.backgroundSize = "100% 100%"
            sqr.classList.add 'krixTileSqrCover'

    #   00000000  000  000      00000000
    #   000       000  000      000     
    #   000000    000  000      0000000 
    #   000       000  000      000     
    #   000       000  0000000  00000000
   
    absFilePath: -> path.join @opt.musicDir, @file
    isFile: -> @opt?.isFile
    isDir: -> not @isFile()

    coverDir:  -> @opt?.krixDir or @absFilePath()
    krixDir:   -> path.join @coverDir(), ".krix" 
    coverFile: -> path.join @krixDir(), "cover.jpg" 

    delete: -> 
        if @isFile()
            fs.unlink @absFilePath(), (err) =>
                if err
                    log "[ERROR] deleting file #{@absFilePath()} failed!", err
                else
                    @focusNeighbor 'right'
                    @del()
                    @div.remove()
        else
            rimraf = require 'rimraf'
            rimraf @absFilePath(), (err) =>
                if err
                    log "[ERROR] deleting directory #{@absFilePath()} failed!", err
                else
                    @focusNeighbor 'right'
                    @del()
                    @div.remove()

    
    #   00000000   0000000    0000000  000   000   0000000
    #   000       000   000  000       000   000  000     
    #   000000    000   000  000       000   000  0000000 
    #   000       000   000  000       000   000       000
    #   000        0000000    0000000   0000000   0000000 
            
    hasFocus: -> @pad.classList.contains 'krixTilePadFocus'
        
    unFocus: => 
        @pad?.classList.remove 'krixTilePadFocus'
        post.removeListener 'unfocus', @unFocus
    
    setFocus: =>
        if not @hasFocus()
            post.emit 'unfocus'
            @pad.classList.add 'krixTilePadFocus'
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
        if not @tag?
            post.emit 'loadDir', @file
        else
            @play()
    onClick: => 
        @setFocus()
        if event.shiftKey
            @add()
                
module.exports = Tile
