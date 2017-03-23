# 000   000   0000000   000   000  00000000
# 000 0 000  000   000  000   000  000     
# 000000000  000000000   000 000   0000000 
# 000   000  000   000     000     000     
# 00     00  000   000      0      00000000
{
encodePath,
escapePath,
post,
elem,
drag,
log
}       = require 'kxk'
cache   = require './cache'
childp  = require 'child_process'
process = require 'process'
path    = require 'path'
fs      = require 'fs'

class Wave
    
    constructor: (@view) ->
        
        @elem = elem class: 'wave'
        @view.appendChild @elem
        
        @line = elem class: 'waveLine'
        @view.appendChild @line

        @blnd = elem class: 'waveBlend'
        @elem.appendChild @blnd
        
        post.on 'status', @onStatus

        @width = null
        @tile  = null
        @song  = null

        @drag = new drag 
            target:  @elem
            onStart: @onDragStart
            onMove:  @onDragMove
            cursor: 'pointer'
      
    onStatus: (status) => 
        left = parseInt @scale * @pps * status.elapsed / 2
        @line.style.left = "#{left+182}px"
        @blnd.style.width = "#{left}px"
        
        clearTimeout @timer
        if status.state == 'play'
            @timer = setTimeout @refresh, Math.min 200, parseInt 1000 * @scale

    refresh: => post.emit 'refresh'
    
    calc: ->
        @width = @elem.clientWidth
        @seconds = @song?.duration or 0
        @scale = 2 * @width / @seconds
        @pps = Math.max 1, parseInt @scale
        if @pps > 1
            @scale = @width/(@seconds*@pps/2)
    
    resized: =>
        pps = @pps
        @calc()
        if @tile and pps != @pps
            clearTimeout @resizeTimer
            @resizeTimer = setTimeout @showFile, 500
    
    showTile: (@tile, @song) -> @showFile()
    
    waveFile: -> path.join cache.waveDir, @tile.file.hash() + "_#{@pps}.png"
    showFile: =>      
        @elem.style.backgroundImage = ""
        @calc()
        fs.stat @waveFile(), (err, stat) =>
            if !err? and stat.isFile()
                @showWave()
            else
                @createWave()
            
    createWave: () ->
        inp = escapePath @tile.absFilePath()
        out = escapePath @waveFile()
        cmmd = "/usr/local/bin/audiowaveform --pixels-per-second #{@pps} --no-axis-labels -h 360 -w #{parseInt @pps * @seconds} --background-color 00000000 --waveform-color ffffff -i \"#{inp}\" -o \"#{out}\""
        childp.exec cmmd, (err) =>
            if err? then @convertWav()
            else @showWave()

    convertWav: () ->
        inp  = escapePath @tile.file
        out  = path.join process.env.TMPDIR, 'krixWave.wav'
        cmmd = "/usr/local/bin/ffmpeg -y -i \"#{inp}\" \"#{out}\""
        childp.exec cmmd, (err) =>
            if err?
                log "[ERROR] can't convert #{inp} to #{out}", err
            else
                inp = out
                out = escapePath @waveFile()
                cmmd = "/usr/local/bin/audiowaveform --pixels-per-second #{@pps} --no-axis-labels -h 360 -w #{parseInt @pps * @seconds} --background-color 00000000 --waveform-color ffffff -i \"#{inp}\" -o \"#{out}\""
                childp.exec cmmd, (err) =>
                    if err?
                        log "[ERROR] can't create waveform for #{inp}", err
                    else
                        @showWave()
        
    showWave: () =>
        @elem.style.backgroundImage = "url(\"file://#{encodePath(@waveFile())}\")"
        @elem.style.backgroundSize = "100% 100%"
        
    clear: () =>
        @elem.style.backgroundImage = 'none'
        @line.style.left = "0"

    #  0000000  00000000  00000000  000   000  
    # 000       000       000       000  000   
    # 0000000   0000000   0000000   0000000    
    #      000  000       000       000  000   
    # 0000000   00000000  00000000  000   000  

    onDragMove: (drag, event) => @seekTo event.clientX
    onDragStart: (drag,event) => @seekTo event.clientX
    seekTo: (x) -> 
        post.emit 'seek', 2*Math.max(0,x-@elem.getBoundingClientRect().left)/(@pps*@scale)
        
module.exports = Wave
