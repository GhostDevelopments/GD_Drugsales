-- server.lua
local QBCore = exports['qb-core']:GetCoreObject()
local isRestartScheduled = false

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    if eventData.secondsRemaining == 300 then
        isRestartScheduled = true
    end
end)

RegisterCommand('dealer', function(source, args, rawcommand)
    if isRestartScheduled then
        TriggerClientEvent('ox_lib:notify', source, {title = 'Drugs', description = 'Cannot use dealer command during scheduled restart.', duration = 5000, position = 'center-right', icon = 'pills'})
        return
    end
    local Player = QBCore.Functions.GetPlayer(source)
    drugToSell = {
        type = '',
        label = '',
        count = 0,
        i = 0,
        price = 0,
    }
    for k, v in pairs(Config.drugs) do
        local item = Player.Functions.GetItemByName(k)
            
        if item == nil then
            return        
        end
            
        count = item.amount
        drugToSell.i = drugToSell.i + 1
        drugToSell.type = k
        drugToSell.label = QBCore.Shared.Items[k].label
        
        if count >= 5 then
            drugToSell.count = math.random(1, 5)
        elseif count > 0 then
            drugToSell.count = math.random(1, count)
        end

        if drugToSell.count ~= 0 then
            drugToSell.price = drugToSell.count * v + math.random(1, 300)
            TriggerClientEvent('stasiek_selldrugsv2:findClient', source, drugToSell)
            break
        end
        
        if #Config.drugs == drugToSell.i and drugToSell.count == 0 then
            TriggerClientEvent('ox_lib:notify', source, {title = 'Drugs', description = Config.notify.nodrugs, duration = 8000, position = 'center-right', icon = 'pills'})
        end
    end
end, false)

RegisterServerEvent('stasiek_selldrugsv2:pay')
AddEventHandler('stasiek_selldrugsv2:pay', function(drugToSell)
    local Player = QBCore.Functions.GetPlayer(source)
    Player.Functions.RemoveItem(drugToSell.type, drugToSell.count)
    Player.Functions.AddItem(Config.account, drugToSell.price)
end)

RegisterServerEvent('stasiek_selldrugsv2:notifycops')
AddEventHandler('stasiek_selldrugsv2:notifycops', function(drugToSell)
    -- If the player has the police job, continue with the notification.
    TriggerClientEvent('stasiek_selldrugsv2:notifyPolice', -1, drugToSell.coords)
end)

lib.callback.register('stasiek_selldrugsv2:getPoliceCount', function(source)
    local count = 0

    local Players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(Players) do
        if v.PlayerData.job.name == "police" then
            count = count + 1
        end
    end
    return count
end)