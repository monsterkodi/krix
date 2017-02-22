
#   00000000    0000000    0000000  000000000
#   000   000  000   000  000          000   
#   00000000   000   000  0000000      000   
#   000        000   000       000     000   
#   000         0000000   0000000      000   

EventEmitter = require 'events'

class Post extends EventEmitter
    
    @singleton = null
    
    constructor: () -> Event.singleton = @
    @instance:   () -> Post.singleton or new Post()
        
module.exports = Post.instance()
