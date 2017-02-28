#  0000000   0000000     0000000   000   000  000000000
# 000   000  000   000  000   000  000   000     000   
# 000000000  0000000    000   000  000   000     000   
# 000   000  000   000  000   000  000   000     000   
# 000   000  0000000     0000000    0000000      000   
{
$}  = require './tools/tools'
log = require './tools/log'
pkg = require "../package.json"

window.openRepoURL = () -> 
    url = pkg.repository.url
    url = url.slice 4 if url.startsWith("git+")
    url = url.slice 0, url.length-4 if url.endsWith(".git")
    require("opener")(url)

log 'about pkg', pkg
$('name').innerHTML    = pkg.productName
$('version').innerHTML = pkg.version