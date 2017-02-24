#  0000000  000000000  00000000   000    
# 000          000     000   000  000    
# 000          000     0000000    000    
# 000          000     000   000  000    
#  0000000     000     000   000  0000000

post = require './post'
Song = require './song'
log  = require './tools/log'

class Ctrl
    
    constructor: (@view) ->
        
        @elem = document.createElement 'div'
        @elem.style.position = 'absolute'
        @elem.style.top = '0'
        @elem.style.left = '0'
        @elem.style.right = '0'
        @elem.style.height = '200px'
        @elem.style.background = "#222"
        @elem.style.overflow = "hidden"
        @elem.classList.add 'ctrl'
        @view.appendChild @elem

        @song = new Song @elem
        
        @initButtons()


    #   0000000    000   000  000000000  000000000   0000000   000   000   0000000
    #   000   000  000   000     000        000     000   000  0000  000  000     
    #   0000000    000   000     000        000     000   000  000 0 000  0000000 
    #   000   000  000   000     000        000     000   000  000  0000       000
    #   0000000     0000000      000        000      0000000   000   000  0000000 

    initButtons: ->
        
        @buttons = document.createElement 'div'
        @buttons.style.position   = 'absolute'
        @buttons.style.top        = '0'
        @buttons.style.left       = '0'
        @buttons.style.bottom     = '0'
        @buttons.style.width      = '200px'
        @buttons.style.paddingTop = "10px"
        @elem.appendChild @buttons
        
        @button 'prev', -> post.emit 'prevSong'
        @button 'play', @onPlayButton
        @button 'next', -> post.emit 'nextSong'

    button: (name, cb) ->
        bttn = document.createElement 'div'
        bttn.style.background   = "#111"
        bttn.style.padding      = '10px'
        bttn.style.borderRadius = '5px'
        bttn.style.marginRight  = '5px'
        bttn.style.display      = 'inline-block'
        bttn.classList.add 'button'
        bttn.innerHTML = name
        bttn.addEventListener 'click', cb
        @buttons.appendChild bttn

    onPlayButton: =>
        log 'onPlayButton'

    # 000   000  00000000  000   000
    # 000  000   000        000 000 
    # 0000000    0000000     00000  
    # 000  000   000          000   
    # 000   000  00000000     000   
    
    modKeyComboEventDown: (mod, key, combo, event) ->
        switch key
            when 'n' then post.emit 'nextSong'
            when 'p' then post.emit 'prevSong'
        
module.exports = Ctrl
