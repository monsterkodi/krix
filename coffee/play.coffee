
# 00000000   000       0000000   000   000
# 000   000  000      000   000   000 000 
# 00000000   000      000000000    00000  
# 000        000      000   000     000   
# 000        0000000  000   000     000   

log    = require '/Users/kodi/s/ko/js/tools/log'
post   = require './post'
childp = require 'child_process' 

class Play
    
    constructor: () ->
        post.on 'playFile', @playFile
        post.on 'addFile',  @addFile
        post.on 'nextSong', @nextSong
        post.on 'prevSong', @prevSong
    
    playFile: (file) =>
        log "Play.playFile file:#{file}"
        # childp.exec "mpc clear && mpc add \"#{file}\" && mpc play", (err) ->
            # log "play: #{file}"
        childp.exec "mpc clear", (err) ->
            # log 'clear'
            childp.exec "mpc add \"#{file}\"", (err) ->
                # log 'add', file
                childp.exec "mpc play", (err) ->
                    # log 'play'

    addFile: (file) => @mpc "add \"#{file}\""
    nextSong: => @mpc 'next'
    prevSong: => @mpc 'prev'
      
    mpc: (arg) -> childp.exec "mpc #{arg}", (err) ->
        log "[ERROR] mpc #{arg}", err if err
        
module.exports = Play
