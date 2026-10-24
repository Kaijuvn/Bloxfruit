--[[ =====================================================
     MAKE BY NDUNG - AIM LOCK V1
     Game PvP (TBS) - Delta Mobile
     - Quet nguoi choi trong server
     - Chon muc tieu bang cach bam ten
     - Camera tu dong quay theo muc tieu
     - Cham do (Aim Dot) + ten + khoang cach
     ===================================================== ]]

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

-- ======== DON DEP BAN CU ========

if _G.NDungAim then pcall(_G.NDungAim.Unload) end
for _, n in ipairs({"NDungAimMain", "NDungAimDot"}) do
    local g = PG:FindFirstChild(n)
    if g then g:Destroy() end
end

local Running = true
local Conns = {}
local function Track(c) table.insert(Conns, c) return c end

-- ======== CAI DAT ========

local S = {
    AimEnabled = false,
    ShowDot = true,
    TargetName = nil,
    AimPartName = "Đầu",
    SmoothName = "Trung bình",
    IgnoreDead = true,
    TeamCheck = false,
}

local SmoothMap = {
    ["Tức thời"] = 1,
    ["Nhanh"] = 0.6,
    ["Trung bình"] = 0.35,
    ["Chậm"] = 0.15,
}

local PartOrderMap = {
    ["Đầu"] = {"Head", "HumanoidRootPart"},
    ["Thân"] = {"UpperTorso", "Torso", "HumanoidRootPart"},
    ["Chân"] = {"LeftLowerLeg", "RightLowerLeg", "LeftLeg", "RightLeg", "HumanoidRootPart"},
}

-- ======== MAU SAC ========

local Mau = {
    BG = Color3.fromRGB(15, 15, 24),
    Side = Color3.fromRGB(22, 20, 35),
    Card = Color3.fromRGB(32, 30, 46),
    Tim = Color3.fromRGB(155, 95, 255),
    TimDam = Color3.fromRGB(85, 45, 155),
    Trang = Color3.fromRGB(245, 245, 255),
    Xam = Color3.fromRGB(165, 165, 185),
    Xanh = Color3.fromRGB(90, 235, 145),
    Do = Color3.fromRGB(255, 100, 110),
    Vang = Color3.fromRGB(255, 200, 90),
}

-- ======== HAM CO BAN ========

local function GetChar(p) return p.Character end

local function GetRoot(p)
    local c = GetChar(p)
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function IsAlive(p)
    local c = GetChar(p)
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return c and h and h.Health > 0
end

local function GetAimPart(char)
    local order = PartOrderMap[S.AimPartName] or PartOrderMap["Đầu"]
    for _, n in ipairs(order) do
        local p = char:FindFirstChild(n)
        if p and p:IsA("BasePart") then return p end
    end
    return nil
end

local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = 3
        })
    end)
end

-- ======== DOT GUI (cham do tren man hinh) ========

local DotGui = Instance.new("ScreenGui")
DotGui.Name = "NDungAimDot"
DotGui.ResetOnSpawn = false
DotGui.IgnoreGuiInset = true
DotGui.DisplayOrder = 50
DotGui.Parent = PG

local Dot = Instance.new("Frame")
Dot.Size = UDim2.fromOffset(12, 12)
Dot.AnchorPoint = Vector2.new(0.5, 0.5)
Dot.BackgroundColor3 = Mau.Do
Dot.BorderSizePixel = 0
Dot.Visible = false
Dot.ZIndex = 5
Dot.Parent = DotGui
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = Dot
    local s = Instance.new("UIStroke")
    s.Color = Color3.new(1, 1, 1)
    s.Thickness = 1.5
    s.Parent = Dot
end

local DotInfo = Instance.new("TextLabel")
DotInfo.AnchorPoint = Vector2.new(0.5, 0)
DotInfo.Size = UDim2.fromOffset(120, 16)
DotInfo.BackgroundTransparency = 1
DotInfo.Font = Enum.Font.GothamBold
DotInfo.TextSize = 11
DotInfo.TextColor3 = Mau.Do
DotInfo.TextStrokeTransparency = 0.4
DotInfo.Text = ""
DotInfo.Visible = false
DotInfo.ZIndex = 5
DotInfo.Parent = DotGui

-- ======== MAIN GUI ========

local MainG = Instance.new("ScreenGui")
MainG.Name = "NDungAimMain"
MainG.ResetOnSpawn = false
MainG.IgnoreGuiInset = true
MainG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainG.Parent = PG

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(345, 430)
Main.Position = UDim2.new(0.5, -172, 0.5, -215)
Main.BackgroundColor3 = Mau.BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = MainG
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 14)
    c.Parent = Main
    local s = Instance.new("UIStroke")
    s.Color = Mau.Tim
    s.Thickness = 1.5
    s.Parent = Main
end

local Head = Instance.new("Frame")
Head.Size = UDim2.new(1, 0, 0, 48)
Head.BackgroundColor3 = Mau.Side
Head.BorderSizePixel = 0
Head.Active = true
Head.Parent = Main
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 14)
    c.Parent = Head
end

local HTitle = Instance.new("TextLabel")
HTitle.BackgroundTransparency = 1
HTitle.Size = UDim2.new(1, -50, 0, 24)
HTitle.Position = UDim2.fromOffset(12, 3)
HTitle.Text = "MAKE By NDung | AIM LOCK"
HTitle.TextColor3 = Mau.Tim
HTitle.Font = Enum.Font.GothamBold
HTitle.TextSize = 15
HTitle.TextXAlignment = Enum.TextXAlignment.Left
HTitle.Parent = Head

local HSub = Instance.new("TextLabel")
HSub.BackgroundTransparency = 1
HSub.Size = UDim2.new(1, -50, 0, 15)
HSub.Position = UDim2.fromOffset(12, 27)
HSub.Text = "Mục tiêu: chưa chọn"
HSub.TextColor3 = Mau.Xam
HSub.Font = Enum.Font.GothamBold
HSub.TextSize = 10
HSub.TextXAlignment = Enum.TextXAlignment.Left
HSub.Parent = Head

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.fromOffset(36, 32)
MinBtn.Position = UDim2.new(1, -42, 0, 8)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "-"
MinBtn.TextColor3 = Mau.Trang
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 22
MinBtn.Parent = Head

local Float = Instance.new("TextButton")
Float.Size = UDim2.fromOffset(52, 52)
Float.Position = UDim2.new(0, 12, 0.45, 0)
Float.BackgroundColor3 = Mau.TimDam
Float.Text = "ND"
Float.TextColor3 = Mau.Trang
Float.Font = Enum.Font.GothamBold
Float.TextSize = 18
Float.Visible = false
Float.Active = true
Float.Parent = MainG
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 26)
    c.Parent = Float
    local s = Instance.new("UIStroke")
    s.Color = Mau.Tim
    s.Thickness = 2
    s.Parent = Float
end

MinBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    Float.Visible = true
end)
Float.MouseButton1Click:Connect(function()
    Main.Visible = true
    Float.Visible = false
end)

-- KEO THA

local function Drag(frame, handle)
    local drag, dStart, sPos
    Track(handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
            or i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true
            dStart = i.Position
            sPos = frame.Position
        end
    end))
    Track(handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
            or i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = false
        end
    end))
    Track(UserInputService.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType == Enum.UserInputType.Touch
            or i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dStart
            frame.Position = UDim2.new(
                sPos.X.Scale, sPos.X.Offset + d.X,
                sPos.Y.Scale, sPos.Y.Offset + d.Y
            )
        end
    end))
end

Drag(Main, Head)
Drag(Float, Float)

-- TAB BAR NGANG

local TabBar = Instance.new("ScrollingFrame")
TabBar.Size = UDim2.new(1, -12, 0, 34)
TabBar.Position = UDim2.fromOffset(6, 52)
TabBar.BackgroundTransparency = 1
TabBar.BorderSizePixel = 0
TabBar.ScrollBarThickness = 0
TabBar.ScrollingDirection = Enum.ScrollingDirection.X
TabBar.CanvasSize = UDim2.new()
TabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
TabBar.Parent = Main

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 4)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabBar

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -12, 1, -96)
Content.Position = UDim2.fromOffset(6, 90)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Mau.Tim
Content.CanvasSize = UDim2.new()
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = Main

local ConPad = Instance.new("UIPadding")
ConPad.PaddingTop = UDim.new(0, 2)
ConPad.PaddingRight = UDim.new(0, 4)
ConPad.PaddingBottom = UDim.new(0, 8)
ConPad.Parent = Content

local TabList = {}
local function MakeTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(75, 30)
    btn.BackgroundColor3 = Mau.Card
    btn.Text = name
    btn.TextColor3 = Mau.Xam
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = TabBar
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = btn
    end

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Mau.Tim
    page.CanvasSize = UDim2.new()
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = Content

    local pl = Instance.new("UIListLayout")
    pl.Padding = UDim.new(0, 6)
    pl.SortOrder = Enum.SortOrder.LayoutOrder
    pl.Parent = page

    local pp = Instance.new("UIPadding")
    pp.PaddingTop = UDim.new(0, 2)
    pp.PaddingRight = UDim.new(0, 4)
    pp.PaddingBottom = UDim.new(0, 8)
    pp.Parent = page

    btn.MouseButton1Click:Connect(function()
        for _, t in ipairs(TabList) do
            t.page.Visible = false
            t.btn.BackgroundColor3 = Mau.Card
            t.btn.TextColor3 = Mau.Xam
        end
        page.Visible = true
        btn.BackgroundColor3 = Mau.TimDam
        btn.TextColor3 = Mau.Trang
    end)

    table.insert(TabList, {btn = btn, page = page})
    if #TabList == 1 then btn.BackgroundColor3 = Mau.TimDam btn.TextColor3 = Mau.Trang page.Visible = true end
    return page
end

-- CAC PHAN TU

local function Section(page, text)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1, 0, 0, 22)
    l.Text = text
    l.TextColor3 = Mau.Tim
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = page
    return l
end

local AimUpdaters = {}
local function SetAim(on)
    S.AimEnabled = on
    for _, fn in ipairs(AimUpdaters) do pcall(fn) end
end

local function Toggle(page, name, key, onFlip)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = Mau.Card
    row.Text = ""
    row.Parent = page
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 9)
        c.Parent = row
    end

    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1, -70, 1, 0)
    l.Position = UDim2.fromOffset(10, 0)
    l.Text = name
    l.TextColor3 = Mau.Trang
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = row

    local sw = Instance.new("Frame")
    sw.Size = UDim2.fromOffset(44, 22)
    sw.Position = UDim2.new(1, -52, 0.5, -11)
    sw.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    sw.BorderSizePixel = 0
    sw.Parent = row
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = sw
    end

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.Position = UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = Mau.Trang
    knob.BorderSizePixel = 0
    knob.Parent = sw
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = knob
    end

    local function Upd()
        local on = S[key]
        TweenService:Create(sw, TweenInfo.new(0.15), {
            BackgroundColor3 = on and Mau.Tim or Color3.fromRGB(60, 60, 75)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = on and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3)
        }):Play()
    end

    row.MouseButton1Click:Connect(function()
        S[key] = not S[key]
        Upd()
        if onFlip then pcall(onFlip, S[key]) end
    end)

    Upd()
    return Upd
end

local function Selector(page, name, key, options)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 44)
    btn.BackgroundColor3 = Color3.fromRGB(37, 31, 57)
    btn.TextColor3 = Mau.Trang
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = page
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 9)
        c.Parent = btn
    end
    local function Upd()
        btn.Text = name .. "  >  " .. tostring(S[key])
    end
    btn.MouseButton1Click:Connect(function()
        local idx = table.find(options, S[key]) or 1
        idx = idx % #options + 1
        S[key] = options[idx]
        Upd()
    end)
    Upd()
    return btn
end

local function Action(page, name, color, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = color or Mau.TimDam
    btn.Text = name
    btn.TextColor3 = Mau.Trang
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = page
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 9)
        c.Parent = btn
    end
    btn.MouseButton1Click:Connect(function()
        local ok, err = pcall(cb)
        if not ok then Notify("Lỗi", tostring(err)) end
    end)
    return btn
end

-- ======== TAO TAB ========

local pTarget = MakeTab("Mục Tiêu")
local pAim = MakeTab("Aim")
local pSet = MakeTab("Cài Đặt")

-- TAB MUC TIEU

local TargetLabel = Section(pTarget, "MỤC TIÊU: CHƯA CHỌN")

local AimBigBtn = Instance.new("TextButton")
AimBigBtn.Size = UDim2.new(1, 0, 0, 46)
AimBigBtn.BackgroundColor3 = Mau.TimDam
AimBigBtn.Text = "▶ BẬT AIMBOT"
AimBigBtn.TextColor3 = Mau.Trang
AimBigBtn.Font = Enum.Font.GothamBold
AimBigBtn.TextSize = 14
AimBigBtn.Parent = pTarget
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 9)
    c.Parent = AimBigBtn
end

local function UpdBigBtn()
    if S.AimEnabled then
        AimBigBtn.Text = "■ TẮT AIMBOT"
        AimBigBtn.BackgroundColor3 = Color3.fromRGB(150, 45, 60)
    else
        AimBigBtn.Text = "▶ BẬT AIMBOT"
        AimBigBtn.BackgroundColor3 = Mau.TimDam
    end
end
table.insert(AimUpdaters, UpdBigBtn)
AimBigBtn.MouseButton1Click:Connect(function()
    SetAim(not S.AimEnabled)
end)
UpdBigBtn()

Action(pTarget, "Chọn người gần nhất", nil, function()
    local best, bd = nil, math.huge
    local myRoot = GetRoot(LP)
    if not myRoot then Notify("Lỗi", "Chưa có nhân vật") return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and not (S.TeamCheck and p.Team == LP.Team) then
            local r = GetRoot(p)
            local alive = IsAlive(p)
            if r and alive then
                local d = (r.Position - myRoot.Position).Magnitude
                if d < bd then best, bd = p, d end
            end
        end
    end
    if best then
        SelectTargetByName(best.Name)
    else
        Notify("NDung", "Không có người chơi nào gần")
    end
end)

Action(pTarget, "Bỏ chọn mục tiêu", Color3.fromRGB(60, 60, 80), function()
    S.TargetName = nil
    UpdateTargetUI()
end)

Action(pTarget, "Làm mới danh sách", nil, function()
    RebuildList()
    Notify("NDung", "Đã làm mới danh sách")
end)

local ListHeader = Section(pTarget, "DANH SÁCH NGƯỜI CHƠI (0)")

-- ======== DANH SACH NGUOI CHOI ========

local Rows = {}

local function SelectTargetByName(name)
    S.TargetName = name
    UpdateTargetUI()
    for n, r in pairs(Rows) do
        if n == name then
            r.row.BackgroundColor3 = Mau.TimDam
            r.nameLabel.TextColor3 = Mau.Trang
        else
            r.row.BackgroundColor3 = Mau.Card
            r.nameLabel.TextColor3 = Mau.Xam
        end
    end
    Notify("NDung", "Đã khóa mục tiêu: " .. name)
end

function UpdateTargetUI()
    if S.TargetName then
        TargetLabel.Text = "MỤC TIÊU: " .. S.TargetName
        TargetLabel.TextColor3 = Mau.Vang
        HSub.Text = "Mục tiêu: " .. S.TargetName
    else
        TargetLabel.Text = "MỤC TIÊU: CHƯA CHỌN"
        TargetLabel.TextColor3 = Mau.Tim
        HSub.Text = "Mục tiêu: chưa chọn"
    end
end

function RebuildList()
    if not Running then return end
    for _, r in pairs(Rows) do
        pcall(function() r.row:Destroy() end)
    end
    Rows = {}

    local myRoot = GetRoot(LP)

    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(list, p) end
    end

    table.sort(list, function(a, b)
        local ra, rb = GetRoot(a), GetRoot(b)
        local da = (ra and myRoot) and (ra.Position - myRoot.Position).Magnitude or math.huge
        local db = (rb and myRoot) and (rb.Position - myRoot.Position).Magnitude or math.huge
        return da < db
    end)

    for _, p in ipairs(list) do
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 36)
        row.BackgroundColor3 = (p.Name == S.TargetName) and Mau.TimDam or Mau.Card
        row.Text = ""
        row.Parent = pTarget
        do
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 8)
            c.Parent = row
        end

        local nm = Instance.new("TextLabel")
        nm.BackgroundTransparency = 1
        nm.Position = UDim2.fromOffset(10, 0)
        nm.Size = UDim2.new(1, -70, 1, 0)
        nm.Text = p.Name
        nm.TextColor3 = (p.Name == S.TargetName) and Mau.Trang or Mau.Xam
        nm.Font = Enum.Font.GothamBold
        nm.TextSize = 12
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.Parent = row

        local dist = Instance.new("TextLabel")
        dist.BackgroundTransparency = 1
        dist.Position = UDim2.new(1, -58, 0, 0)
        dist.Size = UDim2.fromOffset(52, 36)
        dist.Text = "..."
        dist.TextColor3 = Mau.Xam
        dist.Font = Enum.Font.GothamBold
        dist.TextSize = 11
        dist.Parent = row

        Rows[p.Name] = {row = row, nameLabel = nm, dist = dist}

        row.MouseButton1Click:Connect(function()
            SelectTargetByName(p.Name)
        end)
    end

    ListHeader.Text = "DANH SÁCH NGƯỜI CHƠI (" .. #list .. ")"
end

-- TAB AIM

Section(pAim, "CÀI ĐẮT NGẮM")

Toggle(pAim, "Aimbot Camera", "AimEnabled", function(v) SetAim(v) end)
Toggle(pAim, "Hiện chấm đỏ (Aim Dot)", "ShowDot")

Selector(pAim, "Vị trí ngắm", "AimPartName", {"Đầu", "Thân", "Chân"})
Selector(pAim, "Tốc độ quay camera", "SmoothName", {"Tức thời", "Nhanh", "Trung bình", "Chậm"})

Toggle(pAim, "Bỏ qua người đã chết", "IgnoreDead")
Toggle(pAim, "Bỏ qua đồng đội", "TeamCheck")

Section(pAim, "GHI CHÚ")
do
    local note = Instance.new("TextLabel")
    note.BackgroundTransparency = 1
    note.Size = UDim2.new(1, 0, 0, 44)
    note.Text = "Tức thời = camera bám dính hoàn toàn. Chậm = quay mượt hơn, dễ điều chỉnh."
    note.TextColor3 = Mau.Xam
    note.Font = Enum.Font.Gotham
    note.TextSize = 10
    note.TextWrapped = true
    note.TextXAlignment = Enum.TextXAlignment.Left
    note.TextYAlignment = Enum.TextYAlignment.Top
    note.Parent = pAim
end

-- TAB CAI DAT

Section(pSet, "TIỆN ÍCH")

Action(pSet, "Tắt Aim + Bỏ chọn", Color3.fromRGB(60, 60, 80), function()
    SetAim(false)
    S.TargetName = nil
    UpdateTargetUI()
end)

Action(pSet, "GO HUB (Unload)", Color3.fromRGB(120, 45, 55), function()
    _G.NDungAim.Unload()
end)

SCRIPT ]Section(pSet, "MAKE By NDung | Aim Lock V1")

-- ======== VONG LAP CHINH (CAMERA + DOT) ========

Track(RunService.RenderStepped:Connect(function()
    if not Running then return end
    local cam = workspace.CurrentCamera
    if not cam then return end

    -- TIM MUC TIEU HOP LE
    local target = nil
    if S.TargetName then
        local p = Players:FindFirstChild(S.TargetName)
        if p then
            local skip = false
            if S.TeamCheck and p.Team == LP.Team then skip = true end
            if S.IgnoreDead and not IsAlive(p) then skip = true end
            if not skip then target = p end
        end
    end

    -- CHAM DO (AIM DOT)
    if target and S.ShowDot then
        local char = target.Character
        local part = char and GetAimPart(char)
        if part then
            local pos, onScreen = cam:WorldToViewportPoint(part.Position)
            if onScreen then
                Dot.Visible = true
                Dot.Position = UDim2.fromOffset(pos.X, pos.Y)
                DotInfo.Visible = true
                DotInfo.Position = UDim2.fromOffset(pos.X, pos.Y + 10)
                local myRoot = GetRoot(LP)
                local d = myRoot and math.floor((part.Position - myRoot.Position).Magnitude) or 0
                local alive = IsAlive(target)
                DotInfo.Text = target.Name .. " | " .. tostring(d) .. "m" .. (alive and "" or " | CHẾT")
                DotInfo.TextColor3 = alive and Mau.Do or Mau.Xam
            else
                Dot.Visible = false
                DotInfo.Visible = false
            end
        else
            Dot.Visible = false
            DotInfo.Visible = false
        end
    else
        Dot.Visible = false
        DotInfo.Visible = false
    end

    -- CAMERA QUAY THEO MUC TIEU (da fix loi return som)
    if target and S.AimEnabled then
        local char = target.Character
        local part = char and GetAimPart(char)
        if part then
            local goal = CFrame.new(cam.CFrame.Position, part.Position)
            local alpha = SmoothMap[S.SmoothName] or 0.35
            cam.CFrame = cam.CFrame:Lerp(goal, alpha)
        end
    end
end))

-- ======== CAP NHAT KHOANG CACH + TRANG THAI ========

task.spawn(function()
    while Running do
        task.wait(0.5)
        pcall(function()
            local myRoot = GetRoot(LP)
            for name, r in pairs(Rows) do
                local p = Players:FindFirstChild(name)
                if p then
                    local rt = GetRoot(p)
                    local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                    if rt and myRoot then
                        r.dist.Text = math.floor((rt.Position - myRoot.Position).Magnitude) .. "m"
                    else
                        r.dist.Text = "?"
                    end
                    if hum then
                        r.dist.TextColor3 = hum.Health > 0 and Mau.Xanh or Mau.Do
                    end
                end
            end

            -- cap nhat dong trang thai
            if S.TargetName then
                local p = Players:FindFirstChild(S.TargetName)
                if p then
                    local st = S.AimEnabled and " | AIM: BAT" or " | AIM: TAT"
                    HSub.Text = "Mục tiêu: " .. S.TargetName .. st
                else
                    S.TargetName = nil
                    UpdateTargetUI()
                    Notify("NDung", "Mục tiêu đã rời server")
                end
            end
        end)
    end
end)

-- ======== TU QUET KHI CO NGUOI VAO / RA ========

Track(Players.PlayerAdded:Connect(function(p)
    task.wait(2)
    RebuildList()
end))

Track(Players.PlayerRemoving:Connect(function(p)
    if S.TargetName == p.Name then
        S.TargetName = nil
        UpdateTargetUI()
        Notify("NDung", "Mục tiêu đã rời server")
    end
    task.defer(RebuildList)
end))

-- TU DONG LAM MOI KHI SO NGUOI CHOI THAY DOI

local LastCount = #Players:GetPlayers()

task.spawn(function()
    while Running do
        task.wait(2)
        pcall(function()
            local count = #Players:GetPlayers()
            if count ~= LastCount then
                LastCount = count
                RebuildList()
            end
        end)
    end
end)

-- ======== UNLOAD ========

_G.NDungAim = {}

function _G.NDungAim.Unload()
    Running = false
    _G.NDungAim = nil
    for _, c in ipairs(Conns) do
        pcall(c.Disconnect, c)
    end
    if MainG then MainG:Destroy() end
    if DotGui then DotGui:Destroy() end
end

-- ======== KHOI DONG ========

RebuildList()
UpdateTargetUI()

Notify("MAKE By NDung", "Aim Lock V1 đã tải! Vào tab Mục Tiêu để chọn người.")

print("[NDung Aim Lock] Loaded OK")