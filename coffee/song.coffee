#  0000000   0000000   000   000   0000000 
# 000       000   000  0000  000  000      
# 0000000   000   000  000 0 000  000  0000
#      000  000   000  000  0000  000   000
# 0000000    0000000   000   000   0000000 
{
style
}      = require './tools/tools'
elem   = require './tools/elem'
Tile   = require './tile'
Wave   = require './wave'
post   = require './post'
log    = require './tools/log'
moment = require 'moment'
require 'moment-duration-format'

class Song
    
    constructor: (@view) ->
        
        @elem = elem id: 'song', class: 'song'
        @view.appendChild @elem
        
        @wave = new Wave @elem
    
        @info = elem class: 'songInfo'
        @elem.appendChild @info
        
        @infoElapsed = elem class: 'songElapsed'
        @info.appendChild @infoElapsed

        @infoDuration = elem class: 'songDuration'
        @info.appendChild @infoDuration
        
        tileSize = 160
        style '.song .tileImg', "width: #{tileSize}px; height: #{tileSize}px;"

        @elem.addEventListener "click",       @onClick
        @elem.addEventListener "dblclick",    @onDblClick
        @elem.addEventListener "mouseover",   @onHover
        @elem.addEventListener "contextmenu", @onContextMenu
        
        post.on 'currentSong',  @onCurrentSong
        post.on 'focusSong', => @tile?.setFocus()
        post.on 'seek',      => @tile?.setFocus()
        post.on 'status',       @onStatus
        post.on 'trashed',      @onTrashed

    duration: (s) -> moment.duration(parseInt(s), 'seconds').format('h:mm:ss')
    
    onTrashed: (file) =>
        if file == @tile?.file 
            @focusSong = @tile.hasFocus()
            post.emit 'nextSong' 
    
    onStatus: (status) =>
        if @song?.duration? and status?.elapsed?
            @infoElapsed.innerHTML = "#{@duration status.elapsed}"
            @infoDuration.innerHTML = "#{@duration @song.duration}"
        else
            @infoElapsed.innerHTML = ""
            @infoDuration.innerHTML = ""
        
    onCurrentSong: (@song) =>
        if not @tile or @song.file != @tile.file
            @infoDuration.innerHTML = ""
            setFocus = @tile?.hasFocus() or @focusSong
            @tile?.del()
            if @song.file?
                @createTile setFocus
            else
                @wave.clear()
            delete @focusSong
                
    createTile: (setFocus) ->
        @infoDuration.innerHTML = "#{@duration @song.duration}"
        @tile = new Tile @song.file, @elem
        @wave.showTile @tile, @song
        @tile.setFocus() if setFocus

    # 00     00   0000000   000   000   0000000  00000000  
    # 000   000  000   000  000   000  000       000       
    # 000000000  000   000  000   000  0000000   0000000   
    # 000 0 000  000   000  000   000       000  000       
    # 000   000   0000000    0000000   0000000   00000000  

    onDblClick:    (event) => @tileForEvent(event)?.onDblClick event
    onHover:       (event) => @tileForEvent(event)?.onHover event
    onClick:       (event) => @tileForEvent(event)?.onClick event
    onContextMenu: (event) => @tile?.onContextMenu event
    tileForEvent:  (event) => @tileForElem event.target
    tileForElem:   (e) -> 
        if e.tile? then return e.tile
        if e.parentNode? then return @tileForElem e.parentNode

    resized: => @wave?.resized()        
        
module.exports = Song
