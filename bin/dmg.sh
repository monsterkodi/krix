#!/usr/bin/env bash
cd `dirname $0`/..

NAME=`sds -rp productName`
VERSION=`sds -rp version`
VVERSION=v$VERSION

npm rebuild
rm -f $NAME-*.dmg

./node_modules/.bin/appdmg ./bin/dmg.json $NAME-$VVERSION.dmg

open $NAME-$VVERSION.dmg