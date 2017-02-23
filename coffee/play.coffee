
# 00000000   000       0000000   000   000
# 000   000  000      000   000   000 000 
# 00000000   000      000000000    00000  
# 000        000      000   000     000   
# 000        0000000  000   000     000   

childp    = require 'child_process' 
komponist = require 'komponist'
log       = require './tools/log'
post      = require './post'

class Play
    
    constructor: () ->
        
        @mpcc = komponist.createConnection 6600, 'localhost', -> log 'connected to mpc server'
        @mpcc.on 'changed', @onServerChange
        
        post.on 'playFile', @playFile
        post.on 'addFile',  @addFile
        post.on 'nextSong', @nextSong
        post.on 'prevSong', @prevSong
    
    onServerChange: (change) =>
        log "Play.onServerChange change:", change
    
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

    addFile: (file) => @mpc "add", [file]
    nextSong: => @mpc 'next'
    prevSong: => @mpc 'prev'
        
    mpc: (cmmd, args=[]) -> 
        # log 'mpc command', cmmd, args
        @mpcc.command cmmd, args, (err) ->
            log "[ERROR] mpc command failed: #{cmmd} #{args}", err if err
            
        
module.exports = Play
