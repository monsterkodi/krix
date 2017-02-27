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

class Song
    
    constructor: (@view) ->
        
        @elem = document.createElement 'div'
        @elem.style.position        = 'absolute'
        @elem.style.top             = '10px'
        @elem.style.left            = '200px'
        @elem.style.bottom          = '10px'
        @elem.style.right           = '0'
        @elem.style.backgroundColor = "#111"
        @elem.classList.add 'song'
        @view.appendChild @elem
        
        @wave = new Wave @elem
        
        tileSize = 160
        style '.song .tileImg', "width: #{tileSize}px; height: #{tileSize}px;"
        
        post.on 'currentSong', @onCurrentSong
        post.on 'seek', =>  @tile?.setFocus()
        post.emit 'current'
        
    onCurrentSong: (@song) =>
        if not @tile or @song.file != @tile.file
            @tile?.del()
            if @song.file?
                @tile = new Tile @song.file, @elem, isFile: true
                @wave.showFile @tile.absFilePath(), @song
    
module.exports = Song
