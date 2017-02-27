# 000000000  000  000000000  000      00000000  0000000     0000000   00000000 
#    000     000     000     000      000       000   000  000   000  000   000
#    000     000     000     000      0000000   0000000    000000000  0000000  
#    000     000     000     000      000       000   000  000   000  000   000
#    000     000     000     0000000  00000000  0000000    000   000  000   000
{
unresolve,
clamp,
$}       = require './tools/tools'
log      = require './tools/log'
path     = require 'path'
electron = require 'electron'
ipc      = electron.ipcRenderer

class Titlebar
    
    constructor: () ->
        @elem = $('.titlebar')
        @elem.ondblclick = (event) => ipc.send 'maximizeWindow', window.winID

    update: (info) ->
        if info.file?
            title   = path.basename info.file
            tooltip = unresolve info.file
        else
            title = ''
        ic  = info.focus and " focus" or ""
        id  = "<span class='clickarea'><span class=\"winid #{ic}\">#{info.winID}</span>"
        dc  = info.dirty and " dirty" or "clean"
        dot = info.sticky and "○" or "●"
        db  = "<span class=\"dot #{dc}#{ic}\">#{dot}</span>"
        da  = info.dirty and dot or ""
        txt = id + db 
        if title.length
            txt += "<span class=\"title #{dc}#{ic}\" data-tip=\"#{tooltip}\">#{title} #{da}</span>"
        txt += "</span>"
        @elem.innerHTML = txt
        $('.clickarea', @elem)?.addEventListener 'click', @showList
       
module.exports = Titlebar
