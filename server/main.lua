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
            xPlayer.showNotification(("~g~Vous avez revive le joueur %s"):format(xTarget.getName()))
        else
            xPlayer.showNotification("~r~ID invalide ou joueur non connecté.")
        end
    else
        print(("^1[WARNING]^7 Tentative de revive par %s (non-admin)"):format(xPlayer.getName()))
        xPlayer.showNotification("~r~Vous n'avez pas la permission de faire ça.")
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