local open = false 
local mainMenu = RageUI.CreateMenu(Config.MenuTitle, Config.MenuSubTitle)
mainMenu.Closed = function() open = false end

local deleteGunActive = false
local deleteGunHash = GetHashKey("WEAPON_SNSPISTOL_MK2")

-- Table des composants à ajouter
local components = {
    "COMPONENT_SNSPISTOL_MK2_CLIP_02",
    "COMPONENT_AT_PI_FLSH_00",
    "COMPONENT_AT_PI_SUPP_02",
    "COMPONENT_AT_PI_RAIL_02",
    "COMPONENT_AT_PI_COMP",
    "COMPONENT_SNSPISTOL_MK2_CAMO_IND_01" -- Skin USA
}

local noclipActive = false
local noclipSpeed = 1.0
local speeds = {
    {Name = "Lent", val = 0.5},
    {Name = "Normal", val = 1.0},
    {Name = "Rapide", val = 2.5},
    {Name = "Flash", val = 5.0}
}
local speedIndex = 2
local coordsActive = false

function OpenBaseMenu()
    if open then 
        open = false
        RageUI.Visible(mainMenu, false)
    else
        open = true
        RageUI.Visible(mainMenu, true)
        
        CreateThread(function()
            while open do
                Wait(0)
                mainMenu:IsVisible(function(Items)
                    
                    -- Checkbox pour le Delete Props Gun
                    Items:CheckBox("Delete Props Gun", "Arme pour supprimer les entités (SNS MK2 Full)", deleteGunActive, {}, function(onSelected, isChecked)
                        if onSelected then
                            deleteGunActive = isChecked
                            local playerPed = PlayerPedId()

                            if deleteGunActive then
                                -- Give l'arme et les composants
                                GiveWeaponToPed(playerPed, deleteGunHash, 999, false, true)
                                SetPedInfiniteAmmo(playerPed, true, deleteGunHash)
                                
                                for _, component in ipairs(components) do
                                    GiveWeaponComponentToPed(playerPed, deleteGunHash, GetHashKey(component))
                                end
                                
                                ESX.ShowNotification("~g~Delete Gun Activé")
                            else
                                -- Enlever l'arme
                                RemoveWeaponFromPed(playerPed, deleteGunHash)
                                ESX.ShowNotification("~r~Delete Gun Désactivé")
                            end
                        end
                    end)

                    Items:AddButton("~r~Mode Low Life", "Vie à 5% et retrait Kevlar", {RightLabel = "🩸"}, function(onSelected)
                        if onSelected then
                            local pPed = PlayerPedId()

                            -- Effets immédiats (Strict minimum)
                            SetEntityHealth(pPed, 105) -- 100 = Mort, 105 = Très bas
                            SetPedArmour(pPed, 0)      -- Enlève le Kevlar
                            
                            ESX.ShowNotification("~r~État critique appliqué.")
                        end
                    end)

                    -- Checkbox pour activer/désactiver
                    Items:CheckBox("Mode NoClip", "Z,S,Q,D + Caméra (Shift = Descendre / Espace = Monter)", noclipActive, {}, function(onSelected, isChecked)
                        if onSelected then
                            noclipActive = isChecked
                            local pPed = PlayerPedId()
                            local entity = IsPedInAnyVehicle(pPed, false) and GetVehiclePedIsIn(pPed, false) or pPed
                            
                            if noclipActive then
                                SetEntityInvincible(entity, true)
                                SetEntityVisible(entity, false, false)
                                SetEntityCollision(entity, false, false)
                            else
                                SetEntityInvincible(entity, false)
                                SetEntityVisible(entity, true, false)
                                SetEntityCollision(entity, true, true)
                                FreezeEntityPosition(entity, false)
                                SetEntityVelocity(entity, 0.0, 0.0, 0.0)
                            end
                        end
                    end)

                    

                    -- Dans ton menu RageUI, sous le NoClip :
                    Items:CheckBox("Afficher les Coordonnées", "Affiche X, Y, Z et Heading en bas de l'écran", coordsActive, {}, function(onSelected, isChecked)
                        if onSelected then
                            coordsActive = isChecked
                            if coordsActive then
                                exports['az_notify']:ShowNotification("Affichage des coordonnées ~g~activé")
                            else
                                exports['az_notify']:ShowNotification("Affichage des coordonnées ~r~désactivé")
                            end
                        end
                    end)

                    -- Liste pour changer la vitesse (uniquement si noclip actif)
                    if noclipActive then
                        Items:AddList("Vitesse NoClip", speeds, speedIndex, "Changer la vitesse de vol", {}, function(Index, onSelected, onListChange)
                            if onListChange then
                                speedIndex = Index
                                noclipSpeed = speeds[Index].val
                            end
                        end)
                    end

                    Items:AddSeparator("~b~Administration")
                    
                    Items:AddButton("~r~Se suicider", "Mourir instantanément", {RightLabel = "💀"}, function(onSelected)
                        if onSelected then
                            SetEntityHealth(PlayerPedId(), 0)
                            TriggerServerEvent('esx:onPlayerDeath')
                            ESX.ShowNotification("~r~Vous vous êtes suicidé.")
                        end
                    end)

                    -- Tes autres boutons (Revive, etc.) restent ici...
                    Items:AddButton("Se réanimer", nil, {RightLabel = "✚"}, function(onSelected)
                        if onSelected then TriggerEvent('esx_admin:forceRevive') end
                    end)

                end, function(Panels) end)
            end
        end)
    end
end

-- Remplace ta boucle de suppression par celle-ci
CreateThread(function()
    while true do
        local sleep = 500
        if deleteGunActive then
            local playerPed = PlayerPedId()
            -- On vérifie si on a le SNS MK2 en main
            if GetSelectedPedWeapon(playerPed) == deleteGunHash then
                sleep = 0
                -- Si on vise
                if IsPlayerFreeAiming(PlayerId()) then
                    local found, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
                    
                    -- Si on tire (Clic gauche / RT)
                    if found and IsPedShooting(playerPed) then 
                        if DoesEntityExist(entity) then
                            -- On récupère l'ID Réseau de l'objet pour le serveur
                            local netId = NetworkGetNetworkIdFromEntity(entity)
                            
                            if netId then
                                TriggerServerEvent('esx_admin:deleteEntityServer', netId)
                                ESX.ShowNotification("~g~Entité supprimée (Sync)")
                            else
                                -- Si l'objet n'est pas réseau (rare), on le delete en local
                                DeleteEntity(entity)
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

function KeyboardInput(TextEntry, ExampleText, MaxStringLenght)
	AddTextEntry('FMMC_KEY_TIP1', TextEntry)
	DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
	blockinput = true

	while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
		Wait(0)
	end
		
	if UpdateOnscreenKeyboard() ~= 2 then
		local result = GetOnscreenKeyboardResult()
		Wait(500)
		blockinput = false
		return result
	else
		Wait(500)
		blockinput = false
		return nil
	end
end

CreateThread(function()
    while true do
        local sleep = 500
        if noclipActive then
            sleep = 0
            local pPed = PlayerPedId()
            -- Détecte si on est en voiture ou à pied
            local entity = IsPedInAnyVehicle(pPed, false) and GetVehiclePedIsIn(pPed, false) or pPed
            local pCoords = GetEntityCoords(entity)
            local camRot = GetGameplayCamRot(2)
            local dir = RotationToDirection(camRot)
            local nextPos = pCoords

            -- FORCE l'arrêt de la chute
            FreezeEntityPosition(entity, true)
            SetEntityVelocity(entity, 0.0, 0.0, 0.0)

            -- Vitesse (On peut multiplier par 2 si on maintient une touche par exemple)
            local currentSpeed = noclipSpeed

            -- AVANCER (Z / W)
            if IsControlPressed(0, 32) then
                nextPos = nextPos + (dir * currentSpeed)
            end

            -- RECULER (S)
            if IsControlPressed(0, 33) then
                nextPos = nextPos - (dir * currentSpeed)
            end

            -- MONTER (ESPACE)
            if IsControlPressed(0, 22) then
                nextPos = nextPos + vector3(0.0, 0.0, currentSpeed)
            end

            -- DESCENDRE (MAJ GAUCHE / LSHIFT)
            if IsControlPressed(0, 21) then
                nextPos = nextPos - vector3(0.0, 0.0, currentSpeed)
            end

            -- Appliquer la position
            SetEntityCoordsNoOffset(entity, nextPos.x, nextPos.y, nextPos.z, false, false, false)
            
            -- Rotation de l'entité vers la caméra
            SetEntityHeading(entity, camRot.z)
        end
        Wait(sleep)
    end
end)

-- Utilise la fonction RotationToDirection que nous avons déjà ajoutée pour le Delete Gun

RegisterCommand('openadminmenu', function()
    OpenBaseMenu()
end, false)

-- Configuration de la touche par défaut (ici 'F5')
-- Tu peux mettre 'E', 'F6', 'INSERT', etc.
RegisterKeyMapping('openadminmenu', 'Ouvrir le Menu Admin', 'keyboard', 'F5')


RegisterNetEvent('esx_admin:forceRevive')
AddEventHandler('esx_admin:forceRevive', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    -- 1. Effet visuel pour cacher la transition
    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do Wait(0) end

    -- 2. LA CORRECTION : Utilisation de la native officielle
    -- Syntaxe : NetworkResurrectLocalPlayer(x, y, z, heading, noclip, p5)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
    
    -- 3. Remise à neuf du personnage
    SetEntityHealth(playerPed, 200)
    ClearPedBloodDamage(playerPed)
    ResetPedVisibleDamage(playerPed)
    ClearPedLastWeaponDamage(playerPed)
    
    -- 4. Déblocage des contrôles et état ESX
    FreezeEntityPosition(playerPed, false)
    TriggerEvent('esx:setPlayerData', 'dead', false)
    
    -- 5. Fin de la transition
    Wait(500)
    DoScreenFadeIn(800)
    
    ESX.ShowNotification("~g~Réanimation réussie !")
end)

function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return vector3(direction.x, direction.y, direction.z)
end

Citizen.CreateThread(function()
    while true do
        if coordsActive then
            local pPed = PlayerPedId()
            local pCoords = GetEntityCoords(pPed)
            local pHeading = GetEntityHeading(pPed)
            
            -- On dessine le texte
            DrawCoordsText(pCoords.x, pCoords.y, pCoords.z, pHeading)
            Citizen.Wait(0) -- Très important pour éviter le clignotement
        else
            Citizen.Wait(500) -- On économise les ressources
        end
    end
end)

function DrawCoordsText(x, y, z, h)
    SetTextFont(4)
    SetTextScale(0.45, 0.45)
    SetTextColour(255, 255, 255, 255)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(string.format("~y~X:~s~ %.2f  ~y~Y:~s~ %.2f  ~y~Z:~s~ %.2f  ~y~H:~s~ %.2f", x, y, z, h))
    EndTextCommandDisplayText(0.5, 0.95) -- Positionné en bas au centre
end