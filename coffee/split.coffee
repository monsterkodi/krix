#  0000000  00000000   000      000  000000000
# 000       000   000  000      000     000   
# 0000000   00000000   000      000     000   
#      000  000        000      000     000   
# 0000000   000        0000000  000     000   
{ 
prefs,
log,
$}    = require 'kxk'
event = require 'events'
spljs = require 'split.js'

class Split extends event
    
    # 000  000   000  000  000000000
    # 000  0000  000  000     000   
    # 000  000 0 000  000     000   
    # 000  000  0000  000     000   
    # 000  000   000  000     000   
    
    constructor: () ->

        @logVisible = undefined
        
        @split = spljs ['#main', '#logview'], 
            sizes:      [75, 25]
            minSize:    [184, 0]
            cursor:     'row-resize'
            direction:  'vertical'
            gutterSize: 6
            snapOffset: 30
            onDragEnd:  @resized

        @setLogVisible prefs.get 'logvisible', false
            
    # 00000000   00000000   0000000  000  0000000  00000000  0000000  
    # 000   000  000       000       000     000   000       000   000
    # 0000000    0000000   0000000   000    000    0000000   000   000
    # 000   000  000            000  000   000     000       000   000
    # 000   000  00000000  0000000   000  0000000  00000000  0000000  

    resized: =>
        window.main.resized()
        window.logview.resized()
    
    # 000       0000000    0000000 
    # 000      000   000  000      
    # 000      000   000  000  0000
    # 000      000   000  000   000
    # 0000000   0000000    0000000 
    
    showLog:   -> @setLogVisible true
    hideLog:   -> @setLogVisible false
    toggleLog: -> @setLogVisible not @logVisible
    setLogVisible: (v) ->
        if @logVisible != v
            @logVisible = v

            if @logVisible
                @split.setSizes [70, 30]
            else
                @split.collapse 1
            
            prefs.set 'logvisible', v
            @resized()
            
    clearLog: -> window.logview.clear()
    showOrClearLog: -> 
        if @logVisible
            @clearLog()
        else
            @showLog()
     
module.exports = Split
