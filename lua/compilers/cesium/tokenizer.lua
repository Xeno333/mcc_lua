cesium.tokenizer = {}

local def = {
    ["i8"]  = true,
    ["i16"] = true,
    ["i32"] = true,
    ["i64"] = true,

    ["u8"]  = true,
    ["u16"] = true,
    ["u32"] = true,
    ["u64"] = true,

    ["f32"] = true,
    ["f64"] = true,

    ["bool"] = true,
    ["enum"] = true,

    ["mut"] = true,

    ["func"] = true,
}
local valid_def_name_starter = {
    ["a"] = true,
    ["b"] = true,
    ["c"] = true,
    ["d"] = true,
    ["e"] = true,
    ["f"] = true,
    ["g"] = true,
    ["h"] = true,
    ["i"] = true,
    ["j"] = true,
    ["k"] = true,
    ["l"] = true,
    ["m"] = true,
    ["n"] = true,
    ["o"] = true,
    ["p"] = true,
    ["q"] = true,
    ["r"] = true,
    ["s"] = true,
    ["t"] = true,
    ["u"] = true,
    ["v"] = true,
    ["w"] = true,
    ["x"] = true,
    ["y"] = true,
    ["z"] = true,
    ["A"] = true,
    ["B"] = true,
    ["C"] = true,
    ["D"] = true,
    ["E"] = true,
    ["F"] = true,
    ["G"] = true,
    ["H"] = true,
    ["I"] = true,
    ["J"] = true,
    ["K"] = true,
    ["L"] = true,
    ["M"] = true,
    ["N"] = true,
    ["O"] = true,
    ["P"] = true,
    ["Q"] = true,
    ["R"] = true,
    ["S"] = true,
    ["T"] = true,
    ["U"] = true,
    ["V"] = true,
    ["W"] = true,
    ["X"] = true,
    ["Y"] = true,
    ["Z"] = true,
    ["_"] = true
}

local def_cont = {
    ["*"] = true
}

local function press_list(l, max, space)
    local s = ""
    if not max then max = #l end
    for k, v in ipairs(l) do
        s = s .. v
        if k == max then break end
        if space then s = s .. space end
    end
    return s
end

function cesium.tokenizer.tokenize(statements, comp_conf)
    local defined = {}
    local code = {}


    local scope = {"cesium"}
    local scope_c = 0

    local is_c, c_code
    local is_c_started = false
    local skip = false
    for _, statement in ipairs(statements) do
            print(statement[#statement])
        if statement[1] == "c" then
            if string.sub(statement[2], 1, 1) == "\"" or string.sub(statement[2], 1, 1) == "\'" then
                local fn = string.sub(statement[2], 2, -2)
                local file, err = io.open(fn, "r")
                if not file then
                    print("Failed: Error opening file `" .. fn .. "`: " .. err)
                    return false
                end

                -- get src file
                code[#code+1] = {type = "c", code = {file:read("*a") or ""}, scope = new_scope_pressed, depth = #scope}
                file:close()

                skip = true

            else
                scope[1] = ""
                is_c = press_list(scope)
                is_c_started = false
                skip = true

                c_code = ""
            end
        end

        -- Scope
        local new_scope_pressed
        for _, part in ipairs(statement) do
            if part == "{" then
                scope[#scope+1] = "_" .. scope_c
                scope_c = scope_c + 1

            elseif part == "}" then
                scope[#scope] = nil
                if #scope == 0 then
                    print("Error: closed global scope!")
                    return false
                end
            end

            new_scope_pressed = press_list(scope)

            if is_c ~= nil and is_c ~= new_scope_pressed then
                is_c_started = true
            end
        end

        if is_c ~= nil then
            if is_c == new_scope_pressed and is_c_started then             
                is_c = nil
                is_c_started = false
                scope[1] = "cesium"
                code[#code+1] = {type = "c", code = {c_code}, scope = new_scope_pressed, depth = #scope}

            else
                if skip then
                    skip = false
                
                -- C
                else
                    c_code = c_code .. press_list(statement, nil, " ")
                    if string.sub(statement[1], 1, 1) ~= "#" then
                        c_code = c_code .. ";"
                    end
                    c_code = c_code .. "\n"
                end
            end

        else
            if skip then
                skip = false

            -- Cesium
            else
                -- vars
                local skip = false

                if statement[1] == "ref" then
                    skip = true
                    local def_type = {}
                    for i = 3, #statement do
                        def_type[#def_type+1] = statement[i]
                    end
                    defined[statement[2]] = def_type

                else
                    local def_type = {}
                    for _, part in ipairs(statement) do
                        if def[part] or (#def_type > 0 and def_cont[part]) then
                            def_type[#def_type+1] = part

                        elseif #def_type > 0 then
                            if valid_def_name_starter[string.sub(part, 1, 1)] then
                                local d = #scope
                                if def_type[1] == "func" then d = d - 1 end
                                defined[press_list(scope, d) .. "_" .. part] = def_type
                            end
                            def_type = {}

                        else
                            def_type = {}
                        end
                    end
                end

                local statement_n = {}
                for _, part in ipairs(statement) do
                    for i = #scope, 1, -1 do
                        local sc = press_list(scope, i) .. "_" .. part
                        if defined[sc] then
                            part = sc
                        end
                    end
                    statement_n[#statement_n+1] = part
                end

                if not skip then
                    code[#code+1] = {type = "cesium", code = statement_n, scope = new_scope_pressed, depth = #scope}
                end
            end
        end
    end



    --[[elseif statement_l[1] == "const" then
        local t = {}
        for i = 3, #statement_l do
            t[#t+1] = statement_l[i]
        end
        consts[statement_l[2]\] = t]]

    print(mlcc.core.dump(code))

    return code, defined
end