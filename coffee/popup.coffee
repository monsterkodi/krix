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
            continue if item.hide
            div = document.createElement 'div'
            div.classList.add 'popupItem'
            div.textContent = item.text
            div.item = item
            div.addEventListener 'click', @onClick
            if item.combo?
                combo = document.createElement 'span'
                combo.classList.add 'popupCombo'
                combo.textContent = item.combo
                div.appendChild combo
            @items.appendChild div

        @select @items.firstChild
            
        (opt.parent ? document.body).appendChild @items
        
        @items.addEventListener 'keydown',   @onKeyDown
        @items.addEventListener 'focusout',  @onFocusOut
        @items.addEventListener 'mouseover', @onHover
        @items.focus()
        
    close: =>
        @items?.removeEventListener 'keydown',   @onKeyDown
        @items?.removeEventListener 'focusout',  @onFocusOut
        @items?.removeEventListener 'mouseover', @onHover
        @items?.remove()
        delete @items
        @focus.focus()

    select: (item) -> 
        return if not item?
        @selected?.classList.remove 'selected'
        @selected = item
        @selected.classList.add 'selected'
        
    activate: (item) ->
        @close()
        item.item?.cb?(item.item.arg ? item.item.text)
     
    onHover: (event) => @select event.target   
    onFocusOut: (event) => @close()
    onKeyDown: (event) =>
        {mod, key, combo} = keyinfo.forEvent event
        switch combo
            when 'end', 'page down' then @select @items.lastChild
            when 'home', 'page up'  then @select @items.firstChild
            when 'enter'            then @activate @selected
            when 'esc', 'space'     then @close()
            when 'down'             then @select @selected?.nextSibling
            when 'up'               then @select @selected?.previousSibling ? @items.lastChild 
        event.stopPropagation()
     
    onClick: (e) => @activate e.target
        
module.exports = menu: (opt) -> new Popup opt
