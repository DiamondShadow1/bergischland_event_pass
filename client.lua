local isOpen = false

local function setOpen(open, admin)
    isOpen = open
    SetNuiFocus(open, open)
    SendNUIMessage({ action = open and "open" or "close", isAdmin = admin == true })
    if open then TriggerServerEvent("bergischland:event:requestState") end
end

RegisterCommand("bergischlandevent", function() TriggerServerEvent("bergischland:event:requestAdminOpen") end, false)
RegisterKeyMapping("bergischlandevent_open", "Bergischland Event öffnen", "keyboard", "F11")
RegisterCommand("bergischlandevent_open", function() setOpen(not isOpen, false) end, false)
RegisterNetEvent("bergischland:event:openAdmin", function() setOpen(true, true) end)
RegisterNetEvent("bergischland:event:state", function(state) SendNUIMessage({ action = "state", state = state }) end)
RegisterNetEvent("bergischland:event:toast", function(message) SendNUIMessage({ action = "toast", message = message }) end)
RegisterNUICallback("close", function(_, callback) setOpen(false); callback({ ok = true }) end)
RegisterNUICallback("unlockLevel", function(data, callback) TriggerServerEvent("bergischland:event:unlockLevel", tonumber(data.level)); callback({ ok = true }) end)
RegisterNUICallback("claimDaily", function(_, callback) TriggerServerEvent("bergischland:event:claimDaily"); callback({ ok = true }) end)