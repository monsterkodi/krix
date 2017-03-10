# 000000000   0000000    0000000    0000000
#    000     000   000  000        000     
#    000     000000000  000  0000  0000000 
#    000     000   000  000   000       000
#    000     000   000   0000000   0000000 
{
swapExt,
first,
last
}           = require './tools/tools'
log         = require './tools/log'
imgs        = require './imgs'
cache       = require './cache'
jsmediatags = require 'jsmediatags'
childp      = require 'child_process'
mkpath      = require 'mkpath'
path        = require 'path'
fs          = require 'fs'

class Tags
            
    @queue = []
    
    # @pruneCache: ->
        # for key in Object.keys Tags.cache
            # if not Tags.cache[key].cover?
                # delete Tags.cache[key] 
                # jsonFile = path.join path.dirname(key), ".krix", swapExt path.basename(key), '.json'
                # fs.unlink jsonFile, (err) ->
                    # if err
                        # log "[ERROR] can't remove", jsonFile
            
    @clearQueue: -> @queue = []
    
    @enqueue: (tile) ->
        @queue.push tile
        if @queue.length == 1
            @dequeue()
            
    @dequeue: ->
        if Tags.queue.length
            tile = Tags.queue[0]
            if cache.get tile.file
                # setImmediate Tags.cachedTag 
                Tags.cachedTag()
            else
                jsmediatags.read tile.absFilePath(), onSuccess: Tags.tagLoaded, onError: Tags.tagError

    @cachedTag: ->
        if tile = Tags.queue.shift()
            tile.setTag cache.get tile.file
            Tags.dequeue()
        
    @tagLoaded: (tag) ->
        if tile = Tags.queue.shift()
            if tag.tags.APIC? or tag.tags.picture
                Tags.saveCover tile, tag.tags
            else
                Tags.saveTag tile, tag.tags
                  
    @saveTag: (tile, tag, cover) ->
            
        cache.set "#{tile.file}:artist", tag.artist
        cache.set "#{tile.file}:title", tag.title
        if cover?
            cache.set "#{tile.file}:cover", cover 
            imgs.potentialAlbumCover cover
            tag.cover = cover
        else
            delete tag.cover
        tile.setTag tag
        Tags.dequeue()
    
    @saveCover: (tile, tag) ->

        picture   = first(tag.APIC) ? tag.picture 
        format    = last (picture.format ? picture.data.format).toLowerCase().split '/'
        format    = 'jpg' if format == 'jpeg'
        picExt    = '.' + format
        coverFile = imgs.coverForTile tile
        data      = picture.data.data ? picture.data 
                
        if format == 'jpg'
            log 'saveCover', coverFile
            fs.writeFile coverFile, Buffer.from(data), (err) =>
                if err?
                    log "[ERROR] can't save cover image for", tile.file
                    Tags.saveTag tile, tag
                else
                    Tags.saveTag tile, tag, coverFile
        else        
            tmpFile = path.join process.env.TMPDIR, path.basename swapExt coverFile, picExt
            log 'write tmp image', tmpFile
            fs.writeFile tmpFile, Buffer.from(data), (err) =>
                if err?
                    log "[ERROR] can't save tmp image", tmpFile
                    Tags.saveTag tile, tag
                else
                    childp.exec "convert \"#{tmpFile}\" \"#{coverFile}\"", (err) =>
                        if err?
                            log "[ERROR] can't convert cover for", tile.file
                            Tags.saveTag tile, tag
                        else
                            Tags.saveTag tile, tag, coverFile
                    
    @tagError: (err) ->
        if tile = Tags.queue.shift()
            Tags.dequeue()
        
module.exports = Tags
