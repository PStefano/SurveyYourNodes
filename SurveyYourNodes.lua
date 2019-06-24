-- Goal of the addon + logic?
--[[
    Figuring out if you have grabbed every node from a given survey
    To start, seeing if the player is at the survey node to start the checks and prompt the player
    Show the progress of the nodes on screen/chat (give option)
    The first check should occur when the player reaches the survey node (Lib?), 
    the second check should follow the reticle (?) to see if it's targetting a survey node, 
    if it has been looted (?)
    and then show how many nodes have already been claimed
    Add a check to prompt the player if they are leaving the are without grabbing all of the nodes (?)
]]

SYN = {}
 
-- This isn't strictly necessary, but we'll use this string later when registering events.
-- Better to define it in a single place rather than retyping the same string.
SYN.name = "SurveyYourNodes"
SYN.coords = {}
SYN.zoneName = GetPlayerActiveZoneName():lower()
SYN.constants = {
    ITEMTYPE_CLOTHIER_RAW_MATERIAL,
    ITEMTYPE_BLACKSMITHING_RAW_MATERIAL,
    ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL,
    ITEMTYPE_WOODWORKING_RAW_MATERIAL
}
-- Initialize it every time!!!! if survey map
SYN.allSurveys = {
    ["auridon"] =  0 ,
    ["grahtwood"] =  0 ,
    ["greenshade"] =  0 ,
    ["malabal tor"] =  0 ,
    ["reaper's march"] =  0 ,
    ["stonefalls"] =  0 ,
    ["ebonheart"] =  0 ,
    ["deshaan"] =  0 ,
    ["shadowfen"] =  0 ,
    ["eastmarch"] =  0 ,
    ["the rift"] =  0 ,
    ["glenumbra"] =  0 ,
    ["stormhaven"] =  0 ,
    ["rivenspire"] =  0 ,
    ["alik'r desert"] =  0 ,
    ["bangkorai"] =  0 ,
    ["coldharbour"] =  0 ,
    ["craglorn"] =  0 ,
    ["wrothgar"] =  0 ,
    ["vvardenfell"] =  0 
}
SYN.nodes = 0
SYN.chat = LibChatMessage("SurveyYourNodes", "SYN")
SYN.inArea = false
SYN.currentNodes = 0
SYN.itemType = ""
SYN.count = 0
SYN.amountSurveys = 0
SYN.finished = false
SYN.gps = LibGPS2

function SYN:Initialize()
    self.startMessage = false
    SHARED_INVENTORY:RegisterCallback("SlotAdded", self.SlotAdded, self)
    SHARED_INVENTORY:RegisterCallback("SlotRemoved", self.SlotRemoved, self)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, self.GrabCoords)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_LOOT_RECEIVED, self.CheckLoot)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_POI_UPDATED, self.CheckProximity)
end

function SYN.GrabCoords(event)
    if SYN.amountSurveys == SYN.count then
        SYN.finished = true
    end
    SYN.currentNodes = 0
    local data = SURVEY_DATA
    SYN.zoneName = GetPlayerActiveZoneName():lower()
    SYN.coords = data[SYN.zoneName]
    for k,v in pairs(SYN.allSurveys) do
        if k == GetPlayerActiveZoneName():lower() then
            SYN.zoneName = k
            SYN.currentNodes = v
            SYN.coords = data[k]
            EVENT_MANAGER:RegisterForUpdate(SYN.name, 50, SYN.CheckNode)
        end
    end
end

function SYN.CheckProximity() 
    if SYN.allSurveys[GetPlayerActiveZoneName():lower()] > 0 then
        EVENT_MANAGER:RegisterForUpdate(SYN.name, 50, SYN.CheckNode)
    end
end

function SYN.CheckNode()
    local nodeX, nodeY, deltaX, deltaY, maxPosX, minPosX, maxPosY, minPosY
    local playerX, playerY = GetMapPlayerPosition("player")
    if IsPlayerMoving() and SYN.coords ~= nil then
        for i = 1, #SYN.coords do
            nodeX = SYN.coords[i][1]
            nodeY = SYN.coords[i][2]
            playerX = math.floor(playerX * 100) / 100
            playerY = math.floor(playerY * 100) / 100
            maxPosX = math.max(playerX, nodeX)
            minPosX = math.min(playerX, nodeX)
            maxPosY = math.max(playerY, nodeY)
            minPosY = math.min(playerY, nodeY)
            deltaX = minPosX / maxPosX
            deltaY = minPosY / maxPosY
            if deltaX > 0.95 and deltaY > 0.95 and SYN.currentNodes > 0 then
                SYN.chat:Print("Your have collected " .. SYN.nodes .. " out of 6 nodes!")
                SYN.startMessage = true
                SYN.inArea = true
                EVENT_MANAGER:UnregisterForUpdate(SYN.name)
            else
                SYN.inArea = false
            end
        end
    end
end

function SYN:CheckLoot(event, itemName, quantity)
    if SYN.startMessage then
        if SYN.itemType == ITEMTYPE_REAGENT and quantity > 3 then
            SYN.nodes = SYN.nodes + 1
            SYN.chat:Print("Your have collected " .. SYN.nodes .. " out of 6 nodes!")
        end

        if (SYN.itemType == ITEMTYPE_CLOTHIER_RAW_MATERIAL or SYN.itemType == ITEMTYPE_BLACKSMITHING_RAW_MATERIAL or SYN.itemType == ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL or SYN.itemType == ITEMTYPE_WOODWORKING_RAW_MATERIAL) and quantity > 6 then
            SYN.nodes = SYN.nodes + 1
            SYN.chat:Print("Your have collected " .. SYN.nodes .. " out of 6 nodes!")
        end
        if SYN.allSurveys[GetPlayerActiveZoneName():lower()] ~= nil then
            if SYN.nodes == 6 then
                EVENT_MANAGER:UnregisterForUpdate(SYN.name)
                SYN.inArea = false
                SYN.nodes = 0
                SYN.startMessage = false
                SYN.chat:Print("You finished this survey!")
            end
        end
    end   
end

function SYN:SlotAdded(bagId, slotIndex, slotData)
    
    SYN.itemType = slotData.itemType
    if not (bagId == BAG_BACKPACK) then return end
    local isSurveyMap = zo_plainstrfind(zo_strlower(slotData.name), "survey:")
    if isSurveyMap and not zo_plainstrfind(zo_strlower(slotData.name), "enchanter") and not SYN.finished then
        SYN.amountSurveys = SYN.amountSurveys + 1
        if SYN.amountSurveys ~= SYN.count then
            for k,v in pairs(SYN.allSurveys) do
                if zo_plainstrfind(zo_strlower(slotData.name), k) then
                    SYN.allSurveys[k] = SYN.allSurveys[k] + 1
                    SYN.count = SYN.count + 1
                end
                if k == GetPlayerActiveZoneName():lower() then 
                    EVENT_MANAGER:RegisterForUpdate(SYN.name, 50, SYN.CheckNode)
                end
            end
        end
    end
end

function SYN:SlotRemoved(bagId, slotIndex, slotData)
    --[[if bagId == BAG_BANK and zo_plainstrfind(zo_strlower(slotData.name), "survey:") then
        SYN.finished = false
    end]]
    if not (bagId == BAG_BACKPACK) then return end

    local isSurveyMap = zo_plainstrfind(zo_strlower(slotData.name), "survey:")

    if isSurveyMap then
        SYN.count = SYN.count - 1
        SYN.amountSurveys = SYN.amountSurveys - 1
        for k,v in pairs(SYN.allSurveys) do
            if zo_plainstrfind(zo_strlower(slotData.name), k) then
                SYN.allSurveys[k] = SYN.allSurveys[k] - 1
                break
            end
        end
    end
end

-- Check if the addon has been loaded properly with every other resource
function SYN.OnAddOnLoaded(event, addonName)
    if addonName == SYN.name then
        SYN:Initialize()
    end
end

-- Launch the check when addons are being loaded
EVENT_MANAGER:RegisterForEvent(SYN.name, EVENT_ADD_ON_LOADED, SYN.OnAddOnLoaded)
