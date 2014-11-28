local CSP = require('TableSalt')
local TableSalt = CSP.TableSalt
local Pepper = CSP.Pepper

local allDiffSum = require('allDiffSum').allDiffSum

local results = {}
setmetatable(results, {__mode = "v"})  -- make values weak

function KakuroCalc(target, digits, values)
    local key
    if values then
        key = table.concat(values) .. "-" .. digits .. "-" .. target
    else
        key = "-" .. digits .. "-" .. target
    end
    if results[key] then return results[key] end

    local mandatory = {}
    if values then
    for i = 1, #values do
        local val = values[i]
        if val then
            -- print("VAL", val)
            mandatory[val] = true
        end
    end
    end

    local bit = bit
    if not jit then
        bit = require('bit')
    end
    local band = bit.band

    local result = {}
    for mask = 512, 1, -1 do
        local cdigits = digits
        local ctarget = target
        local bits = 1
        local numbers = {}
        local failed = false
        for digit = 9, 1, -1 do
            if band(bits, mask) ~= 0 then
                cdigits = cdigits - 1
                ctarget = ctarget - digit;
                numbers[#numbers + 1] = digit
            else
                if mandatory[digit] then failed = true break end
            end
            bits = bits + bits
        end
        if (ctarget==0 and cdigits == 0 and failed == false) then
            result[#result+1] = numbers
            -- print(table.concat(numbers))
        end
    end

    results[key] = result

    return result

end

local function tcompare_order_doesnt_matter(state, arguments)
    local isSame = true

    if type(arguments[1]) ~= "table" or type(arguments[2]) ~= "table" then
        return false
    end

    if #arguments[1] ~= #arguments[2] then
        return false
    end

    local temp = {}
    for i = 1, #arguments[1] do
        temp[arguments[1][i]] = true
    end

    for i = 1, #arguments[2] do
        if not temp[arguments[2][i]] then
            isSame = false
        end
    end

    return state.mod == isSame
end

-- compares the first tables with all the other ones.
-- returns true if it matches exactly one
local function multi_tcompare(state, arguments)

    local numberOfCompares = #arguments-1
    local tableCompares = {}
    local isSuccessful = false
    for i = 2, #arguments do
        -- need to take care of this heres...
        if type(arguments[1]) ~= "table" or type(arguments[i]) ~= "table" then
            return false
        end

        if #arguments[1] ~= #arguments[i] then
            return false
        end

        local arg = {arguments[1], arguments[i]}
        local compared = tcompare_order_doesnt_matter(state, arg)
        if compared and isSuccessful == false then
            isSuccessful = true
        elseif compared and isSuccessful == true then
            return false
        end
    end

    return state.mod == isSuccessful

end

assert:register("assertion", "tcompare", tcompare_order_doesnt_matter)
assert:register("assertion", "multiTcompare", multi_tcompare)

describe("allDiffSum tests", function()
context("various configurations", function()
    it("should all equal 5", function()
        kakuro = TableSalt:new({1, 2, 3, 4, 5, 6, 7, 8, 9},  1)
        kakuro:addConstraintByIDs({1}, allDiffSum, 5)
        kakuro:solve()
        assert.tcompare(kakuro:getAllValues(), {5})
    end)

    it("should equal 9", function()
        kakuro = TableSalt:new({1, 2, 3, 4, 5, 6, 7, 8, 9},  2)
        kakuro:addConstraintByIDs({1, 2}, allDiffSum, 9)
        kakuro:solve()
        assert.multiTcompare(kakuro:getAllValues(), {1, 8}, {2, 7}, {3, 6}, {4, 5})
    end)

    it("should equal 19", function()
        local expected = {{9,8,2}, {9,7,3}, {9,6,4}, {8,7,4}, {8,6,5}}
        assert.are.same(expected, KakuroCalc(19, 3))
    end)

    it("should equal 19 (memoized)", function()
        local expected = {{9,8,2}, {9,7,3}, {9,6,4}, {8,7,4}, {8,6,5}}
        assert.are.same(expected, KakuroCalc(19, 3))
    end)

    it("should equal 19", function()
        kakuro = TableSalt:new({1, 2, 3, 4, 5, 6, 7, 8, 9},  3)
        kakuro:addConstraintByIDs({1, 2, 3}, allDiffSum, 19)
        kakuro:solve()
        local expected = KakuroCalc(19, 3)
        assert.multiTcompare(kakuro:getAllValues(), unpack(expected))
    end)

    it("should equal 42", function()
        kakuro = TableSalt:new({1, 2, 3, 4, 5, 6, 7, 8, 9},  7)
        kakuro:addConstraintForAll(allDiffSum, 42)
        kakuro:solve()
        local expected = KakuroCalc(42, 7)
        assert.multiTcompare(kakuro:getAllValues(), unpack(expected))
    end)

    it("should equal nil", function()
        assert.is.same(KakuroCalc(20, 0), {})
    end)

    it("should equal nil", function()
        kakuro = TableSalt:new({1, 2, 3, 4, 5, 6, 7, 8, 9}, 2)
        kakuro:addConstraintByIDs({1, 2}, allDiffSum, 20)
        kakuro:solve()
        -- yeah... because you can't add 20 with two single digit vars
        local expected = {nil, nil}
        assert.tcompare(kakuro:getAllValues(), expected)
    end)

    -- taken from top right of wikipedia board
    it("should be all SCARY", function()
        kakuro = TableSalt:new({1, 2, 3, 4, 5, 6, 7, 8, 9}, 2, 2)
        kakuro:addConstraintByIDs({1, 2}, allDiffSum, 15)
        kakuro:addConstraintByIDs({1, 3}, allDiffSum, 17)
        kakuro:addConstraintByIDs({3, 4}, allDiffSum, 14)
        kakuro:addConstraintByIDs({2, 4}, allDiffSum, 12)
        kakuro:solve()
        assert.is.same(kakuro:getAllValues(), {8, 7, 9, 5})
    end)

    -- taken from top right of wikipedia board (expanded)
    it("WOAH this is a big one", function()
        kakuro = TableSalt:new({1, 2, 3, 4, 5, 6, 7, 8, 9}, 4, 4)
        kakuro:addConstraintByIDs({2, 3, 4}, allDiffSum, 24)
        kakuro:addConstraintByIDs({5, 6, 7, 8}, allDiffSum, 29)
        kakuro:addConstraintByIDs({2, 6, 10, 14}, allDiffSum, 26)
        kakuro:addConstraintByIDs({5, 9}, allDiffSum, 17)
        kakuro:addConstraintByIDs({9, 10}, allDiffSum, 16)
        kakuro:addConstraintByIDs({3, 7}, allDiffSum, 12)
        kakuro:addConstraintByIDs({4, 8}, allDiffSum, 16)
        kakuro:addConstraintByIDs({14, 15}, allDiffSum, 8)
        kakuro:addConstraintByIDs({1}, Pepper.setVal, "X")
        kakuro:addConstraintByIDs({11}, Pepper.setVal, "X")
        kakuro:addConstraintByIDs({12}, Pepper.setVal, "X")
        kakuro:addConstraintByIDs({13}, Pepper.setVal, "X")
        kakuro:addConstraintByIDs({16}, Pepper.setVal, "X")
        kakuro:solve()
        assert.is.same(kakuro:getAllValues(), {"X", 8, 7, 9, 8, 9, 5, 7, 9, 7, "X", "X", "X", 2, 6, "X"})
    end)    

-- CRAY debug stuff
-- print("\nFASP")
-- kakuro = TableSalt:new({1, 2, 3, 4, 5, 6, 7, 8, 9}, 4, 5)
-- for i = 1, 20 do
--     kakuro:addConstraintByIDs({i}, Pepper.setVal, i)
-- end
-- kakuro:solve()
-- kakuro:print()
    end)
end)
