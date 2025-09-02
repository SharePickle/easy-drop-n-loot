--- Easy Drop'n'Loot Check ---

-- "Wallmart" integrity check

local checkValue = 0
local targetValue = 29251 + 29252 + 29253

function EDNL_check(value)
    checkValue = checkValue + value
end

function EDNL_hasFailed()     
    return checkValue ~= targetValue
end

local function onGameBoot()
    if EDNL_hasFailed() then
        print("Easy Drop'n'Loot: Mod integrity check failed. Some features may not work correctly. Check installed mods. Expected "..targetValue..", got "..checkValue)
    end
end

Events.OnGameBoot.Add(onGameBoot)
