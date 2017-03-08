# 00000000   000       0000000   000   000  000      000   0000000  000000000
# 000   000  000      000   000   000 000   000      000  000          000   
# 00000000   000      000000000    00000    000      000  0000000      000   
# 000        000      000   000     000     000      000       000     000   
# 000        0000000  000   000     000     0000000  000  0000000      000   
{
$}     = require './tools/tools'
Folder = require './folder'

class Playlist extends Folder
    
    constructor: (@file, elem, @opt) ->
        super @file, elem, @opt

    isDir:      -> false
    isPlaylist: -> true

    onPlaylistInfo: (info) =>
        text =  "<span class='playlistCount'><span class='fa fa-music'></span> #{info.count}</span> "
        text += "<span class='playlistTime'><span class='fa fa-clock-o'></span> #{info.time}</span>"
        @setText info.name, null, text

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
        
    editTitle: =>
        return if @input? 
        return if not @isPlaylist()
        return if @file == ""
        title = $('.playlistName', @div)
        title.textContent = ""
        @input = document.createElement 'input'
        @input.classList.add 'tileInput'
        @input.value = @file
        title.appendChild @input
        @input.addEventListener 'change',   @onTitleChange
        @input.addEventListener 'keydown',  @onTitleKeyDown
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
        $('.playlistName', @div).textContent = @file
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
            @opt.playlist = @file
            $('.playlistName', @div).textContent = @file
        @removeInput()
        
module.exports = Playlist
