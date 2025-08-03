cesium.parser = {}

local comp = {
    ["="] = true,
    ["!"] = true,
    [">"] = true,
    ["<"] = true
}


function cesium.parser.parse(src, comp_conf)
    local statements_l = mlcc.core.default_parser(src)


    -- Combine some parts into proper tokens
    local statements = {}
    local consts = {}

    local pos = 0
    local comment = false
    while true do
        pos = pos + 1
        local statement_l = statements_l[pos]
        if statement_l == nil then break end

        local statement = {}
        local lskip = false
        local skip = false

        if statement_l[1] == "~" then
            if statement_l[2] == "~" then
                comment = not comment
            end

        elseif comment then
            
        elseif statement_l[1] == "import" then
            local tokens_l = cesium.parser.parse(mlcc.libs_path .. "cesium/" .. string.sub(statement_l[2], 2, -2))
            if tokens_l == false or tokens_l == nil then
                return false
            end

            local tokens_n = {}
            for i = 1, pos-1 do
                tokens_n[#tokens_n+1] = statements_l[i]
            end
            for _, v in ipairs(tokens_l) do
                tokens_n[#tokens_n+1] = v
            end
            for i = pos+1, #statements_l do
                tokens_n[#tokens_n+1] = statements_l[i]
            end

            statements_l = tokens_n
            pos = pos - 1

        else
            for i = 1, #statement_l do
                if not lskip then
                    local v = statement_l[i]

                    if statement_l[i+1] == "=" then
                        if comp[v] then
                            v = v .. "="
                            lskip = true
                        end

                    elseif statement_l[i+1] == "+" and v == "+" then
                        v = "++"
                        lskip = true

                    elseif statement_l[i+1] == "-" and v == "-" then
                        v = "--"
                        lskip = true
                    end

                    statement[#statement+1] = v
                else
                    lskip = false
                end
            end

            statements[#statements+1] = statement
        end
    end

    return statements, consts
end