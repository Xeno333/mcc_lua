cesium = {}
-- Include compiler
mcc.compilers["cesium"] = cesium
local code_path = nil

local header = 
    "#if !(defined __STDC_VERSION__ && __STDC_VERSION__ > 201710L)\n" ..
        "\ttypedef enum {\n"..
            "\t\tfalse = 0,\n" ..
            "\t\ttrue = 1\n" ..
        "\t} bool;\n" ..
    "#endif\n"



local def_var_ids = {
    ["mut"] = true,

    ["i8"]  = "singed char",
    ["i16"] = "singed short",
    ["i32"] = "singed int",
    ["i64"] = "singed long long",

    ["u8"]  = "unsinged char",
    ["u16"] = "unsinged short",
    ["u32"] = "unsinged int",
    ["u64"] = "unsinged long long",

    ["f32"] = "float",
    ["f64"] = "double float",

    ["bool"] = "bool",
    ["enum"] = "enum",
}



local function compile(src, dest)
    local tokens = cesium.parser.parse(src)
    if tokens == false or tokens == nil then
        return false
    end

    local defined = {}
    local csrc_lines = {}

    for _, statment in ipairs(tokens) do
        local line = ""
        if def_var_ids[statment[1]] then
            line = "const "
            local i = 1
            if def_var_ids[statment[1]] == true then
                line = ""
                local i = 2
            end
            line = line .. def_var_ids[statment[i]]
            i = i + 1
            
            for p=i,#statment do
                line = line .. statment[p]
            end
        end

        if line then
            if line ~= "" then
                line = line .. ";"
            end
            csrc_lines[#csrc_lines+1] = line
        end
    end

    for _, line in ipairs(csrc_lines) do
        print(line)
    end

    return true
end









function cesium.main(params, path)
    dofile(path .. "parser.lua")

    -- check if params are valid for this compiler
    if params.format ~= "csrc" then
        return "Failed: Cesium compiles to C, therefore requires format=csrc!"
        
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
