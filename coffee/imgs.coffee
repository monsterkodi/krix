# 000  00     00   0000000    0000000
# 000  000   000  000        000     
# 000  000000000  000  0000  0000000 
# 000  000 0 000  000   000       000
# 000  000   000   0000000   0000000 
{
swapExt
}      = require './tools/tools'
log    = require './tools/log'
fs     = require 'fs'
path   = require 'path'
mkpath = require 'mkpath'
childp = require 'child_process'

class Imgs
            
    @cache = {}
    @queue = []
    
    @pruneCache: -> 
        for key in Object.keys @cache
            delete @cache[key] if @cache[key] == false
    
    @clearQueue: -> @queue = []
    
    @enqueue: (tile) ->
        if @cache[tile.coverFile()]?
            if @cache[tile.coverFile()]
                tile.setCover @cache[tile.coverFile()]
        else
            @queue.push tile
            @dequeue() if @queue.length == 1
            
    @dequeue: ->
        if @queue.length
            tile = @queue[0]
            coverDir = tile.absFilePath()
            coverFile = tile.coverFile()
            fs.stat coverFile, (err, stat) =>
                if err == null and stat.isFile()
                    @imgFound coverFile
                else 
                    @checkDirForCover coverDir, coverFile
                @dequeue()
    
    @convertToJPG: (file, cb) ->
        extname = path.extname(file).toLowerCase()
        if extname in ['.gif', '.tif', '.tiff', '.png', '.bmp']
            coverFile = swapExt file, '.jpg'
            childp.exec "convert \"#{file}\" \"#{coverFile}\"", (err) -> cb? err
    
    @potentialAlbumCover: (coverFile) ->
        albumCover = path.join path.dirname(coverFile), "cover.jpg"
        fs.stat albumCover, (err, stat) =>
            if err
                childp.exec "convert \"#{coverFile}\" \"#{albumCover}\"", (err) -> 
                        
    @checkDirForCover: (dir, coverFile) ->
        if tile = @queue.shift()
            @cache[tile.coverFile()] = false
            fs.readdir dir, (err, files) ->
                if not err
                    for file in files
                        absFile = path.join dir, file 
                        extname = path.extname(file).toLowerCase()
                        if extname in ['.gif', '.tif', '.tiff', '.png', '.bmp']
                            mkpath tile.krixDir(), (err) ->
                                childp.exec "convert \"#{absFile}\" \"#{coverFile}\"", (err) ->
                                    if not err
                                        Imgs.cache[tile.coverFile()] = coverFile
                                        tile.setCover coverFile
                                    else
                                        log '[ERROR] converting', absFile, coverFile, err
                            return
                        else if extname == '.jpg'
                            mkpath tile.krixDir(), (err) ->
                                fs.rename absFile, coverFile, (err) ->
                                    if not err
                                        Imgs.cache[tile.coverFile()] = coverFile
                                        tile.setCover coverFile
                                    else
                                        log '[ERROR] moving', absFile, coverFile, err
                            return
        
    @imgFound: (img) ->
        if tile = @queue.shift()
            @cache[tile.coverFile()] = img
            tile.setCover img
        
module.exports = Imgs

