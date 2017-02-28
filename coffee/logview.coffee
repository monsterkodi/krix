# 000       0000000    0000000   000   000  000  00000000  000   000
# 000      000   000  000        000   000  000  000       000 0 000
# 000      000   000  000  0000   000 000   000  0000000   000000000
# 000      000   000  000   000     000     000  000       000   000
# 0000000   0000000    0000000       0      000  00000000  00     00

{ $ } = require './tools/tools'

class LogView 

    constructor: (viewElem) -> @view = $(viewElem)

    clear: -> @view.innerHTML = ""                
    
    appendText: (text) -> @view.innerHTML += "<div class=\"logLine\">#{text}</div>"
       
    resized: ->
            
module.exports = LogView