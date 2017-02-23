#  0000000  000000000  00000000 
# 000          000     000   000
# 0000000      000     0000000  
#      000     000     000   000
# 0000000      000     000   000

noon = require 'noon'

str = (o) ->
    return 'null' if not o?
    if typeof o == 'object'
        if o._str? and typeof(o._str) == 'function'
            o._str()
        else
            s = noon.stringify o, 
                circular: true
            "\n#{s}"
    else
        String o

module.exports = str