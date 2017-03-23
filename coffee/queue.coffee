#  0000000   000   000  00000000  000   000  00000000
# 000   000  000   000  000       000   000  000     
# 000 00 00  000   000  0000000   000   000  0000000 
# 000 0000   000   000  000       000   000  000     
#  00000 00   0000000   00000000   0000000   00000000

queue = (items, opt) ->
    count = opt?.batch ? 1
    while count > 0
        count -= 1
        if item = items.shift()
            r = opt.cb? item
            if r == 'stop'
                return 
        else
            opt.done?()
            return
    opt.batched?()
    if items.length
        fnc = -> queue items, opt
        if not opt?.timeout?
            setImmediate fnc
        else
            setTimeout fnc, opt.timeout

module.exports = queue
