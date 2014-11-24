local Constraint = {}

local bit = bit
if not jit then
    bit = require('bit') 
end

function Constraint.allDiffSum(section, board, sum)
    -- print("target", sum)
    -- print("section size", #section)

    -- determine which values are mandatory
    local mandatory = {}
    for i = 1, #section do
        local val = board:getValueByID(section[i])
        if val then
            -- print("VAL", val)
            mandatory[val] = true
        end
    end


    -- CRAZY CODE
    -- Thanks to edc65 over on stackexchange for this one!
    -- http://codegolf.stackexchange.com/questions/35562/kakuro-combinations
    local band = bit.band
    local result = {}
    local count = 0

    for mask = 512, 1, -1 do
        local cdigits = #section
        local ctarget = sum
        local bit = 1
        local numbers = {}
        local failed = false
        for digit = 9, 1, -1 do
            if band(bit, mask) ~= 0 then
                cdigits = cdigits - 1
                ctarget = ctarget - digit;
                numbers[#numbers + 1] = digit
            else
                if mandatory[digit] then failed = true break end
            end
            bit = bit + bit
        end
        if (ctarget==0 and cdigits == 0 and failed == false) then
            for i = 1, #numbers do
                result[numbers[i]] = true
            end
            count = count + 1
        end
    end

    -- error out RIGHT AWAY
    if count == 0 then return {{}} end
    -- print("Count", count)
    -- print(unpack(result))

    -- uhhh yeah, hardcoded? mebbe
    -- easiest way to get through this list!
    for i = 1, 9 do
        local val = mandatory[i]
        if val then
            result[i] = nil
        end
    end


    -- remove the values from the sections
    -- figure out the new domains, by removing the values from the current domain
    newDomains = {}
    for ind = 1, #section do 
        local currentDomain = board:getDomainByID(section[ind])
        local domainSize = #currentDomain
        if domainSize > 1 then

            for i=1, domainSize do
                if not result[currentDomain[i]] then
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
            -- domain was reduced to 0. GASP! ERROR OUT!
            if j == 0 then return {{}} end

            for i = j+1, domainSize do
                currentDomain[i] = nil
            end

        end
        newDomains[ind] = currentDomain
    end

    -- return the new domains
    return newDomains

end

return Constraint
