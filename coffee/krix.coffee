
#   000   000  00000000   000  000   000
#   000  000   000   000  000   000 000 
#   0000000    0000000    000    00000  
#   000  000   000   000  000   000 000 
#   000   000  000   000  000  000   000
{
resolve
}      = require './tools/tools'
fs     = require 'fs'
path   = require 'path'
childp = require 'child_process'
log    = require './tools/log'
Prefs  = require './prefs'
Brws   = require './brws'
Ctrl   = require './ctrl'
Play   = require './play'
post   = require './post'

class Krix
    
    constructor: (@view) ->

        Prefs.init resolve '~/Library/Application Support/krix/krix.noon'

        @play = new Play
        @ctrl = new Ctrl @view
        @brws = new Brws @view
        
        post.on 'openFile',  @openFile
                
        @brws.loadDir ""
    
    del: ->
        post.stop()
        @ctrl?.del()
        @brws?.del()
        @play?.del()
        
    openFile: (file) =>
        absPath = path.join @brws.musicDir, file
        stat = fs.statSync absPath 
        if stat.isDirectory()
            @brws.loadDir file
        else
            args = [
                '-e', 'tell application "Finder"', 
                '-e', "reveal POSIX file \"#{absPath}\"",
                '-e', 'activate',
                '-e', 'end tell']
            childp.spawn 'osascript', args
        
    resized: (w,h) -> @aspect = w/h
                      
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


