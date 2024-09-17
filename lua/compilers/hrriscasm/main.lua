hrriscasm = {}
-- Include compiler
mcc.compilers["hrriscasm"] = hrriscasm
local code_path = nil

require("bit")


-- debugin take out in production
local function to_binary(n)
    local binary = ""
    while n > 0 do
        local bit = n % 2  -- Extract the least significant bit
        binary = bit .. binary  -- Append the bit to the left of the binary string
        n = math.floor(n / 2)  -- Shift right by dividing by 2
    end
    return binary ~= "" and binary or "0"  -- Return "0" if the number is 0
end



-- real


local instructions = {
    ["mul"] = {
        operand_c = 2,
        opcode = 0
    },
    ["div"] = {
        operand_c = 2,
        opcode = 1
    },
    ["mod"] = {
        operand_c = 2,
        opcode = 2
    },
    ["add"] = {
        operand_c = 2,
        opcode = 3
    },
    ["sub"] = {
        operand_c = 2,
        opcode = 4
    },
    ["or"] = {
        operand_c = 2,
        opcode = 5
    },
    ["and"] = {
        operand_c = 2,
        opcode = 6
    },
    ["xor"] = {
        operand_c = 2,
        opcode = 7
    },
    ["not"] = {
        operand_c = 1,
        opcode = 8
    },
    ["mov"] = {
        operand_c = 2,
        opcode = 9
    },
    ["set"] = {
        operand_c = 2,
        immediate = true, -- Corrected syntax
        opcode = 10
    },
    ["push"] = {
        operand_c = 1,
        opcode = 11
    },
    ["pop"] = {
        operand_c = 1,
        opcode = 12
    },
    ["cmp"] = {
        operand_c = 2,
        opcode = 13
    },
    ["cmov"] = {
        operand_c = 2,
        opcode = 14
    },
    ["xtn"] = {
        opcode = 15
    },
}

local registers = {
    ["r0"] = 0,
    ["r1"] = 1,
    ["r2"] = 2,
    ["r3"] = 3,
    ["r4"] = 4,
    ["r5"] = 5,
    ["r6"] = 6,
    ["r7"] = 7,
    ["r8"] = 8,
    ["r9"] = 9,
    ["r10"] = 10,
    ["r11"] = 11,
    ["r12"] = 12,
    ["r13"] = 13,
    ["r14"] = 14,
    ["r15"] = 15,
}

local sizes = {
    ["b"] = 1,
    ["w"] = 2,
    ["d"] = 4,
    ["q"] = 8,
}




local function extract_mem(str)
    -- Check if the string starts with '[' and ends with ']'
    if str:match("^%[(.-)%]$") then
        -- Extract and return the content between '[' and ']'
        return str:match("^%[(.-)%]$")
    else
        -- Return nil or an appropriate message if the string does not meet the criteria
        return nil
    end
end


local function compile(src, dest)
    local tokens = hrriscasm.parser.parse(src)
    if tokens == false or tokens == nil then
        return false
    end

    for ln, token in ipairs(tokens) do
        if token[1] then
            local instruction = {
                opcode = 0, 
                oprand = 0,
            }

            -- handel instructions as 2 types, "normal" aka set length and "hm" aka annoying
            if instructions[token[1]] and instructions[token[1]].operand_c == 2 then
                local size = sizes[token[2]]
                if not size then
                    print("Error occered! Line " .. ln .. " has an incorrect size value!")
                    return false
                end
                
                -- or together opcode and size of oprands
                instruction.opcode = bit.bor(bit.lshift(math.log(size, 2), 6), instructions[token[1]].opcode)

                -- Get oprand 1 check if mem ref first then default to reg
                local opr1 = extract_mem(token[3])
                if opr1 then
                    instruction.opcode = bit.bor(bit.lshift(1, 5), instruction.opcode)
                    opr1 = registers[opr1]
                else
                    opr1 = registers[token[3]]
                end
                if opr1 == nil then
                    print("Error occered! Line " .. ln .. " has bad opprand 1!")
                    return false
                end
                instruction.oprand = bit.bor(instruction.oprand, bit.lshift(opr1, 4)) 
                
                -- Get oprand 2 check if mem ref first then default to reg
                local opr2 = extract_mem(token[4])
                if opr2 then
                    instruction.opcode = bit.bor(bit.lshift(1, 4), instruction.opcode)
                    opr2 = registers[opr2]
                else
                    opr2 = registers[token[3]]
                end
                if opr2 == nil then
                    print("Error occered! Line " .. ln .. " has bad opprand 2!")
                    return false
                end
                instruction.oprand = bit.bor(instruction.oprand, opr2) 
            else
                print("hm")
            end
        end
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
