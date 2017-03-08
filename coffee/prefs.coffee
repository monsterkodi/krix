# 00000000   00000000   00000000  00000000   0000000
# 000   000  000   000  000       000       000     
# 00000000   0000000    0000000   000000    0000000 
# 000        000   000  000       000            000
# 000        000   000  00000000  000       0000000 

log    = require './tools/log'
_      = require 'lodash'
fs     = require 'fs'
noon   = require 'noon'
path   = require 'path'
mkpath = require 'mkpath'
atomic = require 'write-file-atomic'

class Prefs
    
    @data    = {}
    @file    = null
    @timer   = null
    @timeout = 1000
    
    @init: (@file, defs={}) ->
        if fs.existsSync @file
            str = fs.readFileSync @file, 'utf8'
            @data = noon.parse str if str.length
        else
            log "prefs file doesn't exist"
        @data = _.defaults @data, defs

    #  0000000   00000000  000000000          0000000  00000000  000000000
    # 000        000          000      000   000       000          000   
    # 000  0000  0000000      000    0000000 0000000   0000000      000   
    # 000   000  000          000      000        000  000          000   
    #  0000000   00000000     000            0000000   00000000     000   
        
    @get: (key, value) ->
        keypath = key.split ':'
        object = Prefs.data
        while keypath.length
            object = object[keypath.shift()]
            return value if not object?
        object ? value
                
    @set: (key, value) ->
        
        clearTimeout Prefs.timer if Prefs.timer
        Prefs.timer = setTimeout Prefs.save, Prefs.timeout

        keypath = key.split ':'
        object = Prefs.data
        while keypath.length > 1
            k = keypath.shift()
            if not object[k]?
                if not _.isNaN _.parseInt k
                    object = object[k] = []
                else
                    object = object[k] = {}
            else
                object = object[k]
                
        if keypath.length == 1 and object?
            if value
                object[keypath[0]] = value
            else
                delete object[keypath[0]]
                    
    @del: (key, value) -> @set key

    #  0000000   0000000   000   000  00000000
    # 000       000   000  000   000  000     
    # 0000000   000000000   000 000   0000000 
    #      000  000   000     000     000     
    # 0000000   000   000      0      00000000

    @save: (cb) ->
        return if not Prefs.file
        clearTimeout Prefs.timer if Prefs.timer
        Prefs.timer = null
        mkpath path.dirname(Prefs.file), (err) ->
            if err?
                log "[ERROR] can't mkpath", path.dirname(Prefs.file), err if err?
                cb? !err?
            else
                str = noon.stringify Prefs.data, {indent: 2, maxalign: 8}
                atomic Prefs.file, str, (err) ->
                    log "[ERROR] can't save preferences file", Prefs.file, err if err?
                    cb? !err?
        
module.exports = Prefs
