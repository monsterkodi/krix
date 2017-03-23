# 00     00   0000000   000  000   000  00     00  00000000  000   000  000   000
# 000   000  000   000  000  0000  000  000   000  000       0000  000  000   000
# 000000000  000000000  000  000 0 000  000000000  0000000   000 0 000  000   000
# 000 0 000  000   000  000  000  0000  000 0 000  000       000  0000  000   000
# 000   000  000   000  000  000   000  000   000  00000000  000   000   0000000 
{
unresolve,
log
}     = require 'kxk'
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
                accelerator: 'Cmd+.'
                click:        main.showAbout
            ,
                type: 'separator'
            ,
                label:       "Hide #{pkg.productName}"
                accelerator: 'Cmd+H'
                click:       main.hideWindows
            ,
                label:       'Hide Others'
                accelerator: 'Cmd+Alt+H'
                role:        'hideothers'
            ,
                type: 'separator'
            ,
                label:       'Quit'
                accelerator: 'Cmd+Q'
                click:       main.quit
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
                label:       'Close Window'
                accelerator: 'Cmd+W'
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
                label:       'Toggle DevTools'
                accelerator: 'Cmd+Alt+I'
                click:       (i,win) -> win?.webContents.openDevTools()
            ,                
                label:       'Toggle FullScreen'
                accelerator: 'Ctrl+Cmd+F'
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
