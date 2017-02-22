
#   00     00   0000000   000  000   000
#   000   000  000   000  000  0000  000
#   000000000  000000000  000  000 0 000
#   000 0 000  000   000  000  000  0000
#   000   000  000   000  000  000   000

Stage = require '/Users/kodi/s/ko/js/area/stage'
log   = require '/Users/kodi/s/ko/js/tools/log'
Krix  = require './krix'

class Main extends Stage
    
    constructor: (@view) -> 
        super @view
        @view.focus()
    
    start: -> 
                
        @elem = document.createElement 'div'
        @elem.style.position = 'absolute'
        @elem.style.top = '0'
        @elem.style.left = '0'
        @elem.style.right = '0'
        @elem.style.bottom = '0'
        @elem.style.background = "#111"
        @elem.style.overflow = "scroll"
        @view.appendChild @elem
        
        @krix = new Krix @view
        @view.focus()
        
    stop: ->
        @elem.remove()
        @pause()
        
    resized: (w,h) -> @krix.resized w, h

    modKeyComboEventDown: (mod, key, combo, event) -> @krix.modKeyComboEventDown mod, key, combo, event
    modKeyComboEventUp:   (mod, key, combo, event) -> @krix.modKeyComboEventUp   mod, key, combo, event
        
module.exports = Main
