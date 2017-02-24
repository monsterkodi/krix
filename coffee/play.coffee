
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
        
        @random = 0
        @mpcc = komponist.createConnection 6600, 'localhost', -> log 'connected to mpc server'
        @mpcc.on 'changed',  @onServerChange
        
        post.on 'playFile',  @playFile
        post.on 'addFile',   @addFile
        post.on 'nextSong',  @nextSong
        post.on 'prevSong',  @prevSong
        post.on 'current',   @onCurrent
        post.on 'toggle',    @onToggle
        post.on 'random',    @onRandom
        post.on 'repeat',    @onRepeat
        
        @refreshStatus()
    
    del: -> @mpc 'close'
    
    onRandom: => @mpc 'random', [@status?.random == '0' and '1' or '0']
    onRepeat: => @mpc 'repeat', [@status?.repeat == '0' and '1' or '0']
    onToggle: => @mpcc.toggle()
    onCurrent: => @mpc 'currentsong', (info) -> post.emit 'currentSong', info

    refreshStatus: ->
        @mpc 'status', (@status) => 
            # log 'status', @status
            post.emit 'status', @status
        
    onServerChange: (change) =>
        # log "Play.onServerChange change:", change
        
        switch change
            when 'player' 
                @onCurrent()
                @refreshStatus()
            when 'options'
                @refreshStatus()
            when 'playlist'
                log 'playlist changed'
                @refreshStatus()
                # @mpc 'playlist', (playlist) ->
                    # for f in playlist
                        # log f.file
    
    playFile: (file) =>
        # log "Play.playFile file:#{file}"
        @mpc 'clear'
        @mpc 'add', [file]
        @mpc 'play'

    addFile: (file) => @mpc "add", [file]
    nextSong: => @mpc 'next'
    prevSong: => @mpc 'previous'
    
    mpc: (cmmd, args=[], cb=null) -> 
        # log 'cmmd', cmmd, 'args', args
        if _.isFunction args
            cb = args
            args = []
        @mpcc.command cmmd, args, (err, result) ->
            if err?
                log "[ERROR] mpc command failed: #{cmmd} #{args}", err
            else
                cb? result            
        
module.exports = Play
