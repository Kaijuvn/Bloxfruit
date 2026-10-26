repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

repeat task.wait() until LocalPlayer:FindFirstChild("PlayerGui")

local CONFIG = {
    GitHubRawURL = (getgenv and getgenv().FruitSniperURL) or _G.FruitSniperURL or "",
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
        ["Sound"] = true, ["Phoenix"] = true, ["Quake"] = true
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

local function setupAutoRestart()
    local restartCode = [[
        repeat task.wait() until game:IsLoaded()
        task.wait(2)
        if getgenv and getgenv().FruitSniperURL and getgenv().FruitSniperURL ~= "" then
            pcall(function() loadstring(game:HttpGet(getgenv().FruitSniperURL))() end)
        elseif isfile and isfile("FruitSniper_Auto.lua") then
            pcall(function() loadstring(readfile("FruitSniper_Auto.lua"))() end)
        elseif isfile and isfile("FruitSniper.lua") then
            pcall(function() loadstring(readfile("FruitSniper.lua"))() end)
        end
    ]]
    pcall(function() if syn and syn.queue_on_teleport then syn.queue_on_teleport(restartCode) end end)
    pcall(function() if queue_on_teleport then queue_on_teleport(restartCode) end end)
    pcall(function() if queueonteleport then queueonteleport(restartCode) end end)
    pcall(function() if fluxus and fluxus.queue_on_teleport then fluxus.queue_on_teleport(restartCode) end end)
end

pcall(function()
    local hook = hookmetamethod or (syn and syn.hook_metamethod)
    local getNamecall = getnamecallmethod or (syn and syn.getnamecallmethod)
    local checkCaller = checkcaller or (syn and syn.checkcaller) or function() return false end
    local newClosure = newcclosure or function(f) return f end

    if hook and getNamecall then
        local oldNamecall
        oldNamecall = hook(game, "__namecall", newClosure(function(self, ...)
            local method = getNamecall()
            if not checkCaller() then
                if (method == "Kick" or method == "kick") and self == LocalPlayer then
                    return nil
                end
                if method == "FireServer" or method == "InvokeServer" then
                    local rName = tostring(self.Name):lower()
                    if string.find(rName, "ban") or string.find(rName, "report") or string.find(rName, "cheat") or string.find(rName, "telemetry") then
                        return nil
                    end
                end
            end
            return oldNamecall(self, ...)
        end))
    end
end)

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

task.spawn(function()
    while true do
        task.wait(60)
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
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
    if gethui then return gethui() end
    local s, g = pcall(function() return CoreGui end)
    if s and g then return g end
    return LocalPlayer:WaitForChild("PlayerGui")
end

pcall(function()
    local old = getGuiParent():FindFirstChild("VipAnimeFruitSniper")
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VipAnimeFruitSniper"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = getGuiParent()

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 480, 0, 290)
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

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 2
MainStroke.Color = Color3.fromRGB(0, 240, 255)
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

local StrokeGradient = Instance.new("UIGradient")
StrokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 215, 0)),
    ColorSequenceKeypoint.new(0.35, Color3.fromRGB(0, 240, 255)),
    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 0, 128)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 215, 0))
})
StrokeGradient.Rotation = 45
StrokeGradient.Parent = MainStroke

task.spawn(function()
    while true do
        for rot = 0, 360, 2 do
            StrokeGradient.Rotation = rot
            task.wait(0.04)
        end
    end
end)

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
CrownTitle.Size = UDim2.new(0, 260, 1, 0)
CrownTitle.Position = UDim2.new(0, 14, 0, 0)
CrownTitle.BackgroundTransparency = 1
CrownTitle.Text = "👑 CYBER VIP HUB | ULTIMATE SNIPER"
CrownTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
CrownTitle.TextSize = 13
CrownTitle.Font = Enum.Font.GothamBold
CrownTitle.TextXAlignment = Enum.TextXAlignment.Left
CrownTitle.ZIndex = 4
CrownTitle.Parent = TopBar

local VipBadge = Instance.new("TextLabel")
VipBadge.Name = "VipBadge"
VipBadge.Size = UDim2.new(0, 95, 0, 20)
VipBadge.Position = UDim2.new(1, -145, 0, 11)
VipBadge.BackgroundColor3 = Color3.fromRGB(25, 32, 58)
VipBadge.BackgroundTransparency = 0.2
VipBadge.Text = "★ LIFETIME VIP ★"
VipBadge.TextColor3 = Color3.fromRGB(0, 240, 255)
VipBadge.TextSize = 9
VipBadge.Font = Enum.Font.GothamBold
VipBadge.ZIndex = 4
VipBadge.Parent = TopBar

local BadgeCorner = Instance.new("UICorner")
BadgeCorner.CornerRadius = UDim.new(0, 6)
BadgeCorner.Parent = VipBadge

local MinBtn = Instance.new("TextButton")
MinBtn.Name = "MinBtn"
MinBtn.Size = UDim2.new(0, 26, 0, 26)
MinBtn.Position = UDim2.new(1, -34, 0, 8)
MinBtn.BackgroundColor3 = Color3.fromRGB(22, 28, 50)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(0, 240, 255)
MinBtn.TextSize = 15
MinBtn.Font = Enum.Font.GothamBold
MinBtn.ZIndex = 4
MinBtn.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = MinBtn

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
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 215, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 240, 255)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 0, 128))
})
FloatStrokeGrad.Rotation = 45
FloatStrokeGrad.Parent = FloatStroke

task.spawn(function()
    while true do
        for rot = 0, 360, 4 do
            FloatStrokeGrad.Rotation = rot
            task.wait(0.04)
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

local TabsList = Instance.new("Frame")
TabsList.Name = "TabsList"
TabsList.Size = UDim2.new(1, -12, 1, -50)
TabsList.Position = UDim2.new(0, 6, 0, 46)
TabsList.BackgroundTransparency = 1
TabsList.ZIndex = 4
TabsList.Parent = SideBar

local function createTabBtn(text, yPos, isDefault)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.Position = UDim2.new(0, 0, 0, yPos)
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

local TabBtnStatus, StrokeStatus = createTabBtn("🛰️ Trạng Thái", 0, true)
local TabBtnConfig, StrokeConfig = createTabBtn("⚙️ Cài Đặt", 38, false)
local TabBtnHop, StrokeHop = createTabBtn("🚀 Server Hop", 76, false)
local TabBtnTheme, StrokeTheme = createTabBtn("🎨 Hình Nền", 114, false)

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

createSettingRow("🏴‍☠️ Tự Chọn Phe:", CONFIG.Team, 44, function(btn)
    CONFIG.Team = (CONFIG.Team == "Pirates") and "Marines" or "Pirates"
    btn.Text = CONFIG.Team
end)

createSettingRow("💎 Trùng Kho:", "Bảo Vệ Trái", 88, function(btn)
    if CONFIG.DuplicateHandling == "StopIfRare" then
        CONFIG.DuplicateHandling = "Drop"
        btn.Text = "Tự Thả (Drop)"
    else
        CONFIG.DuplicateHandling = "StopIfRare"
        btn.Text = "Bảo Vệ Trái"
    end
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

local function switchTab(tabName)
    PageStatus.Visible = (tabName == "Status")
    PageConfig.Visible = (tabName == "Config")
    PageHop.Visible = (tabName == "Hop")
    PageTheme.Visible = (tabName == "Theme")

    StrokeStatus.Color = (tabName == "Status") and Color3.fromRGB(0, 240, 255) or Color3.fromRGB(35, 45, 80)
    StrokeConfig.Color = (tabName == "Config") and Color3.fromRGB(0, 240, 255) or Color3.fromRGB(35, 45, 80)
    StrokeHop.Color = (tabName == "Hop") and Color3.fromRGB(0, 240, 255) or Color3.fromRGB(35, 45, 80)
    StrokeTheme.Color = (tabName == "Theme") and Color3.fromRGB(0, 240, 255) or Color3.fromRGB(35, 45, 80)
end

TabBtnStatus.MouseButton1Click:Connect(function() switchTab("Status") end)
TabBtnConfig.MouseButton1Click:Connect(function() switchTab("Config") end)
TabBtnHop.MouseButton1Click:Connect(function() switchTab("Hop") end)
TabBtnTheme.MouseButton1Click:Connect(function() switchTab("Theme") end)

local function makeDraggable(targetFrame, dragHandle)
    local dragging, dragInput, dragStart, startPos
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
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
            targetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

makeDraggable(MainFrame, TopBar)
makeDraggable(FloatingBtn, FloatingBtn)

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatingBtn.Visible = true
end)

FloatingBtn.MouseButton1Click:Connect(function()
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
    ValAction.Text = text
    if color then ValAction.TextColor3 = color end
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

local function autoSelectTeam()
    pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("SetTeam", CONFIG.Team)
    end)
    pcall(function()
        local pGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if pGui and pGui:FindFirstChild("Main") and pGui.Main:FindFirstChild("ChooseTeam") and pGui.Main.ChooseTeam.Visible then
            local teamBtn = pGui.Main.ChooseTeam.Container[CONFIG.Team].Frame.ViewportFrame.TextButton
            if getconnections then
                for _, conn in pairs(getconnections(teamBtn.MouseButton1Click)) do pcall(function() conn:Fire() end) end
            end
        end
    end)
end

autoSelectTeam()
task.wait(1.2)

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

local function safeFlyTo(targetPos)
    local char = getCharacter()
    local hrp = char:WaitForChild("HumanoidRootPart")

    enableNoclip()
    setHoldVelocity(hrp, true)

    local startPos = hrp.Position
    local safeY = math.max(targetPos.Y + 25, 60)

    if startPos.Y < safeY and (Vector3.new(startPos.X, 0, startPos.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude > 100 then
        local upCF = CFrame.new(startPos.X, safeY, startPos.Z)
        local tUp = TweenService:Create(hrp, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {CFrame = upCF})
        tUp:Play()
        tUp.Completed:Wait()
    end

    local skyTarget = Vector3.new(targetPos.X, safeY, targetPos.Z)
    local distHoriz = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude

    if distHoriz > 15 then
        local durHoriz = math.clamp(distHoriz / CONFIG.FlySpeed, 0.4, 30)
        local currentTween = TweenService:Create(hrp, TweenInfo.new(durHoriz, Enum.EasingStyle.Linear), {CFrame = CFrame.new(skyTarget)})
        currentTween:Play()
        currentTween.Completed:Wait()
    end

    local landCF = CFrame.new(targetPos + Vector3.new(0, 1.2, 0))
    local landDist = (hrp.Position - landCF.Position).Magnitude
    local durLand = math.clamp(landDist / (CONFIG.FlySpeed * 0.8), 0.3, 3)

    local landTween = TweenService:Create(hrp, TweenInfo.new(durLand, Enum.EasingStyle.Linear), {CFrame = landCF})
    landTween:Play()
    landTween.Completed:Wait()

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
    for _, item in pairs(Workspace:GetChildren()) do
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
    return fruits
end

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
        if getconnections then
            for _, conn in pairs(getconnections(btn.MouseButton1Click)) do
                pcall(function() conn:Fire() end)
                pcall(function() if conn.Function then conn.Function() end end)
            end
            for _, conn in pairs(getconnections(btn.Activated)) do
                pcall(function() conn:Fire() end)
                pcall(function() if conn.Function then conn.Function() end end)
            end
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

local function performStoreAction(tool)
    local char = getCharacter()
    local hum = char:WaitForChild("Humanoid")
    local commF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
    local fruitId = getStandardFruitId(tool)
    local origName = tool:GetAttribute("OriginalName") or fruitId

    hum:EquipTool(tool)
    task.wait(0.2)

    pcall(function() tool:Activate() end)
    pcall(function()
        if VirtualInputManager then
            local center = Vector2.new(Workspace.CurrentCamera.ViewportSize.X / 2, Workspace.CurrentCamera.ViewportSize.Y / 2)
            VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 1)
            task.wait(0.03)
            VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)
        end
    end)
    task.wait(0.25)

    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        for _, btn in pairs(pGui:GetDescendants()) do
            if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                local bName = btn.Name:lower()
                local bText = tostring(btn.Text or ""):lower()
                local isStore = false

                if bText == "store" or bText == "lưu trữ" or string.find(bText, "store") or string.find(bText, "lưu trữ") or bName == "store" or bName == "option3" then
                    isStore = true
                else
                    local innerText = btn:FindFirstChildWhichIsA("TextLabel")
                    if innerText and innerText.Visible then
                        local iText = innerText.Text:lower()
                        if iText == "store" or iText == "lưu trữ" or string.find(iText, "store") or string.find(iText, "lưu trữ") then
                            isStore = true
                        end
                    end
                end

                if isStore then
                    triggerUiButtonClick(btn)
                    task.wait(0.15)
                    break
                end
            end
        end
    end

    pcall(function() commF:InvokeServer("StoreFruit", origName, tool) end)
    pcall(function() commF:InvokeServer("StoreFruit", origName, LocalPlayer.Backpack:FindFirstChild(tool.Name)) end)
    pcall(function() commF:InvokeServer("StoreFruit", origName) end)
    pcall(function() commF:InvokeServer("StoreFruit", fruitId, tool) end)
    pcall(function() commF:InvokeServer("StoreFruit", fruitId, LocalPlayer.Backpack:FindFirstChild(tool.Name)) end)
    pcall(function() commF:InvokeServer("StoreFruit", fruitId) end)
    pcall(function() commF:InvokeServer("StoreFruit", tool.Name, tool) end)
    pcall(function() commF:InvokeServer("StoreFruit", tool.Name) end)

    task.wait(0.2)
    pcall(function() hum:UnequipTools() end)
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
        setStatus("📦 Đang tự động lưu trữ: " .. fruitTool.Name, Color3.fromRGB(255, 0, 128))
        local storedSuccess = false

        for attempt = 1, 8 do
            if not isFruitStillInHandsOrBackpack(fruitTool) then
                storedSuccess = true
                break
            end

            performStoreAction(fruitTool)
            task.wait(0.6)
        end

        if not storedSuccess and isFruitStillInHandsOrBackpack(fruitTool) then
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
            if type(ts) == "number" and (now - ts) < 3600 then cleaned[id] = ts end
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

    setStatus("🔍 Đang tìm server MỚI (chống lặp lại)...", Color3.fromRGB(0, 240, 255))
    saveServerVisited(JobId)
    setupAutoRestart()
    task.wait(0.3)

    local visitedLocal = getPersistentVisited()
    local candidateServers = {}
    local cursor = ""

    local apiBases = {
        "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?limit=100",
        "https://games.roproxy.com/v1/games/" .. PlaceId .. "/servers/Public?limit=100"
    }

    for _, baseEndpoint in ipairs(apiBases) do
        cursor = ""
        for page = 1, 3 do
            local fetchUrl = baseEndpoint .. (cursor ~= "" and ("&cursor=" .. cursor) or "")
            local result = fetchServersFromApi(fetchUrl)

            if result and result.data then
                for _, srv in ipairs(result.data) do
                    local sId = tostring(srv.id)
                    local playing = tonumber(srv.playing) or 0
                    local maxP = tonumber(srv.maxPlayers) or 12

                    if sId ~= JobId and not VisitedJobIds[sId] and not visitedLocal[sId] then
                        if playing >= 1 and playing < maxP - 1 then
                            table.insert(candidateServers, {
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

    if #candidateServers > 0 then
        local chosen = candidateServers[1]
        setStatus(string.format("🚀 Nhảy server %d/%d người...", chosen.playing, chosen.maxPlayers), Color3.fromRGB(0, 255, 120))
        saveServerVisited(chosen.id)

        pcall(function()
            TeleportService:TeleportToPlaceInstance(PlaceId, chosen.id, LocalPlayer)
        end)

        task.wait(8)
        STATE.IsHopping = false
        hopToRealNewServer()
    else
        setStatus("⚠️ Đang tìm kiếm thêm server khác...", Color3.fromRGB(255, 200, 50))
        task.wait(1.5)
        STATE.IsHopping = false
        pcall(function()
            TeleportService:Teleport(PlaceId, LocalPlayer)
        end)
    end
end

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player == LocalPlayer then
        STATE.IsHopping = false
        task.wait(1)
        hopToRealNewServer()
    end
end)

HopNowBtn.MouseButton1Click:Connect(function() task.spawn(hopToRealNewServer) end)
LargeHopBtn.MouseButton1Click:Connect(function() task.spawn(hopToRealNewServer) end)

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

local function runFruitHunter()
    while STATE.IsPaused do task.wait(1) end

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
    pcall(runFruitHunter)
end)
