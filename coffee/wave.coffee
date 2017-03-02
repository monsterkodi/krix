# 000   000   0000000   000   000  00000000
# 000 0 000  000   000  000   000  000     
# 000000000  000000000   000 000   0000000 
# 000   000  000   000     000     000     
# 00     00  000   000      0      00000000
{
encodePath
}       = require './tools/tools'
log     = require './tools/log'
drag    = require './tools/drag'
childp  = require 'child_process'
process = require 'process'
path    = require 'path'
fs      = require 'fs'
post    = require './post'

class Wave
    
    constructor: (@view) ->
        
        @elem = document.createElement 'div'
        @elem.classList.add 'wave'
        @view.appendChild @elem
        
        @line = document.createElement 'div'
        @line.classList.add 'waveLine'
        @view.appendChild @line

        @blnd = document.createElement 'div'
        @blnd.classList.add 'waveBlend'
        @elem.appendChild @blnd
        
        post.on 'status', @onStatus

        @width = null
        @file  = null
        @song  = null

        @drag = new drag 
            target:  @elem
            onStart: @onDragStart
            onMove:  @onDragMove
            cursor: 'pointer'

    onDragMove: (drag, event) => @seekTo event.clientX
    onDragStart: (drag,event) => @seekTo event.clientX
    seekTo: (x) -> 
        post.emit 'seek', 2*Math.max(0,x-@elem.getBoundingClientRect().left)/(@pps*@scale)
      
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
        if pps != @pps
            clearTimeout @resizeTimer
            reloadWave = => @showFile @file, @song
            @resizeTimer = setTimeout reloadWave, 500
        
    showFile: (@file, @song) ->      
        @elem.style.backgroundImage = ""
        @calc()
        # @refresh() ???
        if @pps == 1
            waveFile = path.join path.dirname(@file), '.krix', path.basename(@file) + ".png"
            fs.stat waveFile, (err, stat) =>
                if !err? and stat.isFile()
                    @showWave waveFile
                else
                    @createWave waveFile, @showWave
        else
            waveFile = path.join process.env.TMPDIR, 'krixWave.png'
            @createWave waveFile, @showWaveData
            
    createWave: (waveFile, cb) ->
        inp = @file.replace /([\`"])/g, '\\$1'
        out = waveFile.replace /([\`"])/g, '\\$1'
        cmmd = "/usr/local/bin/audiowaveform --pixels-per-second #{@pps} --no-axis-labels -h 360 -w #{parseInt @pps * @seconds} --background-color 00000000 --waveform-color ffffff -i \"#{inp}\" -o \"#{out}\""
        childp.exec cmmd, (err) =>
            if err?
                log "[ERROR] can't create waveform for #{@file}", err
            else
                cb waveFile

    showWave: (waveFile) =>
        @elem.style.backgroundImage = "url(\"file://#{encodePath(waveFile)}\")"
        @elem.style.backgroundSize = "100% 100%"

    showWaveData: (waveFile) =>
        fs.readFile waveFile, (err, data) =>
            if !err? and data?
                base = data.toString 'base64' 
                @elem.style.backgroundImage = "url('data:image/png;base64,#{base}')"
                @elem.style.backgroundSize = "100% 100%"
        
module.exports = Wave
