hrriscasm.parser = {}


function hrriscasm.parser.parse(src)
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

    local break_chars = "\n"
    local quote = false
    local esc = nil

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
    end

    file:close()

    return tokens
end