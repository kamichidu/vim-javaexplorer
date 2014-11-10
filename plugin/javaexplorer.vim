if exists('g:loaded_javaexplorer') && g:loaded_javaexplorer
    finish
endif
let g:loaded_javaexplorer= 1

let s:save_cpo= &cpo
set cpo&vim

let g:javaexplorer_use_default_mapping= get(g:, 'javaexplorer_use_default_mapping', 1)

command!
\   JavaExplorer
\   call javaexplorer#open()

let &cpo= s:save_cpo
unlet s:save_cpo
