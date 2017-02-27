#!/usr/bin/env bash
cd `dirname $0`/..

konrad --run

node_modules/electron-packager/cli.js . --overwrite #krix --platform=darwin --arch=x64 --prune --app-bundle-id=net.monsterkodi.krix
# --icon=img/krix.icns

open krix-darwin-x64/krix.app 
