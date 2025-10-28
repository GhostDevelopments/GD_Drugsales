local QBCore = exports['qb-core']:GetCoreObject()
local isRestartScheduled = false

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    if eventData.secondsRemaining == 300 then
        isRestartScheduled = true
    end
end)

RegisterCommand('dealer', function(source)
    if isRestartScheduled then
        TriggerClientEvent('ox_lib:notify', source, {title = 'Drugs', description = 'Cannot use dealer command during scheduled restart.', duration = 5000, position = 'center-right', icon = 'pills'})
        return
    end

    local Player = QBCore.Functions.GetPlayer(source)
    local drugToSell = nil

    for k, v in pairs(Config.drugs) do
        local item = Player.Functions.GetItemByName(k)
        if item and item.amount > 0 then
            local count = item.amount
            local sellCount = (count >= 5) and math.random(1, 5) or math.random(1, count)
            local price = sellCount * v + math.random(1, 300)

            drugToSell = {
                type = k,
                label = QBCore.Shared.Items[k].label,
                count = sellCount,
                price = price
            }
            TriggerClientEvent('stasiek_selldrugsv2:findClient', source, drugToSell)
            return
        end
    end

    TriggerClientEvent('ox_lib:notify', source, {title = 'Drugs', description = Config.notify.nodrugs, duration = 8000, position = 'center-right', icon = 'pills'})
end, false)

RegisterServerEvent('stasiek_selldrugsv2:pay')
AddEventHandler('stasiek_selldrugsv2:pay', function(drugToSell)
    local Player = QBCore.Functions.GetPlayer(source)
    Player.Functions.RemoveItem(drugToSell.type, drugToSell.count)
    Player.Functions.AddItem(Config.account, drugToSell.price)
end)

RegisterServerEvent('stasiek_selldrugsv2:notifycops')
AddEventHandler('stasiek_selldrugsv2:notifycops', function(drugToSell)
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
