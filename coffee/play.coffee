
# 00000000   000       0000000   000   000
# 000   000  000      000   000   000 000 
# 00000000   000      000000000    00000  
# 000        000      000   000     000   
# 000        0000000  000   000     000   

childp    = require 'child_process' 
komponist = require 'komponist'
_         = require 'lodash'
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
        switch change
            when 'player'
                # @mpc 'status', (status) =>
                    # log 'current songid', status.songid
                    # @mpc 'playlistid', status.songid, (song) ->
                        # log 'song', song
                @mpc 'currentsong', (info) ->
                    log 'emit currentSong', info
                    post.emit 'currentSong', info
                    
            when 'playlist'
                @mpc 'playlist', (playlist) ->
                    for f in playlist
                        log f.file
    
    playFile: (file) =>
        log "Play.playFile file:#{file}"

        @mpc 'clear'
        @mpc 'add', [file]
        @mpc 'play'

    addFile: (file) => @mpc "add", [file]
    nextSong: => @mpc 'next'
    prevSong: => @mpc 'prev'
    
    # mpq: (cmmd, args=[]) -> @mpc cmmd, args    
    mpc: (cmmd, args=[], cb=null) -> 
        if _.isFunction args
            cb = args
            args = []
        @mpcc.command cmmd, args, (err, result) ->
            if err?
                log "[ERROR] mpc command failed: #{cmmd} #{args}", err
            else
                cb? result            
        
module.exports = Play
