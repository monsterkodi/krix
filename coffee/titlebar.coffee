# 000000000  000  000000000  000      00000000  0000000     0000000   00000000 
#    000     000     000     000      000       000   000  000   000  000   000
#    000     000     000     000      0000000   0000000    000000000  0000000  
#    000     000     000     000      000       000   000  000   000  000   000
#    000     000     000     0000000  00000000  0000000    000   000  000   000

{$}  = require './tools/tools'
log  = require './tools/log'
post = require './post'

class Titlebar
    
    constructor: () ->
        @elem = $('.titlebar')
        @elem.ondblclick = (event) => 
            win = window.browserWin
            if win?.isMaximized()
                win?.unmaximize() 
            else
                win?.maximize()
                
        post.on 'titleSong', @update

    update: (tag) =>
        @elem.innerHTML = "<span class=\"title\" >#{tag?.artist} ● #{tag?.title}</span>"
       
module.exports = Titlebar
