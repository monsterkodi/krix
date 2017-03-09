# 00000000   000       0000000   000   000  000      000   0000000  000000000
# 000   000  000      000   000   000 000   000      000  000          000   
# 00000000   000      000000000    00000    000      000  0000000      000   
# 000        000      000   000     000     000      000       000     000   
# 000        0000000  000   000     000     0000000  000  0000000      000   
{
queue,
$}      = require './tools/tools'
log     = require './tools/log'
Folder  = require './folder'
Tile    = require './tile'
post    = require './post'
Play    = require './play'
keyinfo = require './tools/keyinfo'

class Playlist extends Folder
    
    constructor: (@file, elem, @opt) ->
        super @file, elem, @opt
        
        if @file == '' # current playlist
            $('.playlistName', @div).innerHTML = "<span class=\"fa fa-bars fa-1\"></span>"
        
        if @opt.openDir == '.' then setImmediate @loadItems
            
        post.on "playlist:#{@file}", @onPlaylistInfo
            
    del: =>
        post.removeListener "playlist:#{@file}", @onPlaylistInfo
        super
            
    loadItems: =>
        
        if @file == '' # current playlist
            Play.instance.mpc 'playlistinfo', (list) =>
                queue list, timeout: 1, cb: (item) =>
                    tile = new Tile item, @div.parentNode, playlist: @file
                    if item == @opt.highlight
                        tile.setFocus()
        else
            post.emit 'playlistInfo', @file, cb: (info) =>
                for item in info.files
                    tile = new Tile item.file, @div.parentNode, playlist: @file, item: item
                    tile.setFocus() if item.file == @opt.highlight
            # Play.instance.mpc 'listplaylist', [@file], (list) =>
                # queue list, timeout: 1, cb: (item) =>
                    # tile = new Tile item, @div.parentNode, playlistItem: @file
                    # if item == @opt.highlight
                        # tile.setFocus()

    isDir:      -> false
    isPlaylist: -> true

    onPlaylistInfo: (@info) =>
        text =  "<span class='playlistCount'><span class='fa fa-music'></span> #{@info.count}</span> "
        text += "<span class='playlistTime'><span class='fa fa-clock-o'></span> #{@info.time}</span>"
        @setText @info.name, null, text

    # 000   000   0000000   00     00  00000000  
    # 0000  000  000   000  000   000  000       
    # 000 0 000  000000000  000000000  0000000   
    # 000  0000  000   000  000 0 000  000       
    # 000   000  000   000  000   000  00000000  
            
    onNameClick: (event) =>
        event.preventDefault()
        event.stopPropagation()
        event.stopImmediatePropagation()
        return if @input
        @editName()
        
    editName: =>
        return if @input? 
        return if not @isPlaylist()
        return if @file == ""
        title = $('.playlistName', @div)
        title.textContent = ""
        @input = document.createElement 'input'
        @input.classList.add 'tileInput'
        @input.value = @file
        title.appendChild @input
        @input.addEventListener 'change',   @onNameChange
        @input.addEventListener 'keydown',  @onNameKeyDown
        @input.addEventListener 'focusout', @onNameFocusOut
        @input.focus()

    onNameKeyDown: (event) =>
        {mod, key, combo} = keyinfo.forEvent event
        switch combo
            when 'enter', 'esc'
                if @input.value == @file or combo != 'enter'
                    @input.value = @file
                    event.preventDefault()
                    event.stopImmediatePropagation()
                    @onNameFocusOut()
        event.stopPropagation()

    onNameFocusOut: (event) =>
        $('.playlistName', @div).textContent = @file
        @removeInput()
        
    removeInput: ->
        return if not @input?
        @input.removeEventListener 'focusout', @onNameFocusOut
        @input.removeEventListener 'change',   @onNameChange
        @input.removeEventListener 'keydown',  @onNameKeyDown
        @input.remove()
        delete @input
        @input = null
        if not document.activeElement? or document.activeElement == document.body
            @setFocus()
    
    onNameChange: (event) =>
        if @input.value.length
            post.emit 'renamePlaylist', @file, @input.value
            @file = @input.value
            @opt.playlist = @file
            $('.playlistName', @div).textContent = @file
        @removeInput()

    addToPlaylist: (playlist) => 
        for file in @info.files
            post.emit 'addToPlaylist', file.file, playlist
        
module.exports = Playlist
