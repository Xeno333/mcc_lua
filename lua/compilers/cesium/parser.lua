cesium.parser = {}


function cesium.parser.parse(src)
    -- open file and check error
    local file, err = io.open(src, "r")
    if not file then
        print("Failed: Error opening file: " .. err)
        return false
    end

    -- get src file
    local src_code = file:read("*a")

    -- Token table that we will return
    local tokens = {}

    local lines = {""}

    local sep_chars = "()[]{} !><= ~^&| %/-+ * , ?"
    local break_chars = ";\n"
    local quote = false
    local esc = nil
    local c_flag = false

    for i=1,#src_code do
        local c = src_code:sub(i, i)
        if c == "\\" then
            esc = 0
        end 
        if esc and esc > 0 then esc = nil end
        if esc ~= nil then esc = esc + 1 end

        if (not esc) and c == "\"" or c == "'" then
            quote = not quote
        end

        if (not esc) and quote == true then
            lines[#lines] = lines[#lines] .. c

        elseif (not esc) and break_chars:find(c, 1, true) then
            lines[#lines+1] = ""

        else
            lines[#lines] = lines[#lines] .. c
        end
    end

    for _, line in ipairs(lines) do
        print(line)
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

    file:close()

    return tokens
end