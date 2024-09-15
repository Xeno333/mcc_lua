hrriscasm = {}
-- Include compiler
mcc.compilers["hrriscasm"] = hrriscasm
local code_path = nil



local function compile(src, dest)
    local tokens = hrriscasm.parser.parse(src)
    if tokens == false or tokens == nil then
        return false
    end

    return true
end









function hrriscasm.main(params, path)
    dofile(path .. "parser.lua")

    -- check if params are valid for this compiler
    if params.format ~= "bin" then
        return "Failed: HR-RISC asm compiles to bin, therefore requires format=bin!"
        
    elseif not params.src then
        return "Failed: No source files!"

    elseif not params.dest then
        return "Failed: No destination files!"
    end


    -- init code path
    code_path = path

    if not (#params.dest == 1 or #params.dest == #params.src) then
        return "Failed: Miss-matched amount of destination files to source!"
    
    elseif #params.dest == 1 then
        local dest = params.dest[1]
        for _, src in ipairs(params.src) do
            local retv = compile(src, dest)
            if retv == false then
                return "Failed!"
            end
        end

    elseif #params.dest == #params.src then
        for i, src in ipairs(params.src) do
            local retv = compile(src, params.dest[i])
            if retv == false then
                return "Failed!"
            end
        end

    end


    return "Done!"
end
