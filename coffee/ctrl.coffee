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
            color:          #444;
            background:     #111;
            padding:        10px;
            border-radius:  5px;
            margin-right:   5px;
            display:        inline-block;
        """
        style '.button:hover',   "color: #fff"
        style '.button:active',  "background: #222"
        style '.buttonActive',   "color: #fa0"
        style '.buttonInactive', "color: #444"
        style "#random", "margin-left: 14px"
        style "#home",   "margin-left: 14px;"
        style "#song",   "vertical-align: bottom;"
        style "#length", "vertical-align: top; margin-top: 5px;"
        style '.label',          """
            display:        inline-block;
            margin-left:    10px;
            padding:        0; 
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
        
        style "@keyframes highlight", """
            0%,100%   {color: rgb(16,16,16);}
            50%  {color: rgb(255,255,255);}
        """
        style ".highlight", """
            animation: highlight 1.5s;
            animation-timing-function: ease-in;
            animation-iteration-count: 1;
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
        
        @button id: 'prev',     icon: 'step-backward fa-2x', cb: -> post.emit 'prevSong'
        @button id: 'play',     icon: 'play fa-3x',          cb: @onPlayButton
        @button id: 'next',     icon: 'step-forward fa-2x',  cb: -> post.emit 'nextSong'
        @buttons.appendChild document.createElement 'br'
        @button id: 'random',   icon: 'random fa-1x',        cb: -> post.emit 'random'
        @button id: 'repeat',   icon: 'repeat fa-1x',        cb: -> post.emit 'repeat'
        @button id: 'song',     icon: 'music fa-1x',         cb: => post.emit 'song', @song.song
        @label id: 'songid', $('song')
        @buttons.appendChild document.createElement 'br'
        @button id: 'home',     icon: 'home fa-1x',          cb: -> post.emit 'home'
        @button id: 'up',       icon: 'arrow-up fa-1x',      cb: -> post.emit 'up'
        @button id: 'playlist', icon: 'bars fa-1x',          cb: => post.emit 'playlist', @song.song
        @label id: 'playlistlength', $('playlist')

    label: (opt, parent) ->
        labl = document.createElement 'div'
        labl.id = opt.id
        labl.classList.add 'label'
        labl.classList.add 'highlight'
        parent.appendChild labl
        
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
        
        if parseInt($('songid').innerHTML) != parseInt(status.song)+1
            node = $('songid')
            clone = node.cloneNode true
            num = parseInt(status.song)+1
            num = 0 if Number.isNaN num
            clone.innerHTML = num
            node.parentNode.replaceChild clone, node
        
        if parseInt($('playlistlength').innerHTML) != parseInt(status.playlistlength)
            node = $('playlistlength')
            clone = node.cloneNode true
            clone.innerHTML = status.playlistlength
            node.parentNode.replaceChild clone, node

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
        switch combo
            when 'n' then post.emit 'nextSong'
            when 'p' then post.emit 'prevSong'
        
module.exports = Ctrl
