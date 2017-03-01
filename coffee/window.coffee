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
window.winID  = 1

saveBounds    = -> if window.browserWin? then prefs.set 'bounds', window.browserWin.getBounds()
loadPrefs     = ->
    app = electron.remote.app
    prefs.init "#{app.getPath('appData')}/#{pkg.productName}/#{pkg.productName}.noon"

# 000  00000000    0000000
# 000  000   000  000     
# 000  00000000   000     
# 000  000        000     
# 000  000         0000000

ipc.on 'setWinID', (event, id) => 
    window.winID = id
    window.browserWin = BrowserWindow.fromId id
    loadPrefs()
    window.titlebar = new Titlebar
    window.main     = new Main $('.main')
    window.logview  = new LogView '.logview'
    window.split    = new Split()
    split.on 'split', ->
        window.main.resized()
        window.logview.resized()
    window.split.resized()
        
ipc.on 'saveBounds', saveBounds

# 00000000   00000000   0000000  000  0000000  00000000
# 000   000  000       000       000     000   000     
# 0000000    0000000   0000000   000    000    0000000 
# 000   000  000            000  000   000     000     
# 000   000  00000000  0000000   000  0000000  00000000

screenSize = => electron.screen.getPrimaryDisplay().workAreaSize

window.onresize = ->
    saveBounds()
    window.split.resized()

window.onunload = -> prefs.save()

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
            log '[ERROR] saving screenshot failed', err if err?

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
        when 'f6'                 then return screenShot()
        when 'command+alt+i'      then return ipc.send 'toggleDevTools', winID
        when 'command+alt+k'      then return window.split.toggleLog()
        when 'command+alt+ctrl+k' then return window.split.showOrClearLog()
        