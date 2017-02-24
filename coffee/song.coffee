#  0000000   0000000   000   000   0000000 
# 000       000   000  0000  000  000      
# 0000000   000   000  000 0 000  000  0000
#      000  000   000  000  0000  000   000
# 0000000    0000000   000   000   0000000 
{
style
}    = require './tools/tools'
Tile = require './tile'
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
        
        tileSize = 160
        style '.song .tileImg', "width: #{tileSize}px; height: #{tileSize}px;"
        
        post.on 'currentSong', @onCurrentSong
        
    onCurrentSong: (song) =>
        log "Song.onCurrentSong file:#{song.file}"
        @tile = new Tile song.file, @elem, isFile: true
    
module.exports = Song
