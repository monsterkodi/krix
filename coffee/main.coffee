
#   00     00   0000000   000  000   000
#   000   000  000   000  000  0000  000
#   000000000  000000000  000  000 0 000
#   000 0 000  000   000  000  000  0000
#   000   000  000   000  000  000   000

log  = require './tools/log'
Brws = require './brws'
Ctrl = require './ctrl'
Play = require './play'
post = require './post'

class Main
    
    constructor: (@view) -> 
                
        @ctrl = new Ctrl @view
        @brws = new Brws @view
        @play = new Play
        @brws.loadDir ""
        
        post.emit 'current'
        post.emit 'refresh'
        
        @view.focus()
        @view.onkeydown = @onKeyDown
    
    onKeyDown: (event) =>
        {mod, key, combo} = keyinfo.forEvent event
        return if not combo
        return if key == 'right click' # weird right command key
        @ctrl?.modKeyComboEventDown mod, key, combo, event
        @brws?.modKeyComboEventDown mod, key, combo, event
               
    del: -> 
        post.stop()
        @ctrl?.del()
        @brws?.del()
        @play?.del()
        
    resized: (w,h) -> 
        @ctrl.resized()
        @brws.resized()

module.exports = Main
