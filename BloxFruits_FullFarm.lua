if getgenv then
    if getgenv().VipFullFarmActive then
        pcall(function()
            if getgenv().VipFullFarmGui and getgenv().VipFullFarmGui.Parent then
                getgenv().VipFullFarmGui:Destroy()
            end
        end)
    end
    getgenv().VipFullFarmActive = true
end

repeat task.wait(0.3) until game:IsLoaded()
local Players = game:GetService("Players")
repeat task.wait(0.3) until Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = nil
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId
local scriptActive = true

repeat task.wait(0.3) until LocalPlayer:FindFirstChild("PlayerGui")
task.wait(2)

local CONFIG = {
    GitHubRawURL = "https://api.mclo.gs/1/raw/cs1nYm4",
    AutoReExecute = true,
    GhostInvisibility = true,
    StealthFlyAltitude = 280,
    Team = "Pirates",
    FlySpeed = 160,
    NoFruitHopDelay = 2,
    VisitedServersFile = "BF_VisitedServers.json",
    DuplicateHandling = "StopIfRare",
    EnableAdminDetector = true,
    DefaultBackground = "rbxassetid://16140502159",
    DefaultIcon = "rbxassetid://14207920404",
    RareFruits = {
        ["Kitsune"] = true, ["Dragon"] = true, ["Leopard"] = true,
        ["Spirit"] = true, ["Control"] = true, ["Venom"] = true,
        ["Shadow"] = true, ["Dough"] = true, ["T-Rex"] = true,
        ["Mammoth"] = true, ["Gravity"] = true, ["Blizzard"] = true,
        ["Pain"] = true, ["Portal"] = true, ["Buddha"] = true,
        ["Sound"] = true, ["Phoenix"] = true, ["Quake"] = true,
        ["Love"] = true, ["Spider"] = true, ["Magma"] = true,
        ["Gas"] = true, ["Yeti"] = true
    }
}

local STATE = {
    IsPaused = false,
    CurrentStatus = "Đang khởi động...",
    FruitName = "Chưa phát hiện",
    FruitDistance = 0,
    HasFruit = false,
    CurrentTab = "Status",
    IsHopping = false
}

STATE.FruitSniperOn = false
STATE.AutoFarmLevel = false
STATE.AutoFarmBoss = false
STATE.FastAttackOn = true
STATE.BringMobOn = true
STATE.AutoBuso = false
STATE.AutoStatsOn = false
STATE.WeaponType = "Melee"
STATE.StatToAdd = "Melee"
STATE.SelectedBoss = "The Gorilla King"
STATE.PlayerESPOn = false
STATE.MiscNoclip = false
STATE.WalkSpeedV = 16
STATE.JumpPowerV = 50

local IgnoredFruitInstances = {}

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
    if getgenv and getgenv().FruitSniperURL then
        url = getgenv().FruitSniperURL
    end
    if (not url or url == "") and _G.FruitSniperURL then
        url = _G.FruitSniperURL
    end
    if (not url or url == "") and isfile and isfile("BF_ScriptURL.txt") then
        pcall(function() url = readfile("BF_ScriptURL.txt") end)
    end
    if not url or url == "" then
        url = CONFIG.GitHubRawURL
    end

    teleportQueued = true
    pcall(function()
        if writefile then writefile("BF_ScriptURL.txt", url) end
    end)

    local payload = string.format('if getgenv then getgenv().FruitSniperURL=[=[%s]=] end task.spawn(function() repeat task.wait(0.5) until game:IsLoaded(); task.wait(2.5); pcall(function() loadstring(game:HttpGet("%s"))() end) end)', url, url)
    pcall(queueFunc, payload)
end

pcall(setupAutoRestart)


local antiAfkConn = nil
pcall(function()
    if getconnections then
        for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
            pcall(function() conn:Disable() end)
        end
    end
end)

antiAfkConn = LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        task.wait(0.2)
        VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    end)
end)

local function checkIsAdmin(player)
    if not player or player == LocalPlayer then return false end
    local isStaff = false
    pcall(function()
        local rank = player:GetRankInGroup(4372130)
        if rank and rank >= 10 then isStaff = true end
    end)
    pcall(function()
        if player:IsInGroup(1200769) then isStaff = true end
    end)
    return isStaff
end

local function getGuiParent()
    if gethui then
        local s, h = pcall(gethui)
        if s and h then return h end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

pcall(function()
    local old = getGuiParent():FindFirstChild("VipFullFarm")
    if old then old:Destroy() end
end)

local QUEST_DATA = {
    {MinLv = 1, MaxLv = 9, MobFullName = "Bandit [Lv. 5]", QuestName = "BanditQuest1", QuestNum = 1, QuestLabel = "Bandit", QuestPos = Vector3.new(1060.94, 16.46, 1547.78), MonPos = Vector3.new(1038.55, 41.30, 1576.51)},
    {MinLv = 10, MaxLv = 14, MobFullName = "Monkey [Lv. 14]", QuestName = "JungleQuest", QuestNum = 1, QuestLabel = "Monkey", QuestPos = Vector3.new(-1604.12, 36.85, 154.24), MonPos = Vector3.new(-1448.14, 50.85, 63.61)},
    {MinLv = 15, MaxLv = 29, MobFullName = "Gorilla [Lv. 20]", QuestName = "JungleQuest", QuestNum = 2, QuestLabel = "Gorilla", QuestPos = Vector3.new(-1601.66, 36.85, 153.39), MonPos = Vector3.new(-1142.65, 40.46, -515.39)},
    {MinLv = 30, MaxLv = 39, MobFullName = "Pirate [Lv. 35]", QuestName = "BuggyQuest1", QuestNum = 1, QuestLabel = "Pirate", QuestPos = Vector3.new(-1140.18, 4.75, 3827.41), MonPos = Vector3.new(-1201.09, 40.63, 3857.60)},
    {MinLv = 40, MaxLv = 59, MobFullName = "Brute [Lv. 45]", QuestName = "BuggyQuest1", QuestNum = 2, QuestLabel = "Brute", QuestPos = Vector3.new(-1140.18, 4.75, 3827.41), MonPos = Vector3.new(-1387.53, 24.59, 4100.96)},
    {MinLv = 60, MaxLv = 74, MobFullName = "Desert Bandit [Lv. 60]", QuestName = "DesertQuest", QuestNum = 1, QuestLabel = "Desert Bandit", QuestPos = Vector3.new(896.52, 6.44, 4390.15), MonPos = Vector3.new(985.00, 16.11, 4417.91)},
    {MinLv = 75, MaxLv = 89, MobFullName = "Desert Officer [Lv. 70]", QuestName = "DesertQuest", QuestNum = 2, QuestLabel = "Desert Officer", QuestPos = Vector3.new(896.52, 6.44, 4390.15), MonPos = Vector3.new(1547.15, 14.45, 4381.80)},
    {MinLv = 90, MaxLv = 99, MobFullName = "Snow Bandit [Lv. 90]", QuestName = "SnowQuest", QuestNum = 1, QuestLabel = "Snow Bandit", QuestPos = Vector3.new(1386.81, 87.27, -1298.36), MonPos = Vector3.new(1356.30, 105.77, -1328.24)},
    {MinLv = 100, MaxLv = 119, MobFullName = "Snowman [Lv. 100]", QuestName = "SnowQuest", QuestNum = 2, QuestLabel = "Snowman", QuestPos = Vector3.new(1386.81, 87.27, -1298.36), MonPos = Vector3.new(1218.80, 138.01, -1488.03)},
    {MinLv = 120, MaxLv = 149, MobFullName = "Chief Petty Officer [Lv. 120]", QuestName = "MarineQuest2", QuestNum = 1, QuestLabel = "Chief Petty Officer", QuestPos = Vector3.new(-5035.50, 28.68, 4324.18), MonPos = Vector3.new(-4931.16, 65.79, 4121.84)},
    {MinLv = 150, MaxLv = 174, MobFullName = "Sky Bandit [Lv. 150]", QuestName = "SkyQuest", QuestNum = 1, QuestLabel = "Sky Bandit", QuestPos = Vector3.new(-4841.83, 717.67, -2623.96), MonPos = Vector3.new(-4970.74, 294.54, -2890.11)},
    {MinLv = 175, MaxLv = 224, MobFullName = "Dark Master [Lv. 175]", QuestName = "SkyQuest", QuestNum = 2, QuestLabel = "Dark Master", QuestPos = Vector3.new(-4841.83, 717.67, -2623.96), MonPos = Vector3.new(-5220.59, 430.69, -2278.17)},
    {MinLv = 225, MaxLv = 274, MobFullName = "Toga Warrior [Lv. 225]", QuestName = "ColosseumQuest", QuestNum = 1, QuestLabel = "Toga Warrior", QuestPos = Vector3.new(-1576.12, 7.39, -2983.31), MonPos = Vector3.new(-1779.98, 44.61, -2736.35)},
    {MinLv = 275, MaxLv = 299, MobFullName = "Gladiator [Lv. 275]", QuestName = "ColosseumQuest", QuestNum = 2, QuestLabel = "Gladiator", QuestPos = Vector3.new(-1576.12, 7.39, -2983.31), MonPos = Vector3.new(-1274.76, 58.19, -3188.16)},
    {MinLv = 300, MaxLv = 329, MobFullName = "Military Soldier [Lv. 300]", QuestName = "MagmaQuest", QuestNum = 1, QuestLabel = "Military Soldier", QuestPos = Vector3.new(-5316.56, 12.24, 8517.30), MonPos = Vector3.new(-5363.01, 41.51, 8548.47)},
    {MinLv = 330, MaxLv = 374, MobFullName = "Military Spy [Lv. 330]", QuestName = "MagmaQuest", QuestNum = 2, QuestLabel = "Military Spy", QuestPos = Vector3.new(-5316.56, 12.24, 8517.30), MonPos = Vector3.new(-5787.99, 120.86, 8762.25)},
    {MinLv = 375, MaxLv = 399, MobFullName = "Fishman Warrior [Lv. 375]", QuestName = "FishmanQuest", QuestNum = 1, QuestLabel = "Fishman Warrior", QuestPos = Vector3.new(61122.56, 18.47, 1568.17), MonPos = Vector3.new(61163.85, 5.31, 1819.78)},
    {MinLv = 400, MaxLv = 449, MobFullName = "Fishman Commando [Lv. 400]", QuestName = "FishmanQuest", QuestNum = 2, QuestLabel = "Fishman Commando", QuestPos = Vector3.new(61122.56, 18.47, 1568.17), MonPos = Vector3.new(61163.85, 5.31, 1819.78)},
    {MinLv = 450, MaxLv = 474, MobFullName = "God's Guard [Lv. 450]", QuestName = "SkyExp1Quest", QuestNum = 1, QuestLabel = "God's Guard", QuestPos = Vector3.new(-4721.71, 845.28, -1954.20), MonPos = Vector3.new(-4716.96, 853.09, -1933.93)},
    {MinLv = 475, MaxLv = 524, MobFullName = "Shanda [Lv. 475]", QuestName = "SkyExp1Quest", QuestNum = 2, QuestLabel = "Shanda", QuestPos = Vector3.new(-7863.64, 5545.49, -379.83), MonPos = Vector3.new(-7685.12, 5601.05, -443.17)},
    {MinLv = 525, MaxLv = 549, MobFullName = "Royal Squad [Lv. 525]", QuestName = "SkyExp2Quest", QuestNum = 1, QuestLabel = "Royal Squad", QuestPos = Vector3.new(-7902.67, 5635.96, -1411.72), MonPos = Vector3.new(-7685.02, 5606.88, -1442.73)},
    {MinLv = 550, MaxLv = 624, MobFullName = "Royal Soldier [Lv. 550]", QuestName = "SkyExp2Quest", QuestNum = 2, QuestLabel = "Royal Soldier", QuestPos = Vector3.new(-7902.67, 5635.96, -1411.72), MonPos = Vector3.new(-7864.45, 5661.94, -1708.22)},
    {MinLv = 625, MaxLv = 649, MobFullName = "Galley Pirate [Lv. 625]", QuestName = "FountainQuest", QuestNum = 1, QuestLabel = "Galley Pirate", QuestPos = Vector3.new(5254.60, 38.50, 4049.70), MonPos = Vector3.new(5595.07, 41.50, 3961.47)},
    {MinLv = 650, MaxLv = 700, MobFullName = "Galley Captain [Lv. 650]", QuestName = "FountainQuest", QuestNum = 2, QuestLabel = "Galley Captain", QuestPos = Vector3.new(5254.60, 38.50, 4049.70), MonPos = Vector3.new(5658.58, 38.54, 4928.94)}
}

local BOSS_DATA = {
    {Name = "The Gorilla King", Anchor = Vector3.new(-1142.65, 40.46, -515.39)},
    {Name = "Bobby", Anchor = Vector3.new(-1140.18, 14.75, 3827.41)},
    {Name = "The Saw", Anchor = Vector3.new(-655.82, 7.89, 1436.68)},
    {Name = "Saber Expert", Anchor = Vector3.new(-1249.77, 25.00, 341.36)},
    {Name = "Mob Leader", Anchor = Vector3.new(-2573.34, 8.89, 2047.00)},
    {Name = "Yeti", Anchor = Vector3.new(1218.80, 138.01, -1488.03)},
    {Name = "Vice Admiral", Anchor = Vector3.new(-4505.00, 20.00, 4260.00)},
    {Name = "Greybeard", Anchor = Vector3.new(-4505.00, 25.00, 4260.00)},
    {Name = "Warden", Anchor = Vector3.new(4854.16, 5.69, 740.19)},
    {Name = "Chief Warden", Anchor = Vector3.new(4854.16, 5.69, 740.19)},
    {Name = "Swan", Anchor = Vector3.new(5230.00, 5.00, 723.00)},
    {Name = "Magma Admiral", Anchor = Vector3.new(-5316.56, 12.24, 8517.30)},
    {Name = "Fishman Lord", Anchor = Vector3.new(61122.56, 18.47, 1568.17)},
    {Name = "Wysper", Anchor = Vector3.new(-7902.67, 5635.96, -1411.72)},
    {Name = "Thunder God", Anchor = Vector3.new(-7902.67, 5550.96, -2300.00)},
    {Name = "Ice Admiral", Anchor = Vector3.new(1198.01, 27.01, -1168.00)},
    {Name = "Cyborg", Anchor = Vector3.new(5658.58, 38.54, 4928.94)}
}

local BOSS_NAMES = {}
local BOSS_BY_NAME = {}
for i, b in ipairs(BOSS_DATA) do
    BOSS_NAMES[i] = b.Name
    BOSS_BY_NAME[b.Name] = b
end

local ISLAND_TP = {
    {"Starter Island", Vector3.new(1071.00, 16.00, 1426.00)},
    {"Marine Starter", Vector3.new(-2573.34, 6.89, 2047.00)},
    {"Middle Town", Vector3.new(-655.82, 7.89, 1436.68)},
    {"Jungle", Vector3.new(-1249.77, 11.89, 341.36)},
    {"Pirate Village", Vector3.new(-1122.35, 4.79, 3855.92)},
    {"Desert", Vector3.new(1094.15, 6.47, 4192.89)},
    {"Frozen Village", Vector3.new(1146.00, 14.00, -1168.00)},
    {"Marine Fortress", Vector3.new(-4505.00, 20.00, 4260.00)},
    {"Skylands", Vector3.new(-4652.00, 872.00, -1814.00)},
    {"Upper Skylands", Vector3.new(-7863.64, 5545.49, -379.83)},
    {"Prison", Vector3.new(4854.16, 5.69, 740.19)},
    {"Colosseum", Vector3.new(-1427.00, 7.00, -2792.00)},
    {"Magma Village", Vector3.new(-5247.00, 12.00, 8504.00)},
    {"Underwater City", Vector3.new(61122.56, 18.47, 1568.17)},
    {"Fountain City", Vector3.new(5254.60, 38.50, 4049.70)}
}

local SHOP_ACTIONS = {
    {"Geppo - Sky Jump ($10,000)", {"BuyHaki", "Geppo"}},
    {"Buso Haki - Enhancement ($25,000)", {"BuyHaki", "Buso"}},
    {"Soru - Flash Step ($100,000)", {"BuyHaki", "Soru"}},
    {"Ken Haki - Observation", {"KenTalk", "Buy"}},
    {"Vo Black Leg", {"BuyBlackLeg"}},
    {"Vo Electro", {"BuyElectro"}},
    {"Vo Fishman Karate", {"BuyFishmanKarate"}},
    {"Katana ($1,000)", {"BuyItem", "Katana"}},
    {"Cutlass ($1,000)", {"BuyItem", "Cutlass"}},
    {"Swordsman Hat", {"BuyItem", "Swordsman Hat"}}
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VipFullFarm"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = getGuiParent()
if getgenv then getgenv().VipFullFarmGui = ScreenGui end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 320)
MainFrame.Position = UDim2.new(0.08, 0, 0.22, 0)
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
AnimeBg.ImageTransparency = 0
AnimeBg.ScaleType = Enum.ScaleType.Crop
AnimeBg.ZIndex = 1
AnimeBg.Parent = MainFrame

local ElectricLayer = Instance.new("Frame")
ElectricLayer.Name = "ElectricLayer"
ElectricLayer.Size = UDim2.new(1, 0, 1, 0)
ElectricLayer.Position = UDim2.new(0, 0, 0, 0)
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
    Color3.fromRGB(0, 255, 170),
    Color3.fromRGB(255, 0, 128)
}

local activeBolts = {}
for idx = 1, 4 do
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

    local bGrad = Instance.new("UIGradient")
    bGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 1),
        NumberSequenceKeypoint.new(0.25, 0.1),
        NumberSequenceKeypoint.new(0.75, 0.1),
        NumberSequenceKeypoint.new(1.0, 1)
    })
    bGrad.Parent = bolt

    local subSpark = Instance.new("Frame")
    subSpark.Size = UDim2.new(0.5, 0, 0, 2)
    subSpark.Position = UDim2.new(0.4, 0, 0, 0)
    subSpark.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    subSpark.BackgroundTransparency = 0.4
    subSpark.BorderSizePixel = 0
    subSpark.Rotation = math.random(25, 50)
    subSpark.ZIndex = 2
    subSpark.Parent = bolt

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(1, 0)
    sCorner.Parent = subSpark

    table.insert(activeBolts, {
        Bolt = bolt,
        Sub = subSpark,
        SpeedX = (math.random() > 0.5 and 1 or -1) * math.random(15, 30) / 1000,
        SpeedY = (math.random() > 0.5 and 1 or -1) * math.random(10, 20) / 1000
    })
end

task.spawn(function()
    while scriptActive and ScreenGui and ScreenGui.Parent do
        for _, bData in ipairs(activeBolts) do
            local bolt = bData.Bolt
            local sub = bData.Sub
            if bolt and bolt.Parent then
                local cur = bolt.Position
                local nx = (cur.X.Scale + bData.SpeedX) % 1.1 - 0.08
                local ny = (cur.Y.Scale + bData.SpeedY) % 1.05 - 0.05
                bolt.Position = UDim2.new(nx, 0, ny, 0)

                if math.random(1, 5) == 1 then
                    bolt.BackgroundTransparency = math.random(10, 45) / 100
                    if sub and sub.Parent then sub.BackgroundTransparency = math.random(15, 55) / 100 end
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
CrownTitle.Size = UDim2.new(0, 275, 1, 0)
CrownTitle.Position = UDim2.new(0, 14, 0, 0)
CrownTitle.BackgroundTransparency = 1
CrownTitle.Text = "[ FULL FARM🌾 MAKE BY nd.⚡]"
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
VipBadge.Size = UDim2.new(0, 120, 0, 20)
VipBadge.Position = UDim2.new(1, -164, 0, 11)
VipBadge.BackgroundColor3 = Color3.fromRGB(18, 22, 45)
VipBadge.BackgroundTransparency = 0.2
VipBadge.Text = "★ FULL FARM EDITION ★"
VipBadge.TextColor3 = Color3.fromRGB(0, 240, 255)
VipBadge.TextSize = 9
VipBadge.Font = Enum.Font.GothamBold
VipBadge.ZIndex = 4
VipBadge.Parent = TopBar

local BadgeCorner = Instance.new("UICorner")
BadgeCorner.CornerRadius = UDim.new(0, 6)
BadgeCorner.Parent = VipBadge

local BadgeStroke = Instance.new("UIStroke")
BadgeStroke.Thickness = 1
BadgeStroke.Color = Color3.fromRGB(0, 240, 255)
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
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(157, 78, 221)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 0, 128)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0, 255, 163)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(0, 240, 255))
})
FloatStrokeGrad.Rotation = 45
FloatStrokeGrad.Parent = FloatStroke

task.spawn(function()
    local rot = 0
    while scriptActive and ScreenGui and ScreenGui.Parent do
        rot = (rot + 3) % 360
        pcall(function()
            if StrokeGradient and StrokeGradient.Parent then StrokeGradient.Rotation = rot end
            if TitleGrad and TitleGrad.Parent then TitleGrad.Rotation = rot end
            if FloatStrokeGrad and FloatStrokeGrad.Parent then FloatStrokeGrad.Rotation = rot end
        end)
        task.wait(0.07)
    end
end)

local FloatSpark = Instance.new("Frame")
FloatSpark.Name = "FloatSpark"
FloatSpark.Size = UDim2.new(0, 10, 0, 10)
FloatSpark.Position = UDim2.new(1, -14, 0, 4)
FloatSpark.BackgroundColor3 = Color3.fromRGB(0, 240, 255)
FloatSpark.BorderSizePixel = 0
FloatSpark.ZIndex = 5
FloatSpark.Parent = FloatingBtn

local SparkCorner = Instance.new("UICorner")
SparkCorner.CornerRadius = UDim.new(1, 0)
SparkCorner.Parent = FloatSpark

task.spawn(function()
    while scriptActive and ScreenGui and ScreenGui.Parent and FloatSpark and FloatSpark.Parent do
        for a = 2, 10 do
            if not scriptActive then break end
            FloatSpark.BackgroundTransparency = a / 12
            task.wait(0.06)
        end
        for a = 10, 2, -1 do
            if not scriptActive then break end
            FloatSpark.BackgroundTransparency = a / 12
            task.wait(0.06)
        end
    end
end)

local SideBar = Instance.new("Frame")
SideBar.Name = "SideBar"
SideBar.Size = UDim2.new(0, 130, 1, -48)
SideBar.Position = UDim2.new(0, 8, 0, 44)
SideBar.BackgroundColor3 = Color3.fromRGB(12, 15, 26)
SideBar.BackgroundTransparency = 0.35
SideBar.BorderSizePixel = 0
SideBar.ZIndex = 3
SideBar.Parent = MainFrame

local SideCorner = Instance.new("UICorner")
SideCorner.CornerRadius = UDim.new(0, 10)
SideCorner.Parent = SideBar

local UserInfoFrame = Instance.new("Frame")
UserInfoFrame.Name = "UserInfo"
UserInfoFrame.Size = UDim2.new(1, -12, 0, 36)
UserInfoFrame.Position = UDim2.new(0, 6, 0, 6)
UserInfoFrame.BackgroundTransparency = 1
UserInfoFrame.ZIndex = 4
UserInfoFrame.Parent = SideBar

local UserAvatar = Instance.new("ImageLabel")
UserAvatar.Name = "Avatar"
UserAvatar.Size = UDim2.new(0, 28, 0, 28)
UserAvatar.Position = UDim2.new(0, 2, 0, 4)
UserAvatar.BackgroundColor3 = Color3.fromRGB(30, 36, 60)
UserAvatar.ZIndex = 4
UserAvatar.Parent = UserInfoFrame

local AvCorner = Instance.new("UICorner")
AvCorner.CornerRadius = UDim.new(1, 0)
AvCorner.Parent = UserAvatar

pcall(function()
    local thumb = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    UserAvatar.Image = thumb
end)

local UserName = Instance.new("TextLabel")
UserName.Name = "UserName"
UserName.Size = UDim2.new(1, -36, 0, 14)
UserName.Position = UDim2.new(0, 34, 0, 4)
UserName.BackgroundTransparency = 1
UserName.Text = LocalPlayer.DisplayName
UserName.TextColor3 = Color3.fromRGB(240, 245, 255)
UserName.TextSize = 10
UserName.Font = Enum.Font.GothamBold
UserName.TextXAlignment = Enum.TextXAlignment.Left
UserName.ZIndex = 4
UserName.Parent = UserInfoFrame

local UserRank = Instance.new("TextLabel")
UserRank.Name = "UserRank"
UserRank.Size = UDim2.new(1, -36, 0, 12)
UserRank.Position = UDim2.new(0, 34, 0, 18)
UserRank.BackgroundTransparency = 1
UserRank.Text = "🛡️ Anti-Ban ON"
UserRank.TextColor3 = Color3.fromRGB(0, 255, 140)
UserRank.TextSize = 9
UserRank.Font = Enum.Font.Gotham
UserRank.TextXAlignment = Enum.TextXAlignment.Left
UserRank.ZIndex = 4
UserRank.Parent = UserInfoFrame

local TabsList = Instance.new("ScrollingFrame")
TabsList.Name = "TabsList"
TabsList.Size = UDim2.new(1, -12, 1, -50)
TabsList.Position = UDim2.new(0, 6, 0, 46)
TabsList.BackgroundTransparency = 1
TabsList.ZIndex = 4
TabsList.ScrollBarThickness = 2
TabsList.ScrollBarImageColor3 = Color3.fromRGB(0, 240, 255)
TabsList.CanvasSize = UDim2.new(0, 0, 0, 0)
TabsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
TabsList.Parent = SideBar

local TabsLayout = Instance.new("UIListLayout")
TabsLayout.Padding = UDim.new(0, 6)
TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabsLayout.Parent = TabsList

local function createTabBtn(text, yPos, isDefault)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.Position = UDim2.new(0, 0, 0, yPos)
    btn.LayoutOrder = math.floor(yPos / 38) + 1
    btn.BackgroundColor3 = isDefault and Color3.fromRGB(24, 32, 60) or Color3.fromRGB(15, 20, 38)
    btn.BackgroundTransparency = isDefault and 0.15 or 0.4
    btn.Text = text
    btn.TextColor3 = isDefault and Color3.fromRGB(0, 240, 255) or Color3.fromRGB(160, 175, 210)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 5
    btn.Parent = TabsList

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Color = isDefault and Color3.fromRGB(0, 240, 255) or Color3.fromRGB(35, 45, 80)
    s.Parent = btn

    return btn, s
end

local TabBtnFarm, StrokeFarm = createTabBtn("🌾 Auto Farm", 0, true)
local TabBtnBoss, StrokeBoss = createTabBtn("👹 Farm Boss", 38, false)
local TabBtnStatus, StrokeStatus = createTabBtn("🍎 Trái Ác Quỷ", 76, false)
local TabBtnTele, StrokeTele = createTabBtn("✈️ Đảo Teleport", 114, false)
local TabBtnStats, StrokeStats = createTabBtn("📊 Cộng Chỉ Số", 152, false)
local TabBtnShop, StrokeShop = createTabBtn("🛒 Shop Nhanh", 190, false)
local TabBtnMisc, StrokeMisc = createTabBtn("🧰 Tiện Ích", 228, false)
local TabBtnConfig, StrokeConfig = createTabBtn("⚙️ Cài Đặt", 266, false)
local TabBtnHop, StrokeHop = createTabBtn("🚀 Server Hop", 304, false)
local TabBtnTheme, StrokeTheme = createTabBtn("🎨 Hình Nền", 342, false)

local MainContent = Instance.new("Frame")
MainContent.Name = "MainContent"
MainContent.Size = UDim2.new(1, -154, 1, -48)
MainContent.Position = UDim2.new(0, 146, 0, 44)
MainContent.BackgroundColor3 = Color3.fromRGB(12, 15, 26)
MainContent.BackgroundTransparency = 0.35
MainContent.BorderSizePixel = 0
MainContent.ZIndex = 3
MainContent.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 10)
ContentCorner.Parent = MainContent

local PageStatus = Instance.new("Frame")
PageStatus.Name = "PageStatus"
PageStatus.Size = UDim2.new(1, -16, 1, -16)
PageStatus.Position = UDim2.new(0, 8, 0, 8)
PageStatus.BackgroundTransparency = 1
PageStatus.ZIndex = 4
PageStatus.Parent = MainContent

local function createInfoCard(label, defaultVal, yPos)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 32)
    card.Position = UDim2.new(0, 0, 0, yPos)
    card.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
    card.BackgroundTransparency = 0.25
    card.BorderSizePixel = 0
    card.ZIndex = 4
    card.Parent = PageStatus

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Thickness = 1
    cardStroke.Color = Color3.fromRGB(28, 48, 85)
    cardStroke.Parent = card

    local tag = Instance.new("TextLabel")
    tag.Size = UDim2.new(0, 95, 1, 0)
    tag.Position = UDim2.new(0, 8, 0, 0)
    tag.BackgroundTransparency = 1
    tag.Text = label
    tag.TextColor3 = Color3.fromRGB(160, 190, 240)
    tag.TextSize = 11
    tag.Font = Enum.Font.GothamMedium
    tag.TextXAlignment = Enum.TextXAlignment.Left
    tag.ZIndex = 5
    tag.Parent = card

    local val = Instance.new("TextLabel")
    val.Name = "Value"
    val.Size = UDim2.new(1, -105, 1, 0)
    val.Position = UDim2.new(0, 100, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = defaultVal
    val.TextColor3 = Color3.fromRGB(0, 240, 255)
    val.TextSize = 11
    val.Font = Enum.Font.GothamBold
    val.TextXAlignment = Enum.TextXAlignment.Left
    val.ZIndex = 5
    val.Parent = card

    return val
end

local ValAction = createInfoCard("🛰️ Trạng thái:", "Khởi chạy hệ thống...", 0)
local ValFruit = createInfoCard("🍎 Phát hiện:", "Đang quét trái thật...", 38)
local ValStore = createInfoCard("📦 Kho đồ:", "Tự động Lưu trữ", 76)
local ValServer = createInfoCard("🌐 Máy chủ:", string.format("%d/%d người chơi", #Players:GetPlayers(), Players.MaxPlayers), 114)

local QuickControl = Instance.new("Frame")
QuickControl.Size = UDim2.new(1, 0, 0, 34)
QuickControl.Position = UDim2.new(0, 0, 1, -36)
QuickControl.BackgroundTransparency = 1
QuickControl.ZIndex = 4
QuickControl.Parent = PageStatus

local PauseBtn = Instance.new("TextButton")
PauseBtn.Size = UDim2.new(0.48, 0, 1, 0)
PauseBtn.BackgroundColor3 = Color3.fromRGB(24, 32, 60)
PauseBtn.Text = "⏸️ Tạm Dừng"
PauseBtn.TextColor3 = Color3.fromRGB(0, 240, 255)
PauseBtn.TextSize = 11
PauseBtn.Font = Enum.Font.GothamBold
PauseBtn.ZIndex = 5
PauseBtn.Parent = QuickControl

local PCorner = Instance.new("UICorner")
PCorner.CornerRadius = UDim.new(0, 8)
PCorner.Parent = PauseBtn

local PStroke = Instance.new("UIStroke")
PStroke.Thickness = 1
PStroke.Color = Color3.fromRGB(0, 240, 255)
PStroke.Parent = PauseBtn

local HopNowBtn = Instance.new("TextButton")
HopNowBtn.Size = UDim2.new(0.48, 0, 1, 0)
HopNowBtn.Position = UDim2.new(0.52, 0, 0, 0)
HopNowBtn.BackgroundColor3 = Color3.fromRGB(35, 24, 55)
HopNowBtn.Text = "🚀 Nhảy Server"
HopNowBtn.TextColor3 = Color3.fromRGB(255, 0, 128)
HopNowBtn.TextSize = 11
HopNowBtn.Font = Enum.Font.GothamBold
HopNowBtn.ZIndex = 5
HopNowBtn.Parent = QuickControl

local HCorner = Instance.new("UICorner")
HCorner.CornerRadius = UDim.new(0, 8)
HCorner.Parent = HopNowBtn

local HStroke = Instance.new("UIStroke")
HStroke.Thickness = 1
HStroke.Color = Color3.fromRGB(255, 0, 128)
HStroke.Parent = HopNowBtn

local PageConfig = Instance.new("Frame")
PageConfig.Name = "PageConfig"
PageConfig.Size = UDim2.new(1, -16, 1, -16)
PageConfig.Position = UDim2.new(0, 8, 0, 8)
PageConfig.BackgroundTransparency = 1
PageConfig.Visible = false
PageConfig.ZIndex = 4
PageConfig.Parent = MainContent

local function createSettingRow(title, valueText, yPos, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 36)
    f.Position = UDim2.new(0, 0, 0, yPos)
    f.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
    f.BackgroundTransparency = 0.25
    f.ZIndex = 4
    f.Parent = PageConfig

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = f

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.55, 0, 1, 0)
    l.Position = UDim2.new(0, 8, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = title
    l.TextColor3 = Color3.fromRGB(220, 230, 255)
    l.TextSize = 11
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 5
    l.Parent = f

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.38, 0, 0.75, 0)
    btn.Position = UDim2.new(0.59, 0, 0.12, 0)
    btn.BackgroundColor3 = Color3.fromRGB(28, 36, 68)
    btn.Text = valueText
    btn.TextColor3 = Color3.fromRGB(0, 240, 255)
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 5
    btn.Parent = f

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = btn

    if callback then
        btn.MouseButton1Click:Connect(function() callback(btn) end)
    end
end

createSettingRow("⚡ Tốc Độ Bay:", "160 stud/s", 0, function(btn)
    if CONFIG.FlySpeed == 160 then
        CONFIG.FlySpeed = 200
        btn.Text = "200 stud/s"
    elseif CONFIG.FlySpeed == 200 then
        CONFIG.FlySpeed = 120
        btn.Text = "120 stud/s"
    else
        CONFIG.FlySpeed = 160
        btn.Text = "160 stud/s"
    end
end)

createSettingRow("🏴‍☠️ Tự Chọn Phe:", CONFIG.Team, 40, function(btn)
    CONFIG.Team = (CONFIG.Team == "Pirates") and "Marines" or "Pirates"
    btn.Text = CONFIG.Team
end)

createSettingRow("💎 Trùng Kho:", "Bảo Vệ Trái", 80, function(btn)
    if CONFIG.DuplicateHandling == "StopIfRare" then
        CONFIG.DuplicateHandling = "Drop"
        btn.Text = "Tự Thả (Drop)"
    else
        CONFIG.DuplicateHandling = "StopIfRare"
        btn.Text = "Bảo Vệ Trái"
    end
end)

createSettingRow("🔄 Tự Chạy Lại:", "BẬT (Tự Động)", 120, function(btn)
    CONFIG.AutoReExecute = not CONFIG.AutoReExecute
    btn.Text = CONFIG.AutoReExecute and "BẬT (Tự Động)" or "TẮT"
end)

createSettingRow("👻 Tàng Hình:", "BẬT", 160, function(btn)
    CONFIG.GhostInvisibility = not CONFIG.GhostInvisibility
    btn.Text = CONFIG.GhostInvisibility and "BẬT" or "TẮT"
    if not CONFIG.GhostInvisibility and LocalPlayer.Character then
        pcall(function()
            for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Transparency = 0 end
                if p:IsA("Decal") then p.Transparency = 0 end
            end
        end)
    end
end)

createSettingRow("🍎 Fruit Sniper + Hop:", "TẮT", 200, function(btn)
    STATE.FruitSniperOn = not STATE.FruitSniperOn
    btn.Text = STATE.FruitSniperOn and "BẬT" or "TẮT"
end)

local PageHop = Instance.new("Frame")
PageHop.Name = "PageHop"
PageHop.Size = UDim2.new(1, -16, 1, -16)
PageHop.Position = UDim2.new(0, 8, 0, 8)
PageHop.BackgroundTransparency = 1
PageHop.Visible = false
PageHop.ZIndex = 4
PageHop.Parent = MainContent

local HopDesc = Instance.new("TextLabel")
HopDesc.Size = UDim2.new(1, 0, 0, 48)
HopDesc.Position = UDim2.new(0, 0, 0, 8)
HopDesc.BackgroundTransparency = 1
HopDesc.Text = "Cơ chế chống lặp server: Tự động ghi nhớ server đã qua, quét trực tiếp danh sách JobId khác 100%, tuyệt đối không vào lại server cũ (2/12)."
HopDesc.TextColor3 = Color3.fromRGB(180, 200, 230)
HopDesc.TextSize = 11
HopDesc.Font = Enum.Font.GothamMedium
HopDesc.TextWrapped = true
HopDesc.ZIndex = 5
HopDesc.Parent = PageHop

local LargeHopBtn = Instance.new("TextButton")
LargeHopBtn.Size = UDim2.new(1, 0, 0, 42)
LargeHopBtn.Position = UDim2.new(0, 0, 0, 70)
LargeHopBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 216)
LargeHopBtn.Text = "🚀 BẮT ĐẦU NHẢY SERVER MỚI (1-3 NGƯỜI) NGAY"
LargeHopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LargeHopBtn.TextSize = 12
LargeHopBtn.Font = Enum.Font.GothamBold
LargeHopBtn.ZIndex = 5
LargeHopBtn.Parent = PageHop

local LCorner = Instance.new("UICorner")
LCorner.CornerRadius = UDim.new(0, 8)
LCorner.Parent = LargeHopBtn

local PageTheme = Instance.new("Frame")
PageTheme.Name = "PageTheme"
PageTheme.Size = UDim2.new(1, -16, 1, -16)
PageTheme.Position = UDim2.new(0, 8, 0, 8)
PageTheme.BackgroundTransparency = 1
PageTheme.Visible = false
PageTheme.ZIndex = 4
PageTheme.Parent = MainContent

local function createPresetBtn(name, imageId, yPos)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 32)
    b.Position = UDim2.new(0, 0, 0, yPos)
    b.BackgroundColor3 = Color3.fromRGB(22, 28, 52)
    b.Text = "🖼️ " .. name
    b.TextColor3 = Color3.fromRGB(220, 230, 255)
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.ZIndex = 5
    b.Parent = PageTheme

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = b

    b.MouseButton1Click:Connect(function()
        AnimeBg.Image = imageId
    end)
end

createPresetBtn("Tinh Tú Rừng Đêm (Màu Gốc)", MenuBgAsset, 0)
createPresetBtn("Gojo Trên Bậc Thang", GojoIconAsset, 38)
createPresetBtn("Sung Jin-Woo (Solo Leveling)", "rbxassetid://16140502159", 76)
createPresetBtn("Zoro Kiếm Sĩ (One Piece)", "rbxassetid://11401835376", 114)

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
    t.Size = UDim2.new(0.42, 0, 1, 0)
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
    v.Size = UDim2.new(0.58, -12, 1, 0)
    v.Position = UDim2.new(0.42, 0, 0, 0)
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

local PageFarm = createScrollPg("PageFarm")
local PageBoss = createScrollPg("PageBoss")
local PageTele = createScrollPg("PageTele")
local PageStats = createScrollPg("PageStats")
local PageShop = createScrollPg("PageShop")
local PageMisc = createScrollPg("PageMisc")

mkCycle(PageFarm, 1, "⚔️ Vũ Khí Farm:", {"Vo (Melee)", "Kiem (Sword)", "Trai (Blox Fruit)"}, 1, function(i, v)
    if i == 1 then STATE.WeaponType = "Melee" elseif i == 2 then STATE.WeaponType = "Sword" else STATE.WeaponType = "Blox Fruit" end
end)
mkToggle(PageFarm, 2, "🌾 Auto Farm Level (Nhan Quest)", function() return STATE.AutoFarmLevel end, function(v) STATE.AutoFarmLevel = v end)
mkToggle(PageFarm, 3, "⚡ Fast Attack (Dánh Sieu Nhanh)", function() return STATE.FastAttackOn end, function(v) STATE.FastAttackOn = v end)
mkToggle(PageFarm, 4, "🧲 Gom Quai (Bring Mob)", function() return STATE.BringMobOn end, function(v) STATE.BringMobOn = v end)
mkToggle(PageFarm, 5, "🔥 Tu Bat Buso Haki", function() return STATE.AutoBuso end, function(v) STATE.AutoBuso = v end)
local ValFarmTarget = mkInfo(PageFarm, 6, "🎯 Muc tieu:", "Chua bat farm")
local ValFarmQuest = mkInfo(PageFarm, 7, "📜 Nhiem vu:", "---")

mkCycle(PageBoss, 1, "👹 Chon Boss:", BOSS_NAMES, 1, function(i, v)
    STATE.SelectedBoss = v
end)
mkToggle(PageBoss, 2, "👹 Auto Farm Boss Da Chon", function() return STATE.AutoFarmBoss end, function(v) STATE.AutoFarmBoss = v end)
local ValBossInfo = mkInfo(PageBoss, 3, "📍 Trang thai:", "Chua bat farm boss")
local BossScanBtn = mkButton(PageBoss, 4, "🔍 Quet Vi Tri Boss Ngay", Color3.fromRGB(0, 120, 200))
local BossNote = mkInfo(PageBoss, 5, "ℹ️ Luu y:", "Chi danh khi boss da spawn")

local TeleButtons = {}
for i, entry in ipairs(ISLAND_TP) do
    TeleButtons[i] = mkButton(PageTele, i, "✈️ " .. entry[1], Color3.fromRGB(24, 32, 60))
end
local StopFlyBtn = mkButton(PageTele, #ISLAND_TP + 1, "⏹️ DUNG BAY NGAY", Color3.fromRGB(200, 60, 60))

local ValLv = mkInfo(PageStats, 1, "🏆 Level:", "...")
local ValPoints = mkInfo(PageStats, 2, "🧮 Diem chua cong:", "...")
local ValBeli = mkInfo(PageStats, 3, "💰 Beli:", "...")
local ValFrag = mkInfo(PageStats, 4, "🟣 Fragments:", "...")
mkCycle(PageStats, 5, "➕ Uu tien vao:", {"Melee", "Defense", "Sword", "Demon Fruit", "Gun"}, 1, function(i, v)
    STATE.StatToAdd = v
end)
mkToggle(PageStats, 6, "📊 Tu Dong Cong Diem (x3/lan)", function() return STATE.AutoStatsOn end, function(v) STATE.AutoStatsOn = v end)
local AddAllBtn = mkButton(PageStats, 7, "⚡ CONG HET DIEM NGAY", Color3.fromRGB(0, 120, 85))

local ShopButtons = {}
for i, act in ipairs(SHOP_ACTIONS) do
    ShopButtons[i] = mkButton(PageShop, i, "🛒 " .. act[1], Color3.fromRGB(28, 36, 68))
end
local GachaBtn = mkButton(PageShop, #SHOP_ACTIONS + 1, "🎲 Quay Trai Ngau Nhien (Gacha)", Color3.fromRGB(120, 60, 160))

mkCycle(PageMisc, 1, "🏃 WalkSpeed:", {"16", "32", "50", "100", "150"}, 1, function(i, v)
    STATE.WalkSpeedV = tonumber(v)
end)
mkCycle(PageMisc, 2, "🦘 JumpPower:", {"50", "100", "150", "250"}, 1, function(i, v)
    STATE.JumpPowerV = tonumber(v)
end)
mkToggle(PageMisc, 3, "👻 Tang Hinh (Ghost)", function() return CONFIG.GhostInvisibility end, function(v) CONFIG.GhostInvisibility = v end)
mkToggle(PageMisc, 4, "🚪 Xuyen Tuong (NoClip)", function() return STATE.MiscNoclip end, function(v) STATE.MiscNoclip = v end)
mkToggle(PageMisc, 5, "📡 ESP Nguoi Choi", function() return STATE.PlayerESPOn end, function(v) STATE.PlayerESPOn = v end)
local FpsBoostBtn = mkButton(PageMisc, 6, "🚀 FPS Boost (Don Do Hoa)", Color3.fromRGB(0, 130, 160))
local RejoinBtn = mkButton(PageMisc, 7, "🔄 Vao Lai Server (Rejoin)", Color3.fromRGB(90, 70, 25))
local HopQuickBtn = mkButton(PageMisc, 8, "🌐 Nhay Server It Nguoi", Color3.fromRGB(30, 90, 60))
local Fps30Btn = mkButton(PageMisc, 9, "📉 FPS 30 (Muot - Tiet Kiem Pin)", Color3.fromRGB(50, 80, 40))
local Fps60Btn = mkButton(PageMisc, 10, "📈 FPS 60 (Chat Luong Cao)", Color3.fromRGB(50, 80, 40))

local function switchTab(tabName)
    local pages = {
        Farm = PageFarm, Boss = PageBoss, Status = PageStatus, Tele = PageTele,
        Stats = PageStats, Shop = PageShop, Misc = PageMisc,
        Config = PageConfig, Hop = PageHop, Theme = PageTheme
    }
    local strokes = {
        Farm = StrokeFarm, Boss = StrokeBoss, Status = StrokeStatus, Tele = StrokeTele,
        Stats = StrokeStats, Shop = StrokeShop, Misc = StrokeMisc,
        Config = StrokeConfig, Hop = StrokeHop, Theme = StrokeTheme
    }
    for k, pg in pairs(pages) do
        pg.Visible = (k == tabName)
    end
    for k, st in pairs(strokes) do
        st.Color = (k == tabName) and Color3.fromRGB(0, 240, 255) or Color3.fromRGB(35, 45, 80)
    end
end

TabBtnFarm.MouseButton1Click:Connect(function() switchTab("Farm") end)
TabBtnBoss.MouseButton1Click:Connect(function() switchTab("Boss") end)
TabBtnStatus.MouseButton1Click:Connect(function() switchTab("Status") end)
TabBtnTele.MouseButton1Click:Connect(function() switchTab("Tele") end)
TabBtnStats.MouseButton1Click:Connect(function() switchTab("Stats") end)
TabBtnShop.MouseButton1Click:Connect(function() switchTab("Shop") end)
TabBtnMisc.MouseButton1Click:Connect(function() switchTab("Misc") end)
TabBtnConfig.MouseButton1Click:Connect(function() switchTab("Config") end)
TabBtnHop.MouseButton1Click:Connect(function() switchTab("Hop") end)
TabBtnTheme.MouseButton1Click:Connect(function() switchTab("Theme") end)
switchTab("Farm")

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

local getFrameMoved = makeDraggable(MainFrame, TopBar)
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

PauseBtn.MouseButton1Click:Connect(function()
    STATE.IsPaused = not STATE.IsPaused
    if STATE.IsPaused then
        PauseBtn.Text = "▶️ Tiếp Tục"
        PauseBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
        ValAction.Text = "Tạm dừng"
    else
        PauseBtn.Text = "⏸️ Tạm Dừng"
        PauseBtn.TextColor3 = Color3.fromRGB(0, 240, 255)
        ValAction.Text = "Đang tiếp tục săn..."
    end
end)

local function setStatus(text, color)
    STATE.CurrentStatus = text
    pcall(function()
        if ValAction and ValAction.Parent then
            ValAction.Text = text
            if color then ValAction.TextColor3 = color end
        end
    end)
end

local function updateFruitDisplay(fruitName, distance)
    if fruitName then
        STATE.FruitName = fruitName
        STATE.FruitDistance = distance or 0
        ValFruit.Text = string.format("%s - %d m", fruitName, distance or 0)
        ValFruit.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        ValFruit.Text = "Không có trái spawn"
        ValFruit.TextColor3 = Color3.fromRGB(160, 170, 190)
    end
end

local teamSelected = false
local function autoSelectTeam()
    if teamSelected then return end
    if LocalPlayer.Team ~= nil and tostring(LocalPlayer.Team) ~= "" and tostring(LocalPlayer.Team) ~= "Neutral" then
        teamSelected = true
        return
    end
    pcall(function()
        local rem = ReplicatedStorage:WaitForChild("Remotes", 8)
        local comm = rem and (rem:WaitForChild("CommF_", 8) or rem:WaitForChild("CommF", 8))
        if comm then
            comm:InvokeServer("SetTeam", CONFIG.Team or "Pirates")
            teamSelected = true
        end
    end)
end

task.spawn(function()
    task.wait(1)
    for _ = 1, 8 do
        if LocalPlayer.Team ~= nil and tostring(LocalPlayer.Team) ~= "" and tostring(LocalPlayer.Team) ~= "Neutral" then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                break
            end
        end
        autoSelectTeam()
        task.wait(1.2)
    end
end)
task.wait(1.5)

local function getCharacter()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    char:WaitForChild("HumanoidRootPart", 10)
    char:WaitForChild("Humanoid", 10)
    return char
end

local noclipConn = nil
local function enableNoclip()
    if noclipConn then return end
    noclipConn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)
end

local function disableNoclip()
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
end

local function setHoldVelocity(hrp, enabled)
    local bv = hrp:FindFirstChild("FruitSniper_BV")
    if enabled then
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = "FruitSniper_BV"
            bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            bv.Velocity = Vector3.zero
            bv.Parent = hrp
        else
            bv.Velocity = Vector3.zero
        end
    else
        if bv then bv:Destroy() end
    end
end

local function applyGhostInvisibility(char)
    if not char or not CONFIG.GhostInvisibility then return end
    pcall(function()
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.Name ~= "HumanoidRootPart" then
                    part.Transparency = 1
                    part.CastShadow = false
                end
            elseif part:IsA("Decal") then
                part.Transparency = 1
            elseif part:IsA("BillboardGui") then
                part.Enabled = false
            elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam") then
                part.Enabled = false
            end
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            hum.NameDisplayDistance = 0
            hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        end
        local head = char:FindFirstChild("Head")
        if head then
            for _, gui in pairs(head:GetChildren()) do
                if gui:IsA("BillboardGui") then
                    gui.Enabled = false
                end
            end
        end
    end)
end

task.spawn(function()
    while scriptActive do
        if CONFIG.GhostInvisibility then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                applyGhostInvisibility(char)
            end
        end
        task.wait(1.5)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    if CONFIG.GhostInvisibility then
        task.spawn(function()
            char:WaitForChild("HumanoidRootPart", 6)
            task.wait(0.4)
            applyGhostInvisibility(char)
        end)
    end
end)

local activeFlyTween = nil
local flyCancelRequested = false

local function safeFlyTo(targetPos)
    local char = getCharacter()
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if CONFIG.GhostInvisibility then
        applyGhostInvisibility(char)
    end

    enableNoclip()
    setHoldVelocity(hrp, true)

    local startPos = hrp.Position
    local safeY = math.max(targetPos.Y + 180, CONFIG.StealthFlyAltitude or 280)

    if startPos.Y < safeY and (Vector3.new(startPos.X, 0, startPos.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude > 60 then
        local upCF = CFrame.new(startPos.X, safeY, startPos.Z)
        pcall(function()
            activeFlyTween = TweenService:Create(hrp, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {CFrame = upCF})
            activeFlyTween:Play()
            activeFlyTween.Completed:Wait()
        end)
        if flyCancelRequested then flyCancelRequested = false setHoldVelocity(hrp, false) disableNoclip() return end
    end

    if not hrp or not hrp.Parent then disableNoclip() return end

    local skyTarget = Vector3.new(targetPos.X, safeY, targetPos.Z)
    local distHoriz = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude

    if distHoriz > 15 then
        local durHoriz = math.clamp(distHoriz / CONFIG.FlySpeed, 0.4, 90)
        pcall(function()
            activeFlyTween = TweenService:Create(hrp, TweenInfo.new(durHoriz, Enum.EasingStyle.Linear), {CFrame = CFrame.new(skyTarget)})
            activeFlyTween:Play()
            activeFlyTween.Completed:Wait()
        end)
        if flyCancelRequested then flyCancelRequested = false setHoldVelocity(hrp, false) disableNoclip() return end
    end

    if not hrp or not hrp.Parent then disableNoclip() return end

    local landCF = CFrame.new(targetPos + Vector3.new(0, 1.2, 0))
    local landDist = (hrp.Position - landCF.Position).Magnitude
    local durLand = math.clamp(landDist / (CONFIG.FlySpeed * 0.8), 0.3, 3)

    pcall(function()
        activeFlyTween = TweenService:Create(hrp, TweenInfo.new(durLand, Enum.EasingStyle.Linear), {CFrame = landCF})
        activeFlyTween:Play()
        activeFlyTween.Completed:Wait()
    end)
    flyCancelRequested = false

    setHoldVelocity(hrp, false)
    disableNoclip()
    task.wait(0.15)
end

local function isValidRealSpawnedFruit(item)
    if not item or not item.Parent then return false end
    if IgnoredFruitInstances[item] then return false end
    if not item:IsA("Tool") then return false end
    if item.Parent ~= Workspace then return false end

    local nameLower = item.Name:lower()
    local blacklistedWords = {
        "statue", "colosseum", "dealer", "cousin", "gacha", "npc",
        "stone", "rock", "pedestal", "stand", "monument", "shrine",
        "tree", "secret", "altar", "display", "chest", "dummy", "boss", "quest"
    }
    for _, word in ipairs(blacklistedWords) do
        if string.find(nameLower, word) then return false end
    end

    local handle = item:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then return false end
    if handle.Anchored == true then return false end

    local isFruit = string.find(nameLower, "fruit") or item:FindFirstChild("EatRemote", true) or item:GetAttribute("OriginalName")
    if not isFruit then return false end

    return true
end

local function createFruitESP(fruitData)
    pcall(function()
        local handle = fruitData.Handle
        local old = handle:FindFirstChild("FruitBillboard")
        if old then old:Destroy() end

        local bill = Instance.new("BillboardGui")
        bill.Name = "FruitBillboard"
        bill.Adornee = handle
        bill.Size = UDim2.new(0, 220, 0, 50)
        bill.StudsOffset = Vector3.new(0, 3.5, 0)
        bill.AlwaysOnTop = true
        bill.Parent = handle

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, 0, 0.5, 0)
        title.BackgroundTransparency = 1
        title.Text = "🍎 " .. fruitData.Name
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextStrokeTransparency = 0
        title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        title.TextSize = 15
        title.Font = Enum.Font.GothamBold
        title.Parent = bill

        local distText = Instance.new("TextLabel")
        distText.Name = "DistText"
        distText.Size = UDim2.new(1, 0, 0.5, 0)
        distText.Position = UDim2.new(0, 0, 0.5, 0)
        distText.BackgroundTransparency = 1
        distText.TextColor3 = Color3.fromRGB(0, 240, 255)
        distText.TextStrokeTransparency = 0
        distText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        distText.TextSize = 13
        distText.Font = Enum.Font.GothamMedium
        distText.Parent = bill

        task.spawn(function()
            while handle and handle.Parent and bill and bill.Parent do
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local d = math.floor((char.HumanoidRootPart.Position - handle.Position).Magnitude)
                    distText.Text = string.format("[%d m]", d)
                    updateFruitDisplay(fruitData.Name, d)
                end
                task.wait(0.2)
            end
        end)
    end)
end

local function findSpawnedFruits()
    local fruits = {}
    local seen = {}

    local function registerFruit(item)
        if not item or seen[item] then return end
        seen[item] = true
        if isValidRealSpawnedFruit(item) then
            local handle = item:FindFirstChild("Handle")
            if handle then
                local fData = {
                    Object = item,
                    Handle = handle,
                    Name = item.Name
                }
                createFruitESP(fData)
                table.insert(fruits, fData)
            end
        end
    end

    for _, item in pairs(Workspace:GetChildren()) do
        registerFruit(item)
        if item:IsA("Folder") or item:IsA("Model") then
            local nLower = item.Name:lower()
            if string.find(nLower, "fruit") or string.find(nLower, "drop") or string.find(nLower, "item") or string.find(nLower, "spawn") then
                for _, sub in pairs(item:GetChildren()) do
                    registerFruit(sub)
                end
            end
        end
    end

    return fruits
end

pcall(function()
    Workspace.ChildAdded:Connect(function(child)
        task.wait(0.15)
        if isValidRealSpawnedFruit(child) then
            local handle = child:FindFirstChild("Handle")
            if handle then
                createFruitESP({Object = child, Handle = handle, Name = child.Name})
            end
        end
    end)
end)

local function pickFruitProperly(fruitData)
    local char = getCharacter()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")

    setStatus("🚀 Bay tới: " .. fruitData.Name, Color3.fromRGB(0, 240, 255))
    safeFlyTo(fruitData.Handle.Position)

    setStatus("🍎 Đang nhặt trái...", Color3.fromRGB(255, 0, 128))

    local touchPart = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or hrp
    local startTime = tick()
    local picked = false

    while fruitData.Object.Parent == Workspace and (tick() - startTime < 3.5) do
        pcall(function()
            fruitData.Handle.CFrame = hrp.CFrame
        end)

        if firetouchinterest and fruitData.Handle then
            pcall(function()
                firetouchinterest(touchPart, fruitData.Handle, 0)
                task.wait(0.04)
                firetouchinterest(touchPart, fruitData.Handle, 1)
                firetouchinterest(hrp, fruitData.Handle, 0)
                task.wait(0.04)
                firetouchinterest(hrp, fruitData.Handle, 1)
            end)
        end

        pcall(function()
            hum:EquipTool(fruitData.Object)
        end)

        task.wait(0.18)
    end

    setHoldVelocity(hrp, false)

    if fruitData.Object.Parent == Workspace then
        IgnoredFruitInstances[fruitData.Object] = true
    else
        picked = true
        setStatus("✅ Đã nhặt thành công!", Color3.fromRGB(0, 255, 120))
    end

    task.wait(0.3)
    return picked
end

local FRUIT_ID_MAP = {
    ["rocket"] = "Rocket-Rocket", ["spin"] = "Spin-Spin", ["blade"] = "Chop-Chop", ["chop"] = "Chop-Chop",
    ["spring"] = "Spring-Spring", ["bomb"] = "Bomb-Bomb", ["smoke"] = "Smoke-Smoke", ["spike"] = "Spike-Spike",
    ["flame"] = "Flame-Flame", ["falcon"] = "Bird-Bird: Falcon", ["ice"] = "Ice-Ice", ["sand"] = "Sand-Sand",
    ["dark"] = "Dark-Dark", ["diamond"] = "Diamond-Diamond", ["light"] = "Light-Light", ["rubber"] = "Rubber-Rubber",
    ["barrier"] = "Barrier-Barrier", ["ghost"] = "Ghost-Ghost", ["magma"] = "Magma-Magma", ["quake"] = "Quake-Quake",
    ["buddha"] = "Human-Human: Buddha", ["love"] = "Love-Love", ["spider"] = "String-String", ["sound"] = "Sound-Sound",
    ["phoenix"] = "Bird-Bird: Phoenix", ["portal"] = "Portal-Portal", ["rumble"] = "Rumble-Rumble", ["pain"] = "Paw-Paw",
    ["blizzard"] = "Blizzard-Blizzard", ["gravity"] = "Gravity-Gravity", ["mammoth"] = "Mammoth-Mammoth",
    ["t-rex"] = "T-Rex-T-Rex", ["trex"] = "T-Rex-T-Rex", ["dough"] = "Dough-Dough", ["shadow"] = "Shadow-Shadow",
    ["venom"] = "Venom-Venom", ["control"] = "Control-Control", ["spirit"] = "Spirit-Spirit", ["dragon"] = "Dragon-Dragon",
    ["leopard"] = "Leopard-Leopard", ["kitsune"] = "Kitsune-Kitsune", ["gas"] = "Gas-Gas", ["yeti"] = "Yeti-Yeti",
}

local function getStandardFruitId(tool)
    local attr = tool:GetAttribute("OriginalName")
    if attr and type(attr) == "string" and attr ~= "" then return attr end
    local clean = tool.Name:lower():gsub(" fruit", ""):gsub(" ", "")
    for k, v in pairs(FRUIT_ID_MAP) do
        if string.find(clean, k) then return v end
    end
    local base = tool.Name:gsub(" Fruit", ""):gsub(" ", "")
    return base .. "-" .. base
end

local function isFruitStillInHandsOrBackpack(tool)
    if not tool or not tool.Parent then return false end
    if tool.Parent == LocalPlayer.Backpack then return true end
    if LocalPlayer.Character and tool.Parent == LocalPlayer.Character then return true end
    return false
end

local function triggerUiButtonClick(btn)
    if not btn then return end

    pcall(function()
        if firesignal then
            firesignal(btn.MouseButton1Click)
            firesignal(btn.Activated)
            firesignal(btn.MouseButton1Down)
            firesignal(btn.MouseButton1Up)
        end
    end)

    pcall(function()
        if firesignal then
            firesignal(btn.MouseButton1Click)
            firesignal(btn.Activated)
        end
    end)

    pcall(function()
        local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
        if VirtualInputManager then
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.04)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
            VirtualInputManager:SendTouchEvent(1, 0, pos.X, pos.Y)
            task.wait(0.04)
            VirtualInputManager:SendTouchEvent(1, 2, pos.X, pos.Y)
        end
    end)

    pcall(function()
        local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
        VirtualUser:Button1Down(pos)
        task.wait(0.04)
        VirtualUser:Button1Up(pos)
    end)
end

local function tapScreenOnce()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2

    pcall(function()
        if VirtualInputManager then
            VirtualInputManager:SendTouchEvent(1, 0, cx, cy)
            task.wait(0.03)
            VirtualInputManager:SendTouchEvent(1, 2, cx, cy)
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
            task.wait(0.03)
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
        end
    end)

    pcall(function()
        VirtualUser:Button1Down(Vector2.new(cx, cy))
        task.wait(0.03)
        VirtualUser:Button1Up(Vector2.new(cx, cy))
    end)
end

local function isInsideOwnGui(inst)
    local anc = inst.Parent
    while anc do
        if anc.Name == "VipFullFarm" then return true end
        anc = anc.Parent
    end
    return false
end

local function isActuallyVisible(inst)
    local anc = inst
    while anc and anc ~= game do
        if anc:IsA("GuiObject") and not anc.Visible then return false end
        if anc:IsA("ScreenGui") and not anc.Enabled then return false end
        anc = anc.Parent
    end
    return true
end

local STORE_TEXTS = {"store", "store fruit", "lưu trữ", "luu tru"}

local function buttonHasStoreText(btn)
    local function txtMatch(s)
        s = tostring(s or ""):lower()
        for _, k in ipairs(STORE_TEXTS) do
            if string.find(s, k, 1, true) then return true end
        end
        return false
    end

    if txtMatch(btn.Name) then return true end

    local okSelf, selfText = pcall(function() return btn.Text end)
    if okSelf and txtMatch(selfText) then return true end

    for _, d in pairs(btn:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            local ok, t = pcall(function() return d.Text end)
            if ok and txtMatch(t) then return true end
        end
    end
    return false
end

local function collectStoreButtons(root)
    local found = {}
    if not root then return found end
    pcall(function()
        for _, btn in pairs(root:GetDescendants()) do
            if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and not isInsideOwnGui(btn) then
                if isActuallyVisible(btn) and buttonHasStoreText(btn) then
                    table.insert(found, btn)
                end
            end
        end
    end)
    return found
end

local function findNewStoreButton(beforeSet)
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local buttons = collectStoreButtons(pGui)

    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui and hui ~= pGui then
            for _, b in ipairs(collectStoreButtons(hui)) do
                table.insert(buttons, b)
            end
        end
    end

    for _, btn in ipairs(buttons) do
        if not beforeSet[btn] then return btn end
    end
    return buttons[1]
end

local function performStoreAction(tool)
    local char = getCharacter()
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    local commF = rem and (rem:FindFirstChild("CommF_") or rem:FindFirstChild("CommF"))
    local fruitId = getStandardFruitId(tool)
    local origName = fruitId
    pcall(function()
        local attr = tool:GetAttribute("OriginalName")
        if type(attr) == "string" and attr ~= "" then origName = attr end
    end)

    local function fireStoreRemotes(targetTool)
        if not commF then return end
        task.spawn(function() pcall(function() commF:InvokeServer("StoreFruit", origName, targetTool) end) end)
        task.spawn(function() pcall(function() commF:InvokeServer("StoreFruit", origName) end) end)
        task.spawn(function() pcall(function() commF:InvokeServer("StoreFruit", fruitId, targetTool) end) end)
    end

    pcall(function()
        if hum then hum:UnequipTools() end
    end)
    task.wait(0.12)

    for burst = 1, 4 do
        if not isFruitStillInHandsOrBackpack(tool) then return end
        local backTool = LocalPlayer.Backpack:FindFirstChild(tool.Name)
        fireStoreRemotes(backTool or tool)
        task.wait(0.18)
    end

    if not isFruitStillInHandsOrBackpack(tool) then return end

    local beforeSet = {}
    for _, btn in ipairs(collectStoreButtons(LocalPlayer:FindFirstChild("PlayerGui"))) do
        beforeSet[btn] = true
    end

    pcall(function()
        if hum then hum:EquipTool(tool) end
    end)
    task.wait(0.12)
    pcall(function() tool:Activate() end)
    tapScreenOnce()
    task.wait(0.3)

    local storeBtn = findNewStoreButton(beforeSet)
    if storeBtn then
        triggerUiButtonClick(storeBtn)
        task.wait(0.22)
    end

    fireStoreRemotes(tool)
    task.wait(0.15)

    pcall(function()
        if hum then hum:UnequipTools() end
    end)
end

local function storeAllFruitsUntilDone()
    local char = getCharacter()
    local function getRemainingFruits()
        local list = {}
        for _, t in pairs(LocalPlayer.Backpack:GetChildren()) do
            if t:IsA("Tool") and (t:FindFirstChild("EatRemote", true) or string.find(t.Name:lower(), "fruit")) then
                table.insert(list, t)
            end
        end
        if char then
            for _, t in pairs(char:GetChildren()) do
                if t:IsA("Tool") and (t:FindFirstChild("EatRemote", true) or string.find(t.Name:lower(), "fruit")) then
                    table.insert(list, t)
                end
            end
        end
        return list
    end

    local fruits = getRemainingFruits()
    if #fruits == 0 then return true, nil end

    for _, fruitTool in ipairs(fruits) do
        setStatus("⚡ Lưu trữ nhanh: " .. fruitTool.Name, Color3.fromRGB(255, 0, 128))
        local storedSuccess = false

        for attempt = 1, 6 do
            if not isFruitStillInHandsOrBackpack(fruitTool) then
                storedSuccess = true
                break
            end

            performStoreAction(fruitTool)
            if not isFruitStillInHandsOrBackpack(fruitTool) then
                storedSuccess = true
                break
            end
            task.wait(0.3)
        end

        if storedSuccess or not isFruitStillInHandsOrBackpack(fruitTool) then
            setStatus("✅ Đã cất: " .. fruitTool.Name, Color3.fromRGB(0, 255, 120))
            task.wait(0.5)
        else
            return false, fruitTool
        end
    end

    return true, nil
end

local function isRareFruit(toolName)
    for rareName, _ in pairs(CONFIG.RareFruits) do
        if string.find(toolName:lower(), rareName:lower()) then return true, rareName end
    end
    return false, nil
end

local VisitedJobIds = {}
VisitedJobIds[JobId] = os.time()

local function getPersistentVisited()
    local visited = {}
    pcall(function()
        if isfile and isfile(CONFIG.VisitedServersFile) then
            visited = HttpService:JSONDecode(readfile(CONFIG.VisitedServersFile))
        end
    end)
    return type(visited) == "table" and visited or {}
end

local function saveServerVisited(sId)
    VisitedJobIds[sId] = os.time()
    pcall(function()
        local list = getPersistentVisited()
        list[tostring(sId)] = os.time()
        local now = os.time()
        local cleaned = {}
        for id, ts in pairs(list) do
            if type(ts) == "number" and (now - ts) < 600 then cleaned[id] = ts end
        end
        if writefile then
            writefile(CONFIG.VisitedServersFile, HttpService:JSONEncode(cleaned))
        end
    end)
end

saveServerVisited(JobId)

local function fetchServersFromApi(apiUrl)
    local s, res = pcall(function()
        if request then
            return HttpService:JSONDecode(request({Url = apiUrl, Method = "GET"}).Body)
        elseif http_request then
            return HttpService:JSONDecode(http_request({Url = apiUrl, Method = "GET"}).Body)
        else
            return HttpService:JSONDecode(game:HttpGet(apiUrl))
        end
    end)
    if s and type(res) == "table" and res.data then return res end
    return nil
end

local function hopToRealNewServer()
    if STATE.IsHopping then return end
    STATE.IsHopping = true
    scriptActive = false

    setStatus("🔍 Đang tìm server MỚI...", Color3.fromRGB(0, 240, 255))
    saveServerVisited(JobId)
    setupAutoRestart()
    task.wait(0.3)

    local visitedLocal = getPersistentVisited()
    local candidateServers = {}
    local fallbackServers = {}
    local cursor = ""

    local apiBases = {
        "https://games.roproxy.com/v1/games/" .. PlaceId .. "/servers/Public?limit=100",
        "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?limit=100"
    }

    for _, baseEndpoint in ipairs(apiBases) do
        cursor = ""
        for page = 1, 4 do
            local fetchUrl = baseEndpoint .. (cursor ~= "" and ("&cursor=" .. cursor) or "")
            local result = fetchServersFromApi(fetchUrl)

            if result and result.data then
                for _, srv in ipairs(result.data) do
                    local sId = tostring(srv.id)
                    local playing = tonumber(srv.playing) or 0
                    local maxP = tonumber(srv.maxPlayers) or 12

                    if sId ~= JobId and playing >= 1 and playing < maxP - 1 then
                        if not VisitedJobIds[sId] and not visitedLocal[sId] then
                            table.insert(candidateServers, {
                                id = sId,
                                playing = playing,
                                maxPlayers = maxP
                            })
                        else
                            table.insert(fallbackServers, {
                                id = sId,
                                playing = playing,
                                maxPlayers = maxP
                            })
                        end
                    end
                end

                if #candidateServers >= 15 or not result.nextPageCursor then break end
                cursor = result.nextPageCursor
            else
                break
            end
            task.wait(0.2)
        end
        if #candidateServers >= 5 then break end
    end

    table.sort(candidateServers, function(a, b)
        return a.playing < b.playing
    end)

    if #candidateServers == 0 and #fallbackServers > 0 then
        table.sort(fallbackServers, function(a, b)
            return a.playing < b.playing
        end)
        candidateServers = fallbackServers
        pcall(function()
            if writefile then writefile(CONFIG.VisitedServersFile, "{}") end
            VisitedJobIds = {}
            VisitedJobIds[JobId] = os.time()
        end)
    end

    if #candidateServers > 0 then
        local chosen = candidateServers[1]
        setStatus(string.format("🚀 Nhảy server %d/%d người...", chosen.playing, chosen.maxPlayers), Color3.fromRGB(0, 255, 120))
        saveServerVisited(chosen.id)

        pcall(function()
            if antiAfkConn then
                antiAfkConn:Disconnect()
                antiAfkConn = nil
            end
            disableNoclip()
            if ScreenGui then ScreenGui.Enabled = false end
        end)
        task.wait(0.6)

        local tpSuccess = pcall(function()
            TeleportService:TeleportToPlaceInstance(PlaceId, chosen.id, LocalPlayer)
        end)

        if not tpSuccess then
            pcall(function()
                TeleportService:Teleport(PlaceId, LocalPlayer)
            end)
        end

        task.wait(25)
        STATE.IsHopping = false
        scriptActive = true
        pcall(function()
            if ScreenGui then ScreenGui.Enabled = true end
        end)
        task.spawn(hopToRealNewServer)
    else
        task.wait(3.5)
        STATE.IsHopping = false
        scriptActive = true
        task.spawn(hopToRealNewServer)
    end
end

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player == LocalPlayer then
        task.wait(6)
        STATE.IsHopping = false
        scriptActive = true
        pcall(function()
            if ScreenGui then ScreenGui.Enabled = true end
        end)
        task.spawn(hopToRealNewServer)
    end
end)

HopNowBtn.MouseButton1Click:Connect(function() task.spawn(hopToRealNewServer) end)
LargeHopBtn.MouseButton1Click:Connect(function() task.spawn(hopToRealNewServer) end)
HopQuickBtn.MouseButton1Click:Connect(function() task.spawn(hopToRealNewServer) end)

if CONFIG.EnableAdminDetector then
    for _, p in pairs(Players:GetPlayers()) do
        if checkIsAdmin(p) then
            task.spawn(function()
                setStatus("⚠️ PHÁT HIỆN ADMIN - ĐANG THOÁT!", Color3.fromRGB(255, 50, 50))
                hopToRealNewServer()
            end)
            break
        end
    end

    Players.PlayerAdded:Connect(function(p)
        if checkIsAdmin(p) then
            task.spawn(function()
                setStatus("⚠️ ADMIN VỪA VÀO - CHẠY TRỐN!", Color3.fromRGB(255, 50, 50))
                hopToRealNewServer()
            end)
        end
    end)
end

local function getCommF()
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    return rem and (rem:FindFirstChild("CommF_") or rem:FindFirstChild("CommF"))
end

local NetFolder = nil
local RE_RegisterAttack = nil
local RE_RegisterHit = nil
pcall(function()
    NetFolder = ReplicatedStorage:WaitForChild("Modules", 10) and ReplicatedStorage.Modules:WaitForChild("Net", 10)
    RE_RegisterAttack = NetFolder and NetFolder:WaitForChild("RE/RegisterAttack", 6)
    RE_RegisterHit = NetFolder and NetFolder:WaitForChild("RE/RegisterHit", 6)
end)

local function getSessionId()
    return tostring(LocalPlayer.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15)
end

local function fastAttackTick(targets)
    if not STATE.FastAttackOn then return end
    if not RE_RegisterHit then return end
    if RE_RegisterAttack then
        pcall(function() RE_RegisterAttack:FireServer(0) end)
    end
    local hitsRoots = {}
    local hitsTuples = {}
    for _, e in ipairs(targets) do
        local hrp = e:FindFirstChild("HumanoidRootPart")
        if hrp then
            table.insert(hitsRoots, hrp)
            table.insert(hitsTuples, {e, hrp})
        end
    end
    if #hitsRoots == 0 then return end
    local main = targets[1]
    local mainHrp = main:FindFirstChild("HumanoidRootPart")
    local head = main:FindFirstChild("Head")
    for i = 1, math.min(3, #hitsRoots) do
        pcall(function() RE_RegisterHit:FireServer(hitsRoots[i]) end)
    end
    if mainHrp then
        pcall(function() RE_RegisterHit:FireServer(mainHrp, hitsRoots) end)
    end
    if head then
        pcall(function() RE_RegisterHit:FireServer(head, hitsTuples, {}, getSessionId()) end)
    end
end

local function equipWeapon()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local current = char:FindFirstChildOfClass("Tool")
    if current then
        local ok, tip = pcall(function() return current.ToolTip end)
        if ok and tip == STATE.WeaponType then return end
    end
    for _, t in pairs(LocalPlayer.Backpack:GetChildren()) do
        if t:IsA("Tool") then
            pcall(function()
                if t.ToolTip == STATE.WeaponType then
                    hum:EquipTool(t)
                end
            end)
        end
    end
end

local function getQuestForLevel()
    local lv = 1
    pcall(function() lv = LocalPlayer.Data.Level.Value end)
    for _, q in ipairs(QUEST_DATA) do
        if lv >= q.MinLv and lv <= q.MaxLv then
            return q, lv
        end
    end
    return nil, lv
end

local function isQuestActive()
    local ok, vis = pcall(function()
        return LocalPlayer.PlayerGui.Main.Quest.Visible
    end)
    return (ok == true) and (vis == true)
end

local lastSpawnSet = 0
local function acceptQuestAndSpawn(q)
    local comm = getCommF()
    if not comm then return end
    if tick() - lastSpawnSet > 25 then
        lastSpawnSet = tick()
        pcall(function() comm:InvokeServer("SetSpawnPoint") end)
    end
    pcall(function() comm:InvokeServer("StartQuest", q.QuestName, q.QuestNum) end)
end

local EnemiesFolder = Workspace:FindFirstChild("Enemies")

local function getAliveEnemiesExact(fullName)
    local list = {}
    if not EnemiesFolder then
        EnemiesFolder = Workspace:FindFirstChild("Enemies")
        if not EnemiesFolder then return list end
    end
    for _, e in pairs(EnemiesFolder:GetChildren()) do
        if e.Name == fullName then
            local hum = e:FindFirstChildOfClass("Humanoid")
            local hrp = e:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                table.insert(list, e)
            end
        end
    end
    return list
end

local function nearestEnemy(list, fromPos)
    local best, bestD = nil, math.huge
    for _, e in ipairs(list) do
        local hrp = e:FindFirstChild("HumanoidRootPart")
        if hrp then
            local d = (hrp.Position - fromPos).Magnitude
            if d < bestD then
                best, bestD = e, d
            end
        end
    end
    return best
end

local farmTween = nil
local function hoverAbove(pointPos, yOffset, dur)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    enableNoclip()
    setHoldVelocity(hrp, true)
    local goal = CFrame.new(pointPos + Vector3.new(0, yOffset or 14, 0))
    pcall(function()
        if farmTween then farmTween:Cancel() end
        farmTween = TweenService:Create(hrp, TweenInfo.new(dur or 0.18, Enum.EasingStyle.Linear), {CFrame = goal})
        farmTween:Play()
    end)
end

local function magnetEnemies(pack, centerCF)
    if not STATE.BringMobOn then return end
    for i = 2, #pack do
        local e = pack[i]
        pcall(function()
            local hrp = e:FindFirstChild("HumanoidRootPart")
            local hum = e:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                hrp.CFrame = centerCF
                hrp.CanCollide = false
                hrp.Velocity = Vector3.zero
                hum.WalkSpeed = 0
                hum.JumpPower = 0
            end
        end)
    end
end

local function stopFly()
    flyCancelRequested = true
    pcall(function()
        if farmTween then farmTween:Cancel() end
        if activeFlyTween then activeFlyTween:Cancel() end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, t in pairs(hrp:GetChildren()) do
                if t:IsA("BodyVelocity") or t:IsA("BodyPosition") or t:IsA("BodyGyro") then
                    t:Destroy()
                end
            end
        end
    end)
    disableNoclip()
    setStatus("⏹️ Đã dừng bay", Color3.fromRGB(255, 200, 50))
end

local function farmCycle()
    local char = getCharacter()
    if not char then
        task.wait(2)
        return
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then
        task.wait(2)
        return
    end

    local q, lv = getQuestForLevel()
    if not q then
        setStatus("⚠️ Level " .. tostring(lv) .. " vượt bảng quest Sea 1 (cần Sea 2)", Color3.fromRGB(255, 200, 50))
        task.wait(5)
        return
    end

    pcall(function()
        ValFarmQuest.Text = q.QuestLabel .. " (" .. q.QuestName .. ")"
    end)

    if not isQuestActive() then
        setStatus("📜 Bay nhận quest: " .. q.QuestLabel, Color3.fromRGB(0, 240, 255))
        safeFlyTo(q.QuestPos + Vector3.new(0, 6, 0))
        if not STATE.AutoFarmLevel then return end
        acceptQuestAndSpawn(q)
        task.wait(0.7)
        return
    end

    local enemies = getAliveEnemiesExact(q.MobFullName)
    if #enemies == 0 then
        setStatus("⏳ Đợi quái spawn: " .. q.MobFullName, Color3.fromRGB(255, 200, 50))
        hoverAbove(q.MonPos, 32, 0.4)
        task.wait(1.2)
        return
    end

    local target = nearestEnemy(enemies, hrp.Position)
    local thrp = target and target:FindFirstChild("HumanoidRootPart")
    local thum = target and target:FindFirstChildOfClass("Humanoid")
    if not thrp or not thum then
        task.wait(0.5)
        return
    end

    local dist = (thrp.Position - hrp.Position).Magnitude
    if dist > 70 then
        setStatus("✈️ Bay tới: " .. q.MobFullName, Color3.fromRGB(0, 240, 255))
        safeFlyTo(thrp.Position + Vector3.new(0, 15, 0))
        if not STATE.AutoFarmLevel then return end
    end

    equipWeapon()
    setStatus("⚔️ Đang đánh: " .. q.MobFullName, Color3.fromRGB(0, 255, 140))
    pcall(function()
        ValFarmTarget.Text = q.MobFullName
    end)

    local deadline = tick() + 30
    while STATE.AutoFarmLevel and target and target.Parent do
        local okHum = pcall(function() return thum.Health end)
        if not okHum or thum.Health <= 0 then break end
        if tick() > deadline then break end
        if not thrp.Parent then break end

        char = LocalPlayer.Character
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then break end

        hoverAbove(thrp.Position, 14, 0.18)

        local pack = {}
        for _, e in ipairs(getAliveEnemiesExact(q.MobFullName)) do
            local eh = e:FindFirstChild("HumanoidRootPart")
            if eh and (eh.Position - hrp.Position).Magnitude <= 55 then
                table.insert(pack, e)
            end
            if #pack >= 6 then break end
        end
        if #pack == 0 then
            break
        end

        magnetEnemies(pack, CFrame.new(thrp.Position))
        fastAttackTick(pack)
        task.wait(0.13)
    end

    pcall(function()
        setHoldVelocity(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"), false)
    end)
end

local function bossCycle()
    local sel = STATE.SelectedBoss
    local bData = BOSS_BY_NAME[sel]
    if not bData then
        task.wait(2)
        return
    end

    local found = nil
    if not EnemiesFolder then
        EnemiesFolder = Workspace:FindFirstChild("Enemies")
    end
    if EnemiesFolder then
        for _, e in pairs(EnemiesFolder:GetChildren()) do
            if string.find(e.Name, sel, 1, true) then
                local hum = e:FindFirstChildOfClass("Humanoid")
                local hrp = e:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    found = e
                    break
                end
            end
        end
    end

    if not found then
        pcall(function() ValBossInfo.Text = "⏳ Chờ " .. sel .. " spawn..." end)
        hoverAbove(bData.Anchor, 40, 0.5)
        task.wait(2)
        return
    end

    pcall(function() ValBossInfo.Text = "⚔️ Đang đánh " .. sel end)
    setStatus("👹 Đang farm boss: " .. sel, Color3.fromRGB(255, 0, 128))
    equipWeapon()

    local thrp = found:FindFirstChild("HumanoidRootPart")
    local thum = found:FindFirstChildOfClass("Humanoid")
    if not thrp or not thum then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and (thrp.Position - hrp.Position).Magnitude > 70 then
        safeFlyTo(thrp.Position + Vector3.new(0, 16, 0))
        if not STATE.AutoFarmBoss then return end
    end

    local deadline = tick() + 60
    while STATE.AutoFarmBoss and found and found.Parent do
        local okHum = pcall(function() return thum.Health end)
        if not okHum or thum.Health <= 0 then break end
        if tick() > deadline then break end
        if not thrp.Parent then break end

        char = LocalPlayer.Character
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then break end

        hoverAbove(thrp.Position, 15, 0.18)
        fastAttackTick({found})
        task.wait(0.13)
    end

    pcall(function()
        setHoldVelocity(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"), false)
    end)
end

task.spawn(function()
    while true do
        if STATE.AutoFarmLevel and scriptActive and not STATE.IsHopping and not STATE.FruitSniperOn then
            local ok = pcall(farmCycle)
            if not ok then
                pcall(function()
                    setHoldVelocity(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"), false)
                    disableNoclip()
                end)
                task.wait(1.5)
            end
        else
            task.wait(0.8)
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if STATE.AutoFarmBoss and scriptActive and not STATE.IsHopping and not STATE.FruitSniperOn then
            local ok = pcall(bossCycle)
            if not ok then
                pcall(function()
                    setHoldVelocity(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"), false)
                    disableNoclip()
                end)
                task.wait(1.5)
            end
        else
            task.wait(0.8)
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if STATE.AutoBuso then
            pcall(function()
                local comm = getCommF()
                if comm then
                    comm:InvokeServer("Buso")
                end
            end)
            task.wait(5)
        else
            task.wait(1)
        end
    end
end)

task.spawn(function()
    while true do
        if STATE.AutoStatsOn then
            pcall(function()
                local pts = LocalPlayer.Data.Points.Value
                if pts > 0 then
                    local comm = getCommF()
                    if comm then
                        comm:InvokeServer("AddPoint", STATE.StatToAdd, math.min(3, pts))
                    end
                end
            end)
            task.wait(0.5)
        else
            task.wait(1)
        end
    end
end)

task.spawn(function()
    while true do
        pcall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                if STATE.WalkSpeedV and STATE.WalkSpeedV ~= 16 then
                    hum.WalkSpeed = STATE.WalkSpeedV
                end
                if STATE.JumpPowerV and STATE.JumpPowerV ~= 50 then
                    hum.JumpPower = STATE.JumpPowerV
                end
            end
        end)
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        pcall(function()
            ValLv.Text = tostring(LocalPlayer.Data.Level.Value)
            ValPoints.Text = tostring(LocalPlayer.Data.Points.Value)
            ValBeli.Text = tostring(LocalPlayer.Data.Beli.Value)
            local okF, frag = pcall(function() return LocalPlayer.Data.Fragments.Value end)
            ValFrag.Text = okF and tostring(frag) or "0"
        end)
        task.wait(1.5)
    end
end)

RunService.Stepped:Connect(function()
    if STATE.MiscNoclip then
        pcall(function()
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end
end)

task.spawn(function()
    while true do
        if STATE.PlayerESPOn then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    pcall(function()
                        local head = p.Character and p.Character:FindFirstChild("Head")
                        if head and not head:FindFirstChild("FF_ESP") then
                            local bill = Instance.new("BillboardGui")
                            bill.Name = "FF_ESP"
                            bill.Adornee = head
                            bill.Size = UDim2.new(0, 180, 0, 40)
                            bill.StudsOffset = Vector3.new(0, 3, 0)
                            bill.AlwaysOnTop = true
                            bill.Parent = head
                            local tl = Instance.new("TextLabel")
                            tl.Size = UDim2.new(1, 0, 1, 0)
                            tl.BackgroundTransparency = 1
                            tl.TextColor3 = Color3.fromRGB(255, 255, 255)
                            tl.TextStrokeTransparency = 0
                            tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            tl.TextSize = 12
                            tl.Font = Enum.Font.GothamBold
                            tl.Parent = bill
                            task.spawn(function()
                                while bill and bill.Parent and head and head.Parent do
                                    local d = 0
                                    pcall(function()
                                        d = math.floor((head.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                                    end)
                                    tl.Text = p.Name .. " [" .. tostring(d) .. " m]"
                                    task.wait(0.5)
                                end
                            end)
                        end
                    end)
                end
            end
        else
            for _, p in pairs(Players:GetPlayers()) do
                pcall(function()
                    local head = p.Character and p.Character:FindFirstChild("Head")
                    local b = head and head:FindFirstChild("FF_ESP")
                    if b then b:Destroy() end
                end)
            end
        end
        task.wait(2)
    end
end)

local function fpsBoost()
    pcall(function()
        local l = game:GetService("Lighting")
        local t = Workspace.Terrain
        t.WaterWaveSize = 0
        t.WaterWaveSpeed = 0
        t.WaterReflectance = 0
        t.WaterTransparency = 0
        l.GlobalShadows = false
        l.FogEnd = 9e9
        l.Brightness = 0
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
                pcall(function() v.Material = Enum.Material.Plastic v.Reflectance = 0 end)
            elseif v:IsA("Decal") or v:IsA("Texture") then
                pcall(function() v.Transparency = 1 end)
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                pcall(function() v.Lifetime = NumberRange.new(0) end)
            elseif v:IsA("Explosion") then
                pcall(function() v.BlastPressure = 1 v.BlastRadius = 1 end)
            elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
                pcall(function() v.Enabled = false end)
            end
        end
        for _, e in pairs(l:GetChildren()) do
            if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
                pcall(function() e.Enabled = false end)
            end
        end
        setStatus("🚀 FPS Boost hoàn tất!", Color3.fromRGB(0, 255, 120))
    end)
end

BossScanBtn.MouseButton1Click:Connect(function()
    local foundPos = nil
    if EnemiesFolder then
        for _, e in pairs(EnemiesFolder:GetChildren()) do
            if string.find(e.Name, STATE.SelectedBoss, 1, true) then
                local h = e:FindFirstChild("HumanoidRootPart")
                if h then
                    foundPos = h.Position
                    break
                end
            end
        end
    end
    if foundPos then
        pcall(function() ValBossInfo.Text = "✅ ĐÃ SPAWN! Bay tới..." end)
        task.spawn(function()
            safeFlyTo(foundPos + Vector3.new(0, 16, 0))
        end)
    else
        pcall(function() ValBossInfo.Text = "❌ Chưa spawn trong map" end)
    end
end)

for i, btn in ipairs(TeleButtons) do
    btn.MouseButton1Click:Connect(function()
        task.spawn(function()
            setStatus("✈️ Bay tới " .. ISLAND_TP[i][1], Color3.fromRGB(0, 240, 255))
            safeFlyTo(ISLAND_TP[i][2] + Vector3.new(0, 10, 0))
        end)
    end)
end

StopFlyBtn.MouseButton1Click:Connect(function()
    stopFly()
end)

FpsBoostBtn.MouseButton1Click:Connect(function()
    task.spawn(fpsBoost)
end)

Fps30Btn.MouseButton1Click:Connect(function()
    pcall(function() setfpscap(30) end)
    setStatus("📉 Đã giới hạn 30 FPS - mượt & mát máy", Color3.fromRGB(0, 255, 120))
end)

Fps60Btn.MouseButton1Click:Connect(function()
    pcall(function() setfpscap(60) end)
    setStatus("📈 Đã giới hạn 60 FPS", Color3.fromRGB(0, 255, 120))
end)

RejoinBtn.MouseButton1Click:Connect(function()
    pcall(function()
        TeleportService:Teleport(PlaceId, LocalPlayer)
    end)
end)

AddAllBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local pts = LocalPlayer.Data.Points.Value
        if pts > 0 then
            local comm = getCommF()
            if comm then
                comm:InvokeServer("AddPoint", STATE.StatToAdd, pts)
                setStatus("📊 Đã cộng " .. tostring(pts) .. " điểm vào " .. STATE.StatToAdd, Color3.fromRGB(0, 255, 120))
            end
        else
            setStatus("⚠️ Không có điểm khả dụng", Color3.fromRGB(255, 200, 50))
        end
    end)
end)

for i, btn in ipairs(ShopButtons) do
    btn.MouseButton1Click:Connect(function()
        pcall(function()
            local comm = getCommF()
            if comm then
                comm:InvokeServer(unpack(SHOP_ACTIONS[i][2]))
                setStatus("🛒 Đã mua: " .. SHOP_ACTIONS[i][1], Color3.fromRGB(0, 255, 120))
            end
        end)
    end)
end

GachaBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local comm = getCommF()
        if comm then
            comm:InvokeServer("Cousin", "Buy")
            comm:InvokeServer("BuyFruit")
            setStatus("🎲 Đã quay trái ngẫu nhiên!", Color3.fromRGB(0, 255, 120))
        end
    end)
end)

local function runFruitHunter()
    while STATE.IsPaused do task.wait(1) end

    while not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) do
        autoSelectTeam()
        task.wait(1)
    end
    task.wait(0.5)

    setStatus("🔍 Đang quét trái ác quỷ THẬT...", Color3.fromRGB(0, 240, 255))
    task.wait(0.8)

    local realFruits = findSpawnedFruits()

    if #realFruits > 0 then
        for _, fruitData in ipairs(realFruits) do
            if STATE.IsPaused then break end
            pcall(function()
                pickFruitProperly(fruitData)
            end)
            task.wait(0.4)
        end

        local success, failedTool = storeAllFruitsUntilDone()

        if success then
            setStatus("✅ Đã cất vào kho đồ! Đang nhảy server...", Color3.fromRGB(0, 255, 120))
            task.wait(1.5)
        else
            if failedTool then
                local isRare, rareName = isRareFruit(failedTool.Name)
                if isRare and CONFIG.DuplicateHandling == "StopIfRare" then
                    setStatus("⚠️ TRÙNG TRÁI QUÝ - ĐÃ DỪNG LẠI!", Color3.fromRGB(255, 50, 50))
                    return
                else
                    pcall(function()
                        failedTool.Parent = LocalPlayer.Character
                        task.wait(0.2)
                        if failedTool:FindFirstChild("EatRemote") then
                            failedTool.EatRemote:InvokeServer("Drop")
                        end
                    end)
                end
            end
        end
    else
        updateFruitDisplay(nil)
        setStatus("Không có trái spawn, chuẩn bị nhảy server...", Color3.fromRGB(255, 200, 50))
        task.wait(CONFIG.NoFruitHopDelay)
    end

    if not STATE.IsPaused then
        task.wait(0.5)
        hopToRealNewServer()
    end
end

task.spawn(function()
    while true do
        if STATE.FruitSniperOn then
            local ok, err = pcall(runFruitHunter)
            if not ok then
                task.wait(3)
            else
                STATE.FruitSniperOn = false
                setStatus("🍎 Fruit Sniper hoàn tất chu kỳ", Color3.fromRGB(0, 255, 140))
            end
        end
        task.wait(1)
    end
end)
