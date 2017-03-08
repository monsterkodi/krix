# 00000000   0000000   000      0000000    00000000  00000000 
# 000       000   000  000      000   000  000       000   000
# 000000    000   000  000      000   000  0000000   0000000  
# 000       000   000  000      000   000  000       000   000
# 000        0000000   0000000  0000000    00000000  000   000

Tile = require './tile'

class Folder extends Tile
    
    constructor: (@file, elem, @opt) ->
        super @file, elem, @opt

    isFile:         -> false
    isDir:          -> true

    # 00000000  000   000  00000000    0000000   000   000  0000000  
    # 000        000 000   000   000  000   000  0000  000  000   000
    # 0000000     00000    00000000   000000000  000 0 000  000   000
    # 000        000 000   000        000   000  000  0000  000   000
    # 00000000  000   000  000        000   000  000   000  0000000  

    isExpanded: -> @children?.length

    expand: ->
        return if not @isDir() or @isExpanded() or @isUp()
        @doExpand()
            
    collapse: ->
        return if not @isDir() or not @isExpanded() or @isUp()
        @doCollapse()

    doExpand: =>
        @div.classList.add 'tileExpanded'
        @children = []
        @walker?.stop()
        @walker = new walk @absFilePath()
        
        @walker.on 'file', (file) =>
            return if not @div.parentNode?
            return if path.basename(file).startsWith '.'
            @addChild new Tile file, @div.parentNode
            
        @walker.on 'directory', (dir) =>
            return if not @div.parentNode?
            dirname = path.basename(dir)
            return if dirname.startsWith('.') or dirname == 'iTunes'
            @addChild new Folder dir, @div.parentNode
            
        @walker.on 'done', =>
            @focusNeighbor 'right' if @hasFocus()
            @del() # remove expanded tile when children are loaded
    
    addChild: (child) ->
        @div.parentNode.insertBefore child.div, last(@children)?.div?.nextSibling or @div.nextSibling
        @children.push child
        
    doCollapse: ->
        @div.classList.remove 'tileExpanded'
        while child = @children?.pop()
            child.del()
        
        
module.exports = Folder
