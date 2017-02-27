
# 00000000   000       0000000   000   000
# 000   000  000      000   000   000 000 
# 00000000   000      000000000    00000  
# 000        000      000   000     000   
# 000        0000000  000   000     000   

childp    = require 'child_process' 
mpd       = require 'mpd'
_         = require 'lodash'
log       = require './tools/log'
post      = require './post'

class Play
    
    @instance = null
    
    constructor: () ->
        
        Play.instance = @
        @random = 0
        @client = null
        @mpcc   = null
        
        @connect()
            
        post.on 'playFile', @playFile
        post.on 'addFile',  @addFile
        post.on 'nextSong', @nextSong
        post.on 'prevSong', @prevSong
        post.on 'current',  @onCurrent
        post.on 'toggle',   @onToggle
        post.on 'random',   @onRandom
        post.on 'repeat',   @onRepeat
        post.on 'seek',     @onSeek
        post.on 'refresh',  @onRefresh
        
    connect: =>
        
        @client = mpd.connect port: 6600, host: 'localhost'
        @client.on 'error',  @onClientError
        @client.on 'system', @onServerChange
        @client.on 'ready',  @onClientReady
            
    onClientReady: =>
        log 'connected to mpd'
        @mpcc = @client
        @onRefresh()
        @onCurrent()
        
    onClientError: (err) =>
        if err.code == 'ECONNREFUSED'
            if not @server
                log 'spawning mpd server'
                @server = childp.spawn 'mpd', ['--no-daemon', '--stderr']
                @server.on 'error', (err)  -> log "[ERROR] can't spawn mpd server", err
                @server.on 'close', (code) -> log "mpd server closed", code
                @server.on 'data',  (data) -> log "mpd server data", data
                setTimeout @connect, 500
            else
                log "can't connect to spawned mpd server either", err
        else
            log '[ERROR] mpd client error:', err
        
    del: -> @mpc 'close'
    
    onRandom:     => @mpc 'random', [@status?.random == '0'    and '1' or '0']
    onRepeat:     => @mpc 'repeat', [@status?.repeat == '0'    and '1' or '0']
    onToggle:     => @mpc 'pause',  [@status?.state  == 'play' and '1' or '0']
    onCurrent:    => @mpc 'currentsong', (info) -> post.emit 'currentSong', info 
    onRefresh:    => @mpc 'status', (@status) => post.emit 'status', @status
    onSeek: (pos) => @mpc 'seekcur', [pos]
    
    nextSong:        => @mpc 'next'
    prevSong:        => @mpc 'previous'        
    addFile:  (file) => @mpc "add", [file]
    playFile: (file) =>
        @mpcc?.sendCommands ['clear', mpd.cmd('add', [file]), 'play'], (err, msg) ->
            if err?
                log "[ERROR] mpc command list failed:", err

    onServerChange: (change) =>
        if change =='player' then @onCurrent()
        @onRefresh()
    
    mpc: (cmmd, args=[], cb=null) -> 
        if _.isFunction args
            cb = args
            args = []
        @mpcc?.sendCommand mpd.cmd(cmmd, args), (err, msg) ->
            if err?
                log "[ERROR] mpc command failed: #{cmmd} #{args}", err
            else
                if cmmd == 'playlistinfo'
                    files = []
                    for l in msg.split '\n'
                        if l.startsWith 'file: '
                            files.push l.substr 6
                    cb? files
                else
                    cb? mpd.parseKeyValueMessage msg
        
module.exports = Play
