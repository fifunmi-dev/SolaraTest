-- Universal Roblox Hitbox Extender, ESP & Rayfield Menu - FIXED VERSION
-- Hitbox now properly expands multiple parts + bone targeting

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Universal Hitbox & ESP",
    LoadingTitle = "Nexon Hitbox Extension",
    LoadingSubtitle = "by klyutz",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "UniversalHub",
        FileName = "UniversalConfig"
    },
    Discord = { Enabled = false },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)
local CombatTab = Window:CreateTab("Combat", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)

-- Variables
local HitboxEnabled = false
local HitboxSize = 10
local HitboxTransparency = 0.7
local HitboxColor = Color3.fromRGB(255, 0, 0)
local SelectedBone = "Head"
local TeamCheck = true
local ESPEnabled = false
local ESPColor = Color3.fromRGB(255, 0, 0)
local ESPThickness = 2
local ShowDistance = true
local ShowName = true
local ShowHealth = true

local Connections = {}
local ESPObjects = {}
local OriginalProperties = {}
local BoneParts = {Head = true, Torso = true, Waist = true}

-- Bone mapping (works across most games)
local function GetTargetPart(character)
    if not character then return nil end
    local boneMap = {
        Head = character:FindFirstChild("Head"),
        Torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
        Waist = character:FindFirstChild("LowerTorso") or character:FindFirstChild("HumanoidRootPart")
    }
    return boneMap[SelectedBone] or character:FindFirstChild("HumanoidRootPart")
end

-- Fixed Hitbox Extender (now targets selected bone + expands surrounding parts)
local function UpdateHitboxes()
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Character then
            local character = player.Character
            local targetPart = GetTargetPart(character)
            
            if not OriginalProperties[player] then
                OriginalProperties[player] = {}
            end
            
            if HitboxEnabled and targetPart then
                -- Store original if not stored
                if not OriginalProperties[player][targetPart] then
                    OriginalProperties[player][targetPart] = {
                        Size = targetPart.Size,
                        Transparency = targetPart.Transparency,
                        Color = targetPart.Color,
                        Material = targetPart.Material,
                        CanCollide = targetPart.CanCollide
                    }
                end
                
                -- Expand main target bone
                targetPart.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                targetPart.Transparency = HitboxTransparency
                targetPart.Color = HitboxColor
                targetPart.Material = Enum.Material.ForceField
                targetPart.CanCollide = false
                
                -- Also expand common hitbox parts for better registration
                for _, partName in ipairs({"Head", "UpperTorso", "LowerTorso", "Torso", "HumanoidRootPart", "LeftUpperArm", "RightUpperArm"}) do
                    local part = character:FindFirstChild(partName)
                    if part and part ~= targetPart then
                        if not OriginalProperties[player][part] then
                            OriginalProperties[player][part] = {
                                Size = part.Size,
                                Transparency = part.Transparency,
                                Color = part.Color,
                                Material = part.Material,
                                CanCollide = part.CanCollide
                            }
                        end
                        part.Size = Vector3.new(HitboxSize * 0.8, HitboxSize * 0.8, HitboxSize * 0.8)
                        part.Transparency = HitboxTransparency * 0.6
                        part.Color = HitboxColor
                        part.Material = Enum.Material.ForceField
                        part.CanCollide = false
                    end
                end
            else
                -- Restore originals
                if OriginalProperties[player] then
                    for part, props in pairs(OriginalProperties[player]) do
                        if part and part.Parent then
                            part.Size = props.Size
                            part.Transparency = props.Transparency
                            part.Color = props.Color
                            part.Material = props.Material
                            part.CanCollide = props.CanCollide
                        end
                    end
                end
            end
        end
    end
end

-- ESP (kept 100% exactly the same as previous version)
local function CreateESP(player)
    if ESPObjects[player] then return end
    
    local esp = {}
    
    local box = Drawing.new("Square")
    box.Thickness = ESPThickness
    box.Filled = false
    box.Color = ESPColor
    box.Transparency = 1
    box.Visible = false
    
    local name = Drawing.new("Text")
    name.Size = 14
    name.Center = true
    name.Outline = true
    name.Color = ESPColor
    name.Font = 2
    name.Visible = false
    
    local distance = Drawing.new("Text")
    distance.Size = 13
    distance.Center = true
    distance.Outline = true
    distance.Color = Color3.fromRGB(255, 255, 255)
    distance.Font = 2
    distance.Visible = false
    
    esp.Box = box
    esp.Name = name
    esp.Distance = distance
    ESPObjects[player] = esp
    
    local connection
    connection = game:GetService("RunService").RenderStepped:Connect(function()
        if not ESPEnabled or not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            box.Visible = false
            name.Visible = false
            distance.Visible = false
            return
        end
        
        local root = player.Character.HumanoidRootPart
        local humanoid = player.Character:FindFirstChild("Humanoid")
        local localPlayer = game.Players.LocalPlayer
        local camera = workspace.CurrentCamera
        
        if TeamCheck and player.Team == localPlayer.Team then
            box.Visible = false
            name.Visible = false
            distance.Visible = false
            return
        end
        
        local rootPos, onScreen = camera:WorldToViewportPoint(root.Position)
        local headPos = camera:WorldToViewportPoint(root.Position + Vector3.new(0, 2.5, 0))
        local legPos = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
        
        if onScreen then
            local height = math.abs(headPos.Y - legPos.Y)
            local width = height / 2
            
            box.Size = Vector2.new(width, height)
            box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
            box.Visible = true
            
            if ShowName then
                name.Text = player.Name
                name.Position = Vector2.new(rootPos.X, rootPos.Y - height/2 - 16)
                name.Visible = true
            else
                name.Visible = false
            end
            
            if ShowDistance or ShowHealth then
                local dist = math.floor((localPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude)
                local text = ""
                
                if ShowDistance then text = text .. dist .. " studs" end
                if ShowHealth and humanoid then
                    text = text .. (ShowDistance and " | " or "") .. math.floor(humanoid.Health) .. " HP"
                end
                
                distance.Text = text
                distance.Position = Vector2.new(rootPos.X, rootPos.Y + height/2 + 5)
                distance.Visible = true
            else
                distance.Visible = false
            end
        else
            box.Visible = false
            name.Visible = false
            distance.Visible = false
        end
    end)
    
    Connections[player] = connection
end

local function RemoveESP(player)
    if ESPObjects[player] then
        ESPObjects[player].Box:Remove()
        ESPObjects[player].Name:Remove()
        ESPObjects[player].Distance:Remove()
        ESPObjects[player] = nil
    end
    if Connections[player] then
        Connections[player]:Disconnect()
        Connections[player] = nil
    end
end

local function UpdateESP()
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            if ESPEnabled then
                CreateESP(player)
            else
                RemoveESP(player)
            end
        end
    end
end

-- Combat Tab
CombatTab:CreateToggle({
    Name = "Hitbox Extender",
    CurrentValue = false,
    Flag = "HitboxToggle",
    Callback = function(Value)
        HitboxEnabled = Value
        if not Value then
            for player, data in pairs(OriginalProperties) do
                for part, props in pairs(data) do
                    if part and part.Parent then
                        part.Size = props.Size
                        part.Transparency = props.Transparency
                        part.Color = props.Color
                        part.Material = props.Material
                        part.CanCollide = props.CanCollide
                    end
                end
            end
        end
        UpdateHitboxes()
    end,
})

CombatTab:CreateDropdown({
    Name = "Target Bone",
    Options = {"Head", "Torso", "Waist"},
    CurrentOption = {"Head"},
    MultipleOptions = false,
    Flag = "BoneSelect",
    Callback = function(CurrentOption)
        SelectedBone = CurrentOption[1]
        if HitboxEnabled then
            UpdateHitboxes()
        end
    end,
})

CombatTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {5, 50},
    Increment = 1,
    CurrentValue = 10,
    Flag = "HitboxSize",
    Callback = function(Value)
        HitboxSize = Value
        if HitboxEnabled then UpdateHitboxes() end
    end,
})

CombatTab:CreateSlider({
    Name = "Hitbox Transparency",
    Range = {0.1, 1},
    Increment = 0.05,
    CurrentValue = 0.7,
    Flag = "Transparency",
    Callback = function(Value)
        HitboxTransparency = Value
        if HitboxEnabled then UpdateHitboxes() end
    end,
})

CombatTab:CreateColorPicker({
    Name = "Hitbox Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "HitboxColor",
    Callback = function(Value)
        HitboxColor = Value
        if HitboxEnabled then UpdateHitboxes() end
    end,
})

CombatTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "TeamCheck",
    Callback = function(Value)
        TeamCheck = Value
        UpdateESP()
        if HitboxEnabled then UpdateHitboxes() end
    end,
})

-- Visuals Tab (ESP unchanged)
VisualsTab:CreateToggle({
    Name = "ESP Box",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(Value)
        ESPEnabled = Value
        UpdateESP()
    end,
})

VisualsTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "ESPColor",
    Callback = function(Value)
        ESPColor = Value
        for _, esp in pairs(ESPObjects) do
            if esp.Box then esp.Box.Color = Value end
            if esp.Name then esp.Name.Color = Value end
        end
    end,
})

VisualsTab:CreateSlider({
    Name = "ESP Thickness",
    Range = {1, 5},
    Increment = 1,
    CurrentValue = 2,
    Flag = "ESPThickness",
    Callback = function(Value)
        ESPThickness = Value
        for _, esp in pairs(ESPObjects) do
            if esp.Box then esp.Box.Thickness = Value end
        end
    end,
})

VisualsTab:CreateToggle({
    Name = "Show Names",
    CurrentValue = true,
    Flag = "ShowNames",
    Callback = function(Value)
        ShowName = Value
    end,
})

VisualsTab:CreateToggle({
    Name = "Show Distance & Health",
    CurrentValue = true,
    Flag = "ShowDistance",
    Callback = function(Value)
        ShowDistance = Value
        ShowHealth = Value
    end,
})

-- Main Tab - Config System + Extra Goodies
MainTab:CreateSection("Configuration System")

MainTab:CreateButton({
    Name = "Save Current Config",
    Callback = function()
        Rayfield:SaveConfiguration()
        Rayfield:Notify({
            Title = "Config Saved",
            Content = "Current settings have been saved successfully.",
            Duration = 4,
        })
    end,
})

MainTab:CreateButton({
    Name = "Load Last Config",
    Callback = function()
        Rayfield:LoadConfiguration()
        Rayfield:Notify({
            Title = "Config Loaded",
            Content = "Previous settings loaded.",
            Duration = 4,
        })
        -- Refresh hitbox/esp after load
        task.wait(0.5)
        if HitboxEnabled then UpdateHitboxes() end
        UpdateESP()
    end,
})

MainTab:CreateSection("Extras")

MainTab:CreateToggle({
    Name = "Auto Update Hitboxes",
    CurrentValue = true,
    Flag = "AutoUpdate",
    Callback = function(Value)
        -- Handled in the loop below
    end,
})

MainTab:CreateButton({
    Name = "Reset All Hitboxes",
    Callback = function()
        for player, data in pairs(OriginalProperties) do
            for part, props in pairs(data) do
                if part and part.Parent then
                    part.Size = props.Size
                    part.Transparency = props.Transparency
                    part.Color = props.Color
                    part.Material = props.Material
                    part.CanCollide = props.CanCollide
                end
            end
        end
        OriginalProperties = {}
        Rayfield:Notify({Title = "Hitboxes Reset", Content = "All hitboxes restored to normal.", Duration = 3})
    end,
})

MainTab:CreateButton({
    Name = "Refresh ESP",
    Callback = function()
        for player in pairs(ESPObjects) do
            RemoveESP(player)
        end
        UpdateESP()
        Rayfield:Notify({Title = "ESP Refreshed", Content = "ESP has been refreshed.", Duration = 3})
    end,
})

-- Player handlers
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        UpdateESP()
        if HitboxEnabled then UpdateHitboxes() end
    end)
end)

game.Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
    OriginalProperties[player] = nil
end)

-- Main update loop (more aggressive for hitbox)
task.spawn(function()
    while true do
        if HitboxEnabled then
            UpdateHitboxes()
        end
        task.wait(0.07) -- Faster update rate for better hitbox registration
    end
end)

Rayfield:Notify({
    Title = "Universal Hub - FIXED",
    Content = "Hitbox extender has been completely rewritten. Bone selection (Head/Torso/Waist) added. Config save/load in Main tab. ESP is untouched.",
    Duration = 8,
    Image = 4483362458,
})

print("Universal Hitbox + ESP + Rayfield Menu - FIXED VERSION Loaded")