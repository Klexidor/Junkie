local _, core = ...

local itemBatch = {};

--[[
    Repairs your gear when interacting with a merchant.
]]
local function RepairGear()
    print("Attempting to auto repair.");
    local repairAllCost, canRepair = GetRepairAllCost();
    local canRepairString = "cannot repair";

    if canRepair then
        canRepairString = "Repairing";
        RepairAllItems(); --ToDo: Use options table value as argument for using guild funds (1,0).
    end

    print(repairAllCost .. " " .. canRepairString);
end

local function SellItemBatch()
    local bIndex = itemBatch[1].bagIndex;
    local sIndex = itemBatch[1].slotIndex;
    local lock = select(3, GetContainerItemInfo(bIndex, sIndex));

    if not lock then
        UseContainerItem(bIndex, sIndex);
        tremove(itemBatch, 1);
    end

    if #itemBatch > 0 then
        C_Timer.After(0.2, SellItemBatch);
    end
end

--ToDo: I should create a table that adds functions based on the filters required.
local function ItemPassedFilter(itemId, itemLink, filter)

    local _, _, rarity, itemLevel, itemMinLevel, itemType, itemSubType = GetItemInfo(itemId);

    --Ignore?
    if filter:ShouldIgnoreItem(itemId) then
        print("Ignoring" .. itemLink);
        return false;
    end

    --Quality
    if not filter:TypeIsInTable(rarity, filter.rarity) then
        print("not selling " .. itemLink .. " because the quality does not match.");
        return false;                          
     end

     if not filter:TypeIsInTable(itemType, filter.itemTypes) then
        print("not selling " .. itemLink .. " because the type does not match.");
        return false;                          
     end

     return true;
end

local function SellItemsWithFilter(filter)
    itemBatch = {};

    for bag=0, 4, 1 do
        print("checking bag " .. bag);

        local numberOfBagSlots = GetContainerNumSlots(bag);

        if numberOfBagSlots > 0 then
            for i=1, numberOfBagSlots, 1 do
                local _, _, locked, _, _, _, itemLink, _, noValue, itemId = GetContainerItemInfo(bag, i);

                if(itemId and itemLink and not noValue) then
                    local passedFilter = ItemPassedFilter(itemId, itemLink, filter)
                    
                    if passedFilter then
                        print("Adding item " .. itemLink .. " to batch.");
                        local bIndex, sIndex = bag, i;
                        
                        tinsert(itemBatch, {bagIndex = bIndex, slotIndex = sIndex});
                    end
                end   
            end
        end
    end

    if #itemBatch > 0 then
        SellItemBatch();
    end
end

local function OnEvent(self, event, ...)
    --ToDo: Call functions based on user settings.
    if(event == "MERCHANT_SHOW") then    
        RepairGear();
        SellItemsWithFilter(core.Config.Filter);
    end
end

--MERCHANT_SHOW
local frame = CreateFrame("Frame", "JunkieFrame", UIParent, "MerchantItemTemplate");
frame:RegisterEvent("MERCHANT_SHOW");
frame:SetScript("OnEvent", OnEvent);