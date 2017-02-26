# 000000000   0000000    0000000    0000000
#    000     000   000  000        000     
#    000     000000000  000  0000  0000000 
#    000     000   000  000   000       000
#    000     000   000   0000000   0000000 
{
swapExt,
last
}           = require './tools/tools'
log         = require './tools/log'
imgs        = require './imgs'
jsmediatags = require 'jsmediatags'
mkpath      = require 'mkpath'
path        = require 'path'
fs          = require 'fs'

class Tags
            
    @cache = {}
    @queue = []
    
    @clearQueue: -> @queue = []
    
    @enqueue: (tile) ->
        @queue.push tile
        if @queue.length == 1
            @dequeue()
            
    @dequeue: ->
        if Tags.queue.length
            tile = Tags.queue[0]
            if Tags.cache[tile.absFilePath()]?
                setImmediate -> Tags.jsonLoaded Tags.cache[tile.absFilePath()]
            else
                Tags.loadJson tile, (err, tag) ->
                    if not err?
                        Tags.jsonLoaded tag
                    else
                        jsmediatags.read tile.absFilePath(), onSuccess: Tags.tagLoaded, onError: Tags.tagError

    @loadJson: (tile, cb) ->
        jsonFile = swapExt path.join(tile.krixDir(), path.basename tile.file), '.json'
        fs.readFile jsonFile, 'utf8', (err, data) =>
            cb err, data? and JSON.parse data

    @jsonLoaded: (tag) ->
        if tile = Tags.queue.shift()
            Tags.cache[tile.absFilePath()] = tag 
            tile.setTag tag
            Tags.dequeue()
        
    @tagLoaded: (tag) ->
        if tile = Tags.queue.shift()
            mkpath tile.krixDir(), (err) =>
                if err?
                    log "[ERROR] can't create .krix folder for", tile.file
                    Tags.dequeue()
                else       
                    if tag.tags.picture
                        Tags.saveCover tile, tag.tags
                    else
                        Tags.saveJson tile, tag.tags
                  
    @saveJson: (tile, tag, cover) ->
                
            jsonFile = swapExt path.join(tile.krixDir(), path.basename tile.file), '.json'
            
            t = 
                title:  tag.title
                artist: tag.artist
                
            t.cover = cover if cover?
        
            fs.writeFile jsonFile, JSON.stringify(t, null, ' '), (err) =>
                log "[ERROR] can't save tag json for", tile.file if err?
            
            tile.setTag t
            Tags.dequeue()
    
    @saveCover: (tile, tag) ->

        format    = tag.picture.format.toLowerCase()
        picExt    = '.' + last format.split '/'
        coverFile = swapExt path.join(tile.krixDir(), path.basename tile.file), picExt
        
        fs.writeFile coverFile, Buffer.from(tag.picture.data), (err) =>
            if err?
                log "[ERROR] can't save cover image for", tile.file
                Tags.saveJson tile, tag
            else
                Tags.saveJson tile, tag, coverFile
            
    @tagError: (err) ->
        if tile = Tags.queue.shift()
            # log "[ERROR] can't load tag for tile", tile.absFilePath()
            Tags.dequeue()
        
module.exports = Tags
