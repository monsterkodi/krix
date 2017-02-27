# 000   000  000  000   000  0000000     0000000   000   000
# 000 0 000  000  0000  000  000   000  000   000  000 0 000
# 000000000  000  000 0 000  000   000  000   000  000000000
# 000   000  000  000  0000  000   000  000   000  000   000
# 00     00  000  000   000  0000000     0000000   00     00
{
sw,sh,$
}           = require './tools/tools'
Split       = require './split'
LogView     = require './logview'
Titlebar    = require './titlebar'
Main        = require './main'
keyinfo     = require './tools/keyinfo'
log         = require './tools/log'
prefs       = require './prefs'
_           = require 'lodash'
fs          = require 'fs'
path        = require 'path'
electron    = require 'electron'
pkg         = require '../package.json'

ipc           = electron.ipcRenderer
remote        = electron.remote
BrowserWindow = remote.BrowserWindow
winID         = null
main          = null
logview       = null

#  0000000  000000000   0000000   000000000  00000000
# 000          000     000   000     000     000     
# 0000000      000     000000000     000     0000000 
#      000     000     000   000     000     000     
# 0000000      000     000   000     000     00000000
   
setState = window.setState = (key, value) ->
    return if not winID
    if winID
        prefs.set "windows:#{winID}:#{key}", value
    
getState = window.getState = (key, value) ->
    return value if not winID
    prefs.get "windows:#{winID}:#{key}", value
    
delState = window.delState = (key) ->
    return if not winID
    prefs.del "windows:#{winID}:#{key}"

# 000  00000000    0000000
# 000  000   000  000     
# 000  00000000   000     
# 000  000        000     
# 000  000         0000000

ipc.on 'setWinID', (event, id) => winID = window.winID = id

#  0000000  00000000   000      000  000000000
# 000       000   000  000      000     000   
# 0000000   00000000   000      000     000   
#      000  000        000      000     000   
# 0000000   000        0000000  000     000   

titlebar = window.titlebar = new Titlebar
main     = window.main     = new Main $('.main')
logview  = window.logview  = new LogView '.logview'
split    = window.split    = new Split()

split.on 'split', =>
    main.resized()
    logview.resized()

# 00000000   00000000   0000000  000  0000000  00000000
# 000   000  000       000       000     000   000     
# 0000000    0000000   0000000   000    000    0000000 
# 000   000  000            000  000   000     000     
# 000   000  00000000  0000000   000  0000000  00000000

screenSize = => electron.screen.getPrimaryDisplay().workAreaSize

window.onresize = ->
    split.resized()
    ipc.send 'saveBounds', winID if winID?

window.onload = => 
    split.resized()
    
# window.onunload = 

# 0000000   0000000  00000000   00000000  00000000  000   000   0000000  000   000   0000000   000000000
#000       000       000   000  000       000       0000  000  000       000   000  000   000     000   
#0000000   000       0000000    0000000   0000000   000 0 000  0000000   000000000  000   000     000   
#     000  000       000   000  000       000       000  0000       000  000   000  000   000     000   
#0000000    0000000  000   000  00000000  00000000  000   000  0000000   000   000   0000000      000   

screenShot = ->
    win = BrowserWindow.fromId winID 
    win.capturePage (img) ->
        file = 'screenShot.png'
        remote.require('fs').writeFile file, img.toPng(), (err) -> 
            log 'saving screenshot failed', err if err?
            log "screenshot saved to #{file}"

# 00000000   0000000    0000000  000   000   0000000
# 000       000   000  000       000   000  000     
# 000000    000   000  000       000   000  0000000 
# 000       000   000  000       000   000       000
# 000        0000000    0000000   0000000   0000000 

window.onblur  = (event) -> 
window.onfocus = (event) -> 
              
# 000   000  00000000  000   000
# 000  000   000        000 000 
# 0000000    0000000     00000  
# 000  000   000          000   
# 000   000  00000000     000   

document.onkeydown = (event) ->
    {mod, key, combo} = keyinfo.forEvent event

    switch combo
        when 'f4'                 then return screenShot()
        when 'command+alt+i'      then return ipc.send 'toggleDevTools', winID
        when 'command+alt+k'      then return split.toggleLog()
        when 'command+alt+ctrl+k' then return split.showOrClearLog()
        