
#   00     00   0000000   000  000   000
#   000   000  000   000  000  0000  000
#   000000000  000000000  000  000 0 000
#   000 0 000  000   000  000  000  0000
#   000   000  000   000  000  000   000

log   = require './tools/log'
Stage = require './stage'
Krix  = require './krix'

class Main extends Stage
    
    constructor: (@view) -> 
        super @view
        @krix = new Krix @view
        @view.focus()
    
    stop: -> @krix?.del()
        
    resized: (w,h) -> @krix?.resized w, h

    modKeyComboEventDown: (mod, key, combo, event) -> @krix?.modKeyComboEventDown mod, key, combo, event
    modKeyComboEventUp:   (mod, key, combo, event) -> @krix?.modKeyComboEventUp   mod, key, combo, event
        
module.exports = Main
