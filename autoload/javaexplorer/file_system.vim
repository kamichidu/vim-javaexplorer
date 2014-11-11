let s:save_cpo= &cpo
set cpo&vim

let s:V= vital#of('javaexplorer')
let s:P= s:V.import('Process')
unlet s:V

let s:sdir= expand('<sfile>:p:h')

function! s:ilua_enabled()
    let res= {}
    lua << ...
    local ok= pcall(function()
        package.path= package.path .. ';' .. vim.eval('s:sdir') .. '/?.lua'

        require 'file_system'
    end)
    vim.eval('res')['can']= ok
...
    return res.can
endfunction
let s:ilua_enabled= has('lua') ? s:ilua_enabled() : 0

function! s:elua_enabled()
    call s:P.system('lua -l lfs -e "os.exit()"')

    return !v:shell_error
endfunction
let s:elua_enabled= executable('lua') ? s:elua_enabled() : 0

function! javaexplorer#file_system#files(path)
    if s:ilua_enabled
        return s:files_ilua(a:path)
    elseif s:elua_enabled
        return s:files_elua(a:path)
    else
        return s:files_vim(a:path)
    endif
endfunction

function! s:files_ilua(path)
    let files= []
    lua << ...
    local fs= require 'file_system'

    local files= vim.eval('files')
    for _, file in ipairs(collect(vim.eval('a:path'))) do
        files:add(file)
    end
...
    return files
endfunction

function! s:files_elua(path)
    let luafile= tempname()
    let outfile= tempname()
    let script= [
    \   printf('package.path= package.path .. ";" .. "%s" .. "/?.lua"', s:sdir),
    \   'local fs= require "file_system"',
    \   '',
    \   printf('local out= io.open("%s", "w")', outfile),
    \   printf('for _, file in ipairs(fs.files("%s")) do', a:path),
    \   '    out:write(file .. "\n")',
    \   'end',
    \   'out:close()',
    \]
    call writefile(script, luafile)
    let procout= s:P.system(printf('lua "%s"', luafile))
    if procout !=# ''
        throw procout
    endif
    return readfile(outfile)
endfunction

function! s:files_vim(path)
    let save_cwd= getcwd()
    try
        execute 'lcd' a:path

        let files= []
        let entries= split(glob('*'), "\n")
        for entry in entries
            let filename= a:path . '/' . entry
            if isdirectory(filename)
                let files+= s:files_vim(filename)
            else
                let files+= [filename]
            endif
        endfor
        return files
    finally
        execute 'lcd' save_cwd
    endtry
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
