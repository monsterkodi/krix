
#   00     00   0000000   000  000   000
#   000   000  000   000  000  0000  000
#   000000000  000000000  000  000 0 000
#   000 0 000  000   000  000  000  0000
#   000   000  000   000  000  000   000

Stage = require '/Users/kodi/s/ko/js/area/stage'
log   = require './tools/log'
Krix  = require './krix'

class Main extends Stage
    
    constructor: (@view) -> 
        super @view
        @view.focus()
    
    start: -> 
                        
        @krix = new Krix @view
        @view.focus()
        
    stop: ->
        @elem.remove()
        @pause()
        
    resized: (w,h) -> @krix.resized w, h

    modKeyComboEventDown: (mod, key, combo, event) -> @krix.modKeyComboEventDown mod, key, combo, event
    modKeyComboEventUp:   (mod, key, combo, event) -> @krix.modKeyComboEventUp   mod, key, combo, event
        
module.exports = Main
