
#   00     00   0000000   000  000   000
#   000   000  000   000  000  0000  000
#   000000000  000000000  000  000 0 000
#   000 0 000  000   000  000  000  0000
#   000   000  000   000  000  000   000
{
resolve,
keyinfo,
post,
log
}       = require 'kxk'
Brws    = require './brws'
Ctrl    = require './ctrl'
Play    = require './play'
cache   = require './cache'
path    = require 'path'

class Main
    
    constructor: (@view) -> 

        @musicDir = resolve "~/Music"
        cache.init @musicDir
                
        @brws = new Brws @view, @musicDir
        @ctrl = new Ctrl @view
        @play = new Play
        @brws.loadDir ''
        
        post.emit 'current'
        post.emit 'refresh'
        
        @view.focus()
        @view.addEventListener 'keydown', @onKeyDown, false
    
    onKeyDown: (event) =>
        {mod, key, combo} = keyinfo.forEvent event
        @onModKeyCombo mod, key, combo, event
        
    onModKeyCombo: (mod, key, combo, event) =>
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
