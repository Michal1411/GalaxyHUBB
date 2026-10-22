local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- ==========================================
-- REMOTES A SLUŽBY
-- ==========================================
local Services = ReplicatedStorage:WaitForChild("Packages", 9e9):WaitForChild("Knit", 9e9):WaitForChild("Services", 9e9)
local TeleportService = Services:WaitForChild("TeleportService", 9e9):WaitForChild("RE", 9e9)
local EggHatchService = Services:WaitForChild("EggHatchService", 9e9):WaitForChild("RE", 9e9)
local BreakableAreaService = Services:WaitForChild("BreakableAreaService", 9e9):WaitForChild("RE", 9e9)
local PlaytimeGiftsService = Services:WaitForChild("PlaytimeGiftsService", 9e9):WaitForChild("RE", 9e9)
local FishingService = Services:WaitForChild("FishingService", 9e9):WaitForChild("RF", 9e9)

-- ==========================================
-- DATABÁZE A SEŘAZENÉ LOKACE
-- ==========================================
local OrderedLocations = {
    "Spawn", "BirchForest", "TreasureDunes", "FrozenAlley", 
    "HauntedHouse", "PetKingdom", "EnchancedGrove", "VolcanoHollow", "FloralSakura"
}
local BestLocation = OrderedLocations[#OrderedLocations]

local EggData = {
    ["Sakura Egg"] = {Teleport = "FloralSakura", Coords = Vector3.new(-1503, 1, -1605)},
    ["Volcano Egg"] = {Teleport = "VolcanoHollow", Coords = Vector3.new(-1155, 2, -2738)},
    ["Mushroom Egg"] = {Teleport = "EnchancedGrove", Coords = Vector3.new(-140, 1, -2718)},
    ["Castle Egg"] = {Teleport = "PetKingdom", Coords = Vector3.new(1581, 2, -2998)},
    ["Zombie Egg"] = {Teleport = "HauntedHouse", Coords = Vector3.new(2455, 3, -2961)},
    ["Frost Egg"] = {Teleport = "FrozenAlley", Coords = Vector3.new(2468, 1, -1702)},
    ["Dried Egg"] = {Teleport = "TreasureDunes", Coords = Vector3.new(1070, 10, -1775)},
    ["Grassy Egg"] = {Teleport = "BirchForest", Coords = Vector3.new(-166, 1, -1722)},
    ["Basic Egg"] = {Teleport = "Spawn", Coords = Vector3.new(-204, 13, -10)},
}
local EggNames = {} 
for k,_ in pairs(EggData) do 
    table.insert(EggNames, k) 
end

local FishingSpots = {"Spawn", "HalloweenEvent", "Treasure Dunes", "Haunted House"}
local FishingCoords = {
    ["Spawn"] = Vector3.new(-192, 13, -36),
    ["HalloweenEvent"] = Vector3.new(-154, 2, 1791),
    ["Treasure Dunes"] = Vector3.new(1133, 2, -1656),
    ["Haunted House"] = Vector3.new(2480, 1, -2838)
}

-- Proměnné stavu
local Toggles = {
    AutoFarm = false, AutoBestLocation = false, AutoBuyLoc = false, 
    AutoHatch = false, AutoGifts = false, AutoPlaytimeEgg = false, 
    AutoFish = false, AutoWalkHouses = false, Censored = false
}
local Selections = {FarmLocation = "Spawn", HatchEgg = "Basic Egg", FishSpot = "Spawn"}

-- ==========================================
-- LOGIKA POHYBU (Bez lagů)
-- ==========================================
local walkingConnection
local function stopWalking()
    if walkingConnection then 
        walkingConnection:Disconnect() 
        walkingConnection = nil 
    end
end

local function SmartWalk(teleportName, targetVector)
    stopWalking()
    if teleportName then
        pcall(function() TeleportService:WaitForChild("GoTo_ng6"):FireServer(teleportName) end)
        task.wait(1)
    end
    if targetVector then
        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if humanoid and root then
            humanoid:MoveTo(targetVector)
            walkingConnection = RunService.Heartbeat:Connect(function()
                if not humanoid or not root or not humanoid.Parent then stopWalking() return end
                humanoid:MoveTo(targetVector)
                if (root.Position - targetVector).Magnitude < 3 then stopWalking() end
            end)
        end
    end
end

-- Plynulé posouvání UI (Smooth Dragging)
local function MakeDraggable(topbar, object)
    local dragging, dragInput, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true 
            dragStart = input.Position 
            startPos = object.Position
            input.Changed:Connect(function() 
                if input.UserInputState == Enum.UserInputState.End then dragging = false end 
            end)
        end
    end)
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    RunService.Heartbeat:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            object.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ==========================================
-- MODERNÍ UI SETUP (Tmavý motiv s plynulými animacemi)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GalaxyHubPremium"
screenGui.ResetOnSpawn = false
if gethui then 
    screenGui.Parent = gethui() 
elseif syn and syn.protect_gui then 
    syn.protect_gui(screenGui) 
else 
    screenGui.Parent = game:GetService("CoreGui") or player:WaitForChild("PlayerGui") 
end

-- Barvy motivu
local bgDark = Color3.fromRGB(15, 15, 15)
local bgLighter = Color3.fromRGB(24, 24, 24)
local accentColor = Color3.fromRGB(230, 160, 40) -- Měkčí zlatá/oranžová
local textColor = Color3.fromRGB(220, 220, 220)

-- Plovoucí váleček (Permanentní navigační tlačítko)
local floatBtn = Instance.new("TextButton", screenGui)
floatBtn.Size = UDim2.new(0, 90, 0, 36)
floatBtn.Position = UDim2.new(0.5, -45, 0, 15)
floatBtn.BackgroundColor3 = bgLighter
floatBtn.Text = "GLXH"
floatBtn.TextColor3 = accentColor
floatBtn.Font = Enum.Font.GothamBold
floatBtn.TextSize = 14
floatBtn.Active = true
floatBtn.Draggable = true
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", floatBtn).Color = accentColor
Instance.new("UIStroke", floatBtn).Thickness = 1.5

-- Hlavní okno
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 700, 0, 450)
mainFrame.Position = UDim2.new(0.5, -350, 0.5, -225)
mainFrame.BackgroundColor3 = bgDark
mainFrame.ClipsDescendants = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Horní lišta pro přesouvání
local topbar = Instance.new("Frame", mainFrame)
topbar.Size = UDim2.new(1, 0, 0, 40)
topbar.BackgroundTransparency = 1
MakeDraggable(topbar, mainFrame)

local title = Instance.new("TextLabel", topbar)
title.Size = UDim2.new(0.5, 0, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Galaxy HUB | Pets Universe!"
title.TextColor3 = textColor
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", topbar)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 5)
closeBtn.BackgroundColor3 = bgLighter
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
closeBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)
closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 60, 60), TextColor3 = Color3.fromRGB(255,255,255)}):Play() end)
closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = bgLighter, TextColor3 = Color3.fromRGB(150, 150, 150)}):Play() end)

-- Propojení válečku a okna
floatBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

-- Sidebar (Levé menu)
local sidebar = Instance.new("Frame", mainFrame)
sidebar.Size = UDim2.new(0, 190, 1, -40)
sidebar.Position = UDim2.new(0, 0, 0, 40)
sidebar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
sidebar.BorderSizePixel = 0

local playerInfo = Instance.new("Frame", sidebar)
playerInfo.Size = UDim2.new(1, 0, 0, 50)
playerInfo.Position = UDim2.new(0, 0, 1, -50)
playerInfo.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
playerInfo.BorderSizePixel = 0

local pfpPlaceholder = Instance.new("Frame", playerInfo)
pfpPlaceholder.Size = UDim2.new(0, 30, 0, 30)
pfpPlaceholder.Position = UDim2.new(0, 15, 0.5, -15)
pfpPlaceholder.BackgroundColor3 = bgLighter
Instance.new("UICorner", pfpPlaceholder).CornerRadius = UDim.new(1, 0)

local welcomeText = Instance.new("TextLabel", playerInfo)
welcomeText.Size = UDim2.new(1, -60, 1, 0)
welcomeText.Position = UDim2.new(0, 55, 0, 0)
welcomeText.BackgroundTransparency = 1
welcomeText.Text = "Welcome, \n" .. player.Name
welcomeText.TextColor3 = textColor
welcomeText.Font = Enum.Font.Gotham
welcomeText.TextSize = 12
welcomeText.TextXAlignment = Enum.TextXAlignment.Left

-- Kontejner pro obsah
local contentArea = Instance.new("Frame", mainFrame)
contentArea.Size = UDim2.new(1, -200, 1, -50)
contentArea.Position = UDim2.new(0, 200, 0, 40)
contentArea.BackgroundTransparency = 1

local tabs, tabBtns = {}, {}
local tabLayout = Instance.new("UIListLayout", sidebar)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 4)
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0, 10)

local function switchTab(name)
    for tName, tab in pairs(tabs) do 
        tab.Visible = (tName == name) 
    end
    for bName, btn in pairs(tabBtns) do
        local isActive = (bName == name)
        TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = isActive and accentColor or Color3.fromRGB(140, 140, 140)}):Play()
        TweenService:Create(btn.Indicator, TweenInfo.new(0.2), {BackgroundColor3 = isActive and accentColor or Color3.fromRGB(12, 12, 12)}):Play()
    end
end

local function createTab(name)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, -10, 0, 38)
    btn.Position = UDim2.new(0, 5, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text = "    " .. name
    btn.TextColor3 = Color3.fromRGB(140, 140, 140)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    
    local indicator = Instance.new("Frame", btn)
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 3, 0, 18)
    indicator.Position = UDim2.new(0, 10, 0.5, -9)
    indicator.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
    
    btn.MouseEnter:Connect(function() 
        if not tabs[name].Visible then 
            TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = textColor}):Play() 
        end 
    end)
    btn.MouseLeave:Connect(function() 
        if not tabs[name].Visible then 
            TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(140, 140, 140)}):Play() 
        end 
    end)
    
    tabBtns[name] = btn
    
    local page = Instance.new("ScrollingFrame", contentArea)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = accentColor
    local pl = Instance.new("UIListLayout", page)
    pl.SortOrder = Enum.SortOrder.LayoutOrder
    pl.Padding = UDim.new(0, 8)
    Instance.new("UIPadding", page).PaddingRight = UDim.new(0, 10)
    
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    tabs[name] = page
    return page
end

-- Hover UI Helpery
local function createToggle(parent, text, varName, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.BackgroundColor3 = bgLighter
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = textColor
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local switchBg = Instance.new("TextButton", frame)
    switchBg.Size = UDim2.new(0, 44, 0, 22)
    switchBg.Position = UDim2.new(1, -60, 0.5, -11)
    switchBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    switchBg.Text = ""
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)
    
    local switchCircle = Instance.new("Frame", switchBg)
    switchCircle.Size = UDim2.new(0, 16, 0, 16)
    switchCircle.Position = UDim2.new(0, 3, 0.5, -8)
    switchCircle.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    Instance.new("UICorner", switchCircle).CornerRadius = UDim.new(1, 0)
    
    local function toggleAction()
        Toggles[varName] = not Toggles[varName]
        local state = Toggles[varName]
        TweenService:Create(switchBg, TweenInfo.new(0.25), {BackgroundColor3 = state and accentColor or Color3.fromRGB(40, 40, 40)}):Play()
        TweenService:Create(switchCircle, TweenInfo.new(0.25), {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)}):Play()
        if callback then 
            task.spawn(function() callback(state) end) 
        end
    end
    
    switchBg.MouseButton1Click:Connect(toggleAction)
    
    -- Hover efekt pro celý řádek
    frame.MouseEnter:Connect(function() TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play() end)
    frame.MouseLeave:Connect(function() TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundColor3 = bgLighter}):Play() end)
end

local function createDropdown(parent, titleText, optionsList, varName)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 48)
    container.BackgroundColor3 = bgLighter
    container.ClipsDescendants = true
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
    
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 0, 48)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. titleText .. ": " .. Selections[varName]
    btn.TextColor3 = accentColor
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    
    local scroll = Instance.new("ScrollingFrame", container)
    scroll.Size = UDim2.new(1, 0, 1, -48)
    scroll.Position = UDim2.new(0, 0, 0, 48)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 2
    local sl = Instance.new("UIListLayout", scroll)
    sl.Padding = UDim.new(0, 2)
    
    local isOpen = false
    btn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = isOpen and UDim2.new(1, 0, 0, 180) or UDim2.new(1, 0, 0, 48)}):Play()
    end)
    
    for _, opt in ipairs(optionsList) do
        local obtn = Instance.new("TextButton", scroll)
        obtn.Size = UDim2.new(1, 0, 0, 32)
        obtn.BackgroundColor3 = bgDark
        obtn.Text = "   " .. opt
        obtn.TextColor3 = textColor
        obtn.Font = Enum.Font.Gotham
        obtn.TextSize = 12
        obtn.TextXAlignment = Enum.TextXAlignment.Left
        
        obtn.MouseEnter:Connect(function() TweenService:Create(obtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40,40,40)}):Play() end)
        obtn.MouseLeave:Connect(function() TweenService:Create(obtn, TweenInfo.new(0.1), {BackgroundColor3 = bgDark}):Play() end)
        
        obtn.MouseButton1Click:Connect(function()
            Selections[varName] = opt
            btn.Text = "  " .. titleText .. ": " .. opt
            isOpen = false
            TweenService:Create(container, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 48)}):Play()
        end)
    end
end

-- ==========================================
-- ZÁLOŽKY A FUNKCE
-- ==========================================

-- 1. Auto Farm
local tFarm = createTab("Auto Farm")
createDropdown(tFarm, "Farm Location", OrderedLocations, "FarmLocation")
createToggle(tFarm, "Auto Farm in Best Location", "AutoBestLocation", function(state)
    if state then
        Selections.FarmLocation = BestLocation
    end
end)
createToggle(tFarm, "Auto Farm", "AutoFarm", function(state)
    pcall(function() BreakableAreaService:WaitForChild("SetAutoBreaking_9kc"):FireServer(state) end)
    if state then 
        local loc = Toggles.AutoBestLocation and BestLocation or Selections.FarmLocation
        SmartWalk(loc, nil) 
    end
end)
createToggle(tFarm, "Auto Buy Locations", "AutoBuyLoc", function(state)
    task.spawn(function()
        while Toggles.AutoBuyLoc do
            pcall(function() TeleportService:WaitForChild("Purchase_cl9"):FireServer("Bought") end)
            task.wait(5)
        end
    end)
end)

-- 2. Auto Hatch
local tHatch = createTab("Auto Hatch")
createDropdown(tHatch, "Select Egg", EggNames, "HatchEgg")
createToggle(tHatch, "Auto Hatch Egg", "AutoHatch", function(state)
    task.spawn(function()
        if state then
            local data = EggData[Selections.HatchEgg]
            if data then SmartWalk(data.Teleport, data.Coords) end
            task.wait(1)
            while Toggles.AutoHatch do
                pcall(function() EggHatchService:WaitForChild("Hatch_ykw"):FireServer(Selections.HatchEgg, "Max") end)
                task.wait(2)
            end
        else
            pcall(function() EggHatchService:WaitForChild("StopHatching_n2d"):FireServer() end)
        end
    end)
end)

-- 3. Playtime Rewards
local tRewards = createTab("Playtime Rewards")
createToggle(tRewards, "Auto Claim Gifts (1-9)", "AutoGifts", function(state)
    task.spawn(function()
        while Toggles.AutoGifts do
            for i = 1, 9 do
                pcall(function() PlaytimeGiftsService:WaitForChild("ClaimGift_k6c"):FireServer("Gift"..i) end)
                task.wait(0.5)
            end
            task.wait(60)
        end
    end)
end)
createToggle(tRewards, "Auto Claim Playtime Egg", "AutoPlaytimeEgg", function(state)
    task.spawn(function()
        while Toggles.AutoPlaytimeEgg do
            -- Tvůj kód pro party egg bypass 
            task.wait(60)
        end
    end)
end)

-- 4. Fishing World (Plynulý cyklus, opravený zásek)
local tFish = createTab("Fishing World")
createDropdown(tFish, "Fishing Spot", FishingSpots, "FishSpot")
createToggle(tFish, "Auto Fish", "AutoFish", function(state)
    if state then
        task.spawn(function()
            local coords = FishingCoords[Selections.FishSpot]
            if coords then SmartWalk(Selections.FishSpot, coords) end
            task.wait(1)
            while Toggles.AutoFish do
                pcall(function() FishingService:WaitForChild("BeginFishing_1a4"):InvokeServer() end)
                task.wait(4.5) -- Ideální doba na vytáhnutí
                pcall(function() FishingService:WaitForChild("EndFishing_7wg"):InvokeServer() end)
                task.wait(0.5)
            end
        end)
    end
end)

-- 5. Halloween Event
local tEvent = createTab("Halloween Event")
createToggle(tEvent, "Auto Walk Houses", "AutoWalkHouses", function(state)
    task.spawn(function()
        if state then
            SmartWalk("HalloweenEvent", nil)
            local points = {Vector3.new(-300, 3, 1700), Vector3.new(-320, 3, 1750)}
            while Toggles.AutoWalkHouses do
                for _, pt in ipairs(points) do
                    if not Toggles.AutoWalkHouses then break end
                    SmartWalk(nil, pt)
                    task.wait(2)
                end
            end
        end
    end)
end)

-- 6. Optimization
local tOpt = createTab("Optimization")
createToggle(tOpt, "Censor Player Name", "Censored", function(state)
    if state then
        welcomeText.Text = "Welcome, \n[CENSORED]"
        title.Text = "[CENSORED] HUB"
    else
        welcomeText.Text = "Welcome, \n" .. player.Name
        title.Text = "Galaxy HUB | Pets Universe!"
    end
end)

-- Start
switchTab("Auto Farm")
