-- --- Easy Drop'n'Loot Options ---

require "EDNLMain"

local config = {
    lootKey = nil,
    dropKey = nil,
    hideLootKey = nil,
    hideDropKey = nil,
    modKey = nil
}

local function createEDNLConfigOptions()
    -- create mod menu options
    local options = PZAPI.ModOptions:create("EDNLOptions", "Easy Drop'n'Loot")
    config.modKey = options:addKeyBind("EDNLOptionsModKey", getText("UI_mod_button"), Keyboard.KEY_NONE, getText("UI_mod_button_tooltip"))
    config.dropKey = options:addKeyBind("EDNLOptionsDropKey", getText("UI_drop_items_button"), Keyboard.KEY_NONE, getText("UI_drop_items_button_tooltip"))
    config.lootKey = options:addKeyBind("EDNLOptionsLootKey", getText("UI_loot_items_button"), Keyboard.KEY_NONE, getText("UI_loot_items_button_tooltip"))
    config.hideDropKey = options:addTickBox("EDNLOptionsHideDropKey", getText("UI_hide_drop_key"), false, getText("UI_hide_drop_key_tooltip"))
    config.hideLootKey = options:addTickBox("EDNLOptionsHideLootKey", getText("UI_hide_loot_key"), false, getText("UI_hide_loot_key_tooltip"))
end

createEDNLConfigOptions()

local function isModKeyPressed(key) 
    if config.modKey and key == config.modKey:getValue() then
        return true
    end
    return false
end

local function isModKeyRequired() 
    if config.modKey then
        return config.modKey:getValue() ~= Keyboard.KEY_NONE
    end
    return false
end

local modKeyPressed = false

local function onEDNLKeyKeepPressed(key)        
    modKeyPressed = isModKeyPressed(key)
end

local function onEDNLKeyPressed(key)    

    -- check if mod key is pressed
    if isModKeyRequired() and modKeyPressed == false then
        -- if mod key is required but not pressed - do nothing        
        return
    end

    -- loot key
    if config.lootKey and key == config.lootKey:getValue() then     
        local player = getPlayer()
        if (player) then
            local playerIndex = player:getPlayerNum()            
            EDNL_lootItems(playerIndex)
        end
    end
    -- drop key
    if config.dropKey and key == config.dropKey:getValue() then        
        local player = getPlayer()
        if (player) then
            local playerIndex = player:getPlayerNum()            
            EDNL_dropItems(playerIndex)
        end
    end
end

Events.OnKeyKeepPressed.Add(onEDNLKeyKeepPressed)
Events.OnKeyPressed.Add(onEDNLKeyPressed)

-- check if loot key is hidden
function EDNL_isLootKeyHidden()
    if config.hideLootKey then
        return config.hideLootKey:getValue()
    end
    return false
end

-- check if drop key is hidden
function EDNL_isDropKeyHidden()
    if config.hideDropKey then
        return config.hideDropKey:getValue()
    end
    return false
end
