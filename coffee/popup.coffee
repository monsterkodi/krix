# 00000000    0000000   00000000   000   000  00000000 
# 000   000  000   000  000   000  000   000  000   000
# 00000000   000   000  00000000   000   000  00000000 
# 000        000   000  000        000   000  000      
# 000         0000000   000         0000000   000      

log     = require './tools/log'
keyinfo = require './tools/keyinfo'

class Popup
    
    constructor: (opt) ->
        @focus = document.activeElement
        @items = document.createElement 'div'
        @items.classList.add 'popup'
        @items.style.left = "#{opt.x}px"
        @items.style.top  = "#{opt.y}px"
        @items.setAttribute 'tabindex', 3
        
        for item in opt.items
            div = document.createElement 'div'
            div.classList.add 'popupItem'
            div.textContent = item.text
            div.item = item
            div.addEventListener 'click', @onClick
            @items.appendChild div

        @select @items.firstChild
            
        (opt.parent ? document.body).appendChild @items
        
        @items.addEventListener 'keydown',   @onKeyDown
        @items.addEventListener 'focusout',  @onFocusOut
        @items.addEventListener 'mouseover', @onHover
        @items.focus()
        
    select: (item) -> 
        return if not item?
        @selected?.classList.remove 'selected'
        @selected = item
        @selected.classList.add 'selected'
        
    activate: (item) ->
        item.item?.cb?()
        @close()
     
    onHover: (event) => @select event.target   
    onFocusOut: (event) => @close()
    onKeyDown: (event) =>
        {mod, key, combo} = keyinfo.forEvent event
        log 'key down', combo
        switch combo
            when 'enter'        then @activate @selected
            when 'esc', 'space' then @close()
            when 'down'         then @select @selected?.nextSibling
            when 'up'           then @select @selected?.previousSibling
        event.stopPropagation()
     
    onClick: (e) => @activate e.target
        
    close: =>
        @items.remove()
        delete @items
        @focus.focus()
        
module.exports = menu: (opt) -> new Popup opt
