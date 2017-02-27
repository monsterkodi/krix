#  0000000  00000000   000      000  000000000
# 000       000   000  000      000     000   
# 0000000   00000000   000      000     000   
#      000  000        000      000     000   
# 0000000   000        0000000  000     000   
{
clamp,
sh,sw,
last,
$}    = require './tools/tools'
log   = require './tools/log'
pos   = require './tools/pos'
drag  = require './tools/drag'
prefs = require './prefs'
_     = require 'lodash'
event = require 'events'

class Split extends event
    
    # 000  000   000  000  000000000
    # 000  0000  000  000     000   
    # 000  000 0 000  000     000   
    # 000  000  0000  000     000   
    # 000  000   000  000     000   
    
    constructor: () ->

        @handleHeight = 6
        @logVisible   = undefined
        
        @elem        = $('.split'      )
        @titlebar    = $('.titlebar'   )
        @handle      = $('.handle.log' )
        @main        = $('.main'       )
        @logview     = $('.logview'    )

        @splitPos    = prefs.get 'split', 20000
        # log 'elemHeight', @elemHeight(), '@splitPos', @splitPos
        @panes       = [@main, @logview]
                            
        @dragLog = new drag
            target: @handle
            cursor: 'ns-resize'
            onStop: (drag) => @snap()
            onMove: (drag) => @splitAt drag.pos.y - @elemTop() - @handleHeight/2
            
        @setLogVisible prefs.get 'logvisible', false

    #  0000000  00000000   000      000  000000000
    # 000       000   000  000      000     000   
    # 0000000   00000000   000      000     000   
    #      000  000        000      000     000   
    # 0000000   000        0000000  000     000   
    
    splitAt: (@splitPos) -> 
        log 'splitAt', @splitPos
        @panes[0].style.height = "#{@splitPos}px"
        @panes[1].style.height = "#{@elemHeight() - @splitPos}px"               
        @setLogVisible(@elemHeight() - @splitPos) > 0
        @elem.scrollTop = 0
        prefs.set 'split', @splitPos
        @emit     'split', @splitPos

    #  0000000  000   000   0000000   00000000 
    # 000       0000  000  000   000  000   000
    # 0000000   000 0 000  000000000  00000000 
    #      000  000  0000  000   000  000      
    # 0000000   000   000  000   000  000      
    
    snap: ->
        y = @splitPos
        if y < @elemHeight() - 50
            @splitAt @elemHeight()
        
    # 00000000   00000000   0000000  000  0000000  00000000  0000000  
    # 000   000  000       000       000     000   000       000   000
    # 0000000    0000000   0000000   000    000    0000000   000   000
    # 000   000  000            000  000   000     000       000   000
    # 000   000  00000000  0000000   000  0000000  00000000  0000000  
    
    resized: =>
        height = sh()-@titlebar.getBoundingClientRect().height
        width  = sw()
        log "Split.resized height:#{height} width:#{width} @splitPos:#{@splitPos}"
        @elem.style.height = "#{height}px"
        @elem.style.width  = "#{width}px"
        @splitAt clamp 0, @elemHeight(), @splitPos
    
    # 00000000    0000000    0000000          0000000  000  0000000  00000000
    # 000   000  000   000  000         0    000       000     000   000     
    # 00000000   000   000  0000000   00000  0000000   000    000    0000000 
    # 000        000   000       000    0         000  000   000     000     
    # 000         0000000   0000000          0000000   000  0000000  00000000
    
    elemTop:    -> @elem.getBoundingClientRect().top
    elemHeight: -> @elem.getBoundingClientRect().height - @handleHeight
    
    paneHeight: (i) -> @panes[i].getBoundingClientRect().height
        
    mainHeight:     -> @paneHeight 0
    logviewHeight:  -> @paneHeight 1
    
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
            if v and @logviewHeight() <= 0
                @splitAt @elemHeight() - Math.max(100, prefs.get('split', 200))-@handleHeight
            else if @logviewHeight() > 0 and not v
                @splitAt @elemHeight()
            display = v and 'inherit' or 'none'
            @logview.style.display   = display
            @handle.style.display = display            
            window.logview.resized()
            prefs.set 'logvisible', v
            
    clearLog: -> window.logview.setText ""
    showOrClearLog: -> 
        if @logVisible
            @clearLog()
        else
            @showLog()
     
module.exports = Split
