#  0000000   0000000   000   000   0000000 
# 000       000   000  0000  000  000      
# 0000000   000   000  000 0 000  000  0000
#      000  000   000  000  0000  000   000
# 0000000    0000000   000   000   0000000 
{
style
}    = require './tools/tools'
Tile = require './tile'
Wave = require './wave'
post = require './post'
log  = require './tools/log'
durt = require 'duration-time-format'

class Song
    
    constructor: (@view) ->
        
        @elem = document.createElement 'div'
        @elem.classList.add 'song'
        @view.appendChild @elem
        
        @wave = new Wave @elem
    
        @info = document.createElement 'div'
        @info.classList.add 'songInfo'
        @elem.appendChild @info
        
        @infoElapsed = document.createElement 'div'
        @infoElapsed.classList.add 'songElapsed'
        @info.appendChild @infoElapsed

        @infoDuration = document.createElement 'div'
        @infoDuration.classList.add 'songDuration'
        @info.appendChild @infoDuration
        
        tileSize = 160
        style '.song .tileImg', "width: #{tileSize}px; height: #{tileSize}px;"
        
        post.on 'currentSong', @onCurrentSong
        post.on 'seek', =>  @tile?.setFocus()
        post.on 'status', @onStatus

    resized: => @wave?.resized()
        
    duration: (s) -> durt().format(parseInt s).replace(/^0+/, '').replace(/^:0?/, '')
        
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
            setFocus = @tile?.hasFocus()
            @tile?.del()
            if @song.file?
                @infoDuration.innerHTML = "#{@duration @song.duration}"
                @tile = new Tile @song.file, @elem, isFile: true
                @wave.showFile @tile.absFilePath(), @song
                @tile.setFocus() if setFocus
    
module.exports = Song
