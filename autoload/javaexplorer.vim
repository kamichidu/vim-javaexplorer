let s:save_cpo= &cpo
set cpo&vim

let s:V= vital#of('javaexplorer')
let s:BM= s:V.import('Vim.BufferManager')
let s:L= s:V.import('Data.List')
unlet s:V

let s:jc= javaclasspath#get()

let s:indicators= {
\   'root':    {'open': '-', 'close': '+'},
\   'package': {'open': '-', 'close': '+'},
\   'file':    {'open': '-', 'close': '+'},
\}

function! javaexplorer#open()
    if !has_key(t:, 'javaexplorer')
        let t:javaexplorer= {
        \   '__bufman': s:BM.new({'range': 'tabpage', 'opener': 'aboveleft vsplit'}),
        \   'ensure_open': function('javaexplorer#ensure_open'),
        \   'apply_mapping': function('javaexplorer#apply_mapping'),
        \   'display_nodes': function('javaexplorer#display_nodes'),
        \   'collect_nodes': function('javaexplorer#collect_nodes'),
        \   'state': function('javaexplorer#state'),
        \}
    endif

    call t:javaexplorer.ensure_open()
    call t:javaexplorer.apply_mapping()
    call t:javaexplorer.display_nodes()
endfunction

function! javaexplorer#ensure_open() dict
    call self.__bufman.open('-- javaexplorer --')

    setlocal nomodifiable nobuflisted buftype=nofile bufhidden=unload
    setlocal nonumber norelativenumber
    setlocal filetype=javaexplorer

    execute 'vertical resize' 30
endfunction

function! javaexplorer#apply_mapping() dict
    nnoremap <buffer> <Plug>(javaexplorer-quit) :<C-U>close!<CR>
    nnoremap <buffer> <Plug>(javaexplorer-toggle-node) :<C-U>javaexplorer#toggle_state()<CR>
    nnoremap <buffer> <Plug>(javaexplorer-menu) :echo 'menu'<CR>

    if g:javaexplorer_use_default_mapping
        nmap <buffer> q <Plug>(javaexplorer-quit)
        nmap <buffer> o <Plug>(javaexplorer-toggle-node)
        nmap <buffer> m <Plug>(javaexplorer-menu)
    endif
endfunction

function! javaexplorer#display_nodes() dict
    let save_modifiable= &modifiable
    try
        setlocal modifiable

        if !has_key(self, '__nodes')
            let self.__nodes= self.collect_nodes()
        endif

        silent %delete _
        let nodes= self.__nodes
        for node in nodes
            let lines= s:trans_tree_to_lines(node)
            if !empty(lines)
                silent $put =lines
            endif
        endfor
        silent 1delete _
    finally
        let &modifiable= save_modifiable
    endtry
endfunction

function! javaexplorer#collect_nodes() dict
    let paths= s:jc.parse()
    let nodes= []
    for srcpath in filter(copy(paths), 'v:val.kind ==# "src"')
        let relpath= fnamemodify(srcpath.path, ':.')
        let nodes+= [{
        \   'type': 'root',
        \   'state': 'open',
        \   'text': relpath,
        \   'children': s:glob_nodes(relpath),
        \}]
    endfor
    for classpath in filter(copy(paths), 'v:val.kind ==# "lib"')
        let nodes+= [{
        \   'type': 'root',
        \   'state': 'close',
        \   'text': fnamemodify(classpath.path, ':t'),
        \   'children': [],
        \}]
    endfor
    return nodes
endfunction

function! javaexplorer#state(...)
    if a:0 == 0
        return 
    else
    endif
endfunction

function! s:trans_tree_to_lines(node, ...)
    let padding= repeat(' ', get(a:000, 0, 0) * &shiftwidth)

    if a:node.type ==# 'file'
        return [padding . s:indicators[a:node.type][a:node.state] . a:node.text]
    elseif a:node.type ==# 'package' || a:node.type ==# 'root'
        let lines= []
        let lines+= [padding . s:indicators[a:node.type][a:node.state] . a:node.text]
        for child in a:node.children
            let lines+= s:trans_tree_to_lines(child, get(a:000, 0, 0) + 1)
        endfor
        return lines
    else
        return []
    endif
endfunction

function! s:glob_nodes(path)
    let save_cwd= getcwd()
    try
        execute 'lcd' a:path

        let files= s:files('.')
        let items= {}
        for file in files
            let package= tr(fnamemodify(file, ':.:h'), '\/', '..')
            if package ==# '.'
                " default package
                let package= '(default package)'
            endif
            let items[package]= get(items, package, []) + [fnamemodify(file, ':t')]
        endfor
        let nodes= []
        for package in sort(keys(items))
            let children= map(items[package], "{
            \   'type': 'file',
            \   'state': 'close',
            \   'text': v:val,
            \   'children': [],
            \}")
            let nodes+= [{
            \   'type': 'package',
            \   'state': 'close',
            \   'text': package,
            \   'children': s:L.sort(children, 'a:a.text >=# a:b.text'),
            \}]
        endfor
        return nodes
    finally
        execute 'lcd' save_cwd
    endtry
endfunction

function! s:files(path, ...)
    let save_cwd= getcwd()
    try
        execute 'lcd' a:path

        let items= split(glob('*'), "\n")
        let files= map(filter(copy(items), '!isdirectory(v:val)'), 'fnamemodify(v:val, ":p")')
        for dir in filter(copy(items), 'isdirectory(v:val)')
            let files+= s:files(dir)
        endfor
        return files
    finally
        execute 'lcd' save_cwd
    endtry
endfunction

" [0/1, node]
function! s:find_node(node, text)
    if a:node.text ==# a:text
        return [1, a:node]
    else
        for child in a:node.children
            let [found, node]= s:find_node(child, a:text)
            if found
                return [1, node]
            endif
        endfor
        return [0, {}]
    endif
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
