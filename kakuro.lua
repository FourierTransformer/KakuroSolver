local CSP = require('TableSalt/TableSalt')
local TableSalt = CSP.TableSalt
local Pepper = CSP.Pepper

-- going to start with http://en.wikipedia.org/wiki/File:Kakuro_black_box.svg 

local function allDiffSum(section, board, sum)
    local maxLookup = {1, 3, 6, 10, 15, 21, 28, 36, 45}
    local maxDomainLookup = { {2, 3, 4, 5, 6, 7, 8, 9}, {3, 4, 5, 6, 7, 8, 9}, {4, 5, 6, 7, 8, 9},
        {5, 6, 7, 8, 9}, {6, 7, 8, 9}, {7, 8, 9}, {8, 9}, {9}, {}
    }
    local minLookup = {9, 17, 24, 30, 35, 39, 42, 44, 45}
    local minDomainLookup = { {}, {1}, {1, 2}, {1, 2, 3}, {1, 2, 3, 4}, {1, 2, 3, 4, 5}, 
        {1, 2, 3, 4, 5, 6}, {1, 2, 3, 4, 5, 6, 7}, {1, 2, 3, 4, 5, 6, 7, 8}, {1, 2, 3, 4, 5, 6, 7, 8, 9}
    }
    local reverseValuesToRemove = {}
    local sum = sum
    local emptyCells = #section
    local lastID = math.huge

    local valuesToRemove = {}
    local newDomains = {}
    local reverseValuesToRemove = {}

    -- determine which values have been set
    for i, v in ipairs(section) do
        local currentValue = board:getValueByID(v)
        if currentValue ~= nil then
            if reverseValuesToRemove[currentValue] == true then
                return {{}}
            else
                reverseValuesToRemove[currentValue] = true
                table.insert(valuesToRemove, currentValue)
                sum = sum - currentValue
                emptyCells = emptyCells - 1
                newDomains[i] = {currentValue}
            end
        else
            lastID = i
        end
    end

    if emptyCells <= 0 then
        if sum ~= 0 then
            return {{}}
        end
    elseif emptyCells > 1 then
        local lookup = sum - maxLookup[(emptyCells - 1)]
        local removeIt = {}
        if lookup < 9 then
            removeIt = maxDomainLookup[lookup]
        else
            lookup = sum - minLookup[(emptyCells - 1)]
            if lookup > 1 then
                removeIt = minDomainLookup[lookup]
            else
                removeIt = minDomainLookup[1]
            end
        end
        if removeIt ~= nil then
            for i = 1, #removeIt do
                table.insert(valuesToRemove, removeIt[i])
            end
        end
    end

    -- remove those values from the domain of the others
    for ind, w in ipairs(section) do
        local currentValue = board:getValueByID(w)
        local currentDomain = board:getDomainByID(w)
        if newDomains[ind] == nil then
            local indicesToRemove = {}
            for i, v in ipairs(currentDomain) do
                for j, t in ipairs(valuesToRemove) do
                    if v == t then
                        indicesToRemove[ #indicesToRemove+1 ] = i
                    end
                end
            end

            for i = #indicesToRemove, 1, -1 do
                table.remove(currentDomain, indicesToRemove[i])
            end
            newDomains[ind] = currentDomain
        end
    end

    return newDomains

end

local kakuro = TableSalt:new({1, 2, 3, 4, 5, 6, 7, 8, 9}, 7, 7)

-- something quick to get the id numbers...
-- print("Just the numbers")
-- for i = 1, 7 do
--     local row = ""
--     for j = 1, 7 do
--         row = row .. string.format("%2d", j+(i-1)*7) .. " "
--     end
--     print(row)
-- end
-- print("\n")

-- HARD MODE HARD CODE.
-- Vertical constraints
kakuro:addConstraintByIDs({1, 8, 15}, allDiffSum, 23)
kakuro:addConstraintByIDs({36, 43}, allDiffSum, 11)
kakuro:addConstraintByIDs({2, 9, 16, 23}, allDiffSum, 30)
kakuro:addConstraintByIDs({37, 44}, allDiffSum, 10)
kakuro:addConstraintByIDs({17, 24, 31, 38, 45}, allDiffSum, 15)
kakuro:addConstraintByIDs({11, 18}, allDiffSum, 17)
kakuro:addConstraintByIDs({32, 39}, allDiffSum, 7)
kakuro:addConstraintByIDs({5, 12, 19, 26, 33}, allDiffSum, 27)
kakuro:addConstraintByIDs({6, 13}, allDiffSum, 12) --THIS IS THE ONE!!!!!!!!!!!!!
kakuro:addConstraintByIDs({27, 34, 41, 48}, allDiffSum, 12)
kakuro:addConstraintByIDs({7, 14}, allDiffSum, 16)
kakuro:addConstraintByIDs({35, 42, 49}, allDiffSum, 7)

-- Horizontal constraints
kakuro:addConstraintByIDs({1, 2}, allDiffSum, 16)
kakuro:addConstraintByIDs({5, 6, 7}, allDiffSum, 24)
kakuro:addConstraintByIDs({8, 9}, allDiffSum, 17)
kakuro:addConstraintByIDs({11, 12, 13, 14}, allDiffSum, 29)
kakuro:addConstraintByIDs({15, 16, 17, 18, 19}, allDiffSum, 35)
kakuro:addConstraintByIDs({23, 24}, allDiffSum, 7)
kakuro:addConstraintByIDs({26, 27}, allDiffSum, 8)
kakuro:addConstraintByIDs({31, 32, 33, 34, 35}, allDiffSum, 16)
kakuro:addConstraintByIDs({36, 37, 38, 39}, allDiffSum, 21)
kakuro:addConstraintByIDs({41, 42}, allDiffSum, 5)
kakuro:addConstraintByIDs({43, 44, 45}, allDiffSum, 6)
kakuro:addConstraintByIDs({48, 49}, allDiffSum, 3)


-- Blank spots?
kakuro:addConstraintByIDs({3}, Pepper.setVal, "X")
kakuro:addConstraintByIDs({4}, Pepper.setVal, "X")
kakuro:addConstraintByIDs({10}, Pepper.setVal, "X")
kakuro:addConstraintByIDs({20}, Pepper.setVal, "X")
kakuro:addConstraintByIDs({21}, Pepper.setVal, "X")
kakuro:addConstraintByIDs({22}, Pepper.setVal, "X")
kakuro:addConstraintByIDs({25}, Pepper.setVal, "X")
kakuro:addConstraintByIDs({28}, Pepper.setVal, "X")
kakuro:addConstraintByIDs({29}, Pepper.setVal, "X")
kakuro:addConstraintByIDs({30}, Pepper.setVal, "X")
kakuro:addConstraintByIDs({40}, Pepper.setVal, "X")
kakuro:addConstraintByIDs({46}, Pepper.setVal, "X")
kakuro:addConstraintByIDs({47}, Pepper.setVal, "X")


-- kakuro:setAddVarsAfterAnyChange(false)
local duration = os.clock()
kakuro:solve()
local time = (os.clock() - duration) * 1000
kakuro:print()
print("Solved in " .. time .. "ms")


-- -- Debug Output (for when testing single puzzles failing)
-- for j = 1, 7 do
--     for i = 1, 7 do
--         local cell = kakuro:getValueByPair(i, j)
--         if cell == nil then
--             print(kakuro:getIDByPair(i, j), table.concat(kakuro:getDomainByPair(i, j)))
--         end
--     end
-- end
