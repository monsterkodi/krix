#  0000000  000000000  00000000   000    
# 000          000     000   000  000    
# 000          000     0000000    000    
# 000          000     000   000  000    
#  0000000     000     000   000  0000000
{
style,
$ }  = require './tools/tools'
log  = require './tools/log'
post = require './post'
Song = require './song'
path = require 'path'

class Ctrl
    
    constructor: (@view) ->
        
        @elem = document.createElement 'div'
        @elem.classList.add 'ctrl'
        @view.appendChild @elem
        @song = new Song @elem
        @initButtons()
        post.on 'status', @onStatus
        
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
        @label  id: 'songid', $('song')
        @buttons.appendChild document.createElement 'br'
        @button id: 'home',     icon: 'home fa-1x',          cb: -> post.emit 'home'
        @button id: 'up',       icon: 'arrow-up fa-1x',      cb: -> post.emit 'up'
        @button id: 'playlist', icon: 'bars fa-1x',          cb: => post.emit 'playlist', '', @song.song.file
        @label  id: 'playlistlength', $('playlist')

    label: (opt, parent) ->
        labl = document.createElement 'span'
        labl.id = opt.id
        labl.classList.add 'label'
        labl.classList.add 'highlight'
        parent.appendChild labl
        
    button: (opt) ->
        bttn = document.createElement 'div'
        bttn.id = opt.id
        bttn.classList.add 'button'
        
        if opt.icon
            bttn.innerHTML = "<span class=\"fa fa-#{opt.icon}\"></span>"
        else
            bttn.innerHTML = opt.text or opt.id
            
        bttn.addEventListener 'click', opt.cb if opt.cb?
        @buttons.appendChild bttn

    onPlayButton: => 
        @song.tile?.setFocus() if @state != 'play'
        post.emit 'toggle'

    loadDirOfCurrentSong: ->
        if @song.tile?.file
            post.emit 'loadDir', path.dirname(@song.tile.file), @song.tile.file
        
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

        @state = status.state
        $('play').innerHTML = "<div class=\"fa fa-#{@state} fa-3x\"></div>"

    resized: => @song.resized()

    # 000   000  00000000  000   000
    # 000  000   000        000 000 
    # 0000000    0000000     00000  
    # 000  000   000          000   
    # 000   000  00000000     000   
    
    modKeyComboEventDown: (mod, key, combo, event) ->
        
        switch combo
            when 'n' then post.emit 'nextSong'
            when 'b' then post.emit 'prevSong'
            when 'p' then @onPlayButton()
            when 'f' then @loadDirOfCurrentSong()
                    
        if @song?.tile?.hasFocus()
            switch combo                    
                when 'left', 'right' then post.emit 'seek', key == 'left' and '-20' or '+20'
                when 'command+right' then post.emit 'nextSong'
                when 'command+left'  then post.emit 'prevSong'
                
module.exports = Ctrl
