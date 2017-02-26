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
                setImmediate -> Tags.tagLoaded Tags.cache[tile.absFilePath()]
            else
                Tags.loadTags tile, (err, tags) ->
                    if tags
                        Tags.tagLoaded tags: tags
                    else
                        jsmediatags.read tile.absFilePath(), onSuccess: Tags.tagLoaded, onError: Tags.tagError
        
    @tagError: (err) =>
        if tile = @queue.shift()
            # log "[ERROR] can't load tag for tile", tile.absFilePath()
            @dequeue()

    @loadTags: (tile, cb) ->
        jsonFile = swapExt path.join(tile.krixDir(), path.basename tile.file), '.json'
        fs.readFile jsonFile, 'utf8', (err, data) ->
            if err?
                cb err
            else
                # log 'got json tags', jsonFile, JSON.parse data
                cb null, JSON.parse data
    
    @saveTag: (tile, tag) ->
        mkpath tile.krixDir(), (err) =>
            if err?
                log "[ERROR] cant create .krix folder for", tile.file
                return
            jsonFile = swapExt path.join(tile.krixDir(), path.basename tile.file), '.json'
            
            t = 
                krix: true
                title: tag.title
                artist: tag.artist
                
            if tag.picture
                t.cover = swapExt jsonFile, '.jpg'
                @saveCover tile, tag
                
            fs.writeFile jsonFile, JSON.stringify(t, null, ' '), (err) ->
                if err?
                    log "[ERROR] cant save tag json for", tile.file
    
    @saveCover: (tile, tag) ->
        coverFile = swapExt path.join(tile.krixDir(), path.basename tile.file), '.jpg'
        format = tag.picture.format.toLowerCase()
        if format.endsWith('jpg') or format.endsWith('jpeg')
            # log 'saveCover', coverFile
            fs.writeFile coverFile, Buffer.from(tag.picture.data), (err) ->
                if err?
                    log '[ERROR] cant save cover jpg for', tile.file
                # else 
                    # log 'cover saved to', coverFile
        else
            picExt = last format.split '/'
            imgSrc = swapExt path.join(tile.krixDir(), path.basename(tile.file)), '.' + picExt
            # log 'convertCover', imgSrc
            fs.writeFile imgSrc, Buffer.from(tag.picture.data), (err) ->
                if err?
                    log '[ERROR] cant save cover jpg for', tile.file
                else
                    # log 'cover to JPG', imgSrc
                    imgs.convertToJPG imgSrc
            
    @tagLoaded: (tag) =>
        if tile = @queue.shift()
            if not tag.tags.krix 
                @saveTag tile, tag.tags
            else
                @cache[tile.absFilePath()] = tag 
            tile.setTag tag
            Tags.dequeue()
            # setTimeout Tags.dequeue, 1
        
module.exports = Tags
