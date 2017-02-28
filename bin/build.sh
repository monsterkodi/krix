#!/usr/bin/env bash
cd `dirname $0`/..

killall krix
konrad --run

node_modules/electron-packager/cli.js . --overwrite --icon=img/krix.icns #krix --platform=darwin --arch=x64 --prune --app-bundle-id=net.monsterkodi.krix

open krix-darwin-x64/krix.app 
