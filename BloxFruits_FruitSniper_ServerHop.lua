-- ==============================================================================
-- 👑 BLOX FRUITS - VIP CYBER ANIME FRUIT SNIPER & SERVER HOP (SELF-PERSISTENT) 👑
-- TỰ ĐỘNG LƯU BỘ NHỚ DELTA VÀ TỰ ĐỘNG CHẠY LẠI KHI QUA SERVER MỚI (AUTO QUEUE)
-- ==============================================================================

local SCRIPT_SOURCE = [==[
-- ==============================================================================
-- 👑 BLOX FRUITS - VIP CYBER ANIME FRUIT SNIPER & SERVER HOP (AUTO LOOP) 👑
-- PHIÊN BẢN VIP EDITION:
-- 1. Giao diện Menu Tiền VIP cực đẹp: Hình nền Anime nam ngầu, tab đa năng, gọn gàng
-- 2. Tự động cầm trái -> Nhấn để hiện menu -> Bấm "Lưu trữ" (Store) 100% tự động
-- 3. Xác nhận cất xong mới nhảy server, không bao giờ bay vội khi chưa cất đồ
-- 4. Tự động chạy lại script khi chuyển server (Auto Queue-on-teleport)
-- 5. Bay êm ái, chống văng biển, hiển thị tên trái MÀU TRẮNG + khoảng cách mét (m)
-- ==============================================================================

repeat task.wait() until game:IsLoaded()

-- Khai báo Roblox Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

-- ==============================================================================
-- CẤU HÌNH SCRIPT (CONFIG)
-- ==============================================================================
local CONFIG = {
    -- ĐIỀN LINK GITHUB RAW CỦA BẠN VÀO ĐÂY ĐỂ TỰ ĐỘNG CHẠY LẠI KHI ĐỔI SERVER:
    -- Ví dụ: "https://raw.githubusercontent.com/tenban/repo/main/FruitSniper.lua"
    GitHubRawURL = (getgenv and getgenv().FruitSniperURL) or _G.FruitSniperURL or "",

    Team = "Pirates",                 -- Phe tự chọn: "Pirates" (Hải tặc) hoặc "Marines" (Hải quân)
    FlySpeed = 160,                   -- Tốc độ bay (160 stud/s: Chậm êm, chống văng biển & giật lag)
    NoFruitHopDelay = 3,              -- Thời gian chờ nếu server không có trái thì nhảy server ngay
    VisitedServersFile = "BF_VisitedServers.json",

    -- XỬ LÝ KHI TRÙNG KHO ĐỒ:
    DuplicateHandling = "StopIfRare", -- "StopIfRare" (Bảo vệ trái quý), "Drop" (Vứt bỏ), "Ignore" (Bỏ qua)

    -- HÌNH NỀN ANIME NAM VIP:
    -- Gojo Satoru: "rbxassetid://14207920404"
    -- Sung Jin-Woo: "rbxassetid://16140502159"
    -- Zoro / Anime Boy: "rbxassetid://11401835376"
    BackgroundImage = "rbxassetid://14207920404", 
    BgTransparency = 0.62,

    -- Danh sách trái quý giá cần giữ lại tuyệt đối nếu trùng kho:
    RareFruits = {
        ["Kitsune"] = true, ["Dragon"] = true, ["Leopard"] = true, 
        ["Spirit"] = true, ["Control"] = true, ["Venom"] = true, 
        ["Shadow"] = true, ["Dough"] = true, ["T-Rex"] = true, 
        ["Mammoth"] = true, ["Gravity"] = true, ["Blizzard"] = true, 
        ["Pain"] = true, ["Portal"] = true, ["Buddha"] = true, 
        ["Sound"] = true, ["Phoenix"] = true, ["Quake"] = true
    },

    DiscordWebhook = ""
}

local STATE = {
    IsPaused = false,
    CurrentStatus = "Đang khởi động...",
    FruitName = "Chưa phát hiện",
    FruitDistance = 0,
    HasFruit = false,
    CurrentTab = "Status",
}

-- ==============================================================================
-- BẢNG MÃ HÓA ID TRÁI ÁC QUỶ CHUẨN CỦA BLOX FRUITS
-- ==============================================================================
local FRUIT_ID_MAP = {
    ["rocket"] = "Rocket-Rocket",
    ["spin"] = "Spin-Spin",
    ["blade"] = "Chop-Chop",
    ["chop"] = "Chop-Chop",
    ["spring"] = "Spring-Spring",
    ["bomb"] = "Bomb-Bomb",
    ["smoke"] = "Smoke-Smoke",
    ["spike"] = "Spike-Spike",
    ["flame"] = "Flame-Flame",
    ["falcon"] = "Bird-Bird: Falcon",
    ["ice"] = "Ice-Ice",
    ["sand"] = "Sand-Sand",
    ["dark"] = "Dark-Dark",
    ["diamond"] = "Diamond-Diamond",
    ["light"] = "Light-Light",
    ["rubber"] = "Rubber-Rubber",
    ["barrier"] = "Barrier-Barrier",
    ["ghost"] = "Ghost-Ghost",
    ["magma"] = "Magma-Magma",
    ["quake"] = "Quake-Quake",
    ["buddha"] = "Human-Human: Buddha",
    ["love"] = "Love-Love",
    ["spider"] = "String-String",
    ["sound"] = "Sound-Sound",
    ["phoenix"] = "Bird-Bird: Phoenix",
    ["portal"] = "Portal-Portal",
    ["rumble"] = "Rumble-Rumble",
    ["pain"] = "Paw-Paw",
    ["blizzard"] = "Blizzard-Blizzard",
    ["gravity"] = "Gravity-Gravity",
    ["mammoth"] = "Mammoth-Mammoth",
    ["t-rex"] = "T-Rex-T-Rex",
    ["trex"] = "T-Rex-T-Rex",
    ["dough"] = "Dough-Dough",
    ["shadow"] = "Shadow-Shadow",
    ["venom"] = "Venom-Venom",
    ["control"] = "Control-Control",
    ["spirit"] = "Spirit-Spirit",
    ["dragon"] = "Dragon-Dragon",
    ["leopard"] = "Leopard-Leopard",
    ["kitsune"] = "Kitsune-Kitsune",
    ["gas"] = "Gas-Gas",
    ["yeti"] = "Yeti-Yeti",
}

-- ==============================================================================
-- THIẾT KẾ GIAO DIỆN MENU TIỀN VIP (ANIME THEME + GLASSMORPHISM)
-- ==============================================================================
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

-- KHUNG CHÍNH (MAIN WINDOW 480x290 - GỌN GÀNG ĐẸP MẮT)
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

-- HÌNH NỀN ANIME NAM NGẦU (CÓ THỂ TÙY CHỌN ẢNH)
local AnimeBg = Instance.new("ImageLabel")
AnimeBg.Name = "AnimeBg"
AnimeBg.Size = UDim2.new(1, 0, 1, 0)
AnimeBg.Position = UDim2.new(0, 0, 0, 0)
AnimeBg.BackgroundTransparency = 1
AnimeBg.Image = CONFIG.BackgroundImage
AnimeBg.ImageTransparency = CONFIG.BgTransparency
AnimeBg.ScaleType = Enum.ScaleType.Crop
AnimeBg.ZIndex = 1
AnimeBg.Parent = MainFrame

-- Lớp phủ tối mờ (Dark Gradient Overlay để chữ luôn rõ nét 100%)
local DarkOverlay = Instance.new("Frame")
DarkOverlay.Name = "DarkOverlay"
DarkOverlay.Size = UDim2.new(1, 0, 1, 0)
DarkOverlay.BackgroundColor3 = Color3.fromRGB(10, 12, 22)
DarkOverlay.BackgroundTransparency = 0.35
DarkOverlay.BorderSizePixel = 0
DarkOverlay.ZIndex = 2
DarkOverlay.Parent = MainFrame

-- Viền phát quang phong cách VIP Gold / Neon Cyan
local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 2
MainStroke.Color = Color3.fromRGB(0, 240, 255)
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

local StrokeGradient = Instance.new("UIGradient")
StrokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 215, 0)), -- Gold VIP
    ColorSequenceKeypoint.new(0.35, Color3.fromRGB(0, 240, 255)), -- Neon Cyan
    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 0, 128)), -- Pink
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

-- THANH TIÊU ĐỀ TRÊN CÙNG (VIP HEADER)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 42)
TopBar.BackgroundColor3 = Color3.fromRGB(18, 22, 38)
TopBar.BackgroundTransparency = 0.25
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
CrownTitle.Text = "👑 CYBER VIP HUB | FRUIT SNIPER"
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
VipBadge.BackgroundColor3 = Color3.fromRGB(35, 42, 70)
VipBadge.BackgroundTransparency = 0.3
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
MinBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 58)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(0, 240, 255)
MinBtn.TextSize = 15
MinBtn.Font = Enum.Font.GothamBold
MinBtn.ZIndex = 4
MinBtn.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = MinBtn

-- NÚT THU NHỎ NỔI (FLOATING MINI ICON KHI THU GỌN MENU)
local FloatingPill = Instance.new("TextButton")
FloatingPill.Name = "FloatingPill"
FloatingPill.Size = UDim2.new(0, 85, 0, 32)
FloatingPill.Position = UDim2.new(0.08, 0, 0.15, 0)
FloatingPill.BackgroundColor3 = Color3.fromRGB(15, 18, 30)
FloatingPill.Text = "👑 VIP MENU"
FloatingPill.TextColor3 = Color3.fromRGB(255, 215, 0)
FloatingPill.TextSize = 11
FloatingPill.Font = Enum.Font.GothamBold
FloatingPill.Visible = false
FloatingPill.Parent = ScreenGui

local PillCorner = Instance.new("UICorner")
PillCorner.CornerRadius = UDim.new(0, 16)
PillCorner.Parent = FloatingPill

local PillStroke = Instance.new("UIStroke")
PillStroke.Thickness = 1.8
PillStroke.Color = Color3.fromRGB(0, 240, 255)
PillStroke.Parent = FloatingPill

-- CỘT BÊN TRÁI: SIDEBAR ĐIỀU HƯỚNG TABS
local SideBar = Instance.new("Frame")
SideBar.Name = "SideBar"
SideBar.Size = UDim2.new(0, 130, 1, -48)
SideBar.Position = UDim2.new(0, 8, 0, 44)
SideBar.BackgroundColor3 = Color3.fromRGB(18, 22, 38)
SideBar.BackgroundTransparency = 0.4
SideBar.BorderSizePixel = 0
SideBar.ZIndex = 3
SideBar.Parent = MainFrame

local SideCorner = Instance.new("UICorner")
SideCorner.CornerRadius = UDim.new(0, 10)
SideCorner.Parent = SideBar

-- THÔNG TIN AVATAR NGƯỜI CHƠI
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
UserRank.Text = "🟢 VIP Online"
UserRank.TextColor3 = Color3.fromRGB(0, 255, 140)
UserRank.TextSize = 9
UserRank.Font = Enum.Font.Gotham
UserRank.TextXAlignment = Enum.TextXAlignment.Left
UserRank.ZIndex = 4
UserRank.Parent = UserInfoFrame

-- CÁC NÚT TAB (TABS NAVIGATION)
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
    btn.BackgroundColor3 = isDefault and Color3.fromRGB(28, 38, 70) or Color3.fromRGB(20, 25, 45)
    btn.BackgroundTransparency = isDefault and 0.2 or 0.5
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

-- KHUNG NỘI DUNG BÊN PHẢI (RIGHT CONTENT AREA)
local MainContent = Instance.new("Frame")
MainContent.Name = "MainContent"
MainContent.Size = UDim2.new(1, -154, 1, -48)
MainContent.Position = UDim2.new(0, 146, 0, 44)
MainContent.BackgroundColor3 = Color3.fromRGB(16, 20, 35)
MainContent.BackgroundTransparency = 0.35
MainContent.BorderSizePixel = 0
MainContent.ZIndex = 3
MainContent.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 10)
ContentCorner.Parent = MainContent

-- TAB 1: TRẠNG THÁI (STATUS TAB)
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
    card.BackgroundColor3 = Color3.fromRGB(22, 28, 50)
    card.BackgroundTransparency = 0.4
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
    tag.TextColor3 = Color3.fromRGB(150, 180, 230)
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
local ValFruit = createInfoCard("🍎 Phát hiện:", "Chưa có trái spawn", 38)
local ValStore = createInfoCard("📦 Kho đồ:", "Tự động Lưu trữ", 76)
local ValServer = createInfoCard("🌐 Máy chủ:", string.format("%d/%d người chơi", #Players:GetPlayers(), Players.MaxPlayers), 114)

-- Hàng nút điều khiển nhanh (Pause & Hop)
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

-- TAB 2: CÀI ĐẶT (CONFIG TAB)
local PageConfig = Instance.new("Frame")
PageConfig.Name = "PageConfig"
PageConfig.Size = UDim2.new(1, -16, 1, -16)
PageConfig.Position = UDim2.new(0, 8, 0, 8)
PageConfig.BackgroundTransparency = 1
PageConfig.Visible = false
PageConfig.ZIndex = 4
PageConfig.Parent = MainContent

local function createSettingRow(title, valueText, yPos, callbackBtnText, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 36)
    f.Position = UDim2.new(0, 0, 0, yPos)
    f.BackgroundColor3 = Color3.fromRGB(22, 28, 50)
    f.BackgroundTransparency = 0.4
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
    btn.BackgroundColor3 = Color3.fromRGB(30, 40, 75)
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
        btn.MouseButton1Click:Connect(function()
            callback(btn)
        end)
    end
end

createSettingRow("⚡ Tốc Độ Bay:", "160 stud/s", 0, nil, function(btn)
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

createSettingRow("🏴‍☠️ Tự Chọn Phe:", CONFIG.Team, 44, nil, function(btn)
    CONFIG.Team = (CONFIG.Team == "Pirates") and "Marines" or "Pirates"
    btn.Text = CONFIG.Team
end)

createSettingRow("💎 Trùng Kho:", "Bảo Vệ Trái", 88, nil, function(btn)
    if CONFIG.DuplicateHandling == "StopIfRare" then
        CONFIG.DuplicateHandling = "Drop"
        btn.Text = "Tự Thả (Drop)"
    else
        CONFIG.DuplicateHandling = "StopIfRare"
        btn.Text = "Bảo Vệ Trái"
    end
end)

-- TAB 3: SERVER HOP
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
HopDesc.Text = "Hệ thống tự động tìm kiếm server có số lượng người chơi ít nhất (1 - 3 người) để tối ưu khả năng nhặt trái ác quỷ chưa bị ai lấy."
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
LargeHopBtn.Text = "🚀 BẮT ĐẦU NHẢY SERVER ÍT NGƯỜI NGAY"
LargeHopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LargeHopBtn.TextSize = 12
LargeHopBtn.Font = Enum.Font.GothamBold
LargeHopBtn.ZIndex = 5
LargeHopBtn.Parent = PageHop

local LCorner = Instance.new("UICorner")
LCorner.CornerRadius = UDim.new(0, 8)
LCorner.Parent = LargeHopBtn

-- TAB 4: HÌNH NỀN ANIME VIP (THEME CUSTOMIZER)
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
    b.BackgroundColor3 = Color3.fromRGB(25, 32, 58)
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
        CONFIG.BackgroundImage = imageId
    end)
end

createPresetBtn("Anime Nam: Gojo Satoru (JJK)", "rbxassetid://14207920404", 0)
createPresetBtn("Anime Nam: Sung Jin-Woo (Solo Leveling)", "rbxassetid://16140502159", 40)
createPresetBtn("Anime Nam: Zoro Ngầu (One Piece)", "rbxassetid://11401835376", 80)

-- CHUYỂN ĐỔI TAB (TAB CONTROLLER)
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

-- KÉO THẢ MENU (DRAGGABLE CHO CẢ MOBILE & PC)
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

-- THU GỌN / MỞ RỘNG MENU
MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatingPill.Visible = true
end)

FloatingPill.MouseButton1Click:Connect(function()
    FloatingPill.Visible = false
    MainFrame.Visible = true
end)

-- Tạm dừng / Tiếp tục
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

-- HIỂN THỊ TÊN TRÁI MÀU TRẮNG KÈM KHOẢNG CÁCH MÉT
local function updateFruitDisplay(fruitName, distance)
    if fruitName then
        STATE.FruitName = fruitName
        STATE.FruitDistance = distance or 0
        ValFruit.Text = string.format("%s - %d m", fruitName, distance or 0)
        ValFruit.TextColor3 = Color3.fromRGB(255, 255, 255) -- MÀU TRẮNG THEO YÊU CẦU
    else
        ValFruit.Text = "Không có trái spawn"
        ValFruit.TextColor3 = Color3.fromRGB(160, 170, 190)
    end
end

-- ==============================================================================
-- ANTI-BAN & CHỐNG AFK
-- ==============================================================================
local function setupAntiBan()
    pcall(function()
        local hook = hookmetamethod or (syn and syn.hook_metamethod)
        local getNamecall = getnamecallmethod or (syn and syn.getnamecallmethod)
        local checkCaller = checkcaller or (syn and syn.checkcaller)
        local newClosure = newcclosure or function(f) return f end

        if hook and getNamecall then
            local old
            old = hook(game, "__namecall", newClosure(function(self, ...)
                local method = getNamecall()
                local isSelf = checkCaller and checkCaller() or false

                if (method == "Kick" or method == "kick") and not isSelf then
                    if self == LocalPlayer then return nil end
                end

                if (method == "FireServer" or method == "InvokeServer") and not isSelf then
                    local rName = tostring(self.Name):lower()
                    if string.find(rName, "ban") or string.find(rName, "report") or string.find(rName, "cheat") or string.find(rName, "telemetry") then
                        return nil
                    end
                end

                return old(self, ...)
            end))
        end
    end)
end

setupAntiBan()

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local function autoSelectTeam()
    pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("SetTeam", CONFIG.Team)
    end)
    pcall(function()
        local pGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if pGui and pGui:FindFirstChild("Main") and pGui.Main:FindFirstChild("ChooseTeam") and pGui.Main.ChooseTeam.Visible then
            local teamBtn = pGui.Main.ChooseTeam.Container[CONFIG.Team].Frame.ViewportFrame.TextButton
            if getconnections then
                for _, conn in pairs(getconnections(teamBtn.MouseButton1Click)) do
                    conn.Function()
                end
            end
        end
    end)
end

autoSelectTeam()
task.wait(1.5)

local function getCharacter()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    char:WaitForChild("HumanoidRootPart", 10)
    char:WaitForChild("Humanoid", 10)
    return char
end

-- ==============================================================================
-- HỆ THỐNG NOCLIP & KHÓA VẬN TỐC (CHỐNG GIẬT LAG & CHỐNG TELE RA BIỂN)
-- ==============================================================================
local noclipConn = nil
local function enableNoclip()
    if noclipConn then return end
    noclipConn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
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

local currentTween = nil
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
        currentTween = TweenService:Create(hrp, TweenInfo.new(durHoriz, Enum.EasingStyle.Linear), {CFrame = CFrame.new(skyTarget)})
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

-- ==============================================================================
-- QUÉT VÀ HIỂN THỊ ESP TRÁI ÁC QUỶ (TÊN MÀU TRẮNG + SỐ MÉT)
-- ==============================================================================
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
        title.TextColor3 = Color3.fromRGB(255, 255, 255) -- MÀU TRẮNG
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


-- ==============================================================================
-- QUÉT VÀ KIỂM TRA TRÁI ÁC QUỶ THẬT (LOẠI BỎ TRIỆT ĐỂ TƯỢNG ĐÁ FRUIT1 / VẬT THỂ GIẢ)
-- ==============================================================================
local BLACKLISTED_OBJECTS = {}

local FAKE_FRUITS_BLACKLIST = {
    ["fruit1"] = true,
    ["fruit2"] = true,
    ["fruit3"] = true,
    ["fruit4"] = true,
    ["fruit5"] = true,
    ["fruit"] = true,
    ["fruitbowl"] = true,
    ["fruitbasket"] = true,
    ["fruittree"] = true,
    ["fruitdealer"] = true,
    ["fruitdealer_c"] = true,
    ["fruitbox"] = true,
    ["fruits"] = true,
    ["fruitstand"] = true,
    ["fruitspawner"] = true,
    ["fruitvendor"] = true,
}

local function isGenuineFruit(item)
    if not item or not item.Parent then return false end
    
    -- 1. BẮT BUỘC PHẢI LÀ CLASS "Tool"
    -- Trong Blox Fruits, trái ác quỷ thật nhặt được LUÔN LUÔN là Tool, KHÔNG BAO GIỜ là Model!
    -- Tất cả Model trong Workspace (như tượng đá Đấu Trường La Mã "Fruit1") sẽ bị loại bỏ 100%!
    if not item:IsA("Tool") then
        return false
    end
    
    local rawName = tostring(item.Name)
    local cleanName = rawName:lower():gsub("%s+", "")
    
    -- 2. LOẠI BỎ TẤT CẢ VẬT THỂ TƯỢNG ĐÁ, TRÁI CÂY TRANG TRÍ (Fruit1, Fruit2...)
    if FAKE_FRUITS_BLACKLIST[cleanName] or cleanName:match("^fruit%d+$") or rawName:match("%d+$") then
        return false
    end
    
    -- 3. BẮT BUỘC PHẢI CÓ HANDLE LÀ BASEPART
    local handle = item:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then
        return false
    end
    
    -- 4. KIỂM TRA ĐẶC ĐIỂM CỦA TRÁI ÁC QUỶ THẬT:
    -- Dấu hiệu A: Có EatRemote bên trong
    if item:FindFirstChild("EatRemote", true) then
        return true
    end
    
    -- Dấu hiệu B: Có thuộc tính OriginalName
    if item:GetAttribute("OriginalName") then
        return true
    end
    
    -- Dấu hiệu C: Tên kết thúc bằng " Fruit" hoặc "-Fruit"
    if rawName:match("%s+[Ff]ruit$") or rawName:match("%-[Ff]ruit$") then
        return true
    end
    
    -- Dấu hiệu D: Tên trái khớp với bảng FRUIT_ID_MAP chuẩn của Blox Fruits
    for fruitKey, _ in pairs(FRUIT_ID_MAP) do
        if cleanName:find(fruitKey) then
            return true
        end
    end
    
    return false
end

local function findSpawnedFruits()
    local fruits = {}
    for _, item in pairs(Workspace:GetChildren()) do
        if not BLACKLISTED_OBJECTS[item] and isGenuineFruit(item) then
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

-- ==============================================================================
-- NHẶT TRÁI CHUẨN XÁC VÀO TÚI (CÓ CƠ CHẾ CHỐNG GHIM VÀO TƯỢNG ĐÁ / TIMEOUT 3.5S)
-- ==============================================================================
local function pickFruitProperly(fruitData)
    if not fruitData or not fruitData.Object or not fruitData.Handle then return false end
    if BLACKLISTED_OBJECTS[fruitData.Object] then return false end
    
    local char = getCharacter()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")
    
    setStatus("🚀 Bay tới: " .. fruitData.Name, Color3.fromRGB(0, 240, 255))
    safeFlyTo(fruitData.Handle.Position)
    
    setStatus("🍎 Đang nhặt: " .. fruitData.Name, Color3.fromRGB(255, 0, 128))
    
    local touchPart = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or hrp
    local startTime = tick()
    local pickedSuccess = false
    
    -- Thử nhặt tối đa 3.5 giây. Nếu sau 3.5 giây không vào balo thì coi như vật thể lỗi/kẹt, KHÔNG BAO GIỜ GHIM LẠI!
    while (tick() - startTime < 3.5) do
        -- Đã rời Workspace (vào balo hoặc người khác lấy)
        if fruitData.Object.Parent ~= Workspace then
            pickedSuccess = true
            break
        end
        
        -- Đã vào balo hoặc đang cầm trên tay
        if LocalPlayer.Backpack:FindFirstChild(fruitData.Name) or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(fruitData.Name)) then
            pickedSuccess = true
            break
        end
        
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
        
        if fruitData.Object:IsA("Tool") then
            pcall(function()
                hum:EquipTool(fruitData.Object)
            end)
        end
        
        task.wait(0.15)
    end
    
    setHoldVelocity(hrp, false)
    
    -- NẾU SAU 3.5 GIÂY MÀ VẬT THỂ VẪN Ở WORKSPACE (VẬT THỂ ẢO / TƯỢNG ĐÁ KHÔNG NHẶT ĐƯỢC)
    if not pickedSuccess and fruitData.Object.Parent == Workspace then
        print("[BLACKLIST] Đã bỏ qua vật thể không thể nhặt: " .. tostring(fruitData.Name))
        BLACKLISTED_OBJECTS[fruitData.Object] = true
        pcall(function()
            if fruitData.Handle:FindFirstChild("FruitBillboard") then
                fruitData.Handle.FruitBillboard:Destroy()
            end
        end)
        setStatus("⚠️ Bỏ qua vật thể ảo: " .. fruitData.Name, Color3.fromRGB(255, 100, 100))
        task.wait(0.3)
        return false
    end
    
    task.wait(0.3)
    setStatus("✅ Đã nhặt thành công!", Color3.fromRGB(0, 255, 120))
    return true
end


local function getStandardFruitId(tool)
    local attr = tool:GetAttribute("OriginalName")
    if attr and type(attr) == "string" and attr ~= "" then
        return attr
    end
    local clean = tool.Name:lower():gsub(" fruit", ""):gsub(" ", "")
    for k, v in pairs(FRUIT_ID_MAP) do
        if string.find(clean, k) then
            return v
        end
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

local function performStoreAction(tool)
    local char = getCharacter()
    local hum = char:WaitForChild("Humanoid")
    local commF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
    local fruitId = getStandardFruitId(tool)

    print(string.format("[STORE] Đang thực hiện cất trái: %s (ID: %s)", tool.Name, fruitId))

    -- 1. CẦM TRÁI LÊN TAY
    hum:EquipTool(tool)
    task.wait(0.3)

    -- 2. TỰ ĐỘNG NHẤN VÀO TRÁI ĐỂ GAME HIỆN BẢNG MENU (ĂN / THẢ / LƯU TRỮ)
    pcall(function()
        tool:Activate()
    end)
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(500, 400))
    end)
    task.wait(0.35)

    -- 3. TỰ ĐỘNG QUÉT VÀ BẤM VÀO NÚT "LƯU TRỮ" / "STORE"
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        for _, btn in pairs(pGui:GetDescendants()) do
            if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                local bName = btn.Name:lower()
                local bText = tostring(btn.Text or ""):lower()
                local isStoreBtn = false

                if bText == "store" or bText == "lưu trữ" or string.find(bText, "store") or string.find(bText, "lưu trữ") or bName == "store" or bName == "option3" then
                    isStoreBtn = true
                else
                    local innerText = btn:FindFirstChildWhichIsA("TextLabel")
                    if innerText and innerText.Visible then
                        local iText = innerText.Text:lower()
                        if iText == "store" or iText == "lưu trữ" or string.find(iText, "store") or string.find(iText, "lưu trữ") then
                            isStoreBtn = true
                        end
                    end
                end

                if isStoreBtn then
                    print("[STORE] ĐÃ PHÁT HIỆN NÚT LƯU TRỮ TRÊN MÀN HÌNH -> ĐANG NHẤN TỰ ĐỘNG!")
                    if getconnections then
                        for _, c in pairs(getconnections(btn.MouseButton1Click)) do c.Function() end
                        for _, c in pairs(getconnections(btn.Activated)) do c.Function() end
                    end
                    pcall(function()
                        VirtualUser:ClickButton1(btn.AbsolutePosition + btn.AbsoluteSize / 2)
                    end)
                    task.wait(0.2)
                    break
                end
            end
        end
    end

    -- 4. GỌI REMOTE VỚI ID CHUẨN XÁC
    pcall(function()
        commF:InvokeServer("StoreFruit", fruitId, tool)
    end)
    pcall(function()
        commF:InvokeServer("StoreFruit", fruitId, LocalPlayer.Backpack:FindFirstChild(tool.Name))
    end)
    pcall(function()
        commF:InvokeServer("StoreFruit", fruitId)
    end)

    task.wait(0.3)
    pcall(function()
        hum:UnequipTools()
    end)
end

-- VÒNG LẶP KIÊN TRÌ CẤT TRÁI (CHỜ ĐẾN KHI CẤT XONG MỚI ĐƯỢC PHÉP ĐI TIẾP)
local function storeAllFruitsUntilDone()
    local char = getCharacter()
    local hum = char:WaitForChild("Humanoid")

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
    if #fruits == 0 then return true end

    for _, fruitTool in ipairs(fruits) do
        setStatus("📦 Đang nhấn để hiện Lưu trữ & cất rương...", Color3.fromRGB(255, 0, 128))
        local storedSuccess = false

        for attempt = 1, 8 do
            if not isFruitStillInHandsOrBackpack(fruitTool) then
                storedSuccess = true
                print("✅ Trái " .. fruitTool.Name .. " đã được cất vào kho đồ thành công!")
                break
            end

            performStoreAction(fruitTool)
            task.wait(0.6)
        end

        if not storedSuccess and isFruitStillInHandsOrBackpack(fruitTool) then
            print("[CẢNH BÁO] Không cất được trái (khả năng cao bị trùng kho đồ)!")
            return false, fruitTool
        end
    end

    return true, nil
end

local function isRareFruit(toolName)
    for rareName, _ in pairs(CONFIG.RareFruits) do
        if string.find(toolName:lower(), rareName:lower()) then
            return true, rareName
        end
    end
    return false, nil
end

-- ==============================================================================
-- KHẮC PHỤC TRIỆT ĐỂ: TỰ ĐỘNG CHẠY LẠI KHI QUA SERVER MỚI TRÊN DELTA
-- ==============================================================================

-- ==============================================================================
-- KHẮC PHỤC TRIỆT ĐỂ: TỰ ĐỘNG CHẠY LẠI KHI QUA SERVER MỚI (DELTA / CODEX / FLUXUS)
-- ==============================================================================
local function getQueueFunc()
    if type(queue_on_teleport) == "function" then return queue_on_teleport end
    if type(queueonteleport) == "function" then return queueonteleport end
    if syn and type(syn.queue_on_teleport) == "function" then return syn.queue_on_teleport end
    if fluxus and type(fluxus.queue_on_teleport) == "function" then return fluxus.queue_on_teleport end
    if getgenv and type(getgenv().queue_on_teleport) == "function" then return getgenv().queue_on_teleport end
    return nil
end

local function setupAutoRestart()
    local qFunc = getQueueFunc()
    if qFunc then
        local reloadCmd = ""
        if CONFIG.GitHubRawURL and CONFIG.GitHubRawURL ~= "" then
            reloadCmd = string.format([[
                repeat task.wait() until game:IsLoaded()
                task.wait(2.5)
                getgenv().FruitSniperURL = "%s"
                loadstring(game:HttpGet("%s"))()
            ]], CONFIG.GitHubRawURL, CONFIG.GitHubRawURL)
        else
            reloadCmd = [[
                repeat task.wait() until game:IsLoaded()
                task.wait(2.5)
                if isfile and isfile("FruitSniper_VIP.lua") then
                    loadstring(readfile("FruitSniper_VIP.lua"))()
                elseif isfile and isfile("FruitSniper.lua") then
                    loadstring(readfile("FruitSniper.lua"))()
                elseif getgenv and getgenv().FruitSniperURL and getgenv().FruitSniperURL ~= "" then
                    loadstring(game:HttpGet(getgenv().FruitSniperURL))()
                end
            ]]
        end
        pcall(function()
            qFunc(reloadCmd)
        end)
        print("[AUTO-RESTART] Đã đăng ký thành công lệnh nạp lại cho server mới!")
    end
end


local function getVisitedServers()
    local visited = {}
    pcall(function()
        if isfile and isfile(CONFIG.VisitedServersFile) then
            visited = HttpService:JSONDecode(readfile(CONFIG.VisitedServersFile))
        end
    end)
    return type(visited) == "table" and visited or {}
end

local function markServerVisited(serverId)
    pcall(function()
        local visited = getVisitedServers()
        visited[tostring(serverId)] = os.time()
        local cleanList = {}
        local now = os.time()
        for id, ts in pairs(visited) do
            if type(ts) == "number" and (now - ts) < 1800 then cleanList[id] = ts end
        end
        if writefile then
            writefile(CONFIG.VisitedServersFile, HttpService:JSONEncode(cleanList))
        end
    end)
end

local function hopToLowPlayerServer()
    setStatus("🔍 Đang tìm server ít người nhất...", Color3.fromRGB(0, 240, 255))
    markServerVisited(JobId)
    setupAutoRestart()
    task.wait(0.5)
    
    local visited = getVisitedServers()
    local cursor = ""
    local lowServers = {}
    
    for page = 1, 3 do
        local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then url = url .. "&cursor=" .. cursor end
        
        local success, res = pcall(function()
            if request then
                return HttpService:JSONDecode(request({Url = url, Method = "GET"}).Body)
            else
                return HttpService:JSONDecode(game:HttpGet(url))
            end
        end)
        
        if success and res and res.data then
            for _, s in ipairs(res.data) do
                local sid = tostring(s.id)
                if sid ~= JobId and s.playing and s.playing < s.maxPlayers and s.playing >= 1 and not visited[sid] then
                    table.insert(lowServers, s)
                end
            end
            if #lowServers >= 10 or not res.nextPageCursor then break end
            cursor = res.nextPageCursor
        else
            task.wait(0.5)
        end
    end
    
    table.sort(lowServers, function(a, b)
        return (a.playing or 0) < (b.playing or 0)
    end)
    
    if #lowServers > 0 then
        local pick = lowServers[math.random(1, math.min(3, #lowServers))]
        setStatus(string.format("🚀 Chuyển đến server %d người...", pick.playing), Color3.fromRGB(0, 255, 120))
        markServerVisited(pick.id)
        
        local hopTries = 0
        while task.wait(1.5) do
            hopTries = hopTries + 1
            if hopTries > 6 then
                -- Nếu server này quá đầy hoặc lỗi kết nối thì chuyển server khác ngay
                markServerVisited(pick.id)
                task.spawn(hopToLowPlayerServer)
                return
            end
            pcall(function()
                setupAutoRestart()
                TeleportService:TeleportToPlaceInstance(PlaceId, pick.id, LocalPlayer)
            end)
        end
    else
        setStatus("🚀 Chuyển server ngẫu nhiên...", Color3.fromRGB(255, 200, 50))
        pcall(function()
            TeleportService:Teleport(PlaceId, LocalPlayer)
        end)
    end
end

HopNowBtn.MouseButton1Click:Connect(function()
    task.spawn(hopToLowPlayerServer)
end)

LargeHopBtn.MouseButton1Click:Connect(function()
    task.spawn(hopToLowPlayerServer)
end)

-- ==============================================================================
-- QUY TRÌNH CHÍNH (MAIN WORKFLOW)
-- ==============================================================================
local function runFruitHunter()
    while STATE.IsPaused do task.wait(1) end
    
    setStatus("🔍 Đang quét trái ác quỷ...", Color3.fromRGB(0, 240, 255))
    task.wait(1)
    
    local fruits = findSpawnedFruits()
    
    if #fruits > 0 then
        -- 1. Bay hạ cánh chuẩn xác nhặt từng trái vào túi
        for _, fruitData in ipairs(fruits) do
            if STATE.IsPaused then break end
            pcall(function()
                pickFruitProperly(fruitData)
            end)
            task.wait(0.5)
        end
        
        -- 2. TỰ ĐỘNG NHẤN VÀO TRÁI ĐỂ HIỆN LƯU TRỮ VÀ BẤM LƯU TRỮ (KIỂM TRA CẤT XONG MỚI ĐI)
        local success, failedTool = storeAllFruitsUntilDone()
        
        if success then
            setStatus("✅ Đã cất toàn bộ trái vào rương!", Color3.fromRGB(0, 255, 120))
            task.wait(1.5)
        else
            if failedTool then
                local isRare, rareName = isRareFruit(failedTool.Name)
                if isRare and CONFIG.DuplicateHandling == "StopIfRare" then
                    setStatus("⚠️ TRÙNG TRÁI QUÝ - ĐÃ DỪNG LẠI!", Color3.fromRGB(255, 50, 50))
                    print("==================================================")
                    print("[BẢO VỆ] Phát hiện trái quý bị trùng kho! Đã dừng lại để bạn tự xử lý.")
                    print("==================================================")
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
        setStatus("Không có trái, chuẩn bị nhảy server...", Color3.fromRGB(255, 200, 50))
        task.wait(CONFIG.NoFruitHopDelay)
    end
    
    -- 3. Chỉ khi hoàn tất toàn bộ mới nhảy sang server ít người tiếp theo
    if not STATE.IsPaused then
        task.wait(1)
        hopToLowPlayerServer()
    end
end

-- Khởi động quy trình
task.spawn(function()
    pcall(runFruitHunter)
end)

]==]

-- 1. TỰ ĐỘNG LƯU FILE VÀO BỘ NHỚ CỦA EXECUTOR (DELTA / CODEX / FLUXUS WORKSPACE)
pcall(function()
    if writefile then
        writefile("FruitSniper_VIP.lua", SCRIPT_SOURCE)
    end
end)

-- 2. ĐĂNG KÝ QUEUE_ON_TELEPORT ĐỂ QUA SERVER MỚI TỰ ĐỘNG CHẠY TIẾP 100%
local function getQueueFunc()
    if type(queue_on_teleport) == "function" then return queue_on_teleport end
    if type(queueonteleport) == "function" then return queueonteleport end
    if syn and type(syn.queue_on_teleport) == "function" then return syn.queue_on_teleport end
    if fluxus and type(fluxus.queue_on_teleport) == "function" then return fluxus.queue_on_teleport end
    if getgenv and type(getgenv().queue_on_teleport) == "function" then return getgenv().queue_on_teleport end
    return nil
end

local qFunc = getQueueFunc()
if qFunc then
    pcall(function()
        qFunc([[
            repeat task.wait() until game:IsLoaded()
            task.wait(2.5)
            if isfile and isfile("FruitSniper_VIP.lua") then
                loadstring(readfile("FruitSniper_VIP.lua"))()
            elseif isfile and isfile("FruitSniper.lua") then
                loadstring(readfile("FruitSniper.lua"))()
            elseif getgenv and getgenv().FruitSniperURL and getgenv().FruitSniperURL ~= "" then
                loadstring(game:HttpGet(getgenv().FruitSniperURL))()
            end
        ]])
    end)
end

-- 3. KHỞI CHẠY SCRIPT NGAY BÂY GIỜ
loadstring(SCRIPT_SOURCE)()
