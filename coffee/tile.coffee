
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

class Tile
    
    constructor: (@file, elem, @opt) ->
            
        @id = @file
        @div = document.createElement 'div'
        @div.tile = @
        @div.id = @id
        @div.className = "krixTile"
        @pad = document.createElement 'div'
        @pad.className = "krixTilePad"
        @div.appendChild @pad
        
        if @opt?.isFile
            img = document.createElement 'div'
            img.classList.add "krixTileImg"
            img.style.display = 'inline-block'
            img.style.overflow = "hidden"

            sqr = document.createElement 'div'
            sqr.classList.add "krixTileImg"
            sqr.classList.add "krixTileSqrFile"
            sqr.innerHTML = path.basename @file
            img.appendChild sqr
        else
            @pad.classList.add "krixTilePadDir"
             
            img = document.createElement 'div'
            img.classList.add "krixTileImg"
            img.style.display = 'inline-block'
            img.style.overflow = "hidden"

            sqr = document.createElement 'div'
            sqr.classList.add "krixTileSqrDir"
            # sqr.classList.add "krixTileImg"
            sqr.innerHTML = path.basename @file
            img.appendChild sqr
             
        @pad.appendChild img
        elem.appendChild @div

        if @isFile() and path.extname(@file).toLowerCase() not in [".wav", ".aif"]
            tags.enqueue @ 
        else
            @loadKrixImage()

        @div.addEventListener "click", @onClick
        @div.addEventListener "dblclick", @onDblClick
   
    absFilePath: -> path.join @opt.musicDir, @file
    isFile: -> @opt?.isFile
    
    loadKrixImage: ->
        krixDir = @opt.krixDir or @absFilePath()
        coverFile = path.join(krixDir, ".krix/cover.jpg")
        fs.stat coverFile, (err, stat) =>
            if err == null and stat.isFile()
                @pad.firstChild.remove()
                img = document.createElement 'img'
                img.setAttribute 'src', "file://" + coverFile
                img.className = "krixTileImg"
                @pad.appendChild img
        
    setTag: (@tag) =>
        # log "tagLoaded @tag.tags:#{@tag.tags}"    # 
        if @tag.tags.picture?
            @pad.firstChild.remove()
            img = document.createElement 'img'
            pic = @tag.tags.picture
            data = new Buffer(pic.data).toString('base64')
            img.setAttribute 'src', "data:#{pic.format};base64,#{data}"
            img.setAttribute 'alt', @file
            img.className = "krixTileImg"
            @pad.appendChild img
        else
            sqr = @pad.firstChild.firstChild
            sqr.innerHTML = @tag.tags.artist + "<br>" + @tag.tags.title
        
    del: ->
        if @div?
            @div.removeEventListener "click", @onClick
            @div.removeEventListener "dblclick", @onDblClick
        @unFocus() if @hasFocus()
    
    hasFocus: -> @pad.classList.contains 'krixTilePadFocus'
    isDir: -> not @tag?
    
    setText: (title, sub) -> @pad.firstChild.firstChild.innerHTML = title + '<br>' + sub
    
    unFocus: => 
        @pad?.classList.remove 'krixTilePadFocus'
        post.removeListener 'unfocus', @unFocus
    
    setFocus: ->
        if not @hasFocus()
            post.emit 'unfocus'
            @pad.classList.add 'krixTilePadFocus'
            post.on 'unfocus', @unFocus
            @pad.scrollIntoViewIfNeeded()
            post.emit 'tileFocus', @
       
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
            
    focusNeighbor: (nb) ->
        tile = @neighbor nb
        tile?.setFocus()  
        
    play: -> post.emit 'playFile', @file
    open: -> post.emit 'openFile', @file
    add:  -> post.emit 'addFile',  @file
    delete: -> 
        log 'delete', @absFilePath()
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
