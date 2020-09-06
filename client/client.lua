local ESX = nil
local PlayerData = {}
local num = nil
local globaldist = nil
local dist = nil
local pedspawned = false
local ped = nil
local whatamiselling = nil
local selling = false
local blip = nil
local timeout = false
Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:pixelgetSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end
	PlayerData = ESX.GetPlayerData()
end)

AddEventHandler("esx:setJob", function(job)
    PlayerData.job = job
end)

RegisterCommand("corner", function(source, args)
    if args[1] == nil and not pedspawned and not timeout then
        zone = CheckLoc()
        if zone ~= nil then
            if pedspawned then
                TriggerEvent("esx:showNotification", "You have got actually customer. If you want to cancel it type /corner c")
            else
                TriggerServerEvent("pixel_corner:getDrugs", zone)
            end
        end
        TriggerEvent("pixel_corner:sellTimeout")
    elseif args[1] == "c" then
        if pedspawned then
            StopSellNow()
        end
    end
end)


RegisterNetEvent("pixel_corner:spawnPed")
AddEventHandler("pixel_corner:spawnPed", function(zone)
    TriggerEvent("pixel_corner:starttimeout")
    pedspawned = true
    data = Cfg.PedLocs[zone][math.random(1, 20)]
    pedmodel = Cfg.PedModels[math.random(1, 10)]
    whatamiselling = zone
    spawnped(data.x, data.y, data.z, data.h, pedmodel)
    --createblip(data.x, data.y, data.z)
    data.x = math.floor(data.x)
    data.y = math.floor(data.y)
    data.x = math.random(data.x-50, data.x+50)
    data.y = math.random(data.y-50, data.y+50)
    TriggerServerEvent("pixel_corner:notifyPoliceSV", data.x, data.y, data.z)
end)

RegisterNetEvent("pixel_corner:startSelling")
AddEventHandler("pixel_corner:startSelling", function()
    if selling then
        return
    end
    selling = true
    success = true
    Citizen.Wait(1000)
	loadAnimDict( "mp_safehouselost@" )
    TaskPlayAnim( PlayerPedId(), "mp_safehouselost@", "package_dropoff", 8.0, 1.0, -1, 16, 0, 0, 0, 0 )
	Citizen.Wait(800)
    PlayAmbientSpeech1(ped, "Chat_State", "Speech_Params_Force")
    if DoesEntityExist(ped) and not IsEntityDead(ped) then
        counter = math.random(200,300)
        FreezeEntityPosition(PlayerPedId(), true)
		while counter > 0 do
			crds = GetEntityCoords(ped)
			counter = counter - 1
            Citizen.Wait(1)
        end
        giveAnim()
        Citizen.Wait(4000)
        FreezeEntityPosition(PlayerPedId(), false)
        if #(crds - GetEntityCoords(PlayerPedId())) > 3.0 or not DoesEntityExist(ped) or IsEntityDead(ped) then
            success = false
        end
        if success then
            TriggerServerEvent("pixel_corner:sold", zone)
        end
        StopSell()
    end
end)

RegisterNetEvent("pixel_corner:createBlipForPolice")
AddEventHandler("pixel_corner:createBlipForPolice",function(x, y, z)
    if PlayerData.job.name == "unemployed" then
        x = x+0.1
        y = y+0.1
        street = GetStreetNameFromHashKey(GetStreetNameAtCoord(x, y, z))
        TriggerEvent("chatMessage", "DISPATCH", {255,255,255}, "Probable drug sale on "..street.." Street")
        local transG = 150
		local drugBlip = AddBlipForCoord(x, y, z)
		SetBlipSprite(drugBlip,  9)
		SetBlipColour(drugBlip,  1)
		SetBlipAlpha(drugBlip,  transG)
		SetBlipScale(drugBlip, 0.75)
		SetBlipAsShortRange(drugBlip,  false)

		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString('Drugs Sell')
		EndTextCommandSetBlipName(drugBlip)
		while transG ~= 0 do
			Wait(500 * 2)
			transG = transG - 1
			SetBlipAlpha(drugBlip,  transG)
			if transG == 0 then
				SetBlipSprite(drugBlip,  9)
				return;
			end
		end
    end
end)



RegisterNetEvent("pixel_corner:starttimeout")
AddEventHandler("pixel_corner:starttimeout", function()
    Citizen.Wait(60000)
    if pedspawned then
        StopSell()
        TriggerEvent("esx:showNotification", "Your client has changed his mind")
    end
end)

RegisterNetEvent("pixel_corner:sellTimeout")
AddEventHandler("pixel_corner:sellTimeout", function()
    timeout = true
    Citizen.Wait(180000)
    timeout = false
end)

Citizen.CreateThread(function()
    while true do
        if pedspawned then
            pedcoords = GetEntityCoords(ped)
            playercoords = GetEntityCoords(PlayerPedId())
            if GetDistanceBetweenCoords(pedcoords, playercoords, true) <= 1.5 and not IsPedInAnyVehicle(PlayerPedId(), true) then
                if not soundplayed then
                    PlayAmbientSpeech1(ped, "Generic_Hi", "Speech_Params_Force")
                end
                soundplayed = true
                if not selling then
                    DrawText3Ds(pedcoords.x, pedcoords.y, pedcoords.z+0.5, "Press E to sell")
                    if IsControlJustPressed(0, 51) then
                        TriggerEvent("pixel_corner:startSelling")
                        FreezeEntityPosition(ped, true)
                        ClearPedTasksImmediately(ped)
                    end
                end
            else
                soundplayed = false
                Citizen.Wait(1000)
            end
        else
            Citizen.Wait(2500)
        end
        Citizen.Wait(5)
    end
end)

Citizen.CreateThread(function()
    while true do
        if pedspawned then
            pedcoords = GetEntityCoords(ped)
            playercoords = GetEntityCoords(PlayerPedId())
            dist = Vdist(pedcoords.x, pedcoords.y, pedcoords.z, playercoords.x, playercoords.y, playercoords.z)
            dist = ESX.Round(dist, 0)
            dist = math.floor(dist)
            DrawAdvancedText(0.591, 0.903, 0.005, 0.08, 0.4, "~w~Client is ~b~"..dist.."~w~ metres from your position.", 0, 191, 255, 255, 6, 0)
        else
            Citizen.Wait(1000)
        end
        Citizen.Wait(10)
    end
end)

function createblip(x, y, z)
    blip = AddBlipForEntity(ped)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Customer")
    EndTextCommandSetBlipName(blip)
    SetBlipAsShortRange(blip, false)
    SetBlipColour(blip, 2)
    SetBlipSprite(blip, 280)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 2)
end

function StopSell()
    num = nil
    globaldist = nil
    dist = nil
    pedspawned = false
    whatamiselling = nil
    selling = false
    if DoesEntityExist(ped) then
        FreezeEntityPosition(ped, false)
        SetEntityCollision(ped, true, false)
	    SetEntityInvincible(ped, false)
        SetBlockingOfNonTemporaryEvents(ped, false)
        SetPedKeepTask(ped, false)
	    TaskSetBlockingOfNonTemporaryEvents(ped, false)
	    ClearPedTasks(ped)
	    TaskWanderStandard(ped, 10.0, 10)
        SetPedAsNoLongerNeeded(ped)
    end
    SetBlipRoute(blip, false)
    if DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
    Citizen.Wait(20000)
    if DoesEntityExist(ped) then
        DeleteEntity(ped)
    end
end

function StopSellNow()
    num = nil
    globaldist = nil
    dist = nil
    pedspawned = false
    whatamiselling = nil
    selling = false
    if DoesEntityExist(ped) then
        FreezeEntityPosition(ped, false)
        SetEntityCollision(ped, true, false)
	    SetEntityInvincible(ped, false)
        SetBlockingOfNonTemporaryEvents(ped, false)
        SetPedKeepTask(ped, false)
	    TaskSetBlockingOfNonTemporaryEvents(ped, false)
	    ClearPedTasks(ped)
	    TaskWanderStandard(ped, 10.0, 10)
        SetPedAsNoLongerNeeded(ped)
    end
    SetBlipRoute(blip, false)
    if DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
    if DoesEntityExist(ped) then
        DeleteEntity(ped)
    end
end

function giveAnim()
    if DoesEntityExist(ped) and not IsEntityDead(ped) then 
        loadAnimDict("mp_safehouselost@")
        if ( IsEntityPlayingAnim(ped, "mp_safehouselost@", "package_dropoff", 3)) then 
            TaskPlayAnim(ped, "mp_safehouselost@", "package_dropoff", 8.0, 1.0, -1, 16, 0, 0, 0, 0)
        else
            TaskPlayAnim(ped, "mp_safehouselost@", "package_dropoff", 8.0, 1.0, -1, 16, 0, 0, 0, 0)
        end     
    end
end

function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Citizen.Wait(5)
    end
end 

function spawnped(x, y, z, h, p)
    pe = p
    z=z-0.98
	RequestModel(GetHashKey(pe))
    while not HasModelLoaded(GetHashKey(pe)) do
	    Wait(155)
    end
    ped = CreatePed(4, GetHashKey(pe), x, y, z, h, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityCollision(ped, false, false)
	SetEntityInvincible(ped, true)
	SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityHeading(ped, h)
    --TaskWanderStandard(ped, 10.0, 10)
    TaskWanderInArea(ped, x, y, z, 100.0, 20.0, 10000) 
end

function CheckLoc()
    globaldist = 5000
    dist = 0
    zone = nil
    for k,v in ipairs(Cfg.Locs) do
        dist = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), vector3(v.x, v.y, v.z), false)
        if dist < globaldist then
            globaldist = dist
            if dist < 300 then
                zone = v.zone
            end
        end
    end
    return zone
end

function DrawText3Ds(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
end

function DrawAdvancedText(x,y ,w,h,sc, text, r,g,b,a,font,jus)
    SetTextFont(font)
    SetTextProportional(0)
    SetTextScale(sc, sc)
	N_0x4e096588b13ffeca(jus)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
	DrawText(x - 0.1+w, y - 0.02+h)
end