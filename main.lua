
local deliveryman = false
local shopBlips = {}

local QBCore = exports['qb-core']:GetCoreObject()

Citizen.CreateThread(function()
    for k,v in pairs(Config.Models) do
        RequestModel(v)
        while not HasModelLoaded(v) do Wait(10) end
    end
    RequestAnimDict("anim@heists@box_carry@")
    RequestAnimDict("mp_am_hold_up")
    while not HasAnimDictLoaded("anim@heists@box_carry@") do Wait(10) end
    while not HasAnimDictLoaded("mp_am_hold_up") do Wait(10) end
    for k,v in pairs(Config.WeaponShops) do
        exports['qb-target']:SpawnPed({
            model = Config.Models.ped,
            coords = v.pedlocation,
            minusOne = true,
            freeze = true,
            invincible = true,
            blockevents = true,
            animDict = 'abigail_mcs_1_concat-0',
            anim = 'csb_abigail_dual-0',
            flag = 1,
            scenario = 'WORLD_HUMAN_GUARD_STAND_CASINO',
            target = {
                options = {
                    {
                        icon = "fas fa-sign-in-alt",
                        label = 'Take Over Shop',
                        action = function ()
                            Rob()
                        end
                    }
                },
            distance = 2.5,
            },
            spawnNow = true,
            currentpednumber = k,
          })
        local blip = AddBlipForRadius(Config.WeaponShops[k].pedlocation, 1.0)
        SetBlipSprite(blip, 9)
        SetBlipColour(blip, 0)
        SetBlipAlpha(blip, 64)
        SetBlipScale(blip, 40.0)
        SetBlipAsShortRange(blip, true)
        local gunblipz = AddBlipForCoord(Config.WeaponShops[k].pedlocation)
        SetBlipSprite(gunblipz, 110)
        SetBlipColour(gunblipz, 0)
        shopBlips[k] = {
            radius = blip,
            gunblip = gunblipz,
        }
    end
    TriggerServerEvent("ammu:requestBlip")
end)



function Rob()
    local closestShop = ClosestShop()
    QBCore.Functions.TriggerCallback('ammu:checkOwned', function(can)
        print(can)
        if not can then
            TriggerEvent('fallouthacking:client:StartMinigame', 5, 4, function(winner)
                if winner then
                    TriggerEvent("QBCore:Notify", "Hey what u doin")
                    SetRelationshipBetweenGroups(0, "Enemy", "Enemy")
                    RequestModel(Config.Models.guard)
                    while not HasModelLoaded(Config.Models.guard) do Wait(10) end
                    local ped = CreatePed(1, Config.Models.guard, Config.WeaponShops[closestShop].guardlocation, 0.0, false, true)
                    GiveWeaponToPed(ped, "WEAPON_PISTOL", 1000, false, true)
                    TaskCombatPed(ped, PlayerPedId(), true, true)
                    while true do
                        if IsEntityDead(ped) then
                            TriggerServerEvent("ammu:regionWin", closestShop)
                            break
                        else
                            if GetEntityHealth(ped) <= 0 then
                                break
                            end
                        end
                        Wait(1000)
                    end
               end
           end)
       end
    end, closestShop)

end

function ClosestShop()
    local coords = GetEntityCoords(PlayerPedId())
    local closestShop = false
    local dist = false
    for k,v in pairs(Config.WeaponShops) do
        if not dist then
            dist = #(coords - vec3(v.pedlocation.x, v.pedlocation.y, v.pedlocation.z))
            closestShop = k
        else
            if #(coords - vec3(v.pedlocation.x, v.pedlocation.y, v.pedlocation.z)) <= dist then
                dist = #(coords - vec3(v.pedlocation.x, v.pedlocation.y, v.pedlocation.z))
                closestShop = k
            end
        end 
    end
    return closestShop
end



RegisterNetEvent("qb-ammu:SetBlips", function(data)
    for k,v in pairs(data) do
        if v.Owned ~= "none" then
            SetBlipSprite(shopBlips[k].gunblip, Config.Gangs[v.Owned].BlipID)
            SetBlipColour(shopBlips[k].radius, Config.Gangs[v.Owned].Colour)
            SetBlipColour(shopBlips[k].gunblip, Config.Gangs[v.Owned].Colour)
        end
    end
end)


AddStateBagChangeHandler('ammubag' , nil, function(bagName, key, value, _unused, replicated)
    if value then
        local ped = NetToPed(value.pedid)
        local veh = NetToVeh(value.vehid)
        while NetworkGetEntityOwner(ped) == -1 do Wait(10) end
        if NetworkHasControlOfEntity(ped) then
            SetBlockingOfNonTemporaryEvents(ped, true)
            TaskVehicleDriveToCoordLongrange(ped, veh, value.pedwalk, 5.0, 786468, 5.0)
        end
    end
end)

RegisterNetEvent("ammu:startwalk", function (netId,vnetId, coords)
    local ped = NetToPed(netId)
    local vehicle = NetToVeh(vnetId)
    TaskVehicleDriveToCoordLongrange(ped, vehicle, coords, 5.0, 786468, 5.0)
end)


Citizen.CreateThread(function()
    while true do
        Wait(2000)
        local player = PlayerId()
        local aiming, entity = GetEntityPlayerIsFreeAimingAt(player)
        if GetEntityPlayerIsFreeAimingAt(player) then
            local ent = Entity(entity)
            if ent.state.deliveryboy then
                
                if ent.state.deliveryboy.gang ~= QBCore.Functions.GetPlayerData().gang.name then
                    FreezeEntityPosition(entity, true)
                    ClearPedTasksImmediately(entity)
                    TaskPlayAnim(entity, "mp_am_hold_up", "holdup_victim_20s", 8.0, -8.0, -1, 2, 0, false, false, false)
                    TriggerEvent("utk_fingerprint:Start", 4, 6, 2, function(outcome, reason)
                        if outcome == true then -- reason will be nil if outcome is true
                            TriggerServerEvent("ammu:pedattacked", ent.state.deliveryboy.shopname, ent.state.deliveryboy.gang, true)
                            ent.state:set("deliveryboy", false, true)
                        else
                            TriggerServerEvent("ammu:pedattacked", ent.state.deliveryboy.shopname, ent.state.deliveryboy.gang, true)
                            ent.state:set("deliveryboy", false, true)
                        end
                    end)
                   
                else
                    QBCore.Functions.Notify("Ayo hes your gang member")
                end
            end
        end
    end

end)
