# 000000000   0000000    0000000    0000000
#    000     000   000  000        000     
#    000     000000000  000  0000  0000000 
#    000     000   000  000   000       000
#    000     000   000   0000000   0000000 

jsmediatags = require 'jsmediatags'
log         = require './tools/log'

class Tags
            
    @cache = {}
    @queue = []
    
    @clearQueue: -> @queue = []
    
    @enqueue: (tile) ->
        @queue.push tile
        if @queue.length == 1
            @dequeue()
            
    @dequeue: ->
        if @queue.length
            tile = @queue[0]
            if @cache[tile.absFilePath()]?
                setImmediate () => @tagLoaded @cache[tile.absFilePath()]
            else
                jsmediatags.read tile.absFilePath(), onSuccess: @tagLoaded, onError: @tagError
        
    @tagError: (err) =>
        if tile = @queue.shift()
            # log "[ERROR] can't load tag for tile", tile.absFilePath()
            @dequeue()
        
    @tagLoaded: (tag) =>
        if tile = @queue.shift()
            @cache[tile.absFilePath()] = tag 
            tile.setTag tag
            @dequeue()
        
module.exports = Tags
