#!/usr/bin/env bash
cd `dirname $0`/..

NAME=`sds -rp productName`
VERSION=`sds -rp version`
VVERSION=v$VERSION
USER=`sds -rp author`
DMG=$NAME-$VERSION.dmg

# wget https://github.com/aktau/github-release/releases/download/v0.6.2/darwin-amd64-github-release.tar.bz2

./bin/github-release release -s $GH_TOKEN -u $USER -r $NAME -t $VVERSION -n $VVERSION --pre-release
./bin/github-release upload  -s $GH_TOKEN -u $USER -r $NAME -t $VVERSION -n $DMG -f $DMG

