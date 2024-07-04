_menuPool = NativeUI.CreatePool()
mainMenu = NativeUI.CreateMenu("FRXBYY MENU", "~b~DRIFT AND CUSTOM CAR MENU")
_menuPool:Add(mainMenu)

local driftMode = false
local isRainbowActive = false

function ShowNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
end

function KeyboardInput(textEntry, defaultText, maxLength)
    AddTextEntry('FMMC_KEY_TIP1', textEntry)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", defaultText, "", "", "", maxLength)
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Citizen.Wait(0)
    end
    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Citizen.Wait(500)
        return result
    else
        Citizen.Wait(500)
        return nil
    end
end

function SpawnVehicle(modelName)
    local model = GetHashKey(modelName)
    if not IsModelInCdimage(model) or not IsModelAVehicle(model) then
        ShowNotification("Invalid vehicle model.")
        return
    end

    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(0)
    end

    local playerPed = PlayerPedId()
    local pos = GetEntityCoords(playerPed)
    local vehicle = CreateVehicle(model, pos.x, pos.y, pos.z, GetEntityHeading(playerPed), true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

    SetModelAsNoLongerNeeded(model)
    ShowNotification("Vehicle spawned: " .. modelName)

    if driftMode then
        EnableDriftMode(vehicle)
    else
        DisableDriftMode(vehicle)
    end

    if isRainbowActive then
        EnableRainbowCar(vehicle)
    else
        DisableRainbowCar(vehicle)
    end
end

local spawnSubMenu = _menuPool:AddSubMenu(mainMenu, "Spawn Car or Ped", "Spawn a vehicle or Ped")

local spawnByNameItem = NativeUI.CreateItem("Spawn Car by Name >>>", "Spawn a vehicle by entering its model name.")
spawnSubMenu:AddItem(spawnByNameItem)

local changePedByNameItem = NativeUI.CreateItem("Change Ped by Name >>>", "Change the player's ped by entering its name.")
spawnSubMenu:AddItem(changePedByNameItem)

spawnSubMenu.OnItemSelect = function(menu, item)
    if item == spawnByNameItem then
        local modelName = KeyboardInput("Enter Vehicle Model", "", 30)
        if modelName and modelName ~= "" then
            SpawnVehicle(modelName)
        else
            ShowNotification("Invalid vehicle model name.")
        end
    elseif item == changePedByNameItem then
        local pedName = KeyboardInput("Enter Ped Model", "", 30)
        if pedName and pedName ~= "" then
            ChangePed(pedName)
        else
            ShowNotification("Invalid ped model name.")
        end
    end
end

function ChangePed(modelName)
    local model = GetHashKey(modelName)
    if not IsModelInCdimage(model) or not IsModelAPed(model) then
        ShowNotification("Invalid ped model.")
        return
    end

    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(0)
    end

    local playerPed = PlayerPedId()
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    ShowNotification("Ped changed to: " .. modelName)
end

local driftMode = false

-- Funkcje EnableDriftMode i DisableDriftMode
local spawnSubMenu = _menuPool:AddSubMenu(mainMenu, "Drift Mode")

-- Przycisk XDDD
local xdddItem = NativeUI.CreateItem("ON/OFF Driftmode", "Press shift to enable")
spawnSubMenu:AddItem(xdddItem)

spawnSubMenu.OnItemSelect = function(menu, item)
    if item == xdddItem then
        ShowNotification("Press SHIFT to enable driftMODE")
    elseif item == spawnByNameItem then
        local modelName = KeyboardInput("Enter Vehicle Model", "", 30)
        if modelName and modelName ~= "" then
            SpawnVehicle(modelName)
        else
            ShowNotification("Invalid vehicle model name.")
        end
    elseif item == changePedByNameItem then
        local pedName = KeyboardInput("Enter Ped Model", "", 30)
        if pedName and pedName ~= "" then
            ChangePed(pedName)
        else
            ShowNotification("Invalid ped model name.")
        end
    end
end
-- Drift Mode Checkbox
-- Rainbow Car Checkbox
local rainbowCarItem = NativeUI.CreateCheckboxItem("Rainbow Car", isRainbowActive, "Toggle Rainbow Car on/off")
mainMenu:AddItem(rainbowCarItem)

mainMenu.OnCheckboxChange = function(sender, item, checked_)
    if item == rainbowCarItem then
        isRainbowActive = checked_
        ShowNotification("Rainbow Car " .. (isRainbowActive and "enabled" or "disabled"))
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if isRainbowActive then
                EnableRainbowCar(vehicle)
            else
                DisableRainbowCar(vehicle)
            end
        end
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        _menuPool:ProcessMenus()

        -- Hide cursor and disable mouse control when menu is open
        if mainMenu:Visible() then
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
            DisableControlAction(0, 239, true) -- CursorX
            DisableControlAction(0, 240, true) -- CursorY
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 30, true) -- MoveLeftRight
            DisableControlAction(0, 31, true) -- MoveUpDown

            -- Set cursor location off-screen
            SetCursorLocation(0.0, 0.0)

            -- Hide cursor
            SetMouseCursorActiveThisFrame()
            ShowCursorThisFrame(false)
            SetMouseCursorVisibleInMenus(false)
        end

        if IsControlJustPressed(1, 249) then
            mainMenu:Visible(not mainMenu:Visible())
        end
    end
end)

_menuPool:RefreshIndex()

-- Rainbow Car Script
local rainbowColors = {
    {255, 0, 0},     -- Red
    {255, 165, 0},   -- Orange
    {255, 255, 0},   -- Yellow
    {0, 255, 0},     -- Green
    {0, 0, 255},     -- Blue
    {75, 0, 130},    -- Indigo
    {148, 0, 211}    -- Violet
}

local colorIndex = 1
local colorChangeInterval = 100 -- time in milliseconds between color changes
local nextColorChange = 0
local currentColor = {255, 0, 0}  -- Initial color (red)

-- Function to interpolate colors (lerp)
local function lerpColor(c1, c2, t)
    return {
        math.floor(c1[1] + (c2[1] - c1[1]) * t),
        math.floor(c1[2] + (c2[2] - c1[2]) * t),
        math.floor(c1[3] + (c2[3] - c1[3]) * t)
    }
end

-- Function to change the vehicle's color
local function changeVehicleColor(vehicle)
    if GetGameTimer() >= nextColorChange then
        nextColorChange = GetGameTimer() + colorChangeInterval

        local nextColor = rainbowColors[colorIndex]
        local t = 0
        while t < 1.0 do
            t = t + 0.02
            currentColor = lerpColor(currentColor, nextColor, t)
            SetVehicleCustomPrimaryColour(vehicle, currentColor[1], currentColor[2], currentColor[3])
            Citizen.Wait(20)
        end

        colorIndex = colorIndex % #rainbowColors + 1
    end
end

function EnableRainbowCar(vehicle)
    Citizen.CreateThread(function()
        while isRainbowActive do
            changeVehicleColor(vehicle)
            Citizen.Wait(0)
        end
    end)
end

function DisableRainbowCar(vehicle)
    SetVehicleCustomPrimaryColour(vehicle, 255, 255, 255) -- Set to default color (white)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        local ped = GetPlayerPed(-1)

        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if driftMode and IsVehicleClassWhitelisted(GetVehicleClass(vehicle)) then
                SetVehicleEnginePowerMultiplier(vehicle, 50.0) -- Reduced from 190.0 to 50.0
            else
                SetVehicleEnginePowerMultiplier(vehicle, 0.0)
            end
        end
    end
end)

function IsVehicleClassWhitelisted(vehicleClass)
    for index, value in ipairs(vehicleClassWhitelist) do
        if value == vehicleClass then
            return true
        end
    end
    return false
end
