# 000  00     00   0000000    0000000
# 000  000   000  000        000     
# 000  000000000  000  0000  0000000 
# 000  000 0 000  000   000       000
# 000  000   000   0000000   0000000 
{
swapExt
}       = require './tools/tools'
log     = require './tools/log'
cache   = require './cache'
fs      = require 'fs'
crypto  = require 'crypto'
fsextra = require 'fs-extra'
path    = require 'path'
childp  = require 'child_process'

class Imgs
            
    @queue = []
    
    @clearQueue: -> @queue = []
    
    @enqueue: (tile) ->
        cover = cache.get "#{tile.file}:cover"
        if cover? 
            if cover
                tile.setCover cover
        else
            @queue.push tile
            @dequeue() if @queue.length == 1
    
    @coverForTile: (tile) -> path.join cache.imgDir, tile.file.hash() + '.jpg'
    @krixForTile:  (tile) -> path.join tile.absFilePath(), '.krix.jpg'
        
    @dequeue: ->
        if @queue.length
            tile = @queue[0]
            coverFile = @coverForTile tile
            fs.stat coverFile, (err, stat) =>
                if err == null and stat.isFile()
                    @imgFound coverFile
                else if tile.isDir()
                    @checkDirForCover()
                @dequeue()
    
    @convertToJPG: (file, cb) ->
        extname = path.extname(file).toLowerCase()
        if extname in ['.gif', '.tif', '.tiff', '.png', '.bmp']
            coverFile = swapExt file, '.jpg'
            childp.exec "/usr/local/bin/convert \"#{file}\" \"#{coverFile}\"", (err) -> cb? err
        else
            log "[ERROR] unknown image format: #{extname}"
    
    @setFileCover: (file, cover, cb) ->
        if cover != cache.get "#{file}:cover"
            cache.set "#{file}:cover", cover
            hash = crypto.createHash 'md5'
            size = 0
            stream = fs.createReadStream cover
            stream.on 'data', (data) -> 
                hash.update data, 'utf8' 
                size += data.length
            stream.on 'end', () -> 
                checksum = hash.digest 'hex'
                cachedCover = cache.hashes.get "_#{checksum}"
                if cachedCover
                    cache.set "#{file}:cover", cachedCover
                    cb cachedCover
                    fs.unlink cover, ->
                else
                    cache.hashes.set "_#{checksum}", cover
                    cb cover
            stream.on 'error', -> 
                log '[ERROR] while reading image for checksum', cover
                cb cover
        else cb cover
        
    @setDirTileImageData: (tile, data) -> 
        if data?.length
            krixFile = @krixForTile tile
            fs.writeFile krixFile, data, (err) =>
                if !err? then @cloneDirTileImage tile
    
    @cloneDirTileImage: (tile) ->
        coverFile = @coverForTile tile
        krixFile  = @krixForTile  tile
        fsextra.copy krixFile, coverFile, (err) ->
            if not err?
                cache.set "#{tile.file}:cover", coverFile
                tile.setCover coverFile
            else
                log "[ERROR] copying #{krixFile} to #{coverFile}: #{err}"
        
    @checkDirForCover: () ->
        if tile = @queue.shift()
            dir = tile.absFilePath()
            coverFile = @coverForTile tile
            krixFile  = @krixForTile  tile
            cache.set "#{tile.file}:cover", false
            fs.readdir dir, (err, files) ->
                if err?
                    log "[ERROR] can't read dir #{dir}"
                    return
                for file in files
                    absFile = path.join dir, file 
                    extname = path.extname(file).toLowerCase()
                    if extname in ['.gif', '.tif', '.tiff', '.png', '.bmp']
                        childp.exec "/usr/local/bin/convert \"#{absFile}\" \"#{krixFile}\"", (err) ->
                            if not err
                                Imgs.cloneDirTileImage tile
                            else
                                log "[ERROR] converting #{absFile} to #{krixFile}: #{err}"
                        return
                    else if extname in ['.jpg', '.jpeg']
                        if file == '.krix.jpg'
                            Imgs.cloneDirTileImage tile
                        else
                            fs.rename absFile, krixFile, (err) ->
                                if not err?
                                    Imgs.cloneDirTileImage tile
                                else
                                    log "[ERROR] moving #{absFile} to #{krixFile}: #{err}"
                        return
        
    @imgFound: (img) ->
        if tile = @queue.shift()
            cache.set "#{tile.file}:cover", img
            tile.setCover img
        
module.exports = Imgs

