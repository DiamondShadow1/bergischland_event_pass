local resource = GetCurrentResourceName()
local players = {}
local defaultState = {
    identifier = nil,
    coins = 0,
    level = 1,
    claimedDays = {},
    achievements = {},
    dailyDay = 1,
    dailyClaimed = false,
    dailyClaimedAt = 0,
    jobName = nil,
    jobSeconds = 0,
    jobLastCheck = 0,
    currentEvent = Config.CurrentEvent or "bergischland_monthly",
    eventName = Config.EventName or "Bergischland Event",
    experience = 0,
    totalProgress = 0,
    completedTasks = {},
    dailyRewards = {},
    claimStatus = {}
}
local ESX
local dbTable = Config.DatabaseTable or "bergischland_event_pass"

if Config.Framework == "esx" then
    ESX = exports["es_extended"]:getSharedObject()
end

local function debugLog(message, ...) if Config.Debug then print(("[^3%s^0] %s"):format(resource, string.format(message, ...))) end end
local function deepCopy(value)
    if value == nil then return nil end
    return json.decode(json.encode(value))
end
local function parseJsonArray(value, fallback)
    if type(value) ~= "string" or value == "" then return deepCopy(fallback or {}) end
    local ok, decoded = pcall(json.decode, value)
    if ok and type(decoded) == "table" then return decoded end
    return deepCopy(fallback or {})
end
local function identifier(source)
    local ids = GetPlayerIdentifiers(source)
    for _, value in ipairs(ids) do
        if value:sub(1, 8) == "license:" then return value end
    end
    return ids[1] or ("source:" .. tostring(source))
end
local function stateFromRow(row)
    local state = deepCopy(defaultState)
    if not row then return state end

    state.identifier = row.identifier
    state.coins = tonumber(row.coins) or 0
    state.level = tonumber(row.pass_level) or 1
    state.claimedDays = parseJsonArray(row.daily_rewards, {})
    state.achievements = parseJsonArray(row.achievements, {})
    state.dailyDay = tonumber(row.daily_day) or 1
    state.dailyClaimed = row.daily_claimed == true or row.daily_claimed == 1 or row.daily_claimed == "1"
    state.dailyClaimedAt = tonumber(row.daily_claimed_at) or 0
    state.currentEvent = row.current_event or state.currentEvent
    state.eventName = row.event_name or state.eventName
    state.experience = tonumber(row.experience) or 0
    state.totalProgress = tonumber(row.total_progress) or 0
    state.completedTasks = parseJsonArray(row.completed_tasks, {})
    state.dailyRewards = parseJsonArray(row.daily_rewards, {})
    state.claimStatus = parseJsonArray(row.claim_status, {})
    return state
end
local function savePlayerState(targetIdentifier, state)
    if not targetIdentifier then return false end

    local payload = {
        ["@identifier"] = targetIdentifier,
        ["@coins"] = tonumber(state.coins) or 0,
        ["@pass_level"] = tonumber(state.level) or 1,
        ["@experience"] = tonumber(state.experience) or 0,
        ["@completed_tasks"] = json.encode(state.completedTasks or {}),
        ["@daily_rewards"] = json.encode(state.dailyRewards or state.claimedDays or {}),
        ["@claim_status"] = json.encode(state.claimStatus or {
            dailyDay = state.dailyDay or 1,
            dailyClaimed = state.dailyClaimed == true,
            dailyClaimedAt = tonumber(state.dailyClaimedAt) or 0
        }),
        ["@achievements"] = json.encode(state.achievements or {}),
        ["@total_progress"] = tonumber(state.totalProgress) or 0,
        ["@event_name"] = state.eventName or Config.EventName or "Bergischland Event",
        ["@current_event"] = state.currentEvent or Config.CurrentEvent or "bergischland_monthly",
        ["@daily_day"] = tonumber(state.dailyDay) or 1,
        ["@daily_claimed"] = state.dailyClaimed and 1 or 0,
        ["@daily_claimed_at"] = tonumber(state.dailyClaimedAt) or 0,
        ["@last_seen"] = os.time()
    }

    local query = string.format([[
        INSERT INTO `%s` (
            identifier, coins, pass_level, experience, completed_tasks, daily_rewards, claim_status, achievements,
            total_progress, event_name, current_event, daily_day, daily_claimed, daily_claimed_at, last_seen
        ) VALUES (
            @identifier, @coins, @pass_level, @experience, @completed_tasks, @daily_rewards, @claim_status, @achievements,
            @total_progress, @event_name, @current_event, @daily_day, @daily_claimed, @daily_claimed_at, @last_seen
        ) ON DUPLICATE KEY UPDATE
            coins = VALUES(coins),
            pass_level = VALUES(pass_level),
            experience = VALUES(experience),
            completed_tasks = VALUES(completed_tasks),
            daily_rewards = VALUES(daily_rewards),
            claim_status = VALUES(claim_status),
            achievements = VALUES(achievements),
            total_progress = VALUES(total_progress),
            event_name = VALUES(event_name),
            current_event = VALUES(current_event),
            daily_day = VALUES(daily_day),
            daily_claimed = VALUES(daily_claimed),
            daily_claimed_at = VALUES(daily_claimed_at),
            last_seen = VALUES(last_seen)
    ]], dbTable)

    MySQL.query.await(query, payload)
    return true
end
local function loadPlayerFromDatabase(identifier)
    if not identifier then return deepCopy(defaultState) end

    local rows = MySQL.query.await(string.format("SELECT * FROM `%s` WHERE identifier = @identifier LIMIT 1", dbTable), {
        ["@identifier"] = identifier
    })

    local row = rows and rows[1]
    if row then return stateFromRow(row) end

    local newState = deepCopy(defaultState)
    newState.identifier = identifier
    savePlayerState(identifier, newState)
    return newState
end
local function getState(source)
    local targetIdentifier = identifier(source)
    if not players[targetIdentifier] then
        players[targetIdentifier] = loadPlayerFromDatabase(targetIdentifier)
    end

    local state = players[targetIdentifier]
    local now = os.time()
    if state.dailyClaimed and (state.dailyClaimedAt or 0) > 0 and now - state.dailyClaimedAt >= 86400 then
        state.dailyClaimed = false
        state.dailyClaimedAt = 0
        state.dailyDay = (state.dailyDay % 14) + 1
        savePlayerState(targetIdentifier, state)
    end

    return state
end
local function publicState(state)
    return {
        coins = state.coins,
        level = state.level,
        claimedDays = state.claimedDays,
        achievements = state.achievements,
        dailyDay = state.dailyDay,
        dailyClaimed = state.dailyClaimed
    }
end
local function sync(source)
    TriggerClientEvent("bergischland:event:state", source, publicState(getState(source)))
end
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
    local state = getState(source)
    state.coins = (state.coins or 0) + amount
    savePlayerState(state.identifier or identifier(source), state)
    sync(source)
    return true
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
        savePlayerState(state.identifier or identifier(source), state)
        return
    end
    if state.jobName ~= jobName then
        state.jobName, state.jobSeconds, state.jobLastCheck = jobName, 0, now
        savePlayerState(state.identifier or identifier(source), state)
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
    savePlayerState(state.identifier or identifier(source), state)
    TriggerClientEvent("bergischland:event:toast", source, ("+%d %s für deine Jobzeit erhalten."):format(amount, Config.JobRewardItem))
end
local function unlockAchievement(source, achievementId)
    achievementId = math.floor(tonumber(achievementId) or 0)
    if achievementId < 1 or achievementId > 8 then return false end
    local state = getState(source)
    for _, value in ipairs(state.achievements) do if value == achievementId then return false end end
    table.insert(state.achievements, achievementId)
    state.totalProgress = state.totalProgress + 1
    savePlayerState(state.identifier or identifier(source), state)
    sync(source)
    return true
end

if GetResourceState("oxmysql") ~= "started" then
    print(("^1[%s] oxmysql ist nicht gestartet. SQL-Persistenz wird nicht aktiv sein.^0"):format(resource))
end

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
    local state = getState(source)
    if type(level) ~= "number" or level ~= state.level or level > Config.MaxPassLevel then return end
    local price = 100 + (level - 1) * 25
    if state.coins < price then TriggerClientEvent("bergischland:event:toast", source, "Nicht genug Event-Coins."); return end
    local reward = Config.PassRewardItems[level]
    if reward and not giveItem(source, reward.item, reward.amount) then TriggerClientEvent("bergischland:event:toast", source, "Belohnung konnte nicht ins Inventar gelegt werden."); return end
    state.coins = state.coins - price
    state.level = state.level + 1
    state.totalProgress = math.max(state.totalProgress, state.level)
    savePlayerState(state.identifier or identifier(source), state)
    sync(source)
    TriggerClientEvent("bergischland:event:toast", source, ("Stufe %d freigeschaltet."):format(level))
end)
RegisterNetEvent("bergischland:event:claimDaily", function()
    local state = getState(source)
    if state.dailyClaimed then TriggerClientEvent("bergischland:event:toast", source, "Die Tagesbelohnung ist noch nicht verfügbar."); return end
    local rewards = { 50, 75, 100, 125, 150, 175, 250, 75, 100, 125, 150, 175, 200, 300 }
    local reward = rewards[state.dailyDay] or rewards[1]
    if Config.DailyRewardItem and not giveItem(source, Config.DailyRewardItem, Config.DailyRewardItemAmount) then TriggerClientEvent("bergischland:event:toast", source, "Tagesbelohnung konnte nicht ins Inventar gelegt werden."); return end
    state.coins = state.coins + reward
    state.dailyClaimed = true
    state.dailyClaimedAt = os.time()
    state.claimedDays = state.claimedDays or {}
    table.insert(state.claimedDays, state.dailyDay)
    state.dailyRewards = state.claimedDays
    state.claimStatus = {
        dailyDay = state.dailyDay,
        dailyClaimed = true,
        dailyClaimedAt = state.dailyClaimedAt
    }
    savePlayerState(state.identifier or identifier(source), state)
    sync(source)
    TriggerClientEvent("bergischland:event:toast", source, ("+%d Event-Coins erhalten."):format(reward))
end)