# 000   000   0000000   000      000   000
# 000 0 000  000   000  000      000  000 
# 000000000  000000000  000      0000000  
# 000   000  000   000  000      000  000 
# 00     00  000   000  0000000  000   000

log          = require './tools/log'
EventEmitter = require 'events'
path         = require 'path'
fs           = require 'fs'

class Walk extends EventEmitter
    
    constructor: (@dir) ->
        # log 'walk', @dir
        fs.readdir @dir, @listFiles
    
    listFiles: (err, files) =>
        while file = files.shift()
            absPath = path.join @dir, file
            func = (w,p,c) -> (err,stat) -> 
                w.emitFile p, stat
                w.emit 'done' if c == 0
            fs.stat absPath, func @, absPath, files.length
            
    emitFile: (absPath,stat) =>
        if stat.isFile()
            @emit 'file', absPath
        else
            @emit 'directory', absPath
        
    stop: -> @removeAllListeners()
        
module.exports = Walk
