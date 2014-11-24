local CSP = require('TableSalt')
local TableSalt = CSP.TableSalt
local Pepper = CSP.Pepper
local allDiffSum = require('allDiffSum').allDiffSum
-- moving on to the sample puzzles!

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

function parse(puzzleLocation)
    -- setup variables to keep track of stuffs
    local verticalAdd = {}
    local horizontalAdd = {}
    local zeros = {}
    local values = {}

    -- read in line by line
    local lineNum = 0
    local fieldNum = 0
    for line in io.lines(puzzleLocation) do

        -- remove all spaces
        line = line:gsub("%s+", "")
        if line == "" then break end

        -- increase line count
        lineNum = lineNum + 1

        -- create some arrays
        verticalAdd[lineNum] = {}
        horizontalAdd[lineNum] = {}
        zeros[lineNum] = {}
        values[lineNum] = {}

        -- split on the "|" in each line
        local fields = line:split("|")
        fieldNum = #fields -- I needed the size. kinda gross but meh

        -- go through each segment
        for i = 1, #fields do

            -- generally checking for numbers.
            if fields[i]:len() == 1 then
                
                -- 0 means we need to fill it in!
                if fields[i] == "0" then
                    zeros[lineNum][i] = "0"
                
                -- IT MIGHT BE A NUMBER!
                elseif fields[i]:match("%d") then
                    values[lineNum][i] = fields[i]

                -- whoops...
                else
                    error("Unknown value: " .. fields[i])
                end

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
                print(fields[i])
                error("Not valid puzzle")
            end
        end
    end

    return fieldNum, lineNum, verticalAdd, horizontalAdd, zeros, values

end

function analyze(fieldNum, lineNum, verticalAdd, horizontalAdd, zeros, values)
    local kakuro = TableSalt:new({1,2,3,4,5,6,7,8,9}, fieldNum, lineNum)

    -- determine what things to add in the horzontal direction
    for j = 1, lineNum do
        for i = 1, fieldNum do
            local val = horizontalAdd[j][i]
            local section = {}
            if val ~= nil then
                -- print(val)
                local examineI = i + 1
                while (zeros[j][examineI] == "0" or values[j][examineI]) do
                    section[#section+1] = {examineI, j}
                    -- print(examineI, j)
                    examineI = examineI + 1
                end
                kakuro:addConstraintByPairs(section, allDiffSum, val)
            end
        end
    end

    -- figure out what needs to be added in the vertical direciton
    for j = 1, lineNum do
        for i = 1, fieldNum do
            local val = verticalAdd[j][i]
            local section = {}
            if val ~= nil then
                -- print(val)
                local examineJ = j + 1
                while (zeros[examineJ][i] == "0" or values[examineJ][i]) do
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

    -- fill in the "X"s and values
    local section = {}
    for j = 1, fieldNum do
        for i = 1, lineNum do
            local val = zeros[i][j]
            if val == "X" then
                section[#section+1] = kakuro:addConstraintByIDs({kakuro:getIDByPair(j, i)}, Pepper.setVal, "X")
            end
            val = values[i][j]
            if val then
                kakuro:addConstraintByIDs({kakuro:getIDByPair(j, i)}, Pepper.setVal, tonumber(val))
            end
        end
    end

    return kakuro

end

function solveKakuro(puzzleLocation)
    local start = os.clock()
    local kakuro = analyze(parse(puzzleLocation))
    kakuro:setAddVarsAfterAnyChange(false)
    local analysisTime = os.clock()
    print((analysisTime-start)*1000 .. "ms to load puzzle")
    
    kakuro:solve()
    local solveTime = (os.clock() - analysisTime) * 1000
    print(solveTime .. "ms to solve")
    kakuro:print()

    print("Able to Solve?", kakuro:isSolved())

    return solveTime
end


-- fun scripty variables!
local total = 0
local minTime = math.huge
local maxTime = 0

-- run through it!
for i = 0, 13 do
    print("Kakuro Puzzle", i)
    local time = solveKakuro("Sample Puzzles/kakuro_" .. i ..".txt")
    total = total + time
    if time < minTime then minTime = time end
    if time > maxTime then maxTime = time end
    print("\n\n")
end

-- just some stats!
print("Total Time: " .. total .. "ms", "Average Time: " .. total/14 .. "ms")
print("Longest Duration: " .. maxTime .. "ms", "Smallest Duration: " .. minTime .. "ms")
