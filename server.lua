local resource = GetCurrentResourceName()
local saveFile = "player_data.json"
local players = {}
local defaultState = { coins = 0, level = 1, claimedDays = {}, achievements = {}, dailyDay = 1, dailyClaimed = false, dailyClaimedAt = 0, jobName = nil, jobSeconds = 0, jobLastCheck = 0 }
local ESX

if Config.Framework == "esx" then
    ESX = exports["es_extended"]:getSharedObject()
end

local function loadData() local raw = LoadResourceFile(resource, saveFile); players = raw and json.decode(raw) or {} end
local function saveData() SaveResourceFile(resource, saveFile, json.encode(players), -1) end
local function identifier(source)
    for _, value in ipairs(GetPlayerIdentifiers(source)) do if value:sub(1, 8) == "license:" then return value end end
    return GetPlayerIdentifiers(source)[1] or ("source:" .. source)
end
local function getState(source)
    local key = identifier(source); if not players[key] then players[key] = json.decode(json.encode(defaultState)) end
    local state, now = players[key], os.time()
    if state.dailyClaimed and now - (state.dailyClaimedAt or 0) >= 86400 then state.dailyClaimed = false; state.dailyDay = (state.dailyDay % 14) + 1; saveData() end
    return state
end
local function publicState(state) return { coins = state.coins, level = state.level, claimedDays = state.claimedDays, achievements = state.achievements, dailyDay = state.dailyDay, dailyClaimed = state.dailyClaimed } end
local function sync(source) TriggerClientEvent("bergischland:event:state", source, publicState(getState(source))) end
local function admin(source)
    if source == 0 or IsPlayerAceAllowed(source, "bergischland.eventadmin") then return true end
    local player = ESX and ESX.GetPlayerFromId(source)
    return player and Config.AdminGroups[player.getGroup()] == true or false
end
local function giveItem(source, item, amount)
    if not item or item == "" or Config.Inventory ~= "ox_inventory" then return true end
    if GetResourceState("ox_inventory") ~= "started" then
        print(("^1[%s] ox_inventory ist nicht gestartet, Item '%s' konnte nicht vergeben werden.^0"):format(resource, item))
        return false
    end
    return exports.ox_inventory:AddItem(source, item, amount or 1)
end
local function addCoins(source, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local state = getState(source); state.coins = state.coins + amount; saveData(); sync(source); return true
end
local function isJobAllowed(jobName)
    if not jobName or jobName == "unemployed" then return false end
    if next(Config.JobNames) == nil then return true end
    return Config.JobNames[jobName] == true
end
local function getJobName(source)
    local player = ESX and ESX.GetPlayerFromId(source)
    local job = player and player.getJob and player.getJob()
    return job and job.name or nil
end
local function processJobTime(source)
    if not ESX or not Config.JobRewardItem or Config.JobRewardItem == "" then return end
    local state = getState(source)
    local jobName = getJobName(source)
    local now = os.time()
    if not isJobAllowed(jobName) then
        state.jobName, state.jobSeconds, state.jobLastCheck = nil, 0, now
        return
    end
    if state.jobName ~= jobName then
        state.jobName, state.jobSeconds, state.jobLastCheck = jobName, 0, now
        saveData()
        return
    end
    local elapsed = math.max(0, math.min(now - (state.jobLastCheck or now), 300))
    state.jobLastCheck = now
    state.jobSeconds = (state.jobSeconds or 0) + elapsed
    local rewards = math.floor(state.jobSeconds / Config.JobRewardInterval)
    if rewards < 1 then return end
    local amount = rewards * Config.JobRewardAmount
    if not giveItem(source, Config.JobRewardItem, amount) then return end
    state.jobSeconds = state.jobSeconds - (rewards * Config.JobRewardInterval)
    saveData()
    TriggerClientEvent("bergischland:event:toast", source, ("+%d %s für deine Jobzeit erhalten."):format(amount, Config.JobRewardItem))
end
local function unlockAchievement(source, achievementId)
    achievementId = math.floor(tonumber(achievementId) or 0)
    if achievementId < 1 or achievementId > 8 then return false end
    local state = getState(source)
    for _, value in ipairs(state.achievements) do if value == achievementId then return false end end
    table.insert(state.achievements, achievementId); saveData(); sync(source); return true
end

loadData()
exports("AddEventCoins", addCoins)
exports("UnlockEventAchievement", unlockAchievement)
exports("GetEventState", function(source) return publicState(getState(source)) end)
CreateThread(function()
    while true do
        Wait(60000)
        for _, playerId in ipairs(GetPlayers()) do processJobTime(tonumber(playerId)) end
    end
end)
RegisterNetEvent("bergischland:event:requestState", function() sync(source) end)
RegisterNetEvent("bergischland:event:requestAdminOpen", function() if admin(source) then TriggerClientEvent("bergischland:event:openAdmin", source) else TriggerClientEvent("bergischland:event:toast", source, "Keine Berechtigung für den Admin-Befehl.") end end)
RegisterNetEvent("bergischland:event:unlockLevel", function(level)
    local state = getState(source); if type(level) ~= "number" or level ~= state.level or level > 50 then return end
    local price = 100 + (level - 1) * 25; if state.coins < price then TriggerClientEvent("bergischland:event:toast", source, "Nicht genug Event-Coins."); return end
    local reward = Config.PassRewardItems[level]
    if reward and not giveItem(source, reward.item, reward.amount) then TriggerClientEvent("bergischland:event:toast", source, "Belohnung konnte nicht ins Inventar gelegt werden."); return end
    state.coins = state.coins - price; state.level = state.level + 1; saveData(); sync(source); TriggerClientEvent("bergischland:event:toast", source, ("Stufe %d freigeschaltet."):format(level))
end)
RegisterNetEvent("bergischland:event:claimDaily", function()
    local state = getState(source); if state.dailyClaimed then TriggerClientEvent("bergischland:event:toast", source, "Die Tagesbelohnung ist noch nicht verfügbar."); return end
    local rewards = { 50, 75, 100, 125, 150, 175, 250, 75, 100, 125, 150, 175, 200, 300 }; local reward = rewards[state.dailyDay] or rewards[1]
    if Config.DailyRewardItem and not giveItem(source, Config.DailyRewardItem, Config.DailyRewardItemAmount) then TriggerClientEvent("bergischland:event:toast", source, "Tagesbelohnung konnte nicht ins Inventar gelegt werden."); return end
    state.coins = state.coins + reward; state.dailyClaimed = true; state.dailyClaimedAt = os.time(); table.insert(state.claimedDays, state.dailyDay); saveData(); sync(source); TriggerClientEvent("bergischland:event:toast", source, ("+%d Event-Coins erhalten."):format(reward))
end)