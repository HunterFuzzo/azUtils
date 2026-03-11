-- Pas besoin de TriggerEvent('esx:getSharedObject') sur les versions récentes
-- ESX est déjà disponible via l'import du manifest

RegisterNetEvent('esx_admin:revive')
AddEventHandler('esx_admin:revive', function(targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(targetId)

    if xPlayer.getGroup() ~= 'user' then
        if xTarget then
            TriggerClientEvent('esx_ambulancejob:revive', xTarget.source)
            print(("^2[INFO]^7 L'admin %s a revive le joueur %s (ID: %s)"):format(xPlayer.getName(), xTarget.getName(), targetId))
            xPlayer.showNotification(("~g~You revived player %s"):format(xTarget.getName()))
        else
            xPlayer.showNotification("~r~Invalid ID or player not connected.")
        end
    else
        print(("^1[WARNING]^7 Tentative de revive par %s (non-admin)"):format(xPlayer.getName()))
        xPlayer.showNotification("~r~You don't have permission to do this.")
    end
end)

RegisterNetEvent('mon_script:actionClient')
AddEventHandler('mon_script:actionClient', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Logique serveur ici
    print(("^2[INFO]^7 Le joueur %s a utilisé le menu."):format(xPlayer.getName()))
end)

-- Commande pour se revive soi-même
RegisterCommand('reviveme', function(source, args, rawCommand)
    TriggerEvent('esx_admin:revivePlayer', source)
end, false)

RegisterNetEvent('esx_admin:revivePlayer')
AddEventHandler('esx_admin:revivePlayer', function(target)
    local _target = target or source
    -- On demande au client spécifique de se réanimer
    TriggerClientEvent('esx_admin:forceRevive', _target)
end)

RegisterNetEvent('esx_admin:deleteEntityServer')
AddEventHandler('esx_admin:deleteEntityServer', function(entityNetId)
    -- On récupère l'entité à partir de son ID réseau
    local entity = NetworkGetEntityFromNetworkId(entityNetId)
    
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
        print(("[ADMIN] Entité %s supprimée par l'ID %s"):format(entityNetId, source))
    end
end)

RegisterNetEvent('az_admin:teleportAllToMe')
AddEventHandler('az_admin:teleportAllToMe', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Vérification de sécurité
    if xPlayer.getGroup() ~= 'user' then
        local adminPed = GetPlayerPed(source)
        local coords = GetEntityCoords(adminPed)
        local players = ESX.GetPlayers()
        
        for i=1, #players, 1 do
            local xTarget = ESX.GetPlayerFromId(players[i])
            if xTarget.source ~= source then -- On ne se TP pas soi-même
                TriggerClientEvent('az_admin:teleportToCoords', xTarget.source, coords)
            end
        end
        
        xPlayer.showNotification("~g~All players have been teleported to you.")
        print(("^2[ADMIN]^7 %s a téléporté TOUS les joueurs sur lui."):format(xPlayer.getName()))
    else
        print(("^1[WARNING]^7 Tentative de TP All par %s (non-admin)"):format(xPlayer.getName()))
    end
end)

RegisterNetEvent('az_admin:teleportToPlayer')
AddEventHandler('az_admin:teleportToPlayer', function(targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(targetId)

    if xPlayer.getGroup() ~= 'user' then
        if xTarget then
            local targetPed = GetPlayerPed(xTarget.source)
            local coords = GetEntityCoords(targetPed)
            TriggerClientEvent('az_admin:teleportToCoords', xPlayer.source, coords)
            xPlayer.showNotification(("~b~You teleported to %s"):format(xTarget.getName()))
        else
            xPlayer.showNotification("~r~Invalid ID or player not connected.")
        end
    end
end)

RegisterNetEvent('az_admin:bringPlayer')
AddEventHandler('az_admin:bringPlayer', function(targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(targetId)

    if xPlayer.getGroup() ~= 'user' then
        if xTarget then
            local adminPed = GetPlayerPed(xPlayer.source)
            local coords = GetEntityCoords(adminPed)
            TriggerClientEvent('az_admin:teleportToCoords', xTarget.source, coords)
            xPlayer.showNotification(("~g~You brought %s to you"):format(xTarget.getName()))
            xTarget.showNotification("~b~You have been teleported by an administrator.")
        else
            xPlayer.showNotification("~r~Invalid ID or player not connected.")
        end
    end
end)