
math.randomseed(os.time())

local function randomString(sizeInBytes)
    local result = ""
    local asciiCode
    
    for i = 1,sizeInBytes do
        asciiCode = math.random(32, 126)
        result = result .. string.char(asciiCode)
    end

    return result
end


local function randomNum(lenght)
    local result = ""
    
    for i = 1,lenght do
        result = result .. math.random(0, 9)
    end

    return result
end

local function rollDice(prob)
    return math.random() < prob
end
-- ------------------------------------------------------------------------- --
-- Define Random module
-- ~~~~~~~~~~~~~~~~~~~~

local Random = {}

-- For Random = require("random")
Random.randomString = randomString
Random.randomNum = randomNum
Random.rollDice = rollDice

return (Random)

-- ------------------------------------------------------------------------- --