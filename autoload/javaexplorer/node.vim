let s:save_cpo= &cpo
set cpo&vim

"
" Node object notation
" ---
" state - string
" data - any
" children - funcref
"
function! javaexplorer#node#new(data, ...)
    let node= {
    \   '__state': 'close',
    \   '__data': a:data,
    \   'data': function('javaexplorer#node#data'),
    \   'children': get(a:000, 0, []),
    \}

    if type(node.children) == type([])
        let node.__children= node.children
        let node.children= function('javaexplorer#node#children')
    elseif type(node.children) != type(function('tr'))
        throw "javaexplorer#node: Argument `children' must be a funcref or a list."
    endif

    return node
endfunction

function! javaexplorer#node#state(...) dict
    if a:0 == 0
        return self.__state
    else
        let self.__state= a:1
        let recurse= get(a:, 2, 0)

        if recurse || self.__state ==# 'close'
            for child in self.children()
                call child.state(val, recurse)
            endfor
        endif
    endif
endfunction

function! javaexplorer#node#data() dict
    return self.__data
endfunction

function! javaexplorer#node#children() dict
    return self.__children
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
