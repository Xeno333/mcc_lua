mcc = {}

mcc.code_path = "lua/"
mcc.compilers = {}


-- Check what system we are running on so we know how to handel paths
is_windows = package.config:sub(1, 1) == "\\" or false

-- convert
function mcc.convert_path(path)
    if is_windows then
        return path:gsub("/", "\\")
    end
    return path
end


dofile(mcc.convert_path(mcc.code_path .. "core/conf.lua"))
dofile(mcc.convert_path(mcc.code_path .. "core/core.lua"))



-- Commands
local function help()
    return "MIT licensed Compiler Collection " .. mcc.conf.version .. 
        "\nUsage: mcc <params>\n" .. 
            "\tParams [key=value]:\n"..
                "\t\t?=<command> [string]\n" .. 
                    "\t\t\thelp\t-Display this help message\n" .. 
                    "\t\t\tcompile\t-Compile code\n" ..

                "\n\t\tlang=<specify languge> [string]\n" .. 
                    "\t\t\tcesium\t-Cesium\n" ..

                "\n\t\tsrc=<source files> [list]\n" ..

                "\n\t\tdst=<destination file> [string]\n" .. 

                "\n\t\tformat=<format of output> [string]\n" ..
                    "\t\t\tcsrc\t-C source file\n" --[[..

                "\n\t\tarch=<architecture> [string]\n" .. 
                    "\t\t\tamd64\t-amd64/x86_64\n"
                    "\t\t\tx86\t-x86\n"]]
end


local function compile(params)
    if params["lang"] and mcc.conf.langs[params["lang"]] then
        local path = mcc.code_path .. "compilers/" .. params["lang"] .. "/"
        dofile(mcc.convert_path(path .."main.lua"))
        return mcc.compilers[params["lang"]].main(params, path)
    end
    return "Error: Failed! No such languge!"
end


-- Table
local requests = {
    ["help"] = help,
    ["compile"] = compile
}




-- Get params
local params = {}

if #arg < 1 then
    print("No args supplied, use 'mcc ?=help' for help.")
end

for _, str in ipairs(arg) do
    local key, value = str:match("^(.-)=(.*)$")
    if key then
        params[key] = value
    else
        print("No key-value pair provided for argument '" .. str .. "'!")
        return false
    end
end


-- Get src files if they exist
if params.src then
    local files = {}
    for item in string.gmatch(params.src, "([^,]+)") do
        files[#files+1] = item
    end
    params.src = files
end

-- Get dest files if they exist
if params.dest then
    local files = {}
    for item in string.gmatch(params.dest, "([^,]+)") do
        files[#files+1] = item
    end
    params.dest = files
end


-- excecute commands

for k, v in pairs(params) do
    if k == "?" then
        if requests[v] then
            print(requests[v](params))
        end
    end
end

return true