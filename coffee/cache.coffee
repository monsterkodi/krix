#  0000000   0000000    0000000  000   000  00000000
# 000       000   000  000       000   000  000     
# 000       000000000  000       000000000  0000000 
# 000       000   000  000       000   000  000     
#  0000000  000   000   0000000  000   000  00000000
{
relative,
$ }      = require './tools/tools'
log      = require './tools/log'
Store    = require './tools/store'
post     = require './post'
fs       = require 'fs-extra'
path     = require 'path'
chokidar = require 'chokidar'

class Cache
    
    @store    = null
    @hashes   = null
    @imgDir   = null
    @waveDir  = null
    @cacheDir = null
    @musicDir = null

    @init: (@musicDir)   -> 
        
        @cacheDir = path.join @musicDir, '.krix'
        
        @store   = new Store timeout: 2000, file: path.join @cacheDir, 'cache.noon'
        @hashes  = new Store timeout: 2000, file: path.join @cacheDir, 'hashes.noon'
        @imgDir  = path.join @cacheDir, 'img' 
        @waveDir = path.join @cacheDir, 'wave' 
        
        try
            fs.mkdirsSync @imgDir
        catch err
            log "[ERROR] can't create image cache directory #{@imgDir}", err
            @imgDir = null
        try
            fs.mkdirsSync @waveDir
        catch err
            log "[ERROR] can't create wave cache directory @{waveDir}", err
            @waveDir = null
                        
    @onFileChange: (p) => 
        log "Cache.@onFileChange #{p}"
        relpath = relative p, @musicDir
        @del relpath
        post.emit 'update', path.dirname relpath
        $(relpath)?.tile?.fileChanged?()

    @onFileUnlink: (p) => 
        log "Cache.@onFileUnlink #{p}"
        relpath = relative p, @musicDir
        @del relpath
        post.emit 'update', path.dirname relpath
        $(relpath)?.tile?.del?()
    
    @watch: (p) ->
        return
        @unwatch()
        absPath = path.join @musicDir, p
        @watcher = chokidar.watch absPath,
            ignored:        /(^|[\/\\])\../
            ignoreInitial:  true
            usePolling:     false
            useFsEvents:    true
            depth:          1

        @watcher
            .on 'add',    @onFileChange
            .on 'change', @onFileChange
            .on 'unlink', @onFileUnlink
            .on 'error' , (err) -> log 'chokidar error', err
        
        # log 'watch:', absPath, @watcher?.getWatched()
        
    @unwatch: () -> 
        return
        @watcher?.unwatch()
        @watcher?.close()
        delete @watcher
        
    @get:  (key, value) -> @store.get key, value
    @set:  (key, value) -> @store.set key, value
    @del:  (key, value) -> @store.del key
    @save: (cb)         -> @store.save cb
    @prune: (dir)       => 
        for key in Object.keys @store.data
            if key.startsWith dir
                if false == @store.get "#{key}:cover"
                    log "clear #{key}:cover"
                    @store.del "#{key}:cover" 

module.exports = Cache
