# 00000000   000       0000000   000   000  000      000   0000000  000000000
# 000   000  000      000   000   000 000   000      000  000          000   
# 00000000   000      000000000    00000    000      000  0000000      000   
# 000        000      000   000     000     000      000       000     000   
# 000        0000000  000   000     000     0000000  000  0000000      000   
{
queue,
escapePath
$}      = require './tools/tools'
log     = require './tools/log'
elem    = require './tools/elem'
Folder  = require './folder'
Tile    = require './tile'
post    = require './post'
Play    = require './play'
keyinfo = require './tools/keyinfo'
childp  = require 'child_process'
path    = require 'path'
_       = require 'lodash'

class Playlist extends Folder
    
    constructor: (@file, elem, @opt) ->
        super @file, elem, @opt
                
        setImmediate @loadItems
            
        post.on "playlist:#{@file}", @onPlaylistInfo
            
    del: =>
        post.removeListener "playlist:#{@file}", @onPlaylistInfo
        super
            
    loadItems: =>
        
        post.emit 'playlistInfo', @file, cb: (@info) =>
            @onPlaylistInfo @info
            if @opt.openDir == '.' 
                files = _.clone @info.files
                adjust = -> post.emit 'adjustTiles'
                queue files, batch: 500, timeout: 0, batched: adjust, done: adjust, cb: (item) =>
                    return 'stop' if not @div.parentNode
                    tile = new Tile item.file, @div.parentNode, playlist: @file, item: item
                    tile.setFocus() if item.file == @opt.highlight

    isDir:      -> false
    isPlaylist: -> true

    onPlaylistInfo: (@info) =>
        text =  "<span class='playlistCount'><span class='fa fa-music'></span> #{@info.count}</span> "
        text += "<span class='playlistTime'><span class='fa fa-clock-o'></span> #{@info.time}</span>"
        
        name = @info.name
        name = "<span class=\"fa fa-bars fa-1\"></span> #{@info.count}" if not name?.length
        @setText name, null, text

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
        @input = elem 'input', class: 'tileInput'
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

    openInMeta: =>
        args = ['-a', 'Meta.app']
        for file in @info.files
            args.push path.join Tile.musicDir, file.file
        childp.spawn "open", args

    addToPlaylist: (playlist) => 
        for file in @info.files
            post.emit 'addToPlaylist', file.file, playlist
        
module.exports = Playlist
