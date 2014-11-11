let s:suite= themis#suite('javaexplorer#node')

function! s:suite.__constructs__()
    let constructs= themis#suite('constructs')

    function! constructs.a_new_object()
        let node= javaexplorer#node#new('data')

        call g:assert.is_dict(node)
        call g:assert.same(node.data(), 'data')
        call g:assert.is_func(node.children)
        call g:assert.equals(node.children(), [])
    endfunction

    function! constructs.a_new_object_with_funcref()
        function! Children()
            return [1, 2, 3]
        endfunction

        let node= javaexplorer#node#new('data', function('Children'))

        call g:assert.is_dict(node)
        call g:assert.same(node.data(), 'data')
        call g:assert.is_func(node.children)
        call g:assert.equals(node.children(), [1, 2, 3])

        delfunction Children
    endfunction

    function! constructs.a_new_object_with_illegal_arguments()
        Throws /^javaexplorer#node:/ javaexplorer#node#new('data', {})
    endfunction
endfunction
