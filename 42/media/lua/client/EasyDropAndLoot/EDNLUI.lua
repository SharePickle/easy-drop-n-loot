--- Easy Drop'n'Loot User Interface ---

require "ISUI/ISButton"
require "EDNLMain"
require "EDNLOptions"

local string_UI_drop_items_button = getText("UI_drop_items_button")
local string_UI_drop_items_button_tooltip = getText("UI_drop_items_button_tooltip")
local string_UI_loot_items_button = getText("UI_loot_items_button")
local string_UI_loot_items_button_tooltip = getText("UI_loot_items_button_tooltip")
local string_UI_grab_category = getText('UI_grab_category')
local string_UI_drop_category = getText('UI_drop_category')
local string_UI_grab_category_tooltip = getText('UI_grab_category_tooltip')
local string_UI_drop_category_tooltip = getText('UI_drop_category_tooltip')
local string_UI_drop_floor = getText('UI_drop_floor')

--- TOOLTIPS ---

-- Create tooltip text to show which categories will be transferred
local function createTransferItemsTooltipText(source, destination)
    local sourceCategories = EDNL_getItemsDisplayCategories(source:getItems())
    local destinationCategories = EDNL_getItemsDisplayCategories(destination:getItems())
    local displayCategories = ""
    for _, category in ipairs(destinationCategories) do
        if (sourceCategories[category] ~= nil) then -- only show categories that can be transferred (intersection of source and destination)
            displayCategories = displayCategories .. category .. " <LINE> "
        end
    end
    return displayCategories
end

--- INVENTORY BUTTONS ---

-- Create "Transfer Category" button on the player inventory UI
local function createDropItemsButton(self)
    if EDNL_isDropKeyHidden() then
        return
    end
    if (self.EDNLDropItems == nil and self.onCharacter) then
        local titleBarHeight = self:titleBarHeight()
        local lootButtonHeight = titleBarHeight
        local textWid = getTextManager():MeasureStringX(UIFont.Small, string_UI_drop_items_button)
        self.EDNLDropItems = ISButton:new(0, 0, textWid, lootButtonHeight, string_UI_drop_items_button, self,
            ISInventoryPage.EDNLDropItemsClick)
        self.EDNLDropItemsTooltip = false
        self.EDNLDropItems:initialise()
        self.EDNLDropItems.tooltip = string_UI_drop_items_button_tooltip
        self.EDNLDropItems.borderColor.a = 0.0
        self.EDNLDropItems.backgroundColor.a = 0.0
        self.EDNLDropItems.backgroundColorMouseOver.a = 0.7
        self:addChild(self.EDNLDropItems)
        self.EDNLDropItems:setVisible(true)
        self.KAtransferAllCompulsively = self.EDNLDropItems -- old button name
    end
end

-- Create "Loot Category" button on the loot inventory UI
local function createLootItemsButton(self)
    if EDNL_isLootKeyHidden() then
        return
    end    
    if (self.EDNLLootItems == nil and not self.onCharacter) then
        local titleBarHeight = self:titleBarHeight()
        local lootButtonHeight = titleBarHeight
        local textWid = getTextManager():MeasureStringX(UIFont.Small, string_UI_loot_items_button)
        self.EDNLLootItems = ISButton:new(0, 0, textWid, lootButtonHeight,
            string_UI_loot_items_button, self, ISInventoryPage.EDNLLootItemsClick)
        self.EDNLLootItems:initialise()
        self.EDNLLootItemsTooltip = false
        self.EDNLLootItems.tooltip = string_UI_loot_items_button_tooltip
        self.EDNLLootItems.borderColor.a = 0.0
        self.EDNLLootItems.backgroundColor.a = 0.0
        self.EDNLLootItems.backgroundColorMouseOver.a = 0.7
        self:addChild(self.EDNLLootItems)
        self.EDNLLootItems:setVisible(true)
        self.KAlootAllCompulsively = self.EDNLLootItems -- old button name
    end
end

-- Call "ISInventoryPageCreateChildren" in case it was not called (other mods conflict)
local function createInventoryButtons(self)    
    createDropItemsButton(self)
    createLootItemsButton(self)    
end

-- reference to original function
local ISInventoryPageCreateChildren = ISInventoryPage.createChildren

-- Override ISInventoryPage:createChildren to inject EDNL code
function ISInventoryPage:createChildren()
    ISInventoryPageCreateChildren(self) -- call original function
    pcall(createInventoryButtons, self) -- pcall to prevent UI from crashing if this mod causes problems
end

-- "Drop Category" button click handler
function ISInventoryPage:EDNLDropItemsClick()
    EDNL_dropItems(self.player)
end

-- "Loot Category" button click handler
function ISInventoryPage:EDNLLootItemsClick()
    EDNL_lootItems(self.player)
end

-- Get "Transfer Category" button offset to prevent overlapping with other UI elements
local function getDropItemsButtonOffset(self)
    local result = 0
    -- "Transfer all" button
    if (self.transferAll:getIsVisible()) then --
        result = self.transferAll:getX() - 3 - self.EDNLDropItems.width
    end
    -- AutoLoot mod button
    if (self.swapAutoLoot ~= nil and self.swapAutoLoot:getIsVisible()) then
        result = self.swapAutoLoot:getX() - 3 - self.EDNLDropItems.width
    end
    return result
end

-- Update "Transfer Category" button
local function updateDropItemsButton(self)
    if (self.onCharacter and self.EDNLDropItems ~= nil) then
        if (self.width >= 370) then
            -- show "Transfer Category" when "Transfer All" button shows
            self.transferAll:setVisible(true)
            self.EDNLDropItems:setVisible(true)
            local offset = getDropItemsButtonOffset(self)
            self.EDNLDropItems:setX(offset)
        else
            -- hide "Transfer Category" when "Transfer All" button hides
            self.EDNLDropItems:setVisible(false)
        end

        if (self.EDNLDropItems.tooltipUI ~= nil) then
            self.EDNLDropItems.tooltipUI:setName(string_UI_drop_items_button_tooltip)
        end

        local mouseOver = self.EDNLDropItems:isMouseOver()
        if (mouseOver and self.EDNLDropItemsTooltip == false) then
            self.EDNLDropItemsTooltip = true -- running stuff below every frame is expensive!
            -- add tooltip to show which categories will be transferred
            local playerData = getPlayerData(self.player)
            local text = createTransferItemsTooltipText(playerData.playerInventory.inventory,
                playerData.lootInventory.inventory)
            self.EDNLDropItems.tooltip = text
        end
        if (mouseOver == false) then
            self.EDNLDropItemsTooltip = false
        end

    end
end

-- Find SmartStack mod button
local function findSmartStackToAllButton(self)
    if (self.children) then
        for _, selectedItem in pairs(self.children) do
            -- since it's not storing its references on the ISInventoryPage
            -- it can only be found by its title (somewhat unreliable)
            if (selectedItem.title == getText("UI_StackToAll")) then
                return selectedItem
            end
        end
    end
    return nil
end

-- Get "Loot Category" button offset to prevent overlapping with other UI elements
local function getLootItemsButtonOffset(self)
    local result = 0
    -- "Loot All" button
    if (self.lootAll:getIsVisible()) then
        result = self.lootAll:getRight() + 3
    end
    -- AutoLoot mod button
    if (self.stackItemsButtonIcon ~= nil and self.stackItemsButtonIcon:getIsVisible()) then
        result = self.stackItemsButtonIcon:getRight() + 3
    end
    -- Smart Stack mod button
    local smartStackButton = findSmartStackToAllButton(self)
    if (smartStackButton ~= nil) then
        result = smartStackButton:getRight() + 3
    end
    return result
end

-- Update "Loot Category" button
local function updateLootItemsButton(self) 
    if (not self.onCharacter and self.EDNLLootItems ~= nil) then
        local offset = getLootItemsButtonOffset(self)
        self.EDNLLootItems:setX(offset)

        if (self.EDNLLootItems.tooltipUI ~= nil) then
            self.EDNLLootItems.tooltipUI:setName(string_UI_loot_items_button_tooltip)
        end

        -- add tooltip to show which categories will be transferred
        local mouseOver = self.EDNLLootItems:isMouseOver()
        if (mouseOver and self.EDNLLootItemsTooltip == false) then
            self.EDNLLootItemsTooltip = true -- running stuff below every frame is expensive!
            -- add tooltip to show which categories will be transferred
            local playerData = getPlayerData(self.player)
            local text = createTransferItemsTooltipText(playerData.lootInventory.inventory,
                playerData.playerInventory.inventory)
            self.EDNLLootItems.tooltip = text
        end
        if (mouseOver == false) then
            self.EDNLLootItemsTooltip = false
        end
    end
end

-- Update "Oven" and "Remove All" button
local function updateOvenAndRemoveAllButton(self)
    if (not self.onCharacter and self.EDNLLootItems ~= nil) then
        local offset = self.EDNLLootItems:getRight() + 3
        if (self.toggleStove:getIsVisible()) then
            self.toggleStove:setX(offset)
        end
        if (self.removeAll:getIsVisible()) then
            self.removeAll:setX(offset)
        end
    end
end

-- reference to original function
local ISInventoryPagePrerender = ISInventoryPage.prerender

-- Override ISInventoryPage:prerender to inject EDNL code to update buttons
function ISInventoryPage:prerender()
    ISInventoryPagePrerender(self) -- call original function
    pcall(updateDropItemsButton, self) -- pcall to prevent UI from crashing if this mod causes problems
    pcall(updateLootItemsButton, self)
    pcall(updateOvenAndRemoveAllButton, self)
    pcall(createInventoryButtons, self) -- in case other mods override ISInventoryPage.createChildren - lets try to create buttons
end

--- CONTEXT MENU OPTIONS ---

-- "Drop (category)" or "Grab (category)" button click handler
local function EDNLMoveItemsClick(_, items, playerIndex, source, destination)
    -- first argument is nil (see contextMenu:addOption(...) 2nd argument)
    EDNL_moveItemsByCategories(items, playerIndex, source, destination)
end

-- Add tooltip to show which categories will be transferred
local function createItemsTooltip(option, items, grabbing)
    local categories = EDNL_getItemsDisplayCategories(items)
    local displayCategories = ""
    for _, category in ipairs(categories) do
        displayCategories = displayCategories .. category .. " <LINE> "
    end
    if (displayCategories == "") then
        return -- no tooltip
    end
    local tooltip = ISToolTip:new()
    local tooltipText = string_UI_drop_category_tooltip
    if (grabbing) then
        tooltipText = string_UI_grab_category_tooltip
    end
    tooltip:setName(tooltipText)
    tooltip.description = displayCategories
    option.toolTip = tooltip
end

-- Add Drop/Grab button to item context menu
local function addMoveItemsMenuOption(playerIndex, contextMenu, items)
    if (#items < 1) then
        return -- no items selected
    end
    if (#items == 1 and EDNL_isEquipped(playerIndex, items)) then
        return -- equipped container selected
    end
    local source, destination, grabbing, floorContainer = EDNL_getSourceAndDestinationInventories(items, playerIndex)
    local string = string_UI_drop_category
    if (grabbing) then
        string = string_UI_grab_category
    end
    -- add right click menu items
    local dropOrLootOption = contextMenu:addOption(string, nil, EDNLMoveItemsClick, items, playerIndex, source, destination)
    local dropOnTheGroundOption = contextMenu:addOption(string_UI_drop_floor, nil, EDNLMoveItemsClick, items, playerIndex, source, floorContainer)
    createItemsTooltip(dropOrLootOption, items, grabbing)
    createItemsTooltip(dropOnTheGroundOption, items, grabbing)
end

-- Create "Grab (category)" and "Drop (category)" context menu items
local function createMoveItemsContextMenu(playerIndex, contextMenu, items)
    pcall(addMoveItemsMenuOption, playerIndex, contextMenu, items) -- pcall to prevent UI from crashing if this mod causes problems
end

Events.OnPreFillInventoryObjectContextMenu.Add(createMoveItemsContextMenu)
