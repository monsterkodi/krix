# 000   000   0000000   000   000  00000000
# 000 0 000  000   000  000   000  000     
# 000000000  000000000   000 000   0000000 
# 000   000  000   000     000     000     
# 00     00  000   000      0      00000000

log     = require './tools/log'
childp  = require 'child_process'
process = require 'process'
path    = require 'path'
fs      = require 'fs'

class Wave
    
    constructor: (@view) ->
        @elem = document.createElement 'div'
        @elem.style.position   = 'absolute'
        @elem.style.top        = '10px'
        @elem.style.left       = '182px'
        @elem.style.right      = '0'
        @elem.style.height     = '160px'
        # @elem.style.background = "#000"
        @elem.style.overflow   = "hidden"
        @elem.classList.add 'wave'
        @view.appendChild @elem
  
    showFile: (file) ->      
        outfile = path.join process.env.TMPDIR, 'krixWave.png'
        width = @elem.clientWidth
        pps = 5
        log 'width', width, pps
        cmmd = "audiowaveform --pixels-per-second #{pps} --no-axis-labels -h 360 -w #{width*2} --background-color 00000000 --waveform-color ffffff -i \"#{file}\" -o \"#{outfile}\""
        # log 'cmmd', cmmd
        @elem.style.backgroundImage = ""
        childp.exec cmmd, (err) =>
            if err?
                log "[ERROR] can't create waveform for #{file}", err
            else
                fs.readFile outfile, (err, data) =>
                    base = data.toString 'base64' 
                    @elem.style.backgroundImage = "url('data:image/png;base64,#{base}')"
                    @elem.style.backgroundSize = "100% 100%"
        
module.exports = Wave
