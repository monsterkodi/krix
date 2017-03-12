
# 00000000   000       0000000   000   000
# 000   000  000      000   000   000 000 
# 00000000   000      000000000    00000  
# 000        000      000   000     000   
# 000        0000000  000   000     000   
{
last
}         = require './tools/tools'
log       = require './tools/log'
post      = require './post'
_         = require 'lodash'
moment    = require 'moment'
childp    = require 'child_process' 
mpd       = require 'mpd'

class Play
    
    @instance = null
    
    constructor: () ->
        
        Play.instance = @
        @playlists = {}
        @random    = 0
        @client    = null
        @mpcc      = null
        
        @connect()
            
        post.on 'playFile',       @playFile
        post.on 'delPlaylist',    @delPlaylist
        post.on 'playPlaylist',   @playPlaylist
        post.on 'playlistInfo',   @playlistInfo
        post.on 'renamePlaylist', @renamePlaylist
        post.on 'addToPlaylist',  @addToPlaylist
        post.on 'addToCurrent',   @addToCurrent
        post.on 'refresh',        @onRefresh
        post.on 'update',         @onUpdate
        post.on 'current',        @onCurrent
        post.on 'nextSong',       @nextSong
        post.on 'prevSong',       @prevSong
        post.on 'toggle',         @onToggle
        post.on 'random',         @onRandom
        post.on 'repeat',         @onRepeat
        post.on 'seek',           @onSeek
        post.on 'mpc',            @mpc
        
    connect: =>
        @client = mpd.connect port: 6600, host: 'localhost'
        @client.on 'error',  @onClientError
        @client.on 'system', @onServerChange
        @client.on 'ready',  @onClientReady
    
    @isConnected: -> Play.instance.mpcc?
            
    onClientReady: =>
        log 'connected to mpd'
        @mpcc = @client
        @onRefresh()
        @onCurrent()
        post.emit 'connected'

    onServerChange: (change) =>
        if change == 'player'          then @onCurrent()
        if change == 'stored_playlist' then @updatePlaylists()
        if change == 'playlist'        then delete @playlists['']; @playlistInfo ''
        @onRefresh()
        
    onClientError: (err) =>
        if err.code == 'ECONNREFUSED'
            if not @server
                log 'spawning mpd server'
                @server = childp.spawn '/usr/local/bin/mpd', ['--no-daemon', '--stderr']
                @server.on 'error', (err)  -> log "[ERROR] can't spawn mpd server", err
                @server.on 'close', (code) -> log "mpd server closed", code
                @server.on 'data',  (data) -> log "mpd server data", data
                setTimeout @connect, 500
            else
                log "[ERROR] can't connect to spawned mpd server either", err
        else
            log '[ERROR] mpd client error:', err
        
    del: -> @mpc 'close'

    onToggle:        => 
        if @status?.state == 'stop'
            @mpc 'play'
        else
            @mpc 'pause',  [@status?.state  == 'play' and '1' or '0']
                     
    onRandom:        => @mpc 'random', [@status?.random == '0'    and '1' or '0']
    onRepeat:        => @mpc 'repeat', [@status?.repeat == '0'    and '1' or '0']
    onCurrent:       => @mpc 'currentsong', (info) -> post.emit 'currentSong', info 
    onRefresh:       => @mpc 'status', (@status) => post.emit 'status', @status
    onUpdate: (p)    => @mpc 'rescan', [p]; log "mpd update #{p}"
    onSeek: (pos)    => @mpc 'seekcur', [pos]    
    nextSong:        => @mpc 'next'
    prevSong:        => @mpc 'previous' 

    playFile: (file) =>
        @mpcc?.sendCommands ['clear', mpd.cmd('add', [file]), 'play'], (err, msg) ->
            log "[ERROR] playFile failed: #{err}" if err?
    
    # 00000000   000       0000000   000   000  000      000   0000000  000000000  
    # 000   000  000      000   000   000 000   000      000  000          000     
    # 00000000   000      000000000    00000    000      000  0000000      000     
    # 000        000      000   000     000     000      000       000     000     
    # 000        0000000  000   000     000     0000000  000  0000000      000     
    
    addToCurrent:  (uri) => @mpc 'add', [uri]
    addToPlaylist: (uri, playlist) => @mpc 'playlistadd', [playlist, uri]

    renamePlaylist: (oldName, newName) => @mpc 'rename', [oldName, newName]
    
    delPlaylist: (playlist, cb) => @mpc 'rm', [playlist], cb
                
    playPlaylist: (playlist) => 
        @mpcc?.sendCommands ['clear', mpd.cmd('load', [playlist]), 'play'], (err, msg) ->
            log "[ERROR] playPlaylist failed:", err if err?

    @newPlaylist: (name, cb) -> Play.instance.newPlaylist name, cb
    newPlaylist: (name, cb) ->
        @mpcc?.sendCommand mpd.cmd('save', [name]), (err, msg) =>
            if err?
                @newPlaylist name+'_', cb
            else
                cb? name

    updatePlaylists: =>
        @mpcc?.sendCommand 'listplaylists', (err, msg) =>
            lines = msg.split '\n'
            for i in [0...lines.length-1] by 2
                name = lines[i  ].split(': ', 2)[1]
                date = lines[i+1].split(': ', 2)[1]
                if not @playlists[name]? 
                    @playlists[name] = name: name, date: date
                    @playlistInfo name, update: true
                else if @playlists[name].date != date
                    @playlists[name].date = date
                    @playlistInfo name, update: true
                
    playlistInfo: (name, opt) => 
        
        if not opt?.update and @playlists[name]?.count?
            if opt?.cb?
                opt.cb @playlists[name]
            else
                post.emit "playlist:#{name}", @playlists[name]
            return
            
        if not @playlists[name]? 
            @playlists[name] = name: name, date: ''

        cmd = mpd.cmd 'listplaylistinfo', [name] 
        cmd = mpd.cmd 'playlistinfo', [] if name == ''
        @mpcc?.sendCommand cmd, (err, msg) => 
            if err?
                log "[ERROR] playlist command failed: #{err}"
                return
            
            lines = msg.split '\n'
            time = 0
            files = []
            for l in lines
                [key, val] = l.split(': ', 2)
                switch key 
                    when 'file'   then files.push file: val
                    when 'Artist' then last(files).artist = val
                    when 'Title'  then last(files).title = val
                    when 'Time'   
                        secs = parseInt val
                        last(files).time = secs
                        time += secs
            @playlists[name].count = files.length
            @playlists[name].secs  = time
            @playlists[name].time  = moment.duration(time, 'seconds').humanize()
            @playlists[name].files = files
            if opt?.cb?
                opt.cb @playlists[name]
            else
                post.emit "playlist:#{name}", @playlists[name]
            
    # 00     00  00000000    0000000  
    # 000   000  000   000  000       
    # 000000000  00000000   000       
    # 000 0 000  000        000       
    # 000   000  000         0000000  
    
    @mpc: (cmmd, args=[], cb=null) -> Play.instance.mpc cmmd, args, cb
    mpc: (cmmd, args=[], cb=null) => 
        if _.isFunction args
            cb = args
            args = []
        @mpcc?.sendCommand mpd.cmd(cmmd, args), (err, msg) ->
            if err?
                log "[ERROR] mpc command failed: #{cmmd} #{args} #{err}"
            else
                if cmmd in ['playlistinfo', 'listplaylist']
                    files = []
                    for l in msg.split '\n'
                        if l.startsWith 'file: '
                            files.push l.substr 6
                    cb? files
                else if cmmd == 'listplaylists'
                    lists = []
                    for l in msg.split '\n'
                        if l.startsWith 'playlist: '
                            lists.push l.substr 10
                    cb? lists
                else
                    cb? mpd.parseKeyValueMessage msg
        
module.exports = Play
