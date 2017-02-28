# 000   000   0000000   000   000  00000000
# 000 0 000  000   000  000   000  000     
# 000000000  000000000   000 000   0000000 
# 000   000  000   000     000     000     
# 00     00  000   000      0      00000000

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
        @elem.style.position   = 'absolute'
        @elem.style.top        = '10px'
        @elem.style.left       = '182px'
        @elem.style.right      = '0'
        @elem.style.height     = '160px'
        @elem.style.overflow   = "hidden"
        @elem.classList.add 'wave'
        @view.appendChild @elem
        
        @line = document.createElement 'div'
        @line.style.position   = 'absolute'
        @line.style.top        = '0'
        @line.style.width      = '2px'
        @line.style.height     = '180px'
        @line.style.backgroundColor = "rgba(255,255,255,0.07)"
        @view.appendChild @line

        @blnd = document.createElement 'div'
        @blnd.style.position   = 'absolute'
        @blnd.style.top        = '0'
        @blnd.style.left       = '0'
        @blnd.style.height     = '160px'
        @blnd.style.backgroundColor = "rgba(19,19,19,0.6)"
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
    seekTo: (x) -> post.emit 'seek', 2*Math.max(0,x-@elem.getBoundingClientRect().left)/@pps
      
    onStatus: (status) => 
        left = parseInt @pps * status.elapsed / 2
        @line.style.left = "#{left+182}px"
        @blnd.style.width = "#{left}px"
        
        clearTimeout @timer
        if status.state == 'play'
            @timer = setTimeout @refresh, parseInt 1000 / @pps

    refresh: => post.emit 'refresh'
    resized: =>
        if @elem.clientWidth != @width
            reloadWave = => @showFile @file, @song
            setTimeout reloadWave, 500
        
    showFile: (@file, @song) ->      
        outfile = path.join process.env.TMPDIR, 'krixWave.png'
        @width = @elem.clientWidth
        @seconds = @song.duration
        @pps = Math.max 1, parseInt 2 * @width / @seconds
        cmmd = "/usr/local/bin/audiowaveform --pixels-per-second #{@pps} --no-axis-labels -h 360 -w #{@width*2} --background-color 00000000 --waveform-color 444444 -i \"#{@file}\" -o \"#{outfile}\""
        @elem.style.backgroundImage = ""
        childp.exec cmmd, (err) =>
            if err?
                log "[ERROR] can't create waveform for #{file}", err.cmd
            else
                fs.readFile outfile, (err, data) =>
                    base = data.toString 'base64' 
                    @elem.style.backgroundImage = "url('data:image/png;base64,#{base}')"
                    @elem.style.backgroundSize = "100% 100%"
        
module.exports = Wave
