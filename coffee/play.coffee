
# 00000000   000       0000000   000   000
# 000   000  000      000   000   000 000 
# 00000000   000      000000000    00000  
# 000        000      000   000     000   
# 000        0000000  000   000     000   

log    = require '/Users/kodi/s/ko/js/tools/log'
post   = require './post'
childp = require 'child_process' 

class Play
    
    constructor: () ->
        post.on 'play_file', @playFile
        post.on 'add_file',  @addFile
        
    playFile: (file) =>
        # childp.exec "mpc clear && mpc add \"#{file}\" && mpc play", (err) ->
            # log "play: #{file}"
        childp.exec "mpc clear", (err) ->
            # log 'clear'
            childp.exec "mpc add \"#{file}\"", (err) ->
                # log 'add', file
                childp.exec "mpc play", (err) ->
                    # log 'play'

    addFile: (file) =>
        childp.exec "mpc add \"#{file}\"", (err) ->
            # log 'play: add ', file, err
        
module.exports = Play
