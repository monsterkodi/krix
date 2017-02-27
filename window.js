(function() {
  var $, Area, BrowserWindow, LogView, Split, Titlebar, _, delState, electron, fs, getState, ipc, keyinfo, log, logview, main, path, pkg, prefs, ref, remote, screenShot, screenSize, setState, sh, split, sw, titlebar, winID;

  ref = require('./tools/tools'), sw = ref.sw, sh = ref.sh, $ = ref.$;

  Split = require('./split');

  Area = require('./area/area');

  LogView = require('./logview/logview');

  Titlebar = require('./titlebar');

  keyinfo = require('./tools/keyinfo');

  log = require('./tools/log');

  prefs = require('./prefs');

  _ = require('lodash');

  fs = require('fs');

  path = require('path');

  electron = require('electron');

  pkg = require('../package.json');

  ipc = electron.ipcRenderer;

  remote = electron.remote;

  BrowserWindow = remote.BrowserWindow;

  winID = null;

  main = null;

  logview = null;

  setState = window.setState = function(key, value) {
    if (!winID) {
      return;
    }
    if (winID) {
      return prefs.set("windows:" + winID + ":" + key, value);
    }
  };

  getState = window.getState = function(key, value) {
    if (!winID) {
      return value;
    }
    return prefs.get("windows:" + winID + ":" + key, value);
  };

  delState = window.delState = function(key) {
    if (!winID) {
      return;
    }
    return prefs.del("windows:" + winID + ":" + key);
  };

  ipc.on('setWinID', (function(_this) {
    return function(event, id) {
      var ref1;
      winID = window.winID = id;
      return (ref1 = window.split) != null ? ref1.setWinID(id) : void 0;
    };
  })(this));

  titlebar = window.titlebar = new Titlebar;

  split = window.split = new Split();

  split.on('split', (function(_this) {
    return function() {
      main.resized();
      return logview.resized();
    };
  })(this));

  main = window.main = new Main('.main');

  logview = window.logview = new LogView('.logview');

  screenSize = (function(_this) {
    return function() {
      return electron.screen.getPrimaryDisplay().workAreaSize;
    };
  })(this);

  window.onresize = function() {
    split.resized();
    if (winID != null) {
      return ipc.send('saveBounds', winID);
    }
  };

  window.onload = (function(_this) {
    return function() {
      return split.resized();
    };
  })(this);

  screenShot = function() {
    var win;
    win = BrowserWindow.fromId(winID);
    return win.capturePage(function(img) {
      var file;
      file = 'screenShot.png';
      return remote.require('fs').writeFile(file, img.toPng(), function(err) {
        if (err != null) {
          log('saving screenshot failed', err);
        }
        return log("screenshot saved to " + file);
      });
    });
  };

  window.onblur = function(event) {};

  window.onfocus = function(event) {};

  document.onkeydown = function(event) {
    var combo, key, mod, ref1;
    ref1 = keyinfo.forEvent(event), mod = ref1.mod, key = ref1.key, combo = ref1.combo;
    switch (combo) {
      case 'f4':
        return screenShot();
      case 'command+alt+i':
        return ipc.send('toggleDevTools', winID);
      case 'command+alt+k':
        return split.toggleLog();
      case 'command+alt+ctrl+k':
        return split.showOrClearLog();
    }
  };

}).call(this);
