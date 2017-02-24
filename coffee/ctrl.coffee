#  0000000  000000000  00000000   000    
# 000          000     000   000  000    
# 000          000     0000000    000    
# 000          000     000   000  000    
#  0000000     000     000   000  0000000
{
$,
style
}    = require './tools/tools'
log  = require './tools/log'
post = require './post'
Song = require './song'

class Ctrl
    
    constructor: (@view) ->
        
        @elem = document.createElement 'div'
        @elem.style.position   = 'absolute'
        @elem.style.top        = '0'
        @elem.style.left       = '0'
        @elem.style.right      = '0'
        @elem.style.height     = '200px'
        @elem.style.background = "#222"
        @elem.style.overflow   = "hidden"
        @elem.classList.add 'ctrl'
        @view.appendChild @elem

        style '.buttons', """
            position:       absolute;
            bottom:         10px;
            left:           10px;
            width:          200px;
            paddingTop:     10px;
        """    
        style '.button', """
            margin-top:     5px; 
            opacity:        1.0; 
            color:          #fff;
            background:     #111;
            padding:        10px;
            border-radius:  5px;
            margin-right:   5px;
            display:        inline-block;
        """
        style '.button:hover',   "opacity: 0.7"
        style '.buttonActive',   "color: #fa0"
        style '.buttonInactive', "color: #333"
        style "#random", "margin-left: 14px"
        style "#home",   "margin-left: 14px"
        style "#song",   "vertical-align: bottom;"
        style "#length", "vertical-align: top; margin-top: 5px;"
        style '.label',          """
            display:        inline-block;
            border-radius:  5px; 
            margin-left:    10px;
            padding:        5px; 
            background:     rgb(16,16,16); 
            color:          #444
        """
        style "#play", """
            width: 42px;
            margin-bottom: 15px;
        """
        style "#next", """
            width: 30px;
            text-align: center;
        """
        style "#prev", """
            width: 30px;
            text-align: center;
        """
        
        @song = new Song @elem
        
        post.on 'status', @onStatus
        
        @initButtons()

    del: -> @elem.remove()

    #   0000000    000   000  000000000  000000000   0000000   000   000   0000000
    #   000   000  000   000     000        000     000   000  0000  000  000     
    #   0000000    000   000     000        000     000   000  000 0 000  0000000 
    #   000   000  000   000     000        000     000   000  000  0000       000
    #   0000000     0000000      000        000      0000000   000   000  0000000 

    initButtons: ->
        
        @buttons = document.createElement 'div'
        @buttons.classList.add "buttons"
        @elem.appendChild @buttons
        
        @button id: 'prev',   icon: 'step-backward fa-2x', cb: -> post.emit 'prevSong'
        @button id: 'play',   icon: 'play fa-3x',          cb: @onPlayButton
        @button id: 'next',   icon: 'step-forward fa-2x',  cb: -> post.emit 'nextSong'
        @buttons.appendChild document.createElement 'br'
        @button id: 'random', icon: 'random fa-1x',        cb: -> post.emit 'random'
        @button id: 'repeat', icon: 'repeat fa-1x',        cb: -> post.emit 'repeat'
        @label  id: 'song' 
        @buttons.appendChild document.createElement 'br'
        @button id: 'home',   icon: 'home fa-1x',          cb: -> post.emit 'home'
        @button id: 'up',     icon: 'arrow-up fa-1x',      cb: -> post.emit 'up'
        @label  id: 'length' 

    label: (opt) ->
        labl = document.createElement 'div'
        labl.id = opt.id
        labl.classList.add 'label'
        @buttons.appendChild labl
        
    button: (opt) ->
        bttn = document.createElement 'div'
        bttn.id = opt.id
        bttn.classList.add 'button'
        
        if opt.icon
            bttn.innerHTML = "<div class=\"fa fa-#{opt.icon}\"></div>"
        else
            bttn.innerHTML = opt.text or opt.id
            
        bttn.addEventListener 'click', opt.cb if opt.cb?
        @buttons.appendChild bttn

    onPlayButton: => post.emit 'toggle'

    onStatus: (status) =>
        $('random').classList.toggle 'buttonInactive', (status.random == '0')
        $('random').classList.toggle 'buttonActive',   (status.random == '1')
        $('repeat').classList.toggle 'buttonInactive', (status.repeat == '0')
        $('repeat').classList.toggle 'buttonActive',   (status.repeat == '1')
        $('song').innerHTML   = parseInt(status.song)+1
        $('length').innerHTML = status.playlistlength
        
        # log 'status', status
        # log 'state', status.state
        icon = switch status.state
            when 'play' then 'pause'
            when 'pause' then 'play'
            else status.state
        $('play').innerHTML = "<div class=\"fa fa-#{icon} fa-3x\"></div>"

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
