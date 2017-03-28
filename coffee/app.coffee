#    0000000   00000000   00000000 
#   000   000  000   000  000   000
#   000000000  00000000   00000000 
#   000   000  000        000      
#   000   000  000        000      
{
about,
prefs, 
log}     = require 'kxk'
pkg      = require '../package.json'
MainMenu = require './mainmenu'
_        = require 'lodash'
fs       = require 'fs'
noon     = require 'noon'
colors   = require 'colors'
electron = require 'electron'
childp   = require 'child_process'
app      = electron.app
Browser  = electron.BrowserWindow
Tray     = electron.Tray
Menu     = electron.Menu
ipc      = electron.ipcMain
main     = undefined # < created in app.on 'ready'
tray     = undefined # < created in Main.constructor

#  0000000   00000000    0000000    0000000
# 000   000  000   000  000        000     
# 000000000  0000000    000  0000  0000000 
# 000   000  000   000  000   000       000
# 000   000  000   000   0000000   0000000 

args  = require('karg') """

#{pkg.productName}

    show      . ? open window on startup  . = false
    prefs     . ? show preferences        . = false
    noprefs   . ? don't load preferences  . = false
    verbose   . ? log more                . = false
    DevTools  . ? open developer tools    . = false
    debug     .                             = false
    
version  #{pkg.version}

""", dontExit: true

app.exit 0 if not args?

if args.verbose
    log colors.white.bold "\n#{pkg.productName}", colors.gray "v#{pkg.version}\n"
    log colors.yellow.bold 'process'
    p = cwd: process.cwd()
    log noon.stringify p, colors:true
    log colors.yellow.bold 'args'
    log noon.stringify args, colors:true
    log ''

# 00000000   00000000   00000000  00000000   0000000
# 000   000  000   000  000       000       000     
# 00000000   0000000    0000000   000000    0000000 
# 000        000   000  000       000            000
# 000        000   000  00000000  000       0000000 

prefs.init shortcut: 'F4'

if args.prefs
    log colors.yellow.bold 'prefs'
    log noon.stringify prefs.store, colors:true

# 000   000  000  000   000   0000000
# 000 0 000  000  0000  000  000     
# 000000000  000  000 0 000  0000000 
# 000   000  000  000  0000       000
# 00     00  000  000   000  0000000 

wins        = -> Browser.getAllWindows()
activeWin   = -> Browser.getFocusedWindow()
visibleWins = -> (w for w in wins() when w?.isVisible() and not w?.isMinimized())
winWithID   = (winID) -> Browser.fromId winID

hideDock = -> app.dock.hide() if app.dock

# 000  00000000    0000000
# 000  000   000  000     
# 000  00000000   000     
# 000  000        000     
# 000  000         0000000

ipc.on 'toggleDevTools', (event)        => event.sender.toggleDevTools()
ipc.on 'maximizeWindow', (event, winID) => main.toggleMaximize winWithID winID
ipc.on 'activateWindow', (event, winID) => main.activateWindowWithID winID
ipc.on 'reloadWindow',   (event, winID) => main.reloadWin winWithID winID
                        
# 00     00   0000000   000  000   000
# 000   000  000   000  000  0000  000
# 000000000  000000000  000  000 0 000
# 000 0 000  000   000  000  000  0000
# 000   000  000   000  000  000   000

class Main
    
    constructor: () -> 
        
        if app.makeSingleInstance @otherInstanceStarted
            app.exit 0
            return

        tray = new Tray "#{__dirname}/../img/menu.png"
        tray.on 'click', @toggleWindows
                                
        app.setName pkg.productName
                                
        electron.globalShortcut.register prefs.get('shortcut'), @toggleWindows
            
        @createWindow()

        MainMenu.init @

    # 000   000  000  000   000  0000000     0000000   000   000   0000000
    # 000 0 000  000  0000  000  000   000  000   000  000 0 000  000     
    # 000000000  000  000 0 000  000   000  000   000  000000000  0000000 
    # 000   000  000  000  0000  000   000  000   000  000   000       000
    # 00     00  000  000   000  0000000     0000000   00     00  0000000 

    reloadWin: (win) -> win?.webContents.reloadIgnoringCache()

    toggleMaximize: (win) ->
        if win.isMaximized()
            win.unmaximize() 
        else
            win.maximize()        

    toggleWindows: =>
        if wins().length
            if visibleWins().length
                if activeWin()
                    @hideWindows()
                else
                    @raiseWindows()
            else
                @showWindows()
        else
            args.show = true
            @createWindow()

    hideWindows: =>
        for w in wins()
            w.hide()
            hideDock()
            
    showWindows: =>
        for w in wins()
            w.show()
            app.dock.show()
            
    raiseWindows: =>
        if visibleWins().length
            for w in visibleWins()
                w.showInactive()
            visibleWins()[0].showInactive()
            visibleWins()[0].focus()
    
    closeWindows: =>
        w.close() for w in wins()
        hideDock()
    
    screenSize: -> electron.screen.getPrimaryDisplay().workAreaSize
                    
    #  0000000  00000000   00000000   0000000   000000000  00000000
    # 000       000   000  000       000   000     000     000     
    # 000       0000000    0000000   000000000     000     0000000 
    # 000       000   000  000       000   000     000     000     
    #  0000000  000   000  00000000  000   000     000     00000000
       
    createWindow: () ->
        
        bounds = prefs.get 'bounds', null
        if not bounds
            {w, h} = @screenSize()
            bounds = {}
            bounds.width = h + 122
            bounds.height = h
            bounds.x = parseInt (w-bounds.width)/2
            bounds.y = 0
            
        win = new Browser
            x:               bounds.x
            y:               bounds.y
            width:           bounds.width
            height:          bounds.height
            minWidth:        556
            minHeight:       206
            useContentSize:  true
            fullscreenable:  true
            show:            false
            backgroundColor: '#000'
            titleBarStyle:   'hidden'

        win.loadURL "file://#{__dirname}/index.html"
        app.dock.show()
        win.on 'close',  @onCloseWin
        win.on 'move',   @onMoveWin
        win.on 'resize', @onResizeWin
                               
        winReadyToShow = =>
            if args.show
                win.show()
                win.focus()
                 
                if args.DevTools then win.webContents.openDevTools()
                        
        win.on 'ready-to-show', winReadyToShow
        win 
    
    onMoveWin: (event) => event.sender.webContents.send 'saveBounds'
    
    # 00000000   00000000   0000000  000  0000000  00000000
    # 000   000  000       000       000     000   000     
    # 0000000    0000000   0000000   000    000    0000000 
    # 000   000  000            000  000   000     000     
    # 000   000  00000000  0000000   000  0000000  00000000
    
    onResizeWin: (event) => 
    
    onCloseWin: (event) =>
        if visibleWins().length == 1
            hideDock()
        
    otherInstanceStarted: (args, dir) =>
        if not visibleWins().length
            @toggleWindows()
            
    quit: => 
        @closeWindows()
        app.exit 0
        process.exit 0
        
    showAbout: => about img: "#{__dirname}/../img/about.png", pkg: pkg

#  0000000   00000000   00000000         0000000   000   000
# 000   000  000   000  000   000       000   000  0000  000
# 000000000  00000000   00000000        000   000  000 0 000
# 000   000  000        000        000  000   000  000  0000
# 000   000  000        000        000   0000000   000   000

app.on 'ready', -> main = new Main
app.on 'window-all-closed', ->
    
app.setName pkg.productName

