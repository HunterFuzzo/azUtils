local open = false 
local mainMenu = RageUI.CreateMenu(Config.MenuTitle, Config.MenuSubTitle)
mainMenu.Closed = function() open = false end

local deleteGunActive = false
local deleteGunHash = GetHashKey("WEAPON_SNSPISTOL_MK2")

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
    {Name = "Slow", val = 0.5},
    {Name = "Normal", val = 1.0},
    {Name = "Fast", val = 2.5},
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
    end
end

-- --- Optimized Main Logic Thread ---
Citizen.CreateThread(function()
    while true do
        local sleep = 500
        local pPed = PlayerPedId()
        local pId = PlayerId()

        -- 1. ADMIN MENU LOOP
        if open then
            sleep = 0
            mainMenu:IsVisible(function(Items)
                
                -- Checkbox pour le Delete Props Gun
                Items:CheckBox("Delete Props Gun", "Weapon to delete entities (SNS MK2 Full)", deleteGunActive, {}, function(onSelected, isChecked)
                    if onSelected then
                        deleteGunActive = isChecked
                        if deleteGunActive then
                            -- Give l'arme et les composants
                            GiveWeaponToPed(pPed, deleteGunHash, 999, false, true)
                            SetPedInfiniteAmmo(pPed, true, deleteGunHash)
                            
                            for _, component in ipairs(components) do
                                GiveWeaponComponentToPed(pPed, deleteGunHash, GetHashKey(component))
                            end
                            
                            ESX.ShowNotification("~g~Delete Gun Enabled")
                        else
                            -- Enlever l'arme
                            RemoveWeaponFromPed(pPed, deleteGunHash)
                            ESX.ShowNotification("~r~Delete Gun Disabled")
                        end
                    end
                end)

                -- Checkbox pour activer/désactiver NoClip
                Items:CheckBox("NoClip Mode", "W,A,S,D + Camera (LSHIFT = Down / SPACE = Up)", noclipActive, {}, function(onSelected, isChecked)
                    if onSelected then
                        noclipActive = isChecked
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

                -- Show Coords
                Items:CheckBox("Show Coords", "Displays X, Y, Z and Heading at the bottom", coordsActive, {}, function(onSelected, isChecked)
                    if onSelected then
                        coordsActive = isChecked
                        if coordsActive then
                            exports['az_notify']:ShowNotification("Coords display ~g~enabled")
                        else
                            exports['az_notify']:ShowNotification("Coords display ~r~disabled")
                        end
                    end
                end)

                -- Liste pour changer la vitesse (uniquement si noclip actif)
                if noclipActive then
                    Items:AddList("NoClip Speed", speeds, speedIndex, "Change flight speed", {}, function(Index, onSelected, onListChange)
                        if onListChange then
                            speedIndex = Index
                            noclipSpeed = speeds[Index].val
                        end
                    end)
                end

                Items:AddSeparator("~b~Administration")
                
                Items:AddButton("Bring (ID)", "Teleport a player to you", {RightLabel = "→"}, function(onSelected)
                    if onSelected then
                        local id = KeyboardInput("Player ID", "", 5)
                        if id and id ~= "" then
                            TriggerServerEvent('az_admin:bringPlayer', tonumber(id))
                        end
                    end
                end)

                Items:AddButton("TP to (ID)", "Teleport to a player", {RightLabel = "→"}, function(onSelected)
                    if onSelected then
                        local id = KeyboardInput("Player ID", "", 5)
                        if id and id ~= "" then
                            TriggerServerEvent('az_admin:teleportToPlayer', tonumber(id))
                        end
                    end
                end)

                Items:AddButton("~r~Suicide", "Die instantly", {RightLabel = "→"}, function(onSelected)
                    if onSelected then
                        SetEntityHealth(pPed, 0)
                        TriggerServerEvent('esx:onPlayerDeath')
                        ESX.ShowNotification("~r~You committed suicide.")
                    end
                end)

                Items:AddButton("Bring All", "Teleport all players to you", {RightLabel = "→"}, function(onSelected)
                    if onSelected then
                        TriggerServerEvent('az_admin:teleportAllToMe')
                    end
                end)

                Items:AddButton("Revive self", nil, {RightLabel = "→"}, function(onSelected)
                    if onSelected then TriggerEvent('esx_admin:forceRevive') end
                end)

            end, function(Panels) end)
        end

        -- 2. DELETE GUN LOGIC
        if deleteGunActive then
            if GetSelectedPedWeapon(pPed) == deleteGunHash then
                sleep = 0
                if IsPlayerFreeAiming(pId) then
                    local found, entity = GetEntityPlayerIsFreeAimingAt(pId)
                    if found and IsPedShooting(pPed) then 
                        if DoesEntityExist(entity) then
                            local netId = NetworkGetNetworkIdFromEntity(entity)
                            if netId then
                                TriggerServerEvent('esx_admin:deleteEntityServer', netId)
                                ESX.ShowNotification("~g~Entity deleted (Sync)")
                            else
                                DeleteEntity(entity)
                            end
                        end
                    end
                end
            end
        end

        -- 3. NOCLIP LOGIC
        if noclipActive then
            sleep = 0
            local entity = IsPedInAnyVehicle(pPed, false) and GetVehiclePedIsIn(pPed, false) or pPed
            local pCoords = GetEntityCoords(entity)
            local camRot = GetGameplayCamRot(2)
            local dir = RotationToDirection(camRot)
            local nextPos = pCoords

            FreezeEntityPosition(entity, true)
            SetEntityVelocity(entity, 0.0, 0.0, 0.0)

            local currentSpeed = noclipSpeed

            if IsControlPressed(0, 32) then nextPos = nextPos + (dir * currentSpeed) end -- Z / W
            if IsControlPressed(0, 33) then nextPos = nextPos - (dir * currentSpeed) end -- S
            if IsControlPressed(0, 22) then nextPos = nextPos + vector3(0.0, 0.0, currentSpeed) end -- SPACE
            if IsControlPressed(0, 21) then nextPos = nextPos - vector3(0.0, 0.0, currentSpeed) end -- SHIFT

            SetEntityCoordsNoOffset(entity, nextPos.x, nextPos.y, nextPos.z, false, false, false)
            SetEntityHeading(entity, camRot.z)
        end

        -- 4. COORDS LOGIC
        if coordsActive then
            sleep = 0
            local pCoords = GetEntityCoords(pPed)
            local pHeading = GetEntityHeading(pPed)
            DrawCoordsText(pCoords.x, pCoords.y, pCoords.z, pHeading)
        end

        Citizen.Wait(sleep)
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

RegisterCommand('openadminmenu', function()
    OpenBaseMenu()
end, false)

RegisterKeyMapping('openadminmenu', 'Open Admin Menu', 'keyboard', 'F5')

RegisterNetEvent('esx_admin:forceRevive')
AddEventHandler('esx_admin:forceRevive', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do Wait(0) end

    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
    
    SetEntityHealth(playerPed, 200)
    ClearPedBloodDamage(playerPed)
    ResetPedVisibleDamage(playerPed)
    ClearPedLastWeaponDamage(playerPed)
    
    FreezeEntityPosition(playerPed, false)
    TriggerEvent('esx:setPlayerData', 'dead', false)
    
    Wait(500)
    DoScreenFadeIn(800)
    
    ESX.ShowNotification("~g~Revive successful!")
end)

RegisterNetEvent('az_admin:teleportToCoords')
AddEventHandler('az_admin:teleportToCoords', function(coords)
    local playerPed = PlayerPedId()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z + 0.5, false, false, false, false)
    Wait(500)
    DoScreenFadeIn(500)
    ESX.ShowNotification("~b~You have been teleported by an administrator.")
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

function DrawCoordsText(x, y, z, h)
    SetTextFont(4)
    SetTextScale(0.45, 0.45)
    SetTextColour(255, 255, 255, 255)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(string.format("~y~X:~s~ %.2f  ~y~Y:~s~ %.2f  ~y~Z:~s~ %.2f  ~y~H:~s~ %.2f", x, y, z, h))
    EndTextCommandDisplayText(0.5, 0.95)
end