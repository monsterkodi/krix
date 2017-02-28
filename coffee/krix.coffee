
#   000   000  00000000   000  000   000
#   000  000   000   000  000   000 000 
#   0000000    0000000    000    00000  
#   000  000   000   000  000   000 000 
#   000   000  000   000  000  000   000

log    = require './tools/log'
Brws   = require './brws'
Ctrl   = require './ctrl'
Play   = require './play'
post   = require './post'

class Krix
    
    constructor: (@view) ->

        @play = new Play
        @ctrl = new Ctrl @view
        @brws = new Brws @view
                        
        @brws.loadDir ""
    
    del: ->
        post.stop()
        @ctrl?.del()
        @brws?.del()
        @play?.del()
                
    resized: (w,h) -> 
        @aspect = w/h
        @ctrl.resized()
        @brws.resized()
                      
    # 000   000  00000000  000   000
    # 000  000   000        000 000 
    # 0000000    0000000     00000  
    # 000  000   000          000   
    # 000   000  00000000     000   
    
    modKeyComboEventDown: (mod, key, combo, event) ->
        
        @ctrl.modKeyComboEventDown mod, key, combo, event
        @brws.modKeyComboEventDown mod, key, combo, event
        
        # log "down", mod, key, combo

    modKeyComboEventUp: (mod, key, combo, event) -> # log "up", mod, key, combo

module.exports = Krix


