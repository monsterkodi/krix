#  0000000   0000000    0000000  000   000  00000000
# 000       000   000  000       000   000  000     
# 000       000000000  000       000000000  0000000 
# 000       000   000  000       000   000  000     
#  0000000  000   000   0000000  000   000  00000000
{
relative,
$ }      = require './tools/tools'
log      = require './tools/log'
Store    = require './store'
# graceful = require 'graceful-fs'
# graceful.gracefulify require 'fs' 
path     = require 'path'
mkpath   = require 'mkpath'
chokidar = require 'chokidar'

class Cache
    
    @store    = null
    @imgDir   = null
    @waveDir  = null
    @cacheDir = null
    @musicDir = null

    @init: (@musicDir)   -> 
        
        @cacheDir = path.join @musicDir, '.krix'
        log 'Cache.@init', @cacheDir
        
        @store   = new Store timeout: 10000, file: path.join @cacheDir, 'cache.noon'
        @imgDir  = path.join @cacheDir, 'img' 
        @waveDir = path.join @cacheDir, 'wave' 
        
        try
            mkpath.sync @imgDir
        catch err
            log "[ERROR] can't create image cache directory #{@imgDir}", err
            @imgDir = null
        try
            mkpath.sync @waveDir
        catch err
            log "[ERROR] can't create wave cache directory @{waveDir}", err
            @waveDir = null
            
        @watcher = chokidar.watch path.dirname(@cacheDir), 
            ignored:        /(^|[\/\\])\../
            ignoreInitial:  true
            usePolling:     false
            useFsEvents:    true
            depth:          1

        @watcher
            .on 'add',    @onFileChange
            .on 'change', @onFileChange
            .on 'error' , (err) -> log 'chokidar error', err
            
    @onFileChange: (p) => 
        log "Cache.@onFileChange #{p}"
        relpath = relative p, @musicDir
        @del relpath
        $(relpath).tile?.fileChanged?()
    
    @watch:   (p) -> @watcher.add p
    @unwatch: () -> @watcher.unwatch '*'
        
    @get:  (key, value) -> @store.get key, value
    @set:  (key, value) -> @store.set key, value
    @del:  (key, value) -> @store.del key
    @save: (cb)         -> @store.save cb
    @prune:             -> @store.clear()

module.exports = Cache
