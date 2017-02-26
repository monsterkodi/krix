# 00000000   00000000   00000000  00000000   0000000
# 000   000  000   000  000       000       000     
# 00000000   0000000    0000000   000000    0000000 
# 000        000   000  000       000            000
# 000        000   000  00000000  000       0000000 

log    = require './tools/log'
nconf  = require 'nconf'
noon   = require 'noon'
path   = require 'path'
mkpath = require 'mkpath'

class Prefs
    
    @file    = null
    @timer   = null
    @timeout = 2000
    
    @init: (file, defs={}) ->
        Prefs.file = file
        nconf.use 'user',
            type: 'file'
            format: 
                parse: noon.parse
                stringify: (o,n,i) -> noon.stringify o, {indent: i, maxalign: 8}
            file: Prefs.file
        nconf.defaults defs

    #  0000000   00000000  000000000          0000000  00000000  000000000
    # 000        000          000      000   000       000          000   
    # 000  0000  0000000      000    0000000 0000000   0000000      000   
    # 000   000  000          000      000        000  000          000   
    #  0000000   00000000     000            0000000   00000000     000   
        
    @get: (key, value) ->
        nconf.get(key) ? value
            
    @set: (key, value) ->
        clearTimeout Prefs.timer if Prefs.timer
        Prefs.timer = setTimeout Prefs.save, Prefs.timeout

        if value?
            nconf.set key, value    
        else
            nconf.clear key
        
    @del: (key, value) -> @set key

    #  0000000   0000000   000   000  00000000
    # 000       000   000  000   000  000     
    # 0000000   000000000   000 000   0000000 
    #      000  000   000     000     000     
    # 0000000   000   000      0      00000000

    @save: (cb) ->
        clearTimeout Prefs.timer if Prefs.timer
        Prefs.timer = null
        mkpath path.dirname(Prefs.file), (err) =>
            if err?
                log "[ERROR] can't mkpath", path.dirname(Prefs.file), err if err?
                cb? !err?
            else
                nconf.save (err) => 
                    log "[ERROR] can't save nconf", Prefs.file, err if err?
                    cb? !err?
        
module.exports = Prefs
