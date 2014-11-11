local lfs= require 'lfs'

local file_system= {}

function file_system.files(path)
    local files= {}
    for entry in lfs.dir(path) do
        if not (entry == '.' or entry == '..') then
            local filename= path .. '/' .. entry
            local mode= lfs.attributes(filename, 'mode')

            if mode == 'directory' then
                for _, file in ipairs(file_system.files(filename)) do
                    table.insert(files, file)
                end
            elseif mode == 'file' then
                table.insert(files, filename)
            end
        end
    end
    return files
end

return file_system
