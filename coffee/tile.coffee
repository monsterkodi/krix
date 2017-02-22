
# 000000000  000  000      00000000
#    000     000  000      000     
#    000     000  000      0000000 
#    000     000  000      000     
#    000     000  0000000  00000000

log  = require '/Users/kodi/s/ko/js/tools/log'
post = require './post'
path = require 'path'

class Tile
    
    constructor: (@file, elem, @tag) ->
            
        @id = @file
        @div = document.createElement 'div'
        @div.tile = @
        @div.id = @id
        @div.className = "krixTile"
        @pad = document.createElement 'div'
        @pad.className = "krixTilePad"
        @div.appendChild @pad
        if @tag?.tags.picture?
            img = document.createElement 'img'
            pic = @tag.tags.picture
            data = new Buffer(pic.data).toString('base64')
            img.setAttribute 'src', "data:#{pic.format};base64,#{data}"
            img.setAttribute 'alt', @file
            img.className = "krixTileImg"
        else if @tag?
            img = document.createElement 'div'
            img.style.display = 'inline-block'
            img.style.overflow = "hidden"
            img.className = "krixTileImg"

            sqr = document.createElement 'div'
            sqr.style.padding = "5px"
            sqr.style.backgroundColor = "#222222"
            sqr.style.overflow = "hidden"
            sqr.innerHTML = @tag.tags.artist + "<br>" + @tag.tags.title
            sqr.className = "krixTileImg"
            img.appendChild sqr
        else
            img = document.createElement 'div'
            img.style.display = 'inline-block'
            img.style.overflow = "hidden"
            img.className = "krixTileImg"

            sqr = document.createElement 'div'
            sqr.style.padding = "5px"
            sqr.style.backgroundColor = "#4444aa"
            sqr.style.overflow = "hidden"
            sqr.innerHTML = path.basename @file
            sqr.className = "krixTileImg"
            img.appendChild sqr
            
        @pad.appendChild img
        elem.appendChild @div

        @div.addEventListener "click", @onClick
        @div.addEventListener "dblclick", @onDblClick
    
    del: ->
        if @div?
            @div.removeEventListener "click", @onClick
            @div.removeEventListener "dblclick", @onDblClick
        @unFocus() if @hasFocus()
    
    hasFocus: () -> @pad.classList.contains 'krixTilePadFocus'
    
    unFocus: () => 
        @pad?.classList.remove 'krixTilePadFocus'
        post.removeListener 'unfocus', @unFocus
    
    setFocus: () ->
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
