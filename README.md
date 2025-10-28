GD Drugsales Is The Best Way To Sell Drugs ON Fivem

    [ client sided code ]
    
    local data = exports['cd_dispatch']:GetPlayerInfo()
	TriggerServerEvent('cd_dispatch:AddNotification', {
    	job_table = {'police'}, 
    	coords = npc.ped,
    	title = '10-15 - Drug Sale',
    	message = 'A '..data.sex..' is selling drugs near '..data.street, 
    	flash = 0,
    	unique_id = tostring(math.random(0000000,9999999)),
    	blip = {
        	sprite = 431, 
        	scale = 1.2, 
        	colour = 3,
        	flashes = false, 
        	text = '911 - Drug Sales',
        	time = (5*60*1000),
        	sound = 1,
    	}
	})

    -- for cd_dispatch integration add the above under line 367 in client.lua & remove
	lib.notify({
		title = Config.notify.police_notify_title,
		description = Config.notify.police_notify_subtitle .. " at " .. street2,
		icon = 'pills',
		iconAnimation = 'pulse',
		position = 'center-left',
		duration = 12500,
		type = 'error',
		style = {
			backgroundColor = '#141517',
			color = '#EE4B2B',
			['.description'] = {
			  color = '#FFFFFF'
			}
		},
	})

    -----------------------------------------

    [ server sided code ]

    TriggerClientEvent('cd_dispatch:AddNotification', -1, {
        job_table = {'police'},
        coords = drugToSell.coords,
        title = '10-15 - Drug Sale',
        message = 'Someone is selling drugs',
        flash = 0,
        unique_id = tostring(math.random(0000000,9999999)),
        blip = {
            sprite = 403,
            scale = 1.2,
            colour = 1,
            flashes = false,
            text = '911 - Drug Sale',
            time = (5*60*1000),
            sound = 1,
        }
    })

    -- for cd_dispatch integration add the above under line 90 in server.lua & remove
    TriggerClientEvent('stasiek_selldrugsv2:notifyPolice', -1, drugToSell.coords)

-----------------------------------------

If you want to make required item before you can do /dealer, replace this on server-side.

RegisterCommand('dealer', function(source, args, rawcommand)
    xPlayer = ESX.GetPlayerFromId(source)
    local hasRequiredItem = xPlayer.getInventoryItem('trapphone') -- change me to whatever item u want

    if hasRequiredItem == nil or hasRequiredItem.count <= 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Drugs',
            description = 'You need a trap phone to sell drugs.', -- change the name here too, this is the notification
            duration = 5000,
            position = 'center-right',
            icon = 'pills'
        })
        return
    end

    if isRestartScheduled then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Drugs',
            description = 'Cannot use dealer command during scheduled restart.',
            duration = 5000,
            position = 'center-right',
            icon = 'pills'
        })
        return
    end

    local drugToSell = {
        type = '',
        label = '',
        count = 0,
        i = 0,
        price = 0,
    }

    for k, v in pairs(Config.drugs) do
        local item = xPlayer.getInventoryItem(k)
        
        if item == nil then
            return        
        end
        
        local count = item.count
        drugToSell.i = drugToSell.i + 1
        drugToSell.type = k
        drugToSell.label = item.label
        
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
        
        if ESX.Table.SizeOf(Config.drugs) == drugToSell.i and drugToSell.count == 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Drugs',
                description = Config.notify.nodrugs,
                duration = 8000,
                position = 'center-right',
                icon = 'pills'
            })
        end
    end
end, false)

