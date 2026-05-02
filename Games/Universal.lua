--[[
    Vyper - Roblox Universal Script
    Features: ESP, Aimbot, Rage (Silent Aim, Triggerbot, No Recoil, Rapid Fire)
    UI: WindUI Custom
--]]

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Saersa/Vyper-Development/refs/heads/main/WindUI_Custom.lua"))()

-- Create Window
local Window = WindUI:CreateWindow({
    Title = "Vyper",
    Icon = "crosshair",
    Author = "By: Vyper",
    Folder = "Vyper",
    NewElements = true,

    ToggleKey = Enum.KeyCode.RightShift,
    Size = UDim2.fromOffset(600, 500),
    MinSize = Vector2.new(600, 500),
    MaxSize = Vector2.new(600, 500),
    Transparent = true,
    Theme = "Vyper",
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = false,
    ScrollBarEnabled = false,
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            print("User clicked")
        end,
    },
    Topbar = {
        Height = 44,
        ButtonsType = "Default",
    },
})

Window:Tag({
    Title = Window:IsPremium() and "Premium User" or "Free User",
    Icon = "zap",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 8,
})

-- ====================== SERVICES ======================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ====================== SETTINGS ======================
local Settings = {
    -- ESP
    MasterESP = true,
    Box = true,
    BoxFill = false,
    Name = true,
    Distance = true,
    HealthBar = true,
    ArmorBar = true,
    Snapline = true,
    TeamCheck = true,
    MaxESPDistance = 1000,
    FriendlyColor = Color3.fromRGB(0, 120, 255),
    EnemyColor = Color3.fromRGB(255, 50, 50),
    
    -- Aimbot
    Aimbot = false,
    AimKey = Enum.UserInputType.MouseButton2,
    Smoothness = 5,
    FOV = 150,
    ShowFOV = true,
    VisibilityCheck = true,
    AimPart = "Head",
    
    -- Rage
    SilentAim = false,
    Triggerbot = false,
    NoRecoil = false,
    RapidFire = false,
    TriggerbotKey = Enum.UserInputType.MouseButton1,
}

-- ====================== ESP SYSTEM ======================
local ActiveDrawings = {}
local FOVCircle = nil

local BOX_THICKNESS = 1.5
local BOX_TRANSPARENCY = 0.7
local TEXT_FONT = 2
local SNAPLINE_TRANSPARENCY = 0.4

local function getArmor(character)
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        local armorVal = humanoid:FindFirstChild("Armor") or humanoid:FindFirstChild("armor")
        if armorVal and armorVal:IsA("NumberValue") then
            return armorVal.Value
        end
        local attr = humanoid:GetAttribute("Armor")
        if attr and type(attr) == "number" then
            return attr
        end
    end
    return 0
end

local function createESP(player)
    local drawings = {}
    
    local boxOutline = Drawing.new("Square")
    boxOutline.Visible = false
    boxOutline.Color = Color3.fromRGB(0, 0, 0)
    boxOutline.Thickness = BOX_THICKNESS + 0.5
    boxOutline.Filled = false
    boxOutline.Transparency = 1
    
    local boxFill = Drawing.new("Square")
    boxFill.Visible = false
    boxFill.Color = Settings.FriendlyColor
    boxFill.Thickness = 1
    boxFill.Filled = true
    boxFill.Transparency = BOX_TRANSPARENCY
    
    local snapline = Drawing.new("Line")
    snapline.Visible = false
    snapline.Color = Color3.fromRGB(255, 255, 255)
    snapline.Thickness = 1
    snapline.Transparency = SNAPLINE_TRANSPARENCY
    
    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Color = Color3.fromRGB(255, 255, 255)
    nameText.Size = 14
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.fromRGB(0, 0, 0)
    nameText.Font = TEXT_FONT
    
    local healthBg = Drawing.new("Square")
    healthBg.Visible = false
    healthBg.Color = Color3.fromRGB(0, 0, 0)
    healthBg.Filled = true
    healthBg.Transparency = 0.5
    
    local healthFill = Drawing.new("Square")
    healthFill.Visible = false
    healthFill.Color = Color3.fromRGB(0, 255, 0)
    healthFill.Filled = true
    
    local armorBg = Drawing.new("Square")
    armorBg.Visible = false
    armorBg.Color = Color3.fromRGB(0, 0, 0)
    armorBg.Filled = true
    armorBg.Transparency = 0.5
    
    local armorFill = Drawing.new("Square")
    armorFill.Visible = false
    armorFill.Color = Color3.fromRGB(0, 180, 255)
    armorFill.Filled = true
    
    local distanceText = Drawing.new("Text")
    distanceText.Visible = false
    distanceText.Color = Color3.fromRGB(200, 200, 200)
    distanceText.Size = 12
    distanceText.Center = true
    distanceText.Outline = true
    distanceText.OutlineColor = Color3.fromRGB(0, 0, 0)
    distanceText.Font = TEXT_FONT
    
    table.insert(drawings, boxOutline)
    table.insert(drawings, boxFill)
    table.insert(drawings, snapline)
    table.insert(drawings, nameText)
    table.insert(drawings, healthBg)
    table.insert(drawings, healthFill)
    table.insert(drawings, armorBg)
    table.insert(drawings, armorFill)
    table.insert(drawings, distanceText)
    
    return drawings
end

local function updateESP()
    if not Settings.MasterESP then
        for _, drawings in pairs(ActiveDrawings) do
            for _, d in ipairs(drawings) do d.Visible = false end
        end
        return
    end
    
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local screenSize = Camera.ViewportSize
    
    for player, drawings in pairs(ActiveDrawings) do
        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local head = character and character:FindFirstChild("Head")
        
        if not (root and humanoid and head) or humanoid.Health <= 0 then
            for _, d in ipairs(drawings) do d.Visible = false end
            continue
        end
        
        local distance = myRoot and (myRoot.Position - root.Position).Magnitude or 0
        if distance > Settings.MaxESPDistance then
            for _, d in ipairs(drawings) do d.Visible = false end
            continue
        end
        
        local isEnemy = (player.Team and player.Team ~= LocalPlayer.Team)
        if Settings.TeamCheck and not isEnemy then
            for _, d in ipairs(drawings) do d.Visible = false end
            continue
        end
        
        local headPos = head.Position + Vector3.new(0, 0.5, 0)
        local feetPos = root.Position - Vector3.new(0, 2.8, 0)
        local headScr, onScreen1 = Camera:WorldToViewportPoint(headPos)
        local feetScr, onScreen2 = Camera:WorldToViewportPoint(feetPos)
        
        if not (onScreen1 and onScreen2) then
            for _, d in ipairs(drawings) do d.Visible = false end
            continue
        end
        
        local height = math.abs(headScr.Y - feetScr.Y)
        local width = height * 0.65
        local centerX = (headScr.X + feetScr.X) / 2
        local boxX = centerX - width / 2
        local boxY = math.min(headScr.Y, feetScr.Y)
        
        local boxColor = isEnemy and Settings.EnemyColor or Settings.FriendlyColor
        
        if Settings.Box then
            drawings[1].Position = Vector2.new(boxX, boxY)
            drawings[1].Size = Vector2.new(width, height)
            drawings[1].Visible = true
        else
            drawings[1].Visible = false
        end
        
        if Settings.BoxFill then
            drawings[2].Position = Vector2.new(boxX, boxY)
            drawings[2].Size = Vector2.new(width, height)
            drawings[2].Color = boxColor
            drawings[2].Visible = true
        else
            drawings[2].Visible = false
        end
        
        if Settings.Snapline then
            local bottomCenter = Vector2.new(screenSize.X / 2, screenSize.Y)
            drawings[3].From = bottomCenter
            drawings[3].To = Vector2.new(centerX, feetScr.Y)
            drawings[3].Color = boxColor
            drawings[3].Visible = true
        else
            drawings[3].Visible = false
        end
        
        if Settings.Name then
            drawings[4].Text = player.Name
            drawings[4].Position = Vector2.new(centerX, boxY - 20)
            drawings[4].Visible = true
        else
            drawings[4].Visible = false
        end
        
        if Settings.HealthBar then
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            local barH = height * healthPercent
            local barY = boxY + (height - barH)
            
            drawings[5].Position = Vector2.new(boxX - 6, boxY)
            drawings[5].Size = Vector2.new(3, height)
            drawings[5].Visible = true
            
            drawings[6].Position = Vector2.new(boxX - 6, barY)
            drawings[6].Size = Vector2.new(3, barH)
            drawings[6].Color = Color3.fromHSV(healthPercent * 0.3, 1, 1)
            drawings[6].Visible = true
        else
            drawings[5].Visible = false
            drawings[6].Visible = false
        end
        
        local armor = getArmor(character)
        if Settings.ArmorBar and armor > 0 then
            local maxArmor = 100
            local armorPercent = math.clamp(armor / maxArmor, 0, 1)
            local armorBarH = height * armorPercent
            local armorBarY = boxY + (height - armorBarH)
            
            drawings[7].Position = Vector2.new(boxX + width + 3, boxY)
            drawings[7].Size = Vector2.new(3, height)
            drawings[7].Visible = true
            
            drawings[8].Position = Vector2.new(boxX + width + 3, armorBarY)
            drawings[8].Size = Vector2.new(3, armorBarH)
            drawings[8].Visible = true
        else
            drawings[7].Visible = false
            drawings[8].Visible = false
        end
        
        if Settings.Distance then
            drawings[9].Text = string.format("%.0f m", distance * 0.28)
            drawings[9].Position = Vector2.new(centerX, boxY + height + 5)
            drawings[9].Visible = true
        else
            drawings[9].Visible = false
        end
    end
end

-- ====================== AIMBOT SYSTEM ======================
local function isVisible(targetPart)
    if not Settings.VisibilityCheck then return true end
    local myHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
    if not myHead then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    
    local ray = workspace:Raycast(myHead.Position, (targetPart.Position - myHead.Position).Unit * 1000, raycastParams)
    if ray and ray.Instance then
        return ray.Instance:IsDescendantOf(targetPart.Parent)
    end
    return false
end

local function getAimPart(character)
    if Settings.AimPart == "Head" then
        return character:FindFirstChild("Head")
    elseif Settings.AimPart == "Torso" then
        return character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    elseif Settings.AimPart == "Left Arm" then
        return character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm")
    elseif Settings.AimPart == "Right Arm" then
        return character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm")
    elseif Settings.AimPart == "Left Leg" then
        return character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg")
    elseif Settings.AimPart == "Right Leg" then
        return character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg")
    else
        return character:FindFirstChild("Head")
    end
end

local function getClosestTarget()
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closest = nil
    local minDist = Settings.FOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        if Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        local aimPart = getAimPart(char)
        if not aimPart then continue end
        
        if not isVisible(aimPart) then continue end
        
        local screenPos, onScreen = Camera:WorldToScreenPoint(aimPart.Position)
        if not onScreen then continue end
        
        local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
        if distFromCenter < minDist then
            minDist = distFromCenter
            closest = aimPart
        end
    end
    
    return closest
end

local function aimAt(targetPart)
    if not targetPart then return end
    
    local cameraPos = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local lookAt = CFrame.lookAt(cameraPos, targetPos)
    
    if Settings.Smoothness <= 1 then
        Camera.CFrame = lookAt
    else
        local smoothFactor = 1 / (Settings.Smoothness * 0.5)
        Camera.CFrame = Camera.CFrame:Lerp(lookAt, smoothFactor)
    end
end

local function updateFOVCircle()
    if Settings.ShowFOV and Settings.Aimbot then
        if not FOVCircle then
            FOVCircle = Drawing.new("Circle")
            FOVCircle.Color = Color3.fromRGB(255, 255, 255)
            FOVCircle.Thickness = 1.5
            FOVCircle.NumSides = 60
            FOVCircle.Filled = false
            FOVCircle.Transparency = 0.8
        end
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = Settings.FOV
        FOVCircle.Visible = true
    else
        if FOVCircle then
            FOVCircle.Visible = false
        end
    end
end




-- ====================== PLAYER TRACKING ======================
local function onPlayerAdded(player)
    if player ~= LocalPlayer then
        ActiveDrawings[player] = createESP(player)
    end
end

local function onPlayerRemoving(player)
    if ActiveDrawings[player] then
        for _, d in ipairs(ActiveDrawings[player]) do
            d:Remove()
        end
        ActiveDrawings[player] = nil
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ====================== UI CREATION ======================
local ESPTab = Window:Tab({ Title = "ESP" })
local AimbotTab = Window:Tab({ Title = "Aimbot" })

local RightShiftToToggle = Window:Tab({ Title = "RightShift To Toggle", Locked = true })

-- ESP Tab
local ESPSection = ESPTab:Section({ Title = "ESP Settings" })

ESPSection:Toggle({
    Title = "Master Switch",
    Default = Settings.MasterESP,
    Callback = function(value) Settings.MasterESP = value end,
})

ESPSection:Toggle({
    Title = "Box",
    Default = Settings.Box,
    Callback = function(value) Settings.Box = value end,
})

ESPSection:Toggle({
    Title = "Box Fill",
    Default = Settings.BoxFill,
    Callback = function(value) Settings.BoxFill = value end,
})

ESPSection:Toggle({
    Title = "Name",
    Default = Settings.Name,
    Callback = function(value) Settings.Name = value end,
})

ESPSection:Toggle({
    Title = "Distance",
    Default = Settings.Distance,
    Callback = function(value) Settings.Distance = value end,
})

ESPSection:Toggle({
    Title = "Health Bar",
    Default = Settings.HealthBar,
    Callback = function(value) Settings.HealthBar = value end,
})

ESPSection:Toggle({
    Title = "Armor Bar",
    Default = Settings.ArmorBar,
    Callback = function(value) Settings.ArmorBar = value end,
})

ESPSection:Toggle({
    Title = "Snapline",
    Default = Settings.Snapline,
    Callback = function(value) Settings.Snapline = value end,
})

ESPSection:Toggle({
    Title = "Team Check",
    Default = Settings.TeamCheck,
    Callback = function(value) Settings.TeamCheck = value end,
})

ESPSection:Slider({
    Title = "Max ESP Distance",
    Step = 10,
    Value = {
        Min = 10,
        Max = 2000,
        Default = Settings.MaxESPDistance,
    },
    Callback = function(value) 
        Settings.MaxESPDistance = (value * 0.28)
     end,
})

local ColorSection = ESPTab:Section({ Title = "Colors" })

ColorSection:Colorpicker({
    Title = "Friendly Color",
    Default = Settings.FriendlyColor,
    Callback = function(color) Settings.FriendlyColor = color end,
})

ColorSection:Colorpicker({
    Title = "Enemy Color",
    Default = Settings.EnemyColor,
    Callback = function(color) Settings.EnemyColor = color end,
})

-- Aimbot Tab
local AimbotSection = AimbotTab:Section({ Title = "Aimbot Settings" })

AimbotSection:Toggle({
    Title = "Aimbot",
    Default = Settings.Aimbot,
    Callback = function(value) Settings.Aimbot = value end,
})

AimbotSection:Toggle({
    Title = "Show FOV Circle",
    Default = Settings.ShowFOV,
    Callback = function(value) Settings.ShowFOV = value end,
})

AimbotSection:Toggle({
    Title = "Visibility Check",
    Default = Settings.VisibilityCheck,
    Callback = function(value) Settings.VisibilityCheck = value end,
})

AimbotSection:Slider({
    Title = "Smoothness",
    Step = 1,
    Value = {
        Min = 1,
        Max = 20,
        Default = Settings.Smoothness,
    },
    Callback = function(value) Settings.Smoothness = value end,
})

AimbotSection:Slider({
    Title = "FOV Size",
    Step = 5,
    Value = {
        Min = 50,
        Max = 400,
        Default = Settings.FOV,
    },
    Callback = function(value) Settings.FOV = value end,
})

AimbotSection:Dropdown({
    Title = "Aim Part",
    Values  = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
    Default = Settings.AimPart,
    Callback = function(value) Settings.AimPart = value end,
})

AimbotSection:Keybind({
    Title = "Aim Key",
    Default = "MouseButton2",
    Callback = function(key)
        local inputType = Enum.UserInputType[key]
        if inputType then Settings.AimKey = inputType end
    end,
})

-- ====================== MAIN LOOP ======================
RunService.RenderStepped:Connect(function()
    updateESP()
    updateFOVCircle()
    
    if Settings.Aimbot then
        local isKeyDown = UserInputService:IsMouseButtonPressed(Settings.AimKey)
        if isKeyDown then
            local target = getClosestTarget()
            if target then
                aimAt(target)
            end
        end
    end
    
    
<<<<<<< Updated upstream
end)
=======
end)
>>>>>>> Stashed changes
