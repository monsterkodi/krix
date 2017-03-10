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
path        = require 'path'
fs          = require 'fs'

class Tags
            
    @queue = []
                
    @clearQueue: -> @queue = []
    
    @enqueue: (tile) ->
        @queue.push tile
        if @queue.length == 1
            @dequeue()
            
    @dequeue: ->
        if Tags.queue.length
            tile = Tags.queue[0]
            if cache.get tile.file
                if tile = Tags.queue.shift()
                    tile.setTag cache.get tile.file
                    Tags.dequeue()
            else
                jsmediatags.read tile.absFilePath(), 
                    onSuccess: Tags.tagLoaded
                    onError:   Tags.tagError

    @tagLoaded: (tag) ->
        if tile = Tags.queue.shift()
            if tag.tags.APIC? or tag.tags.picture
                Tags.saveCover tile, tag.tags
            else
                Tags.setTag tile, tag.tags

    @tagError: (err) ->
        if tile = Tags.queue.shift()
            Tags.dequeue()
                  
    @setTag: (tile, tag, cover) ->
            
        cache.set "#{tile.file}:artist", tag.artist
        cache.set "#{tile.file}:title", tag.title
        if cover?
            cache.set "#{tile.file}:cover", cover 
            
            if not cache.get "#{path.dirname(tile.file)}:cover"
                cache.set "#{path.dirname(tile.file)}:cover", cover
            
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
            fs.writeFile coverFile, Buffer.from(data), (err) =>
                if err?
                    log "[ERROR] can't save cover image for", tile.file
                    Tags.setTag tile, tag
                else
                    Tags.setTag tile, tag, coverFile
        else        
            tmpFile = path.join process.env.TMPDIR, path.basename swapExt coverFile, picExt
            fs.writeFile tmpFile, Buffer.from(data), (err) =>
                if err?
                    log "[ERROR] can't save tmp image", tmpFile
                    Tags.setTag tile, tag
                else
                    childp.exec "convert \"#{tmpFile}\" \"#{coverFile}\"", (err) =>
                        if err?
                            log "[ERROR] can't convert cover for", tile.file
                            Tags.setTag tile, tag
                        else
                            Tags.setTag tile, tag, coverFile
                        fs.unlink tmpFile, ->
                            
module.exports = Tags
