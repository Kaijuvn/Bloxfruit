if getgenv then
    if getgenv().ChestEspActive then
        pcall(function()
            if getgenv().ChestEspGui and getgenv().ChestEspGui.Parent then
                getgenv().ChestEspGui:Destroy()
            end
        end)
    end
    getgenv().ChestEspActive = true
end

repeat task.wait(0.3) until game:IsLoaded()
local Players = game:GetService("Players")
repeat task.wait(0.3) until Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId
local scriptActive = true
local bootTick = os.clock()

repeat task.wait(0.3) until LocalPlayer:FindFirstChild("PlayerGui")
task.wait(2)

local CONFIG = {
    GitHubRawURL = "https://raw.githubusercontent.com/Kaijuvn/Bloxfruit/refs/heads/main/BloxFruits_ChestESP.lua",
    AutoReExecute = true,
    CollectSpeed = 250,
    ScanInterval = 2.5,
    HopScanPages = 4,
    HopEmptyDelay = 4,
    DefaultBackground = "rbxassetid://16140502159",
    DefaultIcon = "rbxassetid://14207920404"
}

local STATE = {
    EspOn = true,
    EspT1 = true,
    EspT2 = true,
    EspT3 = true,
    AutoCollect = false,
    SkipSilver = false,
    StopOnKey = true,
    AutoHopEmpty = true,
    NoclipOn = true,
    AutoGrabKey = true,
    HuntKeyMode = false,
    HuntLootFirst = true,
    HuntedServers = 0,
    KillTween = false,
    LastTryId = nil,
    RetryHop = false,
    LastHopMode = "oldest",
    HopMaxPlayers = 2,
    KeyFound = false,
    Collected = 0,
    ChestCount = 0,
    NearestDist = 0,
    IsHopping = false,
    IsPaused = false,
    CurrentTween = nil,
    IgnoredChests = {}
}

local CHEST_BLUE = Color3.fromRGB(30, 144, 255)
local KEY_RED = Color3.fromRGB(255, 30, 45)

local TIER_INFO = {
    [1] = {Name = "Chest1", Label = "💰 RƯƠNG BẠC", Color = CHEST_BLUE},
    [2] = {Name = "Chest2", Label = "👑 RƯƠNG VÀNG", Color = CHEST_BLUE},
    [3] = {Name = "Chest3", Label = "💎 RƯƠNG XANH", Color = CHEST_BLUE}
}
local NAME_TO_TIER = {Chest1 = 1, Chest2 = 2, Chest3 = 3}

local function isFistName(n)
    return n == "Fist of Darkness" or n == "FistOfDarkness"
end

local ChestMap = {}
local FistMap = {}
local VisitedServers = {}
if getgenv and getgenv().ChestEspVisited then
    VisitedServers = getgenv().ChestEspVisited
elseif getgenv then
    getgenv().ChestEspVisited = VisitedServers
end
VisitedServers[JobId] = true

local function resolveAsset(filename, fallbackAssetId)
    local asset = fallbackAssetId
    pcall(function()
        if (getcustomasset or getsynasset) and isfile and isfile(filename) then
            asset = (getcustomasset or getsynasset)(filename)
        end
    end)
    return asset
end

local MenuBgAsset = resolveAsset("BF_MenuBg.jpg", CONFIG.DefaultBackground)
local GojoIconAsset = resolveAsset("BF_GojoIcon.jpg", CONFIG.DefaultIcon)

local teleportQueued = false
local function setupAutoRestart()
    if teleportQueued or not CONFIG.AutoReExecute then return end
    local queueFunc = (syn and syn.queue_on_teleport) or queue_on_teleport or queueonteleport or (fluxus and fluxus.queue_on_teleport)
    if not queueFunc then return end

    local url = nil
    if getgenv and getgenv().ChestEspURL then
        url = getgenv().ChestEspURL
    end
    if (not url or url == "") and _G.ChestEspURL then
        url = _G.ChestEspURL
    end
    if (not url or url == "") and isfile and isfile("BF_ChestURL.txt") then
        pcall(function() url = readfile("BF_ChestURL.txt") end)
    end
    if not url or url == "" then
        url = CONFIG.GitHubRawURL
    end

    teleportQueued = true
    pcall(function()
        if writefile then writefile("BF_ChestURL.txt", url) end
    end)

    local payload = string.format('if getgenv then getgenv().ChestEspURL=[=[%s]=] end task.spawn(function() repeat task.wait(0.5) until game:IsLoaded(); task.wait(2.5); pcall(function() loadstring(game:HttpGet("%s"))() end) end)', url, url)
    pcall(queueFunc, payload)
end

pcall(setupAutoRestart)

pcall(function()
    if getconnections then
        for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
            pcall(function() conn:Disable() end)
        end
    end
end)

LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        task.wait(0.2)
        VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    end)
end)

local function getGuiParent()
    if gethui then
        local s, h = pcall(gethui)
        if s and h then return h end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

pcall(function()
    local old = getGuiParent():FindFirstChild("VipChestEsp")
    if old then old:Destroy() end
end)

local ScreenGui
local ValAction
local ValChestCount
local ValNearest
local ValKeyMap
local ValKeyStatus
local ValCollected
local ValTarget
local ValUptime
local ValPlayers
local ValHopStatus
local ValHunted
local HopOldBtn
local HopRandBtn
local HopLowBtn
local RejoinBtn
local Fps30Btn
local Fps60Btn
local FpsBoostBtn

do
ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VipChestEsp"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = getGuiParent()
if getgenv then getgenv().ChestEspGui = ScreenGui end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 460, 0, 310)
MainFrame.Position = UDim2.new(0.08, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 28)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local AnimeBg = Instance.new("ImageLabel")
AnimeBg.Name = "AnimeBg"
AnimeBg.Size = UDim2.new(1, 0, 1, 0)
AnimeBg.Position = UDim2.new(0, 0, 0, 0)
AnimeBg.BackgroundTransparency = 1
AnimeBg.Image = MenuBgAsset
AnimeBg.ScaleType = Enum.ScaleType.Crop
AnimeBg.ZIndex = 1
AnimeBg.Parent = MainFrame

local ElectricLayer = Instance.new("Frame")
ElectricLayer.Name = "ElectricLayer"
ElectricLayer.Size = UDim2.new(1, 0, 1, 0)
ElectricLayer.BackgroundTransparency = 1
ElectricLayer.ClipsDescendants = true
ElectricLayer.ZIndex = 2
ElectricLayer.Parent = MainFrame

local ScanBeam = Instance.new("Frame")
ScanBeam.Name = "ScanBeam"
ScanBeam.Size = UDim2.new(1.2, 0, 0, 3)
ScanBeam.Position = UDim2.new(-0.1, 0, 0, -10)
ScanBeam.BackgroundColor3 = Color3.fromRGB(0, 240, 255)
ScanBeam.BackgroundTransparency = 0.4
ScanBeam.BorderSizePixel = 0
ScanBeam.ZIndex = 2
ScanBeam.Parent = ElectricLayer

local ScanBeamGrad = Instance.new("UIGradient")
ScanBeamGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(0, 240, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 0, 160)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(0, 240, 255))
})
ScanBeamGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0.0, 1),
    NumberSequenceKeypoint.new(0.2, 0.2),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(0.8, 0.2),
    NumberSequenceKeypoint.new(1.0, 1)
})
ScanBeamGrad.Parent = ScanBeam

task.spawn(function()
    while scriptActive and ScreenGui and ScreenGui.Parent and ScanBeam and ScanBeam.Parent do
        ScanBeam.Position = UDim2.new(-0.1, 0, 0, -10)
        local tw = TweenService:Create(ScanBeam, TweenInfo.new(3.8, Enum.EasingStyle.Linear), {Position = UDim2.new(-0.1, 0, 1, 10)})
        tw:Play()
        tw.Completed:Wait()
        task.wait(0.8)
    end
end)

local electricColors = {
    Color3.fromRGB(0, 240, 255),
    Color3.fromRGB(157, 78, 221),
    Color3.fromRGB(0, 255, 170)
}

local activeBolts = {}
for idx = 1, 3 do
    local bolt = Instance.new("Frame")
    bolt.Name = "ElectricBolt_" .. idx
    bolt.Size = UDim2.new(0, math.random(60, 110), 0, 2)
    bolt.Position = UDim2.new(math.random(5, 85) / 100, 0, math.random(10, 80) / 100, 0)
    bolt.BackgroundColor3 = electricColors[((idx - 1) % #electricColors) + 1]
    bolt.BackgroundTransparency = 0.3
    bolt.BorderSizePixel = 0
    bolt.Rotation = math.random(-40, 40)
    bolt.ZIndex = 2
    bolt.Parent = ElectricLayer

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(1, 0)
    bCorner.Parent = bolt

    table.insert(activeBolts, {
        Bolt = bolt,
        SpeedX = (math.random() > 0.5 and 1 or -1) * math.random(15, 30) / 1000,
        SpeedY = (math.random() > 0.5 and 1 or -1) * math.random(10, 20) / 1000
    })
end

task.spawn(function()
    while scriptActive and ScreenGui and ScreenGui.Parent do
        for _, bData in ipairs(activeBolts) do
            local bolt = bData.Bolt
            if bolt and bolt.Parent then
                local cur = bolt.Position
                local nx = (cur.X.Scale + bData.SpeedX) % 1.1 - 0.08
                local ny = (cur.Y.Scale + bData.SpeedY) % 1.05 - 0.05
                bolt.Position = UDim2.new(nx, 0, ny, 0)
                if math.random(1, 5) == 1 then
                    bolt.BackgroundTransparency = math.random(10, 45) / 100
                    bolt.Rotation = bolt.Rotation + math.random(-6, 6)
                else
                    bolt.BackgroundTransparency = math.random(30, 70) / 100
                end
            end
        end
        task.wait(0.08)
    end
end)

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 2
MainStroke.Color = Color3.fromRGB(0, 240, 255)
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

local StrokeGradient = Instance.new("UIGradient")
StrokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(0, 240, 255)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(157, 78, 221)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 0, 128)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0, 255, 163)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(0, 240, 255))
})
StrokeGradient.Rotation = 45
StrokeGradient.Parent = MainStroke

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 42)
TopBar.BackgroundColor3 = Color3.fromRGB(12, 15, 26)
TopBar.BackgroundTransparency = 0.3
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 3
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 14)
TopCorner.Parent = TopBar

local CrownTitle = Instance.new("TextLabel")
CrownTitle.Name = "CrownTitle"
CrownTitle.Size = UDim2.new(0, 265, 1, 0)
CrownTitle.Position = UDim2.new(0, 14, 0, 0)
CrownTitle.BackgroundTransparency = 1
CrownTitle.Text = "[ CHEST ESP💰 MAKE BY nd.⚡]"
CrownTitle.TextColor3 = Color3.fromRGB(0, 240, 255)
CrownTitle.TextSize = 13
CrownTitle.Font = Enum.Font.GothamBold
CrownTitle.TextXAlignment = Enum.TextXAlignment.Left
CrownTitle.ZIndex = 4
CrownTitle.Parent = TopBar

local TitleGrad = Instance.new("UIGradient")
TitleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(0, 240, 255)),
    ColorSequenceKeypoint.new(0.35, Color3.fromRGB(255, 240, 120)),
    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 0, 160)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(0, 255, 170))
})
TitleGrad.Parent = CrownTitle

local VipBadge = Instance.new("TextLabel")
VipBadge.Name = "VipBadge"
VipBadge.Size = UDim2.new(0, 110, 0, 20)
VipBadge.Position = UDim2.new(1, -154, 0, 11)
VipBadge.BackgroundColor3 = Color3.fromRGB(18, 22, 45)
VipBadge.BackgroundTransparency = 0.2
VipBadge.Text = "★ CHEST EDITION ★"
VipBadge.TextColor3 = Color3.fromRGB(255, 205, 60)
VipBadge.TextSize = 9
VipBadge.Font = Enum.Font.GothamBold
VipBadge.ZIndex = 4
VipBadge.Parent = TopBar

local BadgeCorner = Instance.new("UICorner")
BadgeCorner.CornerRadius = UDim.new(0, 6)
BadgeCorner.Parent = VipBadge

local BadgeStroke = Instance.new("UIStroke")
BadgeStroke.Thickness = 1
BadgeStroke.Color = Color3.fromRGB(255, 205, 60)
BadgeStroke.Parent = VipBadge

local MinBtn = Instance.new("TextButton")
MinBtn.Name = "MinBtn"
MinBtn.Size = UDim2.new(0, 26, 0, 26)
MinBtn.Position = UDim2.new(1, -34, 0, 8)
MinBtn.BackgroundColor3 = Color3.fromRGB(20, 25, 48)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(0, 240, 255)
MinBtn.TextSize = 15
MinBtn.Font = Enum.Font.GothamBold
MinBtn.ZIndex = 4
MinBtn.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = MinBtn

local MinStroke = Instance.new("UIStroke")
MinStroke.Thickness = 1
MinStroke.Color = Color3.fromRGB(0, 240, 255)
MinStroke.Parent = MinBtn

local FloatingBtn = Instance.new("ImageButton")
FloatingBtn.Name = "FloatingGojoBtn"
FloatingBtn.Size = UDim2.new(0, 58, 0, 58)
FloatingBtn.Position = UDim2.new(0.03, 0, 0.18, 0)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 30)
FloatingBtn.Image = GojoIconAsset
FloatingBtn.ScaleType = Enum.ScaleType.Crop
FloatingBtn.Visible = false
FloatingBtn.ClipsDescendants = true
FloatingBtn.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(0, 14)
FloatCorner.Parent = FloatingBtn

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Thickness = 2
FloatStroke.Color = Color3.fromRGB(0, 240, 255)
FloatStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
FloatStroke.Parent = FloatingBtn

local FloatStrokeGrad = Instance.new("UIGradient")
FloatStrokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(0, 240, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 240, 120)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 0, 128))
})
FloatStrokeGrad.Parent = FloatStroke

task.spawn(function()
    while scriptActive and FloatingBtn and FloatingBtn.Parent do
        for hue = 0, 360, 10 do
            if not (scriptActive and FloatingBtn and FloatingBtn.Parent) then break end
            FloatStroke.Color = Color3.fromHSV(hue / 360, 0.85, 1)
            task.wait(0.12)
        end
    end
end)

local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -16, 0, 36)
TabBar.Position = UDim2.new(0, 8, 0, 48)
TabBar.BackgroundColor3 = Color3.fromRGB(12, 15, 26)
TabBar.BackgroundTransparency = 0.45
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 4
TabBar.Parent = MainFrame

local TabBarCorner = Instance.new("UICorner")
TabBarCorner.CornerRadius = UDim.new(0, 10)
TabBarCorner.Parent = TabBar

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Padding = UDim.new(0, 6)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabBar

local function createTabBtn(text, order)
    local btn = Instance.new("TextButton")
    btn.Name = "Tab_" .. text
    btn.Size = UDim2.new(0, 100, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(20, 25, 48)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(190, 220, 255)
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.LayoutOrder = order
    btn.ZIndex = 5
    btn.Parent = TabBar
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn
    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Color = Color3.fromRGB(35, 45, 80)
    s.Parent = btn
    return btn, s
end

local TabBtnEsp, StrokeEsp = createTabBtn("📡 ESP", 1)
local TabBtnFarm, StrokeFarm = createTabBtn("🤏 THU", 2)
local TabBtnHop, StrokeHop = createTabBtn("🌐 SERVER", 3)
local TabBtnSys, StrokeSys = createTabBtn("⚙️ HỆ THỐNG", 4)

local MainContent = Instance.new("Frame")
MainContent.Name = "MainContent"
MainContent.Size = UDim2.new(1, -16, 1, -128)
MainContent.Position = UDim2.new(0, 8, 0, 90)
MainContent.BackgroundColor3 = Color3.fromRGB(10, 13, 24)
MainContent.BackgroundTransparency = 0.5
MainContent.BorderSizePixel = 0
MainContent.ZIndex = 3
MainContent.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 10)
ContentCorner.Parent = MainContent

local function createScrollPg(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.new(1, -16, 1, -16)
    page.Position = UDim2.new(0, 8, 0, 8)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(0, 240, 255)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ZIndex = 4
    page.Parent = MainContent
    local lo = Instance.new("UIListLayout")
    lo.Padding = UDim.new(0, 6)
    lo.SortOrder = Enum.SortOrder.LayoutOrder
    lo.Parent = page
    return page
end

local function mkRow(parent, order)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -4, 0, 34)
    f.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
    f.BackgroundTransparency = 0.25
    f.BorderSizePixel = 0
    f.LayoutOrder = order
    f.ZIndex = 4
    f.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = f
    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Color = Color3.fromRGB(28, 48, 85)
    s.Parent = f
    return f
end

local function mkToggle(parent, order, text, getState, setState)
    local f = mkRow(parent, order)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.62, 0, 1, 0)
    l.Position = UDim2.new(0, 8, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(220, 230, 255)
    l.TextSize = 11
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 5
    l.Parent = f
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 62, 0, 24)
    b.Position = UDim2.new(1, -70, 0.5, -12)
    b.BackgroundColor3 = getState() and Color3.fromRGB(0, 170, 90) or Color3.fromRGB(45, 30, 60)
    b.Text = getState() and "BẬT" or "TẮT"
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 10
    b.Font = Enum.Font.GothamBold
    b.ZIndex = 5
    b.Parent = f
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = b
    b.MouseButton1Click:Connect(function()
        setState(not getState())
        b.BackgroundColor3 = getState() and Color3.fromRGB(0, 170, 90) or Color3.fromRGB(45, 30, 60)
        b.Text = getState() and "BẬT" or "TẮT"
    end)
    return b
end

local function mkButton(parent, order, text, accent)
    local f = mkRow(parent, order)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -16, 0, 24)
    b.Position = UDim2.new(0, 8, 0.5, -12)
    b.BackgroundColor3 = accent or Color3.fromRGB(28, 36, 68)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.ZIndex = 5
    b.Parent = f
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = b
    return b
end

local function mkInfo(parent, order, label, defaultVal)
    local f = mkRow(parent, order)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(0.44, 0, 1, 0)
    t.Position = UDim2.new(0, 8, 0, 0)
    t.BackgroundTransparency = 1
    t.Text = label
    t.TextColor3 = Color3.fromRGB(160, 190, 240)
    t.TextSize = 11
    t.Font = Enum.Font.GothamMedium
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.ZIndex = 5
    t.Parent = f
    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(0.56, -12, 1, 0)
    v.Position = UDim2.new(0.44, 0, 0, 0)
    v.BackgroundTransparency = 1
    v.Text = defaultVal
    v.TextColor3 = Color3.fromRGB(0, 240, 255)
    v.TextSize = 11
    v.Font = Enum.Font.GothamBold
    v.TextXAlignment = Enum.TextXAlignment.Left
    v.ZIndex = 5
    v.Parent = f
    return v
end

local function mkCycle(parent, order, label, options, startIdx, onChange)
    local idx = startIdx
    local f = mkRow(parent, order)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.44, 0, 1, 0)
    l.Position = UDim2.new(0, 8, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = label
    l.TextColor3 = Color3.fromRGB(220, 230, 255)
    l.TextSize = 11
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 5
    l.Parent = f
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.52, 0, 0, 24)
    b.Position = UDim2.new(0.46, 0, 0.5, -12)
    b.BackgroundColor3 = Color3.fromRGB(28, 36, 68)
    b.Text = options[idx]
    b.TextColor3 = Color3.fromRGB(0, 240, 255)
    b.TextSize = 9
    b.Font = Enum.Font.GothamBold
    b.ZIndex = 5
    b.Parent = f
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = b
    b.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        b.Text = options[idx]
        onChange(idx, options[idx])
    end)
    onChange(idx, options[idx])
    return b
end

local PageEsp = createScrollPg("PageEsp")
local PageFarm = createScrollPg("PageFarm")
local PageHop = createScrollPg("PageHop")
local PageSys = createScrollPg("PageSys")

mkToggle(PageEsp, 1, "📡 ESP Rương (Tổng)", function() return STATE.EspOn end, function(v) STATE.EspOn = v end)
mkToggle(PageEsp, 2, "💰 Rương Bạc (Chest1)", function() return STATE.EspT1 end, function(v) STATE.EspT1 = v end)
mkToggle(PageEsp, 3, "👑 Rương Vàng (Chest2)", function() return STATE.EspT2 end, function(v) STATE.EspT2 = v end)
mkToggle(PageEsp, 4, "💎 Rương Xanh (Chest3)", function() return STATE.EspT3 end, function(v) STATE.EspT3 = v end)
ValChestCount = mkInfo(PageEsp, 5, "🧭 Rương phát hiện:", "0")
ValNearest = mkInfo(PageEsp, 6, "📏 Rương gần nhất:", "---")
ValKeyMap = mkInfo(PageEsp, 7, "🗝️ Key Râu Đen trên map:", "0")

mkToggle(PageFarm, 1, "🤏 Auto Thu Rương (Bay Tới Nhặt)", function() return STATE.AutoCollect end, function(v)
    STATE.AutoCollect = v
    if not v then
        STATE.KillTween = true
        if STATE.CurrentTween then
            pcall(function() STATE.CurrentTween:Cancel() end)
        end
    end
end)
mkToggle(PageFarm, 2, "⏭️ Bỏ Qua Rương Bạc", function() return STATE.SkipSilver end, function(v) STATE.SkipSilver = v end)
mkToggle(PageFarm, 3, "🚪 Xuyên Tường Khi Thu (NoClip)", function() return STATE.NoclipOn end, function(v) STATE.NoclipOn = v end)
mkCycle(PageFarm, 4, "🚀 Tốc Độ Bay:", {"200", "250", "300"}, 2, function(i, v)
    CONFIG.CollectSpeed = tonumber(v)
end)
mkToggle(PageFarm, 5, "🛑 Dừng Khi Có Key Râu Đen", function() return STATE.StopOnKey end, function(v) STATE.StopOnKey = v end)
mkToggle(PageFarm, 6, "🌐 Tự Hop Server Khi Hết Rương", function() return STATE.AutoHopEmpty end, function(v) STATE.AutoHopEmpty = v end)
ValKeyStatus = mkInfo(PageFarm, 7, "🗝️ Key Râu Đen:", "Chưa có ❌")
ValCollected = mkInfo(PageFarm, 8, "📦 Đã thu server này:", "0 rương")
ValTarget = mkInfo(PageFarm, 9, "🎯 Đang tới:", "---")
mkToggle(PageFarm, 10, "🗝️ Tự Bay Nhặt Key Râu Đen (Ưu Tiên #1)", function() return STATE.AutoGrabKey end, function(v) STATE.AutoGrabKey = v end)

ValUptime = mkInfo(PageHop, 1, "⏱️ Tuổi server này:", "...")
ValPlayers = mkInfo(PageHop, 2, "👥 Người chơi:", "...")
mkCycle(PageHop, 3, "👤 Chỉ hop server ≤:", {"2 người", "4 người", "6 người"}, 1, function(i, v)
    if i == 1 then STATE.HopMaxPlayers = 2 elseif i == 2 then STATE.HopMaxPlayers = 4 else STATE.HopMaxPlayers = 6 end
end)
HopOldBtn = mkButton(PageHop, 4, "🕰️ HOP SERVER CŨ NHẤT (Treo 3-4h+)", Color3.fromRGB(120, 80, 20))
HopRandBtn = mkButton(PageHop, 5, "🎲 Hop Server Cũ Ngẫu Nhiên", Color3.fromRGB(30, 90, 60))
HopLowBtn = mkButton(PageHop, 6, "🌐 Hop Server Ít Người Nhất", Color3.fromRGB(24, 60, 90))
ValHopStatus = mkInfo(PageHop, 7, "📊 Trạng thái:", "Sẵn sàng")
mkToggle(PageHop, 8, "🎯 SĂN KEY 100% (Hop Tới Khi Gặp Key)", function() return STATE.HuntKeyMode end, function(v)
    STATE.HuntKeyMode = v
    if v then
        STATE.HuntedServers = 0
        pcall(function()
            if ValHunted and ValHunted.Parent then
                ValHunted.Text = "0 server"
            end
        end)
        setStatus("🎯 Săn Key 100% BẬT - sẽ hop tới khi gặp server có key!")
    end
end)
mkToggle(PageHop, 9, "💰 Mở Hết Rương Trước Khi Hop", function() return STATE.HuntLootFirst end, function(v) STATE.HuntLootFirst = v end)
ValHunted = mkInfo(PageHop, 10, "🔎 Đã dò săn:", "0 server")

mkInfo(PageSys, 1, "🆔 Server ID:", string.sub(JobId, 1, 8) .. "...")
ValAction = mkInfo(PageSys, 2, "📍 Trạng thái:", "Sẵn sàng 💰")
mkInfo(PageSys, 3, "💡 Mẹo:", "Bật Auto Thu + Tự Hop = AFK cả ngày")
FpsBoostBtn = mkButton(PageSys, 4, "🚀 FPS Boost (Dọn Đồ Họa)", Color3.fromRGB(0, 130, 160))
Fps30Btn = mkButton(PageSys, 5, "📉 FPS 30 (Mượt - Pin Lâu)", Color3.fromRGB(50, 80, 40))
Fps60Btn = mkButton(PageSys, 6, "📈 FPS 60 (Chất Lượng Cao)", Color3.fromRGB(50, 80, 40))
RejoinBtn = mkButton(PageSys, 7, "🔄 Vào Lại Server (Rejoin)", Color3.fromRGB(90, 70, 25))

local function switchTab(tabName)
    local pages = {Esp = PageEsp, Farm = PageFarm, Hop = PageHop, Sys = PageSys}
    local strokes = {Esp = StrokeEsp, Farm = StrokeFarm, Hop = StrokeHop, Sys = StrokeSys}
    for k, pg in pairs(pages) do
        pg.Visible = (k == tabName)
    end
    for k, st in pairs(strokes) do
        st.Color = (k == tabName) and Color3.fromRGB(0, 240, 255) or Color3.fromRGB(35, 45, 80)
    end
end

TabBtnEsp.MouseButton1Click:Connect(function() switchTab("Esp") end)
TabBtnFarm.MouseButton1Click:Connect(function() switchTab("Farm") end)
TabBtnHop.MouseButton1Click:Connect(function() switchTab("Hop") end)
TabBtnSys.MouseButton1Click:Connect(function() switchTab("Sys") end)
switchTab("Esp")

local function makeDraggable(targetFrame, dragHandle)
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            hasMoved = false
            dragStart = input.Position
            startPos = targetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 6 then
                hasMoved = true
            end
            targetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    return function() return hasMoved end
end

makeDraggable(MainFrame, TopBar)
local getFloatMoved = makeDraggable(FloatingBtn, FloatingBtn)

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatingBtn.Visible = true
end)

FloatingBtn.MouseButton1Click:Connect(function()
    if getFloatMoved and getFloatMoved() then return end
    FloatingBtn.Visible = false
    MainFrame.Visible = true
end)

end

local function setStatus(text)
    STATE.CurrentStatus = text
    pcall(function()
        if ValAction and ValAction.Parent then
            ValAction.Text = text
        end
    end)
end

local function getCharacter()
    local char = LocalPlayer.Character
    if not char or not char.Parent then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return nil end
    return char, hrp, hum
end

local function clearEspEntry(part)
    local data = ChestMap[part]
    if data then
        pcall(function()
            if data.Gui and data.Gui.Parent then data.Gui:Destroy() end
        end)
        ChestMap[part] = nil
    end
end

local function addEspForPart(part)
    if ChestMap[part] then return end
    local tier = NAME_TO_TIER[part.Name]
    if not tier then return end
    if not part:IsA("BasePart") then return end

    local info = TIER_INFO[tier]
    local bb = Instance.new("BillboardGui")
    bb.Name = "ChestEspBB"
    bb.Size = UDim2.new(0, 150, 0, 36)
    bb.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = math.huge
    bb.Parent = part

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundColor3 = Color3.fromRGB(10, 12, 22)
    lbl.BackgroundTransparency = 0.45
    lbl.Text = info.Label .. "\n[? m]"
    lbl.TextColor3 = info.Color
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = bb

    local lc = Instance.new("UICorner")
    lc.CornerRadius = UDim.new(0, 6)
    lc.Parent = lbl

    local ls = Instance.new("UIStroke")
    ls.Thickness = 1
    ls.Color = info.Color
    ls.Parent = lbl

    ChestMap[part] = {Gui = bb, Label = lbl, Tier = tier}
    part.AncestryChanged:Connect(function(_, parent)
        if not parent then
            clearEspEntry(part)
        end
    end)
end

local function rescanChests()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if NAME_TO_TIER[v.Name] and v:IsA("BasePart") then
            pcall(addEspForPart, v)
        end
    end
    for part, _ in pairs(ChestMap) do
        if not part or not part.Parent then
            clearEspEntry(part)
        end
    end
end

local function getFistRoot(inst)
    if not inst or not inst.Parent then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Tool") then
        return inst:FindFirstChild("Handle")
    end
    if inst:IsA("Model") then
        return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function clearFistEntry(root)
    local data = FistMap[root]
    if data then
        pcall(function()
            if data.Gui and data.Gui.Parent then data.Gui:Destroy() end
        end)
        FistMap[root] = nil
    end
end

local function addEspForFist(inst)
    local root = getFistRoot(inst)
    if not root or FistMap[root] then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "FistEspBB"
    bb.Size = UDim2.new(0, 190, 0, 46)
    bb.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = math.huge
    bb.Parent = root

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundColor3 = Color3.fromRGB(30, 0, 5)
    lbl.BackgroundTransparency = 0.3
    lbl.Text = "🗝️ KEY RÂU ĐEN\n[? m]"
    lbl.TextColor3 = KEY_RED
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = bb

    local lc = Instance.new("UICorner")
    lc.CornerRadius = UDim.new(0, 8)
    lc.Parent = lbl

    local ls = Instance.new("UIStroke")
    ls.Thickness = 2
    ls.Color = KEY_RED
    ls.Parent = lbl

    FistMap[root] = {Gui = bb, Label = lbl, Src = inst}
    inst.AncestryChanged:Connect(function(_, parent)
        if not parent then
            clearFistEntry(root)
        end
    end)
    setStatus("🗝️ PHÁT HIỆN KEY RÂU ĐEN TRÊN MAP!")
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "CHEST ESP 🗝️",
            Text = "Key Râu Đen (Fist of Darkness) vừa spawn trên map! Màu ĐỎ!",
            Duration = 8
        })
    end)
end

local function rescanFists()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if isFistName(v.Name) and (v:IsA("Tool") or v:IsA("Model") or v:IsA("BasePart")) then
            pcall(addEspForFist, v)
        end
    end
    for root, _ in pairs(FistMap) do
        if not root or not root.Parent then
            clearFistEntry(root)
        end
    end
end

local function countFists()
    local n = 0
    for root, _ in pairs(FistMap) do
        if root and root.Parent then n = n + 1 end
    end
    return n
end

Workspace.DescendantAdded:Connect(function(v)
    if NAME_TO_TIER[v.Name] and v:IsA("BasePart") then
        task.defer(function()
            pcall(addEspForPart, v)
        end)
    elseif isFistName(v.Name) and (v:IsA("Tool") or v:IsA("Model") or v:IsA("BasePart")) then
        task.defer(function()
            pcall(addEspForFist, v)
        end)
    end
end)

local espAcc = 0
RunService.Heartbeat:Connect(function(dt)
    espAcc = espAcc + dt
    if espAcc < 0.3 then return end
    espAcc = 0
    local char, hrp = getCharacter()
    local count = 0
    local nearest = math.huge
    for part, data in pairs(ChestMap) do
        if part and part.Parent and data.Gui and data.Gui.Parent then
            local enabled = STATE.EspOn and STATE["EspT" .. data.Tier]
            data.Gui.Enabled = enabled
            if enabled and hrp then
                count = count + 1
                local d = (part.Position - hrp.Position).Magnitude
                data.Label.Text = TIER_INFO[data.Tier].Label .. "\n[" .. tostring(math.floor(d + 0.5)) .. " m]"
                if d < nearest then nearest = d end
            end
        else
            clearEspEntry(part)
        end
    end
    STATE.ChestCount = count
    STATE.NearestDist = nearest
    local fistCount = 0
    for root, data in pairs(FistMap) do
        if root and root.Parent and data.Gui and data.Gui.Parent then
            fistCount = fistCount + 1
            if hrp then
                local d = (root.Position - hrp.Position).Magnitude
                data.Label.Text = "🗝️ KEY RÂU ĐEN\n[" .. tostring(math.floor(d + 0.5)) .. " m]"
            end
        else
            clearFistEntry(root)
        end
    end
    pcall(function()
        if ValChestCount and ValChestCount.Parent then
            ValChestCount.Text = tostring(count) .. " rương"
        end
        if ValNearest and ValNearest.Parent then
            ValNearest.Text = (nearest < math.huge) and (tostring(math.floor(nearest + 0.5)) .. " m") or "---"
        end
        if ValKeyMap and ValKeyMap.Parent then
            ValKeyMap.Text = tostring(fistCount) .. (fistCount > 0 and " 🔴" or "")
        end
    end)
end)

local function hasFistOfDarkness()
    local function checkTools(container)
        if not container then return false end
        for _, v in ipairs(container:GetChildren()) do
            if v:IsA("Tool") and v.Name == "Fist of Darkness" then
                return true
            end
        end
        return false
    end
    if checkTools(LocalPlayer:FindFirstChild("Backpack")) then return true end
    if checkTools(LocalPlayer.Character) then return true end
    local data = LocalPlayer:FindFirstChild("Data")
    if data then
        local inv = data:FindFirstChild("Inventory")
        if inv then
            for _, v in ipairs(inv:GetChildren()) do
                if v.Name == "Fist of Darkness" then
                    return true
                end
            end
        end
    end
    return false
end

local function onKeyDetected()
    STATE.KeyFound = true
    setStatus("🗝️ ĐÃ CÓ KEY RÂU ĐEN!")
    pcall(function()
        if ValKeyStatus and ValKeyStatus.Parent then
            ValKeyStatus.Text = "✅ ĐÃ CÓ RỒI!"
            ValKeyStatus.TextColor3 = Color3.fromRGB(0, 255, 140)
        end
    end)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "CHEST ESP 💰",
            Text = "🗝️ Đã nhặt được Fist of Darkness (Key Râu Đen)!",
            Duration = 8
        })
    end)
    if STATE.StopOnKey then
        STATE.AutoCollect = false
        STATE.KillTween = true
        if STATE.CurrentTween then
            pcall(function() STATE.CurrentTween:Cancel() end)
        end
    end
end

pcall(function()
    LocalPlayer:FindFirstChild("Backpack").ChildAdded:Connect(function(v)
        if v.Name == "Fist of Darkness" and not STATE.KeyFound then
            onKeyDetected()
        end
    end)
end)

task.spawn(function()
    while scriptActive do
        if not STATE.KeyFound and hasFistOfDarkness() then
            onKeyDetected()
        end
        task.wait(4)
    end
end)

RunService.Stepped:Connect(function()
    if (STATE.AutoCollect or STATE.HuntKeyMode) and STATE.NoclipOn then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end
        local _, hrp = getCharacter()
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
    end
end)

local function tweenToChest(part)
    local char, hrp, hum = getCharacter()
    if not hrp then return false end
    if not part or not part.Parent then return false end
    local targetPos = part.Position + Vector3.new(0, 2, 0)
    local dist = (hrp.Position - targetPos).Magnitude
    local duration = math.max(dist / CONFIG.CollectSpeed, 0.12)
    local tw = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
    STATE.KillTween = false
    STATE.CurrentTween = tw
    tw:Play()
    local completed = false
    task.spawn(function()
        tw.Completed:Connect(function() completed = true end)
    end)
    local t0 = os.clock()
    local maxWait = duration + 2.5
    while os.clock() - t0 < maxWait do
        if STATE.KillTween then
            pcall(function() tw:Cancel() end)
            STATE.CurrentTween = nil
            return false
        end
        if not part.Parent then
            pcall(function() tw:Cancel() end)
            STATE.CurrentTween = nil
            return true
        end
        if completed then break end
        task.wait(0.1)
    end
    STATE.CurrentTween = nil
    return true
end

local function getSortedChests()
    local char, hrp = getCharacter()
    if not hrp then return {} end
    local list = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if NAME_TO_TIER[v.Name] and v:IsA("BasePart") and not STATE.IgnoredChests[v] then
            if not (STATE.SkipSilver and NAME_TO_TIER[v.Name] == 1) then
                table.insert(list, {Part = v, Dist = (v.Position - hrp.Position).Magnitude, Tier = NAME_TO_TIER[v.Name]})
            end
        end
    end
    table.sort(list, function(a, b) return a.Dist < b.Dist end)
    return list
end

local function fmtUptime(seconds)
    local s = math.floor(seconds)
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    if h > 0 then
        return tostring(h) .. " giờ " .. tostring(m) .. " phút"
    end
    return tostring(m) .. " phút " .. tostring(s % 60) .. " giây"
end

local function refreshServerInfo()
    pcall(function()
        if ValUptime and ValUptime.Parent then
            ValUptime.Text = fmtUptime(Workspace.DistributedGameTime)
        end
        if ValPlayers and ValPlayers.Parent then
            ValPlayers.Text = tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers) .. " người"
        end
    end)
end

task.spawn(function()
    while scriptActive do
        refreshServerInfo()
        task.wait(5)
    end
end)

local function fetchOldServers()
    local cands = {}
    local cursor = ""
    for page = 1, CONFIG.HopScanPages do
        local url = "https://games.roblox.com/v1/games/" .. tostring(PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then
            url = url .. "&cursor=" .. cursor
        end
        local ok, res = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if ok and res and res.data then
            for _, s in ipairs(res.data) do
                if s.id and s.id ~= JobId and s.playing and s.maxPlayers
                    and s.playing > 0
                    and s.playing < s.maxPlayers
                    and s.playing <= STATE.HopMaxPlayers
                    and not VisitedServers[s.id] then
                    table.insert(cands, {Id = s.id, Playing = s.playing})
                end
            end
            cursor = res.nextPageCursor or ""
            if cursor == "" then break end
        else
            break
        end
        task.wait(0.25)
    end
    return cands
end

local function teleportTo(id)
    STATE.IsHopping = true
    STATE.LastTryId = id
    VisitedServers[id] = true
    VisitedServers[JobId] = true
    pcall(setupAutoRestart)
    pcall(function()
        TeleportService:TeleportToPlaceInstance(PlaceId, id, LocalPlayer)
    end)
    task.wait(4)
    STATE.IsHopping = false
    STATE.LastTryId = nil
end

local function hopServer(mode, statusLabel)
    if STATE.IsHopping then return end
    STATE.LastHopMode = mode
    STATE.RetryHop = true
    statusLabel = statusLabel or "Đang quét server cũ (lâu ngày)..."
    setStatus(statusLabel)
    pcall(function()
        if ValHopStatus and ValHopStatus.Parent then
            ValHopStatus.Text = "Đang quét danh sách..."
        end
    end)
    local cands = fetchOldServers()
    if #cands == 0 then
        pcall(function()
            if ValHopStatus and ValHopStatus.Parent then
                ValHopStatus.Text = "Không thấy server phù hợp, thử nới tiêu chuẩn..."
            end
        end)
        local oldMax = STATE.HopMaxPlayers
        STATE.HopMaxPlayers = 11
        cands = fetchOldServers()
        STATE.HopMaxPlayers = oldMax
    end
    if #cands == 0 then
        setStatus("❌ Không tìm được server nào!")
        pcall(function()
            if ValHopStatus and ValHopStatus.Parent then
                ValHopStatus.Text = "Thất bại - thử lại sau"
            end
        end)
        return
    end
    local pick
    if mode == "low" then
        table.sort(cands, function(a, b) return a.Playing < b.Playing end)
        pick = cands[1]
    elseif mode == "random" then
        local upper = math.min(#cands, 20)
        pick = cands[math.random(1, upper)]
    else
        local upperOld = math.min(#cands, 10)
        pick = cands[math.random(1, upperOld)]
    end
    pcall(function()
        if ValHopStatus and ValHopStatus.Parent then
            ValHopStatus.Text = "Hop vào server " .. tostring(pick.Playing) .. " người..."
        end
    end)
    setStatus("🌐 Đang hop server...")
    teleportTo(pick.Id)
end

HopOldBtn.MouseButton1Click:Connect(function()
    task.spawn(function()
        hopServer("oldest", "⏳ Tìm server cũ nhất (ưu tiên treo lâu 3-4h+)...")
    end)
end)

HopRandBtn.MouseButton1Click:Connect(function()
    task.spawn(function()
        hopServer("random", "🎲 Chọn ngẫu nhiên trong các server cũ...")
    end)
end)

HopLowBtn.MouseButton1Click:Connect(function()
    task.spawn(function()
        hopServer("low", "🌐 Tìm server ít người nhất...")
    end)
end)

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    local wasOurHop = (STATE.LastTryId ~= nil)
    pcall(function()
        if STATE.LastTryId then
            VisitedServers[STATE.LastTryId] = true
            STATE.LastTryId = nil
        end
    end)
    STATE.IsHopping = false
    if not wasOurHop then return end
    setStatus("⚠️ Server chết/bị chặn (773) - tự đổi server khác...")
    pcall(function()
        if ValHopStatus and ValHopStatus.Parent then
            ValHopStatus.Text = "Server lỗi 773 - đang thử cái khác..."
        end
    end)
    if STATE.RetryHop then
        task.delay(2, function()
            if STATE.RetryHop and not STATE.IsHopping then
                hopServer(STATE.LastHopMode or "oldest", "🔄 Thử server kế tiếp...")
            end
        end)
    end
end)

RejoinBtn.MouseButton1Click:Connect(function()
    pcall(setupAutoRestart)
    setStatus("🔄 Đang vào lại server...")
    pcall(function()
        TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
    end)
end)

local function applyFpsCap(num)
    pcall(function()
        if setfpscap then
            setfpscap(num)
        end
    end)
    setStatus("📊 Đã đặt FPS " .. tostring(num))
end

Fps30Btn.MouseButton1Click:Connect(function() applyFpsCap(30) end)
Fps60Btn.MouseButton1Click:Connect(function() applyFpsCap(60) end)

FpsBoostBtn.MouseButton1Click:Connect(function()
    setStatus("🚀 Đang dọn đồ họa...")
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
                v.Enabled = false
            end
        end
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
                v.Enabled = false
            end
        end
    end)
    applyFpsCap(60)
    setStatus("🚀 FPS Boost hoàn tất!")
end)

task.spawn(function()
    task.wait(1)
    rescanChests()
    rescanFists()
    setStatus("📡 ESP sẵn sàng - " .. tostring(STATE.ChestCount) .. " rương")
    while scriptActive do
        task.wait(CONFIG.ScanInterval)
        rescanChests()
        rescanFists()
    end
end)

task.spawn(function()
    while scriptActive do
        task.wait(0.5)
        if not STATE.AutoCollect and not STATE.HuntKeyMode then
            STATE.KillTween = true
            if STATE.CurrentTween then
                pcall(function() STATE.CurrentTween:Cancel() end)
                STATE.CurrentTween = nil
            end
        else
            if STATE.StopOnKey and hasFistOfDarkness() then
                onKeyDetected()
                task.wait(3)
            else
                local char, hrp = getCharacter()
                if not char then
                    setStatus("⏳ Đợi hồi sinh nhân vật...")
                    task.wait(2)
                elseif STATE.GrabbingKey then
                    setStatus("🗝️ Ưu tiên nhặt Key Râu Đen...")
                    task.wait(1.5)
                else
                    local list = getSortedChests()
                    local proceedCollect = true
                    if STATE.HuntKeyMode then
                        if os.clock() - bootTick < 7 then
                            proceedCollect = false
                            setStatus("⏳ Săn Key: đợi map tải đủ...")
                            task.wait(2)
                        elseif countFists() > 0 then
                            proceedCollect = false
                            setStatus("🗝️ SERVER NÀY CÓ KEY RÂU ĐEN 🔴 - ĐANG NHẶT!")
                            task.wait(1.5)
                        elseif STATE.HuntLootFirst and #list > 0 then
                            setStatus("💰 Không thấy key rớt - mở rương xét xác suất...")
                        else
                            proceedCollect = false
                            STATE.HuntedServers = STATE.HuntedServers + 1
                            pcall(function()
                                if ValHunted and ValHunted.Parent then
                                    ValHunted.Text = tostring(STATE.HuntedServers) .. " server"
                                end
                            end)
                            setStatus("🔎 Không có key - hop server săn tiếp...")
                            task.wait(1.2)
                            if STATE.HuntKeyMode then
                                hopServer("oldest", "🎯 Săn Key 100%: dò server cũ tiếp...")
                            end
                        end
                    end
                    if proceedCollect then
                    if #list == 0 then
                        if STATE.AutoHopEmpty then
                            setStatus("📭 Hết rương! Đang chuyển server cũ...")
                            pcall(function()
                                if ValTarget and ValTarget.Parent then
                                    ValTarget.Text = "Hết rương - đang hop..."
                                end
                            end)
                            task.wait(CONFIG.HopEmptyDelay)
                            if STATE.AutoCollect and STATE.AutoHopEmpty then
                                hopServer("oldest", "⏳ Hết rương - tìm server cũ nhất...")
                            end
                        else
                            setStatus("📭 Hết rương - đợi hồi...")
                            task.wait(5)
                        end
                    else
                        local target = list[1]
                        local info = TIER_INFO[target.Tier]
                        pcall(function()
                            if ValTarget and ValTarget.Parent then
                                ValTarget.Text = info.Label .. " [" .. tostring(math.floor(target.Dist)) .. " m]"
                            end
                        end)
                        setStatus("🤏 Đang nhặt " .. info.Label .. "...")
                        local before = STATE.Collected
                        local okGo = tweenToChest(target.Part)
                        if okGo then
                            task.wait(0.35)
                            if not (target.Part and target.Part.Parent) then
                                STATE.Collected = STATE.Collected + 1
                                pcall(function()
                                    if ValCollected and ValCollected.Parent then
                                        ValCollected.Text = tostring(STATE.Collected) .. " rương"
                                    end
                                end)
                            else
                                task.wait(0.5)
                                if target.Part and target.Part.Parent then
                                    STATE.IgnoredChests[target.Part] = true
                                    setStatus("⚠️ Rương kẹt - bỏ qua rương này")
                                    task.wait(0.8)
                                else
                                    STATE.Collected = STATE.Collected + 1
                                    pcall(function()
                                        if ValCollected and ValCollected.Parent then
                                            ValCollected.Text = tostring(STATE.Collected) .. " rương"
                                        end
                                    end)
                                end
                            end
                        end
                        if STATE.Collected ~= before then
                            if hasFistOfDarkness() and not STATE.KeyFound then
                                onKeyDetected()
                            end
                        end
                    end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while scriptActive do
        task.wait(1)
        if STATE.AutoGrabKey and not STATE.IsHopping and not STATE.KeyFound then
            local char, hrp = getCharacter()
            if hrp then
                local fistTarget = nil
                local fistDist = math.huge
                for root, _ in pairs(FistMap) do
                    if root and root.Parent then
                        local d = (root.Position - hrp.Position).Magnitude
                        if d < fistDist then
                            fistDist = d
                            fistTarget = root
                        end
                    end
                end
                if fistTarget then
                    STATE.GrabbingKey = true
                    STATE.KillTween = true
                    if STATE.CurrentTween then
                        pcall(function() STATE.CurrentTween:Cancel() end)
                        task.wait(0.3)
                    end
                    setStatus("🗝️ BAY NHẶT KEY RÂU ĐEN 🔴 [" .. tostring(math.floor(fistDist)) .. " m]")
                    pcall(function()
                        if ValTarget and ValTarget.Parent then
                            ValTarget.Text = "🗝️ KEY RÂU ĐEN 🔴"
                        end
                    end)
                    local t0 = os.clock()
                    while fistTarget and fistTarget.Parent and os.clock() - t0 < 25 do
                        if not STATE.AutoGrabKey then break end
                        tweenToChest(fistTarget)
                        task.wait(0.35)
                        if hasFistOfDarkness() then break end
                        if not (fistTarget and fistTarget.Parent) then break end
                    end
                    STATE.GrabbingKey = false
                    if hasFistOfDarkness() and not STATE.KeyFound then
                        onKeyDetected()
                    end
                end
            end
        end
    end
end)

setStatus("✅ CHEST ESP đã tải xong - Mở tab 📡 ESP!")
refreshServerInfo()
