#    0000000   00000000   00000000 
#   000   000  000   000  000   000
#   000000000  00000000   00000000 
#   000   000  000        000      
#   000   000  000        000      
{
first,
fileList,
dirExists,
fileExists,
resolve}      = require './tools/tools'
log           = require './tools/log'
pkg           = require '../package.json'
prefs         = require './prefs'
MainMenu      = require './mainmenu'
_             = require 'lodash'
fs            = require 'fs'
noon          = require 'noon'
colors        = require 'colors'
electron      = require 'electron'
childp        = require 'child_process'
app           = electron.app
BrowserWindow = electron.BrowserWindow
Tray          = electron.Tray
Menu          = electron.Menu
ipc           = electron.ipcMain
main          = undefined # < created in app.on 'ready'
tray          = undefined # < created in Main.constructor

#  0000000   00000000    0000000    0000000
# 000   000  000   000  000        000     
# 000000000  0000000    000  0000  0000000 
# 000   000  000   000  000   000       000
# 000   000  000   000   0000000   0000000 

# childp.execSync "syslog -s -l error \"argv: #{process.argv.join ' '}\""

args  = require('karg') """

#{pkg.productName}

    show      . ? open window on startup  . = true
    prefs     . ? show preferences        . = false
    noprefs   . ? don't load preferences  . = false
    verbose   . ? log more                . = false
    DevTools  . ? open developer tools    . = false
    debug     .                             = false
    test      .                             = false
    
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

prefs.init "#{app.getPath('appData')}/#{pkg.productName}/#{pkg.productName}.noon", shortcut: 'F3'

if args.prefs
    log colors.yellow.bold 'prefs'
    if fileExists prefs.path
        log noon.stringify noon.load(prefs.path), colors:true

# 000   000  000  000   000   0000000
# 000 0 000  000  0000  000  000     
# 000000000  000  000 0 000  0000000 
# 000   000  000  000  0000       000
# 00     00  000  000   000  0000000 

wins        = -> BrowserWindow.getAllWindows().sort (a,b) -> a.id - b.id 
activeWin   = -> BrowserWindow.getFocusedWindow()
visibleWins = -> (w for w in wins() when w?.isVisible() and not w?.isMinimized())
winWithID   = (winID) ->
    wid = parseInt winID
    for w in wins()
        return w if w.id == wid

# 0000000     0000000    0000000  000   000
# 000   000  000   000  000       000  000 
# 000   000  000   000  000       0000000  
# 000   000  000   000  000       000  000 
# 0000000     0000000    0000000  000   000

hideDock = ->
    return if prefs.get 'trayOnly', false
    app.dock.hide() if app.dock

# 000  00000000    0000000
# 000  000   000  000     
# 000  00000000   000     
# 000  000        000     
# 000  000         0000000

ipc.on 'toggleDevTools',         (event)         => event.sender.toggleDevTools()
ipc.on 'maximizeWindow',         (event, winID)  => main.toggleMaximize winWithID winID
ipc.on 'activateWindow',         (event, winID)  => main.activateWindowWithID winID
ipc.on 'saveBounds',             (event, winID)  => main.saveWinBounds winWithID winID
ipc.on 'reloadWindow',           (event, winID)  => main.reloadWin winWithID winID
                        
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

        setTimeout @showWindows, 10
        
    # 000   000  000  000   000  0000000     0000000   000   000   0000000
    # 000 0 000  000  0000  000  000   000  000   000  000 0 000  000     
    # 000000000  000  000 0 000  000   000  000   000  000000000  0000000 
    # 000   000  000  000  0000  000   000  000   000  000   000       000
    # 00     00  000  000   000  0000000     0000000   00     00  0000000 

    wins:        wins
    winWithID:   winWithID
    activeWin:   activeWin
    visibleWins: visibleWins
        
    reloadWin: (win) ->
        if win?
            dev = win.webContents.isDevToolsOpened()
            if dev
                win.webContents.closeDevTools()
                setTimeout win.webContents.reloadIgnoringCache, 100
            else
                win.webContents.reloadIgnoringCache()

    toggleMaximize: (win) ->
        if win.isMaximized()
            win.unmaximize() 
        else
            win.maximize()

    saveWinBounds: (win) ->
        prefs.set "windows:#{win.id}:bounds",win.getBounds()

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
    
    closeWindow: (w) => w?.close()
    closeWindows: =>
        for w in wins()
            @closeWindow w
        hideDock()
    
    closeWindowsAndQuit: => 
        @closeWindows()
        @quit()
      
    #  0000000  000000000   0000000    0000000  000   000
    # 000          000     000   000  000       000  000 
    # 0000000      000     000000000  000       0000000  
    #      000     000     000   000  000       000  000 
    # 0000000      000     000   000   0000000  000   000
     
    screenSize: -> electron.screen.getPrimaryDisplay().workAreaSize
    
    # 00000000   00000000   0000000  000000000   0000000   00000000   00000000
    # 000   000  000       000          000     000   000  000   000  000     
    # 0000000    0000000   0000000      000     000   000  0000000    0000000 
    # 000   000  000            000     000     000   000  000   000  000     
    # 000   000  00000000  0000000      000      0000000   000   000  00000000
    
    restoreWin: (state) ->
        w = @createWindow state.file
        w.setBounds state.bounds if state.bounds?
        w.webContents.openDevTools() if state.devTools
        w.showInactive()
        w.focus()
                
    #  0000000  00000000   00000000   0000000   000000000  00000000
    # 000       000   000  000       000   000     000     000     
    # 000       0000000    0000000   000000000     000     0000000 
    # 000       000   000  000       000   000     000     000     
    #  0000000  000   000  00000000  000   000     000     00000000
       
    createWindow: () ->
        
        {width, height} = @screenSize()
        ww = height + 122
        
        win = new BrowserWindow
            x:               parseInt (width-ww)/2
            y:               0
            width:           ww
            height:          height
            minWidth:        140
            minHeight:       130
            useContentSize:  true
            fullscreenable:  true
            show:            true
            hasShadow:       false
            backgroundColor: '#000'
            titleBarStyle:   'hidden'

        win.loadURL "file://#{__dirname}/../index.html"
        app.dock.show()
        win.on 'close',  @onCloseWin
        win.on 'move',   @onMoveWin
        win.on 'resize', @onResizeWin
                
        winReady = => win.webContents.send 'setWinID', win.id
                        
        winLoaded = =>

            # win.showInactive()
            win.show()
            win.focus()
            
            if args.DevTools
                win.webContents.openDevTools()
                        
            saveState = => @saveWinBounds win
                    
            setTimeout saveState, 1000
        
        win.webContents.on 'dom-ready',       winReady
        win.webContents.on 'did-finish-load', winLoaded
        win 
    
    onMoveWin: (event) => @saveWinBounds event.sender
    
    # 00000000   00000000   0000000  000  0000000  00000000
    # 000   000  000       000       000     000   000     
    # 0000000    0000000   0000000   000    000    0000000 
    # 000   000  000            000  000   000     000     
    # 000   000  00000000  0000000   000  0000000  00000000
    
    onResizeWin: (event) => 
    
    onCloseWin: (event) =>
        prefs.del "windows:#{event.sender.id}"
        if visibleWins().length == 1
            hideDock()
        
    otherInstanceStarted: (args, dir) =>
        if not visibleWins().length
            @toggleWindows()
            
    quit: => 
        # prefs.save (ok) =>
            # app.exit 0
            # process.exit 0
        
    #  0000000   0000000     0000000   000   000  000000000
    # 000   000  000   000  000   000  000   000     000   
    # 000000000  0000000    000   000  000   000     000   
    # 000   000  000   000  000   000  000   000     000   
    # 000   000  0000000     0000000    0000000      000   
    
    showAbout: =>    
        cwd = __dirname
        w = new BrowserWindow
            dir:             cwd
            preloadWindow:   true
            resizable:       true
            frame:           true
            show:            true
            center:          true
            backgroundColor: '#333'            
            width:           400
            height:          420
        w.loadURL "file://#{cwd}/../about.html"

    log: -> log (str(s) for s in [].slice.call arguments, 0).join " " if args.verbose
    dbg: -> log (str(s) for s in [].slice.call arguments, 0).join " " if args.debug
            
#  0000000   00000000   00000000         0000000   000   000
# 000   000  000   000  000   000       000   000  0000  000
# 000000000  00000000   00000000        000   000  000 0 000
# 000   000  000        000        000  000   000  000  0000
# 000   000  000        000        000   0000000   000   000

app.on 'activate', (event, hasVisibleWindows) => #log "app.on activate #{hasVisibleWindows}"
app.on 'browser-window-focus', (event, win)   => #log "app.on browser-window-focus #{win.id}"

app.on 'ready', => main = new Main
    
app.on 'window-all-closed', ->
    
app.setName pkg.productName

