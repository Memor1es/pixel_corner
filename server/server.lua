ESX = nil

TriggerEvent('esx:pixelgetSharedObject', function(obj) ESX = obj end)

local zonedist = 5000



RegisterServerEvent("pixel_corner:getDrugs")
AddEventHandler("pixel_corner:getDrugs", function(zone)
    if zone ~= nil then
        if DoIHaveRequiredDrugs(zone) then
            if CountPolice() >= Cfg.RequiredCops then
                TriggerClientEvent("pixel_corner:spawnPed", source, zone)
                TriggerClientEvent("esx:showNotification", source, "I have marked location of customer on your GPS")
            else
                TriggerClientEvent("esx:showNotification", source, "There isn't much cops to do that")
            end
        else
            TriggerClientEvent("esx:showNotification", source, "You don't have drugs for that zone")
        end
    end
end)

Prices = {
    ["Vinewood"] = {["moneymin"]=50, ["moneymax"]=100, ["drug"]="coke"},
    ["Vespucci"] = {["moneymin"]=25, ["moneymax"]=50, ["drug"]="heroine"},
    ["DelPerro"] = {["moneymin"]=35, ["moneymax"]=70, ["drug"]="meth"},
    ["Ghetto"] = {["moneymin"]=15, ["moneymax"]=30, ["drug"]="weed"}
}

RegisterServerEvent("pixel_corner:sold")
AddEventHandler("pixel_corner:sold", function(zone)
    local xPlayer = ESX.GetPlayerFromId(source)
    drugg = xPlayer.getInventoryItem(Prices[zone]["drug"])
    cash = math.random(Prices[zone]["moneymin"], Prices[zone]["moneymax"])
    if drugg.count > 0 then
        xPlayer.removeInventoryItem(drugg, 1)
        if Cfg.Blackmoney then
            xPlayer.addAccountMoney("black_money", cash)
        else
            xPlayer.addMoney(cash)
        end
        xPlayer.showNotification("You have earned "..cash.."~g~$~w~ from selling 1x ~b~"..drugg.label)
    end
end)

RegisterServerEvent("pixel_corner:notifyPoliceSV")
AddEventHandler("pixel_corner:notifyPoliceSV", function(x, y, z)
    TriggerClientEvent("pixel_corner:createBlipForPolice", -1, x, y, z)
end)



function CountPolice()
    local xPlayers = ESX.GetPlayers()

	count = 0

	for i=1, #xPlayers, 1 do
		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
		if xPlayer.job.name == 'police' then
			count = count + 1
		end
	end
    return 5
end


function DoIHaveRequiredDrugs(zonename)
    local xPlayer = ESX.GetPlayerFromId(source)
    if zonename == "Vinewood" then
        reqdrug = "coke"
    elseif zonename == "Vespucci" then
        reqdrug = "heroine"
    elseif zonename == "DelPerro" then
        reqdrug = "meth"
    elseif zonename == "Ghetto" then
        reqdrug = "weed"
    end
    if zonename ~= "n/a" then
        if xPlayer.getInventoryItem(reqdrug).count > 0 then
            return true
        else
            return false
        end
    end
end