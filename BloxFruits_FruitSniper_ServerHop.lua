-- ==============================================================================
-- 👑 BLOX FRUITS - VIP CYBER ANIME FRUIT SNIPER & SERVER HOP (AUTO LOOP) 👑
-- BẢN SỬA LỖI TOÀN DIỆN & NÂNG CẤP HÌNH NỀN GOJO TRÊN BẬC THANG (VIP EDITION)
-- 1. FIX LỖI TƯỢNG ĐÁ (COLOSSEUM STATUE):
--    - Chỉ nhặt trái thật (Tool), tuyệt đối KHÔNG nhặt Model tượng đá hay quả ghim trên tượng.
--    - Kiểm tra Handle.Anchored == false (Quả trên tượng đá luôn bị Anchored = true).
--    - Bộ lọc từ khóa cấm: "statue", "colosseum", "dealer", "rock", "stone", "pedestal",...
-- 2. FIX LỖI SERVER HOP (KHÔNG BỊ VÀO LẠI SERVER CŨ 2/12 NGƯỜI):
--    - Tuyệt đối không dùng TeleportService:Teleport() mù quáng (khiến Roblox ghép lại server cũ).
--    - Quét trực tiếp danh sách JobId qua nhiều trang (roblox.com & roproxy.com fallback).
--    - Sắp xếp và chọn server ít người nhất (1 - 3 người) KHÁC 100% server hiện tại và chưa từng vào.
--    - Tự động bắt lỗi TeleportInitFailed để thử ngay server tiếp theo nếu server đầy.
-- 3. FIX LỖI TỰ ĐỘNG CHẠY LẠI TRÊN DELTA / MOBILE (AUTO RE-RUN):
--    - Tự động ghi mã nguồn vào "FruitSniper_Auto.lua" và thư mục "autoexec" ngay khi khởi động.
--    - Hỗ trợ toàn diện queue_on_teleport, queueonteleport, syn, fluxus.
-- 4. GIAO DIỆN NÚT THU NHỎ MINI ICON HÌNH GOJO SATORU TRÊN BẬC THANG:
--    - Khi menu chưa mở / thu nhỏ: Hiển thị ảnh Gojo ngồi trên bậc thang siêu ngầu với viền VIP phát sáng!
--    - Có thể kéo thả tự do, chạm vào để mở menu lớn, bấm "—" để thu gọn.
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
-- CẤU HÌNH HỆ THỐNG (CONFIG)
-- ==============================================================================
local CONFIG = {
    GitHubRawURL = (getgenv and getgenv().FruitSniperURL) or _G.FruitSniperURL or "",
    Team = "Pirates",                 -- Phe tự chọn: "Pirates" hoặc "Marines"
    FlySpeed = 160,                   -- Tốc độ bay ổn định chống văng biển (160 stud/s)
    NoFruitHopDelay = 2,              -- Thời gian chờ nếu server không có trái thì nhảy server ngay
    VisitedServersFile = "BF_VisitedServers.json",
    LocalScriptFile = "FruitSniper_Auto.lua",
    DuplicateHandling = "StopIfRare", -- "StopIfRare" (Bảo vệ trái quý), "Drop" (Vứt)
    BgTransparency = 0.65,
    BackgroundImage = "rbxassetid://14207920404", -- Gojo Satoru Wallpaper

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
}

-- Danh sách blacklist đối tượng tạm thời bỏ qua (tránh kẹt vĩnh viễn)
local IgnoredFruitInstances = {}

-- ==============================================================================
-- BASE64 DECODER THUẦN LUA & NẠP HÌNH ẢNH GOJO CHO NÚT MENU CHƯA MỞ
-- ==============================================================================
local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function decodeBase64(data)
    data = string.gsub(data, "[^" .. B64_CHARS .. "=]", "")
    return (data:gsub(".", function(x)
        if (x == "=") then return "" end
        local r, f = "", (B64_CHARS:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i - 1) > 0 and "1" or "0") end
        return r
    end):gsub("%d%d%d%d%d%d%d%d", function(x)
        if (#x ~= 8) then return "" end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2^(8 - i) or 0) end
        return string.char(c)
    end))
end

local GOJO_IMAGE_BASE64 = "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"

local function getGojoCustomAsset()
    local defaultAsset = "rbxassetid://14207920404"
    local filename = "BF_GojoIcon.jpg"
    pcall(function()
        if writefile and (getcustomasset or getsynasset) then
            local getAsset = getcustomasset or getsynasset
            if not isfile or not isfile(filename) then
                local raw = decodeBase64(GOJO_IMAGE_BASE64)
                if raw and #raw > 100 then
                    writefile(filename, raw)
                end
            end
            if isfile and isfile(filename) then
                defaultAsset = getAsset(filename)
            end
        end
    end)
    return defaultAsset
end

local GojoAssetId = getGojoCustomAsset()

-- ==============================================================================
-- TỰ ĐỘNG LƯU MÃ NGUỒN VÀ THIẾT LẬP AUTO-RESTART CHO DELTA TRÊN SERVER MỚI
-- ==============================================================================
local function setupAutoRestart()
    local restartCode = string.format([[
        repeat task.wait() until game:IsLoaded()
        task.wait(2.5)
        if getgenv and getgenv().FruitSniperURL and getgenv().FruitSniperURL ~= "" then
            pcall(function() loadstring(game:HttpGet(getgenv().FruitSniperURL))() end)
        elseif isfile and isfile("FruitSniper_Auto.lua") then
            pcall(function() loadstring(readfile("FruitSniper_Auto.lua"))() end)
        elseif isfile and isfile("FruitSniper.lua") then
            pcall(function() loadstring(readfile("FruitSniper.lua"))() end)
        end
    ]])

    pcall(function()
        if syn and syn.queue_on_teleport then syn.queue_on_teleport(restartCode) end
    end)
    pcall(function()
        if queue_on_teleport then queue_on_teleport(restartCode) end
    end)
    pcall(function()
        if queueonteleport then queueonteleport(restartCode) end
    end)
    pcall(function()
        if fluxus and fluxus.queue_on_teleport then fluxus.queue_on_teleport(restartCode) end
    end)
end

-- Tự động ghi file dự phòng vào bộ nhớ Delta
pcall(function()
    if writefile then
        local selfLoader = string.format([[
            -- Tự động chạy lại script Fruit Sniper
            repeat task.wait() until game:IsLoaded()
            task.wait(2)
            if isfile and isfile("FruitSniper_Auto.lua") then
                loadstring(readfile("FruitSniper_Auto.lua"))()
            end
        ]])
        pcall(function() writefile("autoexec/FruitSniper_Auto.lua", selfLoader) end)
    end
end)

-- ==============================================================================
-- THIẾT KẾ GIAO DIỆN VIP MENU & NÚT THU NHỎ HÌNH GOJO NGỒI TRÊN BẬC THANG
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

-- KHUNG CHÍNH (MAIN WINDOW 480x290)
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

-- HÌNH NỀN MENU
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

local DarkOverlay = Instance.new("Frame")
DarkOverlay.Name = "DarkOverlay"
DarkOverlay.Size = UDim2.new(1, 0, 1, 0)
DarkOverlay.BackgroundColor3 = Color3.fromRGB(10, 12, 22)
DarkOverlay.BackgroundTransparency = 0.35
DarkOverlay.BorderSizePixel = 0
DarkOverlay.ZIndex = 2
DarkOverlay.Parent = MainFrame

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

-- THANH TIÊU ĐỀ TRÊN CÙNG
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

-- ==============================================================================
-- NÚT THU NHỎ MINI ICON HÌNH GOJO SATORU TRÊN BẬC THANG (KHI MENU CHƯA MỞ)
-- ==============================================================================
local FloatingBtn = Instance.new("ImageButton")
FloatingBtn.Name = "FloatingGojoBtn"
FloatingBtn.Size = UDim2.new(0, 56, 0, 72)
FloatingBtn.Position = UDim2.new(0.03, 0, 0.18, 0)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 30)
FloatingBtn.Image = GojoAssetId
FloatingBtn.ScaleType = Enum.ScaleType.Crop
FloatingBtn.Visible = false
FloatingBtn.ClipsDescendants = true
FloatingBtn.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(0, 12)
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

-- Huy hiệu nhỏ VIP ở dưới nút Gojo
local FloatBadge = Instance.new("TextLabel")
FloatBadge.Name = "FloatBadge"
FloatBadge.Size = UDim2.new(1, 0, 0, 18)
FloatBadge.Position = UDim2.new(0, 0, 1, -18)
FloatBadge.BackgroundColor3 = Color3.fromRGB(12, 14, 25)
FloatBadge.BackgroundTransparency = 0.25
FloatBadge.Text = "👑 VIP"
FloatBadge.TextColor3 = Color3.fromRGB(255, 215, 0)
FloatBadge.TextSize = 9
FloatBadge.Font = Enum.Font.GothamBold
FloatBadge.Parent = FloatingBtn

-- Hiệu ứng chuyển động viền nút Gojo
task.spawn(function()
    while true do
        for rot = 0, 360, 4 do
            FloatStrokeGrad.Rotation = rot
            task.wait(0.04)
        end
    end
end)

-- CỘT BÊN TRÁI: SIDEBAR
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

-- CÁC NÚT TAB (TABS)
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

-- KHUNG NỘI DUNG BÊN PHẢI
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

-- TAB 1: TRẠNG THÁI
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

-- TAB 2: CÀI ĐẶT
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

-- TAB 4: HÌNH NỀN ANIME (THEME)
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

createPresetBtn("Gojo Trên Bậc Thang (Mới)", GojoAssetId, 0)
createPresetBtn("Gojo Satoru Chiến Đấu (JJK)", "rbxassetid://14207920404", 38)
createPresetBtn("Sung Jin-Woo (Solo Leveling)", "rbxassetid://16140502159", 76)
createPresetBtn("Zoro Kiếm Sĩ (One Piece)", "rbxassetid://11401835376", 114)

-- CHUYỂN ĐỔI TAB
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

-- KÉO THẢ CHO MAIN FRAME & FLOATING GOJO BUTTON
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

-- BẤM ĐỂ THU GỌN / MỞ MENU
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
        ValFruit.TextColor3 = Color3.fromRGB(255, 255, 255) -- MÀU TRẮNG
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
                for _, conn in pairs(getconnections(teamBtn.MouseButton1Click)) do conn.Function() end
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

-- ==============================================================================
-- NOCLIP & KHÓA VẬN TỐC
-- ==============================================================================
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

-- ==============================================================================
-- 🛡️ KHẮC PHỤC TRIỆT ĐỂ: BỘ LỌC CHẶN HOÀN TOÀN TƯỢNG ĐÁ (COLOSSEUM STATUE FILTER)
-- ==============================================================================
local function isValidRealSpawnedFruit(item)
    if not item or not item.Parent then return false end
    if IgnoredFruitInstances[item] then return false end

    -- 1. Trái thật trong Blox Fruits BẮT BUỘC là Tool, TUYỆT ĐỐI không phải Model tượng đá
    if not item:IsA("Tool") then
        return false
    end

    -- 2. Trái spawn tự nhiên phải nằm trực tiếp ngoài Workspace, không nằm trong các folder Map / NPC / Tượng
    if item.Parent ~= Workspace then
        return false
    end

    local nameLower = item.Name:lower()

    -- 3. Danh sách từ khóa cấm (Loại trừ toàn bộ tượng đá, NPC, quầy bán, bàn thờ, bí mật đảo)
    local blacklistedWords = {
        "statue", "colosseum", "dealer", "cousin", "gacha", "npc",
        "stone", "rock", "pedestal", "stand", "monument", "shrine",
        "tree", "secret", "altar", "display", "chest", "dummy", "boss", "quest"
    }
    for _, word in ipairs(blacklistedWords) do
        if string.find(nameLower, word) then
            return false
        end
    end

    -- 4. Phải có Part chính tên Handle
    local handle = item:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then
        return false
    end

    -- 5. TIÊU CHÍ QUAN TRỌNG NHẤT: TRÁI THẬT TRÊN MẶT ĐẤT KHÔNG BAO GIỜ BỊ ANCHORED!
    -- Các loại quả gắn trên tượng đá hoặc trang trí map luôn bị ghim cố định (Anchored == true)
    if handle.Anchored == true then
        return false
    end

    -- 6. Tên phải có chữ "fruit" hoặc có Remote ăn trái
    local isFruit = string.find(nameLower, "fruit") or item:FindFirstChild("EatRemote", true) or item:GetAttribute("OriginalName")
    if not isFruit then
        return false
    end

    return true
end

-- ESP HIỂN THỊ TÊN TRÁI THẬT MÀU TRẮNG + SỐ MÉT
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

-- ==============================================================================
-- NHẶT TRÁI CHUẨN XÁC VÀO TÚI (CÓ CƠ CHẾ TIMEOUT KHÔNG BAO GIỜ BỊ KẸT)
-- ==============================================================================
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
        -- Nếu sau 3.5 giây vẫn không nhặt được -> Chặn không quét lại để tránh kẹt
        IgnoredFruitInstances[fruitData.Object] = true
        print("[FruitSniper] Bỏ qua vật thể không thể nhặt: " .. fruitData.Name)
    else
        picked = true
        setStatus("✅ Đã nhặt thành công!", Color3.fromRGB(0, 255, 120))
    end
    
    task.wait(0.3)
    return picked
end

-- ==============================================================================
-- BẢNG MÃ HÓA & TỰ ĐỘNG BẤM LƯU TRỮ (STORE FRUIT)
-- ==============================================================================
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

local function performStoreAction(tool)
    local char = getCharacter()
    local hum = char:WaitForChild("Humanoid")
    local commF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
    local fruitId = getStandardFruitId(tool)

    -- 1. CẦM TRÁI LÊN TAY
    hum:EquipTool(tool)
    task.wait(0.25)

    -- 2. TỰ ĐỘNG BẤM KÍCH HOẠT ĐỂ GAME BẬT MENU (ĂN / THẢ / LƯU TRỮ)
    pcall(function() tool:Activate() end)
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(500, 400))
    end)
    task.wait(0.3)

    -- 3. TỰ ĐỘNG BẤM NÚT "LƯU TRỮ" TRÊN GIAO DIỆN MÀN HÌNH
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        for _, btn in pairs(pGui:GetDescendants()) do
            if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                local bName = btn.Name:lower()
                local bText = tostring(btn.Text or ""):lower()
                local isStoreBtn = (bText == "store" or bText == "lưu trữ" or string.find(bText, "store") or string.find(bText, "lưu trữ") or bName == "store" or bName == "option3")

                if not isStoreBtn then
                    local innerText = btn:FindFirstChildWhichIsA("TextLabel")
                    if innerText and innerText.Visible then
                        local iText = innerText.Text:lower()
                        if iText == "store" or iText == "lưu trữ" or string.find(iText, "store") or string.find(iText, "lưu trữ") then
                            isStoreBtn = true
                        end
                    end
                end

                if isStoreBtn then
                    if getconnections then
                        for _, c in pairs(getconnections(btn.MouseButton1Click)) do c.Function() end
                        for _, c in pairs(getconnections(btn.Activated)) do c.Function() end
                    end
                    pcall(function()
                        VirtualUser:ClickButton1(btn.AbsolutePosition + btn.AbsoluteSize / 2)
                    end)
                    task.wait(0.15)
                    break
                end
            end
        end
    end

    -- 4. GỌI REMOTE VỚI ID CHUẨN
    pcall(function() commF:InvokeServer("StoreFruit", fruitId, tool) end)
    pcall(function() commF:InvokeServer("StoreFruit", fruitId, LocalPlayer.Backpack:FindFirstChild(tool.Name)) end)
    pcall(function() commF:InvokeServer("StoreFruit", fruitId) end)

    task.wait(0.25)
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
    if #fruits == 0 then return true end

    for _, fruitTool in ipairs(fruits) do
        setStatus("📦 Đang cất rương: " .. fruitTool.Name, Color3.fromRGB(255, 0, 128))
        local storedSuccess = false

        for attempt = 1, 6 do
            if not isFruitStillInHandsOrBackpack(fruitTool) then
                storedSuccess = true
                break
            end
            performStoreAction(fruitTool)
            task.wait(0.55)
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

-- ==============================================================================
-- 🚀 KHẮC PHỤC TRIỆT ĐỂ: SERVER HOP THẬT 100% (CHỐNG LẶP LẠI SERVER CŨ 2/12)
-- ==============================================================================
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
    setStatus("🔍 Đang tìm server MỚI (chống lặp lại)...", Color3.fromRGB(0, 240, 255))
    saveServerVisited(JobId)
    setupAutoRestart()
    task.wait(0.3)

    local visitedLocal = getPersistentVisited()
    local candidateServers = {}
    local cursor = ""

    -- Thử quét qua roblox API và roproxy API dự phòng
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

                    -- ĐIỀU KIỆN LỌC NGHIÊM NGẶT:
                    -- 1. TUYỆT ĐỐI không phải server hiện tại (JobId)
                    -- 2. Chưa từng vào trong phiên này hoặc file lưu trữ
                    -- 3. Có từ 1 người trở lên và còn chỗ trống để vào
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

    -- Sắp xếp ưu tiên server ÍT NGƯỜI NHẤT (1 - 3 người) lên đầu
    table.sort(candidateServers, function(a, b)
        return a.playing < b.playing
    end)

    if #candidateServers > 0 then
        -- Lần lượt thử kết nối đến các server phù hợp
        for i = 1, math.min(5, #candidateServers) do
            local targetServer = candidateServers[i]
            setStatus(string.format("🚀 Nhảy server %d/%d người...", targetServer.playing, targetServer.maxPlayers), Color3.fromRGB(0, 255, 120))
            saveServerVisited(targetServer.id)

            local tpSuccess = pcall(function()
                TeleportService:TeleportToPlaceInstance(PlaceId, targetServer.id, LocalPlayer)
            end)

            if tpSuccess then
                -- Chờ teleport kích hoạt (nếu lỗi Roblox sẽ kích hoạt TeleportInitFailed)
                task.wait(3.5)
            end
        end
    else
        -- Trong trường hợp mạng lag không load được API, tìm server ngẫu nhiên KHÁC JobId
        setStatus("⚠️ Đang tìm kiếm thêm server khác...", Color3.fromRGB(255, 200, 50))
        task.wait(1)
        pcall(function()
            TeleportService:TeleportToPlaceInstance(PlaceId, "", LocalPlayer)
        end)
    end
end

-- Tự động bắt lỗi nếu server đầy để thử ngay server tiếp theo
TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player == LocalPlayer then
        print("[TeleportFailed] " .. tostring(errorMessage) .. " -> Đang chọn server khác...")
        task.wait(1)
        hopToRealNewServer()
    end
end)

HopNowBtn.MouseButton1Click:Connect(function() task.spawn(hopToRealNewServer) end)
LargeHopBtn.MouseButton1Click:Connect(function() task.spawn(hopToRealNewServer) end)

-- ==============================================================================
-- QUY TRÌNH SĂN CHÍNH (MAIN BOT LOOP)
-- ==============================================================================
local function runFruitHunter()
    while STATE.IsPaused do task.wait(1) end

    setStatus("🔍 Đang quét trái ác quỷ THẬT...", Color3.fromRGB(0, 240, 255))
    task.wait(0.8)

    local realFruits = findSpawnedFruits()

    if #realFruits > 0 then
        -- 1. Nhặt từng trái thật (Không bao giờ chạm vào tượng đá)
        for _, fruitData in ipairs(realFruits) do
            if STATE.IsPaused then break end
            pcall(function()
                pickFruitProperly(fruitData)
            end)
            task.wait(0.4)
        end

        -- 2. Tự động bấm để hiện Lưu trữ & Cất rương
        local success, failedTool = storeAllFruitsUntilDone()

        if success then
            setStatus("✅ Đã cất toàn bộ trái vào kho đồ!", Color3.fromRGB(0, 255, 120))
            task.wait(1.5)
        else
            if failedTool then
                local isRare, rareName = isRareFruit(failedTool.Name)
                if isRare and CONFIG.DuplicateHandling == "StopIfRare" then
                    setStatus("⚠️ TRÙNG TRÁI QUÝ - ĐÃ DỪNG LẠI!", Color3.fromRGB(255, 50, 50))
                    print("[BẢO VỆ] Phát hiện trái quý bị trùng kho! Giữ lại an toàn.")
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
        setStatus("Không có trái spawn, nhảy server mới...", Color3.fromRGB(255, 200, 50))
        task.wait(CONFIG.NoFruitHopDelay)
    end

    -- 3. Nhảy sang server MỚI 100%
    if not STATE.IsPaused then
        task.wait(0.8)
        hopToRealNewServer()
    end
end

-- Khởi động bot
task.spawn(function()
    pcall(runFruitHunter)
end)
