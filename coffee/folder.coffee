# 00000000   0000000   000      0000000    00000000  00000000 
# 000       000   000  000      000   000  000       000   000
# 000000    000   000  000      000   000  0000000   0000000  
# 000       000   000  000      000   000  000       000   000
# 000        0000000   0000000  0000000    00000000  000   000
{
last,
log
}    = require 'kxk'
Tile = require './tile'
walk = require './walk'
path = require 'path'

class Folder extends Tile
    
    constructor: (@file, elem, @opt) ->
        super @file, elem, @opt

    isFile: -> false
    isDir:  -> true

    # 00000000  000   000  00000000    0000000   000   000  0000000  
    # 000        000 000   000   000  000   000  0000  000  000   000
    # 0000000     00000    00000000   000000000  000 0 000  000   000
    # 000        000 000   000        000   000  000  0000  000   000
    # 00000000  000   000  000        000   000  000   000  0000000  

    isExpanded: -> @expanded?

    expand: ->
        return if not @isDir() or @isExpanded() or @isUp()
        @doExpand()
            
    doExpand: =>
        @div.classList.add 'tileExpanded'
        @insertAfter = @div
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
            tile = new Folder dir, @div.parentNode
            tile.setText path.basename(@file), path.basename(dir)
            @addChild tile
            
        @walker.on 'end', =>
            @del() # remove expanded tile when children are loaded
    
    addChild: (child) ->
        @insertAfter.parentNode.insertBefore child.div, @insertAfter.nextSibling
        if @insertAfter == @div
            child.setFocus() if @hasFocus()
            @div.style.display = 'none'
        @insertAfter = child.div
        child.expanded = @file
        
module.exports = Folder
