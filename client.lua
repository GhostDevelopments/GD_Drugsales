-- client.lua
local QBCore = exports['qb-core']:GetCoreObject()
PlayerData = {}
npc = {}
cooldown = false
blips = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData')
AddEventHandler('QBCore:Player:SetPlayerData', function(key, val)
    if key == 'job' then
        PlayerData.job = val
    end
end)

local function DrawText3D(coords, text, size)
    local camCoords = GetGameplayCamCoords()
    local dist = #(coords - camCoords)
    local scale = (size / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov
    SetTextScale(0.0, scale * 0.55)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(coords, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function Round(num)
    return math.floor(num + 0.5)
end

local function PlayAnim(dict, anim, speed, time, flag)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
    TaskPlayAnim(PlayerPedId(), dict, anim, speed, speed, time, flag, 1, false, false, false)
end

local function PlayAnimOnPed(ped, dict, anim, speed, time, flag)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
    TaskPlayAnim(ped, dict, anim, speed, speed, time, flag, 1, false, false, false)
end

local function MakeEntityFaceEntity(entity1, entity2)
    local p1 = GetEntityCoords(entity1, true)
    local p2 = GetEntityCoords(entity2, true)

    local dx = p2.x - p1.x
    local dy = p2.y - p1.y

    local heading = GetHeadingFromVector_2d(dx, dy)
    SetEntityHeading(entity1, heading)
end

Citizen.CreateThread(function()
    while PlayerData.job == nil do
        Citizen.Wait(5000)
    end

    PlayerData = QBCore.Functions.GetPlayerData()
    RequestStreamedTextureDict('DIA_CLIFFORD')
end)

next_ped = function(drugToSell)

    if cooldown then
        lib.notify({
            title = Config.notify.title,
            description = Config.notify.cooldown,
            position = 'center-right',
            duration = 8000,
            icon = 'pills'
        })
        return
    end

    cooldown = true

    if Config.cityPoint ~= false and #(GetEntityCoords(PlayerPedId()) - Config.cityPoint) > 1500.0 then
        lib.notify({
            title = Config.notify.title,
            description = Config.notify.toofar,
            position = 'center-right',
            duration = 8000,
            icon = 'pills'
        })
        return
    end

    if npc ~= nil and npc.ped ~= nil then
        SetPedAsNoLongerNeeded(npc.ped)
        DeletePed(npc.ped)
    end

    cops = 0
    cops = lib.callback.await('stasiek_selldrugsv2:getPoliceCount', false)

    if cops < Config.requiredCops then
        lib.notify({
            title = Config.notify.title,
            description = Config.notify.cops,
            position = 'center-right',
            duration = 8000,
            icon = 'pills'
        })
        return
    end

    if cops == 3 then
        drugToSell.price = Round(drugToSell.price * 1.03)
    elseif cops == 4 then
        drugToSell.price = Round(drugToSell.price * 1.05)
    elseif cops == 5 then
        drugToSell.price = Round(drugToSell.price * 1.07)
    elseif cops == 6 then
        drugToSell.price = Round(drugToSell.price * 1.10)
    elseif cops >= 7 then
        drugToSell.price = Round(drugToSell.price * 1.14)
    end

    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_STAND_MOBILE", 0, true)
    LocalPlayer.state.invBusy = true
    lib.notify({
        title = Config.notify.title,
        description = Config.notify.searching .. drugToSell.label,
        position = 'center-right',
        duration = 8000,
        icon = 'pills'
    })
    Wait(math.random(5000, 10000))
    ClearPedTasks(PlayerPedId()) 
    npc.hash = GetHashKey(Config.pedlist[math.random(1, #Config.pedlist)])
    RequestModel(npc.hash)
    while not HasModelLoaded(npc.hash) do
        Wait(0)
    end
    npc.coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 50.0, 5.0)
    retval, npc.z = GetGroundZFor_3dCoord(npc.coords.x, npc.coords.y, npc.coords.z, 0)

    if retval == false then
        cooldown = false
        lib.notify({
            title = Config.notify.title,
            description = Config.notify.abort,
            position = 'center-right',
            duration = 8000,
            icon = 'pills'
        })
        LocalPlayer.state.invBusy = false
        ClearPedTasks(PlayerPedId())
        return
    end

    npc.zone = GetLabelText(GetNameOfZone(npc.coords))
    drugToSell.zone = npc.zone
    npc.ped = CreatePed(5, npc.hash, npc.coords.x, npc.coords.y, npc.z, 0.0, true, true)
    PlaceObjectOnGroundProperly(npc.ped)
    SetEntityAsMissionEntity(npc.ped)
    
    if IsEntityDead(npc.ped) or GetEntityCoords(npc.ped) == vector3(0.0, 0.0, 0.0) then
        lib.notify({
            title = Config.notify.title,
            description = Config.notify.notfound,
            position = 'center-right',
            duration = 8000,
            icon = 'pills'
        })
        LocalPlayer.state.invBusy = false
        return
    end
    lib.notify({
        title = Config.notify.title,
        description = Config.notify.approach, Config.notify.found .. npc.zone,
        position = 'center-right',
        duration = 8000,
        icon = 'pills'
    })
    TaskGoToEntity(npc.ped, PlayerPedId(), 60000, 4.0, 2.0, 0, 0)

    CreateThread(function()
        canSell = true
        while npc.ped ~= nil and npc.ped ~= 0 and not IsEntityDead(npc.ped) do
            Wait(0)
            npc.coords = GetEntityCoords(npc.ped)
            DrawText3D(npc.coords, (Config.notify.client):format(drugToSell.count, drugToSell.label), 0.5)
            distance = #(GetEntityCoords(PlayerPedId()) - npc.coords)^2
            
            if distance >= 6.25 then
                if (IsControlJustPressed(0, 49) or IsControlJustPressed(0, 73)) and canSell then
                    canSell = false
                    lib.hideTextUI()
                    lib.notify({
                        title = Config.notify.title,
                        description = Config.notify.cancelsell,
                        position = 'center-right',
                        duration = 8000,
                        style = {
                            backgroundColor = '#141517',
                            color = '#EE4B2B',
                            ['.description'] = {
                              color = '#FFFFFF'
                            }
                        },
                        icon = 'pills',
                        iconColor = '#EE4B2B'
                    })
                    SetPedAsNoLongerNeeded(npc.ped)
                    npc = {}
                    Wait(500)
                    LocalPlayer.state.invBusy = false
                end
            end
            
            if distance < 4.0 then
                lib.showTextUI('[E] - Sell Drugs to Local', {
                    position = "right-center",
                    icon = 'pills',
                })
                if (IsControlJustPressed(0, 49) or IsControlJustPressed(0, 73)) and canSell then
                    canSell = false
                    lib.hideTextUI()
                    lib.notify({
                        title = Config.notify.title,
                        description = Config.notify.cancelsell,
                        position = 'center-right',
                        duration = 8000,
                        style = {
                            backgroundColor = '#141517',
                            color = '#EE4B2B',
                            ['.description'] = {
                              color = '#FFFFFF'
                            }
                        },
                        icon = 'pills',
                        iconColor = '#EE4B2B'
                    })
                    SetPedAsNoLongerNeeded(npc.ped)
                    npc = {}
                    Wait(500)
                    LocalPlayer.state.invBusy = false
                elseif IsControlJustPressed(0, 38) and canSell then
                    canSell = false
                    lib.hideTextUI()
                    LocalPlayer.state.invBusy = true 
                    
                    reject = math.random(1, 100)
                    alert = math.random(1, 100)
                    
                    if reject <= 45 then
                        lib.notify({
                            title = Config.notify.title,
                            description = Config.notify.reject,
                            position = 'center-right',
                            duration = 8000,
                            style = {
                                backgroundColor = '#141517',
                                color = '#EE4B2B',
                                ['.description'] = {
                                  color = '#FFFFFF'
                                }
                            },
                            icon = 'pills',
                            iconColor = '#EE4B2B'
                        })
                        PlayAmbientSpeech1(npc.ped, 'GENERIC_HI', 'SPEECH_PARAMS_STANDARD')
                        drugToSell.coords = GetEntityCoords(PlayerPedId())
                        TriggerServerEvent('stasiek_selldrugsv2:notifycops', drugToSell)
                        SetPedAsNoLongerNeeded(npc.ped)
                        if Config.npcFightOnReject then
                            TaskCombatPed(npc.ped, PlayerPedId(), 0, 16)
                        end
                        npc = {}
                        Wait(500)
                        LocalPlayer.state.invBusy = false  
                        return
                    end
    
                    if IsPedInAnyVehicle(PlayerPedId(), false) then
                        lib.notify({
                            title = Config.notify.title,
                            description = Config.notify.vehicle,
                            duration = 8000,
                            icon = 'pills',
                            type = 'success'
                        })
                        Wait(500)
                        LocalPlayer.state.invBusy = false
                        return
                    end
    
                    
                    MakeEntityFaceEntity(PlayerPedId(), npc.ped)
                    MakeEntityFaceEntity(npc.ped, PlayerPedId())
                    SetPedTalk(npc.ped)
                    PlayAmbientSpeech1(npc.ped, 'GENERIC_HI', 'SPEECH_PARAMS_STANDARD')
                    
                    
                    obj = CreateObject(GetHashKey('prop_weed_bottle'), 0, 0, 0, true)
                    AttachEntityToEntity(obj, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.13, 0.02, 0.0, -90.0, 0, 0, 1, 1, 0, 1, 0, 1)
                    obj2 = CreateObject(GetHashKey('hei_prop_heist_cash_pile'), 0, 0, 0, true)
                    AttachEntityToEntity(obj2, npc.ped, GetPedBoneIndex(npc.ped, 57005), 0.13, 0.02, 0.0, -90.0, 0, 0, 1, 1, 0, 1, 0, 1)
                    
                    PlayAnim('mp_common', 'givetake1_a', 8.0, -1, 0)
                    PlayAnimOnPed(npc.ped, 'mp_common', 'givetake1_a', 8.0, -1, 0)
                    Wait(1000)
                    
                    if alert <= 23 then
                        PlayAmbientSpeech1(npc.ped, 'GENERIC_HI', 'SPEECH_PARAMS_STANDARD')
                        drugToSell.coords = GetEntityCoords(PlayerPedId())
                        TriggerServerEvent('stasiek_selldrugsv2:notifycops', drugToSell)
                    end
                    
                    AttachEntityToEntity(obj2, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.13, 0.02, 0.0, -90.0, 0, 0, 1, 1, 0, 1, 0, 1)
                    AttachEntityToEntity(obj, npc.ped, GetPedBoneIndex(npc.ped, 57005), 0.13, 0.02, 0.0, -90.0, 0, 0, 1, 1, 0, 1, 0, 1)
                    Wait(1000)
                    
                    DeleteEntity(obj)
                    DeleteEntity(obj2)
                    PlayAmbientSpeech1(npc.ped, 'GENERIC_THANKS', 'SPEECH_PARAMS_STANDARD')
                    SetPedAsNoLongerNeeded(npc.ped)
                    TriggerServerEvent('stasiek_selldrugsv2:pay', drugToSell)
                    
                    lib.notify({
                        title = Config.notify.title,
                        description = (Config.notify.sold):format(drugToSell.count, drugToSell.label, drugToSell.price),
                        position = 'center-right',
                        duration = 8000,
                        icon = 'pills'
                    })
                    
                    Wait(7000)
                    LocalPlayer.state.invBusy = false 
                    npc = {}
                    canSell = true 
                end
            end
        end
    end)
end

CreateThread(function()
    while true do
        Wait(20000)
        if cooldown then
            cooldown = false
        end
    end
end)

RegisterNetEvent('stasiek_selldrugsv2:findClient')
AddEventHandler('stasiek_selldrugsv2:findClient', next_ped)

RegisterNetEvent('stasiek_selldrugsv2:notifyPolice')
AddEventHandler('stasiek_selldrugsv2:notifyPolice', function(coords)	
    if PlayerData.job ~= nil and PlayerData.job.name == 'police' then
        street = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        street2 = GetStreetNameFromHashKey(street)
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
        PlaySoundFrontend(-1, "Bomb_Disarmed", "GTAO_Speed_Convoy_Soundset", 0)

        blip = AddBlipForCoord(coords)
        SetBlipSprite(blip,  403)
        SetBlipColour(blip,  1)
        SetBlipAlpha(blip, 250)
        SetBlipScale(blip, 1.2)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString('# Selling Drugs')
        EndTextCommandSetBlipName(blip)
        table.insert(blips, blip)
        Wait(90000)
        for i in pairs(blips) do
            RemoveBlip(blips[i])
            blips[i] = nil
        end
    end
end)