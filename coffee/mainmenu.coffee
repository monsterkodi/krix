# 00     00   0000000   000  000   000  00     00  00000000  000   000  000   000
# 000   000  000   000  000  0000  000  000   000  000       0000  000  000   000
# 000000000  000000000  000  000 0 000  000000000  0000000   000 0 000  000   000
# 000 0 000  000   000  000  000  0000  000 0 000  000       000  0000  000   000
# 000   000  000   000  000  000   000  000   000  00000000  000   000   0000000 
{
unresolve
}     = require './tools/tools'
log   = require './tools/log'
pkg   = require '../package.json'
Menu  = require('electron').Menu

class MainMenu
    
    @init: (main) -> 
        
        Menu.setApplicationMenu Menu.buildFromTemplate [
            
            #   000   000  00000000   000  000   000
            #   000  000   000   000  000   000 000 
            #   0000000    0000000    000    00000  
            #   000  000   000   000  000   000 000 
            #   000   000  000   000  000  000   000
            
            label: pkg.name   
            submenu: [     
                label:       "About #{pkg.productName}"
                click:        main.showAbout
            ,
                type: 'separator'
            ,
                label:       "Hide #{pkg.productName}"
                accelerator: 'Command+H'
                click:       main.hideWindows
            ,
                label:       'Hide Others'
                accelerator: 'Command+Alt+H'
                role:        'hideothers'
            ,
                type: 'separator'
            ,
                label:       'Quit'
                accelerator: 'Command+Q'
                click:       main.quit
            ,
                label:       'Close All Windows And Quit'
                accelerator: 'Command+Alt+Q'
                click:       main.closeWindowsAndQuit
            ]
        ,
            # 000   000  000  000   000  0000000     0000000   000   000
            # 000 0 000  000  0000  000  000   000  000   000  000 0 000
            # 000000000  000  000 0 000  000   000  000   000  000000000
            # 000   000  000  000  0000  000   000  000   000  000   000
            # 00     00  000  000   000  0000000     0000000   00     00
            
            label: 'Window'
            submenu: [
                label:       'Minimize'
                accelerator: 'Alt+Cmd+M'
                click:       (i,win) -> win?.minimize()
            ,
                label:       'Maximize'
                accelerator: 'Cmd+Shift+m'
                click:       (i,win) -> main.toggleMaximize win
            ,
                type: 'separator'
            ,                            
                label:       'Close All Windows'
                accelerator: 'Alt+Cmd+W'
                click:       main.closeWindows
            ,
                label:       'Close Other Windows'
                accelerator: 'CmdOrCtrl+Shift+w'
                click:       main.closeOtherWindows
            ,
                type: 'separator'
            ,                            
                label:       'Bring All to Front'
                accelerator: 'Alt+Cmd+`'
                role:        'front'
            ,
                type: 'separator'
            ,   
                label:       'Reload Window'
                accelerator: 'Ctrl+Alt+Cmd+L'
                click:       (i,win) -> main.reloadWin win
            ,                
                label:       'Toggle FullScreen'
                accelerator: 'Ctrl+Command+Alt+F'
                click:       (i,win) -> win?.setFullScreen !win.isFullScreen()
            ]
        ,        
            # 000   000  00000000  000      00000000 
            # 000   000  000       000      000   000
            # 000000000  0000000   000      00000000 
            # 000   000  000       000      000      
            # 000   000  00000000  0000000  000      
            
            label: 'Help'
            role: 'help'
            submenu: []            
        ]

module.exports = MainMenu
