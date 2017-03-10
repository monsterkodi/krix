#  0000000   0000000    0000000  000   000  00000000
# 000       000   000  000       000   000  000     
# 000       000000000  000       000000000  0000000 
# 000       000   000  000       000   000  000     
#  0000000  000   000   0000000  000   000  00000000

log    = require './tools/log'
Store  = require './store'
path   = require 'path'
mkpath = require 'mkpath'

class Cache
    
    @store  = null
    @imgDir = null

    @init: (cacheDir)   -> 
        log 'Cache.@init', cacheDir
        @store  = new Store file: path.join cacheDir, 'cache.noon'
        @imgDir = path.join(cacheDir, 'img')
        try
            mkpath.sync @imgDir
        catch err
            log "[ERROR] can't create image cache directory #{@imgDir}", err
            @imgDir = null
        
    @get:  (key, value) -> @store.get key, value
    @set:  (key, value) -> @store.set key, value
    @del:  (key, value) -> @store.del key
    @save: (cb)         -> @store.save cb
    @prune:             -> @store.clear()

module.exports = Cache
