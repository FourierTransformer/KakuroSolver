local CSP = require('TableSalt/TableSalt')
local TableSalt = CSP.TableSalt
local Pepper = CSP.Pepper

-- moving on to the sample puzzles!

local function allDiffSum(section, board, sum)
    -- print(sum, #section)
    -- import the bitwise and from luajit...
    local band = bit.band
    local count = 0

    -- Magic code I found/modified that returns the values to remove
    -- http://codegolf.stackexchange.com/questions/35562/kakuro-combinations
    local result = {}
    for mask = 1, 512 do
        local cdigits = #section
        local ctarget = sum
        local bit = 1
        local numbers = {}
        for digit = 1, 9 do
            if band(bit, mask) ~= 0 then
                cdigits = cdigits - 1
                ctarget = ctarget - digit;
            else
                numbers[#numbers + 1] = digit
            end
            bit = bit + bit
        end
        if (ctarget==0 and cdigits == 0) then
            for i = 1, #numbers do
                result[numbers[i]] = true
            end
            count = count + 1
        end
    end

    if count == 0 then return {{}} end

    -- figure out the new domains, by removing the values from the current domain
    newDomains = {}
    for ind = 1, #section do 
        local currentDomain = board:getDomainByID(section[ind])
        local domainSize = #currentDomain
        if domainSize > 1 then

            for i=1, domainSize do
                if result[currentDomain[i]] then
                    currentDomain[i] = nil
                end
            end
            local j = 0;
            for i=1, domainSize do
                if currentDomain[i] then
                    j = j + 1
                    currentDomain[j] = currentDomain[i]
                end
            end
            for i = j+1, domainSize do
                currentDomain[i] = nil
            end

        end
        newDomains[ind] = currentDomain
    end

    -- return the new domains
    return newDomains

end

function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c:gsub("%s+", "") end)
    return fields
end

function string:starts(starts)
   return string.sub(self,1,string.len(starts))==starts
end

function string:ends(ends)
   return string.sub(self,-string.len(ends))==ends
end

-- setup variables to keep track of stuffs
local verticalAdd = {}
local horizontalAdd = {}
local zeros = {}

-- read in line by line
local lineNum = 0
local fieldNum = 0
for line in io.lines("Sample Puzzles/kakuro_wiki.txt") do

    -- remove all spaces
    line = line:gsub("%s+", "")
    if line == "" then break end

    -- increase line count
    lineNum = lineNum + 1

    -- create some arrays
    verticalAdd[lineNum] = {}
    horizontalAdd[lineNum] = {}
    zeros[lineNum] = {}

    -- split on the "|"
    local fields = line:split("|")
    fieldNum = #fields -- I needed the size. kinda gross but meh

    -- go through each segment
    for i = 1, #fields do

        -- 0 means we need to fill it in!
        if fields[i] == "0" then
            zeros[lineNum][i] = "0"

        -- "X\X" DON'T FILL IT IN! we got to go deeper!
        elseif string.find(fields[i], "\\") then

            if fields[i]:match("%d+\\%d+") then
                zeros[lineNum][i] = "X"

                -- BLANK SPACES
                if fields[i] == "0\\0" then
                    --lolz what shhhhhhh
                
                -- starts with "0\" adds horizontally.
                elseif fields[i]:starts("0\\") then
                    horizontalAdd[lineNum][i] = fields[i]:gsub("0\\", "")

                -- ends with "\0" adds vertically
                elseif fields[i]:ends("\\0") then
                    verticalAdd[lineNum][i] = fields[i]:gsub("\\0", "")

                -- adds horizontally and vertically (or error shhhhh)
                else
                    verticalAdd[lineNum][i] = fields[i]:gsub("\\%d+", "")
                    horizontalAdd[lineNum][i] = fields[i]:gsub("%d+\\", "")


                end

            else
                error("invalid puzzle")
            end

        else
            error("Not valid puzzle")
        end
    end
end

local kakuro = TableSalt:new({1,2,3,4,5,6,7,8,9}, fieldNum, lineNum)
print("lineNum", lineNum)
print("fieldNum", fieldNum)

-- print("Zeros")
-- for i = 1, lineNum do
--     print(table.concat(zeros[i], " "))
-- end

for j = 1, lineNum do
    for i = 1, fieldNum do
        local val = horizontalAdd[j][i]
        local section = {}
        if val ~= nil then
            -- print(val)
            local examineI = i + 1
            while (zeros[j][examineI] == "0") do
                section[#section+1] = {examineI, j}
                -- print(examineI, j)
                examineI = examineI + 1
            end
            kakuro:addConstraintByPairs(section, Pepper.allDiff, val)
        end
    end
end

for j = 1, lineNum do
    for i = 1, fieldNum do
        local val = verticalAdd[j][i]
        local section = {}
        if val ~= nil then
            -- print(val)
            local examineJ = j + 1
            while (zeros[examineJ][i] == "0") do
                section[#section+1] = {i, examineJ}
                examineJ = examineJ + 1
                if examineJ > lineNum then
                    break
                end
                -- print(i, examineJ)
            end
            -- print("Size", #section, "Val:", val)
            kakuro:addConstraintByPairs(section, allDiffSum, val)
        end
    end
end

local section = {}
for j = 1, fieldNum do
    for i = 1, lineNum do
        local val = zeros[i][j]
        if val == "X" then
            section[#section+1] = kakuro:getIDByPair(j, i)
        end
    end
end


-- kakuro:addConstraintByPairs(section, Pepper.setVal, "X")
kakuro:addConstraintByIDs(section, Pepper.setVal, "X")

-- kakuro:solveConstraints()
kakuro:solve()
kakuro:print()
-- Debug Output (for when testing single puzzles failing)
for j = 1, 8 do
    for i = 1, 8 do
        local cell = kakuro:getValueByPair(i, j)
        if cell == nil then
            print(kakuro:getIDByPair(i, j), table.concat(kakuro:getDomainByPair(i, j)))
        end
    end
end