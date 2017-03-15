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
                    if cache.get("#{tile.file}:cover") and false == cache.get "#{path.dirname tile.file}:cover"
                        cache.set "#{path.dirname tile.file}:cover", cache.get "#{tile.file}:cover"
            else
                readTags = ->
                    jsmediatags.read tile.absFilePath(), 
                        onSuccess: Tags.tagLoaded
                        onError:   Tags.tagError
                setTimeout readTags, 100

    @tagLoaded: (tag) ->
        if tile = Tags.queue.shift()
            if tag.tags.APIC? or tag.tags.picture
                Tags.saveCover tile, tag.tags
            else
                Tags.setTag tile, tag.tags

    @tagError: (err) ->
        if tile = Tags.queue.shift()
            Tags.dequeue()
                      
    @saveCover: (tile, tag) ->

        picture   = first(tag.APIC) ? tag.picture 
        format    = last (picture.format ? picture.data.format).toLowerCase().split '/'
        format    = 'jpg' if format == 'jpeg'
        picExt    = '.' + format
        data      = picture.data.data ? picture.data 
        coverFile = imgs.coverForTile tile
                
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
                    childp.exec "/usr/local/bin/convert \"#{tmpFile}\" \"#{coverFile}\"", (err) =>
                        if err?
                            log "[ERROR] can't convert cover for", tile.file
                            log "        \"#{tmpFile}\" -> \"#{coverFile}\""
                            Tags.setTag tile, tag
                        else
                            Tags.setTag tile, tag, coverFile
                        fs.unlink tmpFile, ->

    @saveJpgData: (tile, jpgData) ->
        coverFile = imgs.coverForTile tile   
        fs.writeFile coverFile, Buffer.from(jpgData), (err) =>
            if err?
                log "[ERROR] can't save jpg image for", tile.file
            else
                imgs.setFileCover tile.file, coverFile, (coverHash) -> 
                    tile.setCover imgs.coverForHash coverHash
                    if false == cache.get "#{path.dirname tile.file}:cover"
                        cache.set "#{path.dirname tile.file}:cover", coverHash
    
    @setTag: (tile, tag, coverFile) ->
            
        cache.set "#{tile.file}:artist", tag.artist
        cache.set "#{tile.file}:title",  tag.title
        if coverFile?
            imgs.setFileCover tile.file, coverFile, (coverHash) -> 
                tag.cover = coverHash
                tile.setTag tag
                Tags.dequeue()
                if false == cache.get "#{path.dirname tile.file}:cover"
                    cache.set "#{path.dirname tile.file}:cover", coverHash
        else
            delete tag.cover
            tile.setTag tag
            Tags.dequeue()
                            
module.exports = Tags
