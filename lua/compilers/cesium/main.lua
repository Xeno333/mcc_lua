cesium = {}
-- Include compiler
mlcc.compilers["cesium"] = cesium
local code_path = nil

local header = 
    "#if !(defined __STDC_VERSION__ && __STDC_VERSION__ > 201710L)\n" ..
        "\ttypedef enum {\n"..
            "\t\tfalse = 0,\n" ..
            "\t\ttrue = 1\n" ..
        "\t} bool;\n" ..
    "#endif\n"



local types = {
    ["i8"]  = "signed char",
    ["i16"] = "signed short",
    ["i32"] = "signed int",
    ["i64"] = "signed long long",

    ["u8"]  = "unsigned char",
    ["u16"] = "unsigned short",
    ["u32"] = "unsigned int",
    ["u64"] = "unsigned long long",

    ["f32"] = "float",
    ["f64"] = "double float",

    ["bool"] = "bool",
    ["enum"] = "enum",

    ["mut"] = true
}

local passthrough = {
    [";"] = 1,

    ["{"] = 0,
    ["}"] = 0,
    ["("] = 0,
    [")"] = 0,
    [","] = 0,
    ["*"] = 0,
    ["="] = 0,
    ["!"] = 0,
    ["["] = 0,
    ["]"] = 0,

    ["=="] = 0,
    ["!="] = 0,
    ["<="] = 0,
    [">="] = 0,

    ["true"] = 0,
    ["false"] = 0,
    ["if"] = 0,
    ["else"] = 0,
    ["break"] = 0,
    ["continue"] = 0,
    ["while"] = 0,
    ["return"] = 0,
}

local no_right_space_synt = {
    [";"] = true,
    ["("] = true,
    ["!"] = true,
    ["["] = true,
    ["]"] = true,
}

local no_left_space_synt = {
    [";"] = true,
    [")"] = true,
    [","] = true,
    ["*"] = true,
    ["!"] = true,
    ["["] = true,
    ["]"] = true,
}




local function compile(src, dest, comp_conf)
    local tokens, consts = cesium.parser.parse(src, comp_conf)
    if tokens == false or tokens == nil then
        return false
    end
    local tokens, defined = cesium.tokenizer.tokenize(tokens, comp_conf)




    local c_starter =[[
// ********* Cesium Header *********

typedef enum {false = 0, true = 1} bool;
void cesium_main();

]]

    if not comp_conf.bare_min then
        c_starter = c_starter .. [[

signed int argc = 0;
signed char** args = 0;

int main(signed int argc_passed, signed char** args_passed) {
    args = args_passed;
    argc = argc_passed;
    cesium_main();
}

]]
    end

    c_starter = c_starter .. [[

// ********* End Cesium Header *********

]]


    local errors = {}

    -- [name] = {type, func, temp} temp is for temp holders aka extern or def without code etc
    local csrc_statements = {}

    -- Main loop
    local pos = 0
    while true do
        tokens[pos] = nil
        pos = pos + 1
        if tokens[pos] == nil then break end
        local statement_token = tokens[pos]
        local statement_t = statement_token.type
        local statement_i = statement_token.code
        local depth = statement_token.depth

        local c_statement = {}
        local endl = true

        if statement_t == "c" then
            endl = false
            c_statement = {"\n//********* Start C include *********\n\n" .. statement_i[1] .. "\n// ********* End C include *********"}

        else
            local statement = {}
            for _, v in ipairs(statement_i) do
                if consts[v] then
                    for _, e in ipairs(consts[v]) do
                        statement[#statement+1] = e
                    end
                else
                    statement[#statement+1] = v
                end
            end
            statement_i = nil

            -- Vars
            if types[statement[1]] then
                local i = 2
                if types[statement[1]] ~= true then
                    c_statement[1] = "const"
                    i = 1
                end
                local vtype = types[statement[i]]
                c_statement[#c_statement+1] = vtype
                i = i + 1

                for p=i,#statement do
                    local v = statement[p]
                    c_statement[#c_statement+1] = v
                end

            elseif statement[1] == "loop" then
                --endl = false
                c_statement[1] = "while(true)"
                for i = 2, #statement do
                    c_statement[#c_statement+1] = statement[i]
                end

            -- Funcs
            elseif statement[1] == "func" then
                endl = false
                c_statement[1] = "void"


                local i = 2
                local fname = statement[i]
                if not fname then
                    errors[#errors+1] = "Error: No function name!"
                else
                    c_statement[#c_statement+1] = fname
                end
                i = i + 1

                -- Block start and end
                local endi = #statement
                local block_starts = false
                if statement[#statement] == "{" then
                    endi = endi - 1
                    block_starts = true
                end

                -- Args
                local has_return = false
                local args_l = endi
                if statement[endi-1] == ":" then
                    has_return = true
                    for j = 0, endi do
                        if statement[endi - j] == ")" then
                            args_l = endi - j
                        end
                    end
                    if endi == args_l then
                        errors[#errors+1] = "Error: Bad definition for '" .. fname .. "'!"
                    end
                end

                for p = i, args_l do
                    if passthrough[statement[p]] == 0 then
                        c_statement[#c_statement+1] = statement[p]

                    elseif types[statement[p]] then
                        c_statement[#c_statement+1] = "const"
                        c_statement[#c_statement+1] = types[statement[p]]

                    else
                        c_statement[#c_statement+1] = statement[p]
                        --errors[#errors+1] = "Error: Not ready to handel '" .. statement[p] .. "' in definition of '" .. fname .. "'"
                    end
                end

                -- Return/Type
                if has_return then
                    if types[statement[endi]] and types[statement[endi]] ~= true then
                        c_statement[1] = types[statement[endi]]
                    else
                        errors[#errors+1] = "Error: Invalid return type for '" .. fname .. "'"
                    end
                end

                if block_starts then
                    c_statement[#c_statement+1] = "{"
                end

            elseif defined[statement[1]] then
                for _, v in ipairs(statement) do
                    c_statement[#c_statement+1] = v
                end

            else
                for _, v in ipairs(statement) do
                    if passthrough[v] ~= nil then
                        c_statement[#c_statement+1] = v

                    elseif defined[v] then
                        c_statement[#c_statement+1] = v

                    elseif tonumber(v) ~= nil then
                        c_statement[#c_statement+1] = v

                    else
                        errors[#errors+1] = "Error: " .. v
                    end
                end

            end
        end

        if #c_statement > 0 then
            csrc_statements[#csrc_statements+1] = {
                depth = depth,
                endl = endl,
                c = c_statement
            }
        end
    end


    -- Errors
    if #errors ~= 0 then
        for _, e in ipairs(errors) do
            print(e)
        end

        return false
    end


    local output = c_starter
    local last_indent = 0
    for _, statement in ipairs(csrc_statements) do
        local line = nil

        local last_part = ""
        for _, part in ipairs(statement.c) do
            if line and (not no_left_space_synt[part] and not no_right_space_synt[last_part]) then
                line = line .. " "
            end
            line = (line or "") .. part
            last_part = part
        end
        if statement.endl then
            line = line .. ";"
        end

        local spaceing = ""
        local adj = 0
        if last_indent < statement.depth then
            adj = 1
            spaceing = "\n"
        end
        last_indent = statement.depth
        for i = 2, statement.depth-adj do
            spaceing = spaceing .. "\t"
        end

        output = output .. spaceing .. line .. "\n"
    end

    --print("\n\n" .. output .. "\n")

    local file, err = io.open(dest, "w")
    if not file then
        print("Failed: Error opening file: " .. err)
        return false
    end
    file:write(output)
    file:close()


    return true
end









function cesium.main(params, path)
    dofile(path .. "parser.lua")
    dofile(path .. "tokenizer.lua")

    -- check if params are valid for this compiler
    if params.format ~= "csrc" then
        return "Failed: Cesium compiles to C, therefore requires format=csrc!"
        
    elseif not params.src then
        return "Failed: No source files!"

    elseif not params.dest then
        return "Failed: No destination files!"
    end

    local comp_conf = {}

    if params.bare == "true" then
        comp_conf.bare_min = true
    end


    -- init code path
    code_path = path

    if not (#params.dest == 1 or #params.dest == #params.src) then
        return "Failed: Miss-matched amount of destination files to source!"
    
    elseif #params.dest == 1 then
        local dest = params.dest[1]
        for _, src in ipairs(params.src) do
            local retv = compile(src, dest, comp_conf)
            if retv == false then
                return "Failed!"
            end
        end

    elseif #params.dest == #params.src then
        for i, src in ipairs(params.src) do
            local retv = compile(src, params.dest[i], comp_conf)
            if retv == false then
                return "Failed!"
            end
        end

    end


    return "Done!"
end
