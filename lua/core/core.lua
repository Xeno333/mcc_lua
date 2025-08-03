mlcc.core = {}

local core = mlcc.core


local sep = "  "
function core.dump(data, depth)
    local output = ""
    if data == nil then return output end

    -- Indentation
    local t_depth = depth or 0
    local tab = ""
    for i = 1, t_depth do
        tab = tab .. sep
    end

    -- Parse
    if type(data) == "table" then
        output = "{\n"

        for k, v in pairs(data) do
            output = output .. tab .. sep .. "[" .. core.dump(k, t_depth + 1) .. "] = " .. core.dump(v, t_depth + 1) .. "\n"
        end

        output = output .. tab .. "}"

    elseif type(data) == "string" then
        output = "\"" .. data .. "\""

    else
        output = tostring(data)
    end


    return output
end

function core.merge(t1, p, t2)
    local t = {}

    for i = 1, p do
        t[#t+1] = t1[i]
    end

    for _, v in ipairs(t2) do
        t[#t+1] = v
    end

    for i = p+1, #t1 do
        t[#t+1] = t1[i]
    end

    return t
end


function core.default_parser(src)
    -- open file and check error
    local file, err = io.open(src, "r")
    if not file then
        print("Failed: Error opening file: " .. err)
        return false
    end

    -- get src file
    local src_code = file:read("*a") or ""
    file:close()

    -- Token table that we will return
    local tokens = {}

    local lines = {""}

    local sep_chars = "()[]{} !><= ~^&| %/-+ * , ?\t"
    local break_chars = ";\n"
    local quote = false
    local esc = 0
    local c_flag = false

    for i=1,#src_code do
        local c = src_code:sub(i, i)
        local skip = false
        if c == "\\" and esc == 0 then
            esc = 1
            skip = true
        end

        if not skip and esc > 0 then
            if c == "n" then
                c = "\\n"
                esc = 0
            elseif c == "\\" then
                c = "\\\\"
                esc = 0
            end
        end

        if not skip and esc > 0 then
            skip = true
            esc = esc - 1
        end

        if not skip then
            if c == "\"" or c == "'" then
                quote = not quote
            end

            if quote == true then
                lines[#lines] = lines[#lines] .. c

            elseif break_chars:find(c, 1, true) then
                lines[#lines+1] = ""

            else
                lines[#lines] = lines[#lines] .. c
            end
        end
    end

    for _, line in ipairs(lines) do
        local tokens_l = {""}
        for i=1,#line do
            local c = line:sub(i, i)
            if c == "\"" or c == "'" then
                quote = not quote
            end

            if quote == true then
                tokens_l[#tokens_l] = tokens_l[#tokens_l] .. c

            elseif sep_chars:find(c, 1, true) then
                tokens_l[#tokens_l+1] = c
                tokens_l[#tokens_l+1] = ""

            else
                tokens_l[#tokens_l] = tokens_l[#tokens_l] .. c
            end
        end
        tokens[#tokens+1] = tokens_l
    end


    -- remove extra blank spaces
    local statements = {}
    for n, statement in pairs(tokens) do
        local tokens_l = {}
        for i, token in pairs(statement) do
            if token ~= "" and token ~= " " and token ~= "\t" then
                tokens_l[#tokens_l+1] = token
            end
        end
        if #tokens_l > 0 then
            statements[#statements+1] = tokens_l
        end
    end

    return statements
end