let s:suite= themis#suite('javaexplorer#file_system')

function! s:suite.files_fast()
    call g:assert.equals(sort(javaexplorer#file_system#files('./t/fixtures/')), [
    \   './t/fixtures/a',
    \   './t/fixtures/b/c/d',
    \   './t/fixtures/b/e',
    \])
endfunction

function! s:suite.files_pure_vim()
    call g:assert.equals(sort(javaexplorer#file_system#files('./t/fixtures/', {'pure_vim': 1})), [
    \   './t/fixtures/a',
    \   './t/fixtures/b/c/d',
    \   './t/fixtures/b/e',
    \])
endfunction
