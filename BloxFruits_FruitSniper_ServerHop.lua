-- ==============================================================================
-- 🔮 BLOX FRUITS - HOLOGRAM FRUIT SNIPER & LOW SERVER HOP (AUTO LOOP) 🔮
-- BẢN SỬA LỖI ĐẶC BIỆT:
-- 1. Tự động cầm trái -> Nhấn để hiện menu (Ăn/Thả/Lưu trữ) -> Tự động bấm "Lưu trữ" (Store)
-- 2. Kiểm tra xác nhận cất xong 100% mới nhảy server (Không bao giờ cứ thế bay tiếp)
-- 3. Tự động chạy lại script khi đổi server (Queue-on-teleport + Hướng dẫn Delta Auto-Execute)
-- 4. Bay êm ái, chống văng biển, hiển thị tên trái MÀU TRẮNG + khoảng cách mét (m)
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

    -- Danh sách trái quý giá cần giữ lại tuyệt đối nếu trùng kho:
    RareFruits = {
        ["Kitsune"] = true, ["Dragon"] = true, ["Leopard"] = true, 
        ["Spirit"] = true, ["Control"] = true, ["Venom"] = true, 
        ["Shadow"] = true, ["Dough"] = true, ["T-Rex"] = true, 
        ["Mammoth"] = true, ["Gravity"] = true, ["Blizzard"] = true, 
        ["Pain"] = true, ["Portal"] = true, ["Buddha"] = true, 
        ["Sound"] = true, ["Phoenix"] = true, ["Quake"] = true
    },

    DiscordWebhook = "" -- (Tùy chọn) Webhook nhận thông báo
}

local STATE = {
    IsPaused = false,
    CurrentStatus = "Đang khởi động...",
    FruitName = "Chưa phát hiện",
    FruitDistance = 0,
    HasFruit = false,
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
-- GIAO DIỆN HOLOGRAM CYBERPUNK NEON (MENU ĐẸP MẮT)
-- ==============================================================================
local function getGuiParent()
    if gethui then return gethui() end
    local s, g = pcall(function() return CoreGui end)
    if s and g then return g end
    return LocalPlayer:WaitForChild("PlayerGui")
end

pcall(function()
    local old = getGuiParent():FindFirstChild("HologramFruitSniper")
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HologramFruitSniper"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = getGuiParent()

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 360, 0, 260)
MainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 28)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local NeonStroke = Instance.new("UIStroke")
NeonStroke.Thickness = 2.4
NeonStroke.Color = Color3.fromRGB(0, 240, 255)
NeonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
NeonStroke.Parent = MainFrame

local StrokeGradient = Instance.new("UIGradient")
StrokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(0, 240, 255)),
    ColorSequenceKeypoint.new(0.35, Color3.fromRGB(255, 0, 128)),
    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(138, 43, 226)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(0, 240, 255))
})
StrokeGradient.Rotation = 45
StrokeGradient.Parent = NeonStroke

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundColor3 = Color3.fromRGB(20, 26, 48)
Header.BackgroundTransparency = 0.25
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 14)
HeaderCorner.Parent = Header

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(1, -70, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "✦ HOLOGRAM FRUIT SNIPER ✦"
TitleLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Header

local MinButton = Instance.new("TextButton")
MinButton.Name = "MinButton"
MinButton.Size = UDim2.new(0, 28, 0, 28)
MinButton.Position = UDim2.new(1, -36, 0, 7)
MinButton.BackgroundColor3 = Color3.fromRGB(28, 36, 65)
MinButton.Text = "—"
MinButton.TextColor3 = Color3.fromRGB(0, 240, 255)
MinButton.TextSize = 16
MinButton.Font = Enum.Font.GothamBold
MinButton.Parent = Header

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = MinButton

local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "Content"
ContentFrame.Size = UDim2.new(1, -20, 1, -100)
ContentFrame.Position = UDim2.new(0, 10, 0, 48)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local function createStatusRow(name, labelText, yPos)
    local row = Instance.new("Frame")
    row.Name = name
    row.Size = UDim2.new(1, 0, 0, 24)
    row.Position = UDim2.new(0, 0, 0, yPos)
    row.BackgroundColor3 = Color3.fromRGB(22, 28, 50)
    row.BackgroundTransparency = 0.45
    row.BorderSizePixel = 0
    row.Parent = ContentFrame

    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = UDim.new(0, 6)
    rCorner.Parent = row

    local tag = Instance.new("TextLabel")
    tag.Size = UDim2.new(0, 100, 1, 0)
    tag.Position = UDim2.new(0, 8, 0, 0)
    tag.BackgroundTransparency = 1
    tag.Text = labelText
    tag.TextColor3 = Color3.fromRGB(150, 180, 230)
    tag.TextSize = 11
    tag.Font = Enum.Font.GothamMedium
    tag.TextXAlignment = Enum.TextXAlignment.Left
    tag.Parent = row

    local val = Instance.new("TextLabel")
    val.Name = "Value"
    val.Size = UDim2.new(1, -115, 1, 0)
    val.Position = UDim2.new(0, 105, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = "Đang tải..."
    val.TextColor3 = Color3.fromRGB(0, 240, 255)
    val.TextSize = 11
    val.Font = Enum.Font.GothamBold
    val.TextXAlignment = Enum.TextXAlignment.Left
    val.Parent = row

    return val
end

local StatusVal = createStatusRow("StatusRow", "🛰️ Trạng thái:", 0)
local FruitVal = createStatusRow("FruitRow", "🍎 Phát hiện:", 28)
local SpeedVal = createStatusRow("SpeedRow", "⚡ Tốc độ bay:", 56)
local ServerVal = createStatusRow("ServerRow", "🌐 Máy chủ:", 84)

local ButtonsFrame = Instance.new("Frame")
ButtonsFrame.Name = "Buttons"
ButtonsFrame.Size = UDim2.new(1, -20, 0, 36)
ButtonsFrame.Position = UDim2.new(0, 10, 1, -44)
ButtonsFrame.BackgroundTransparency = 1
ButtonsFrame.Parent = MainFrame

local PauseBtn = Instance.new("TextButton")
PauseBtn.Name = "PauseBtn"
PauseBtn.Size = UDim2.new(0.48, 0, 1, 0)
PauseBtn.Position = UDim2.new(0, 0, 0, 0)
PauseBtn.BackgroundColor3 = Color3.fromRGB(22, 30, 55)
PauseBtn.Text = "⏸️ Tạm Dừng"
PauseBtn.TextColor3 = Color3.fromRGB(0, 240, 255)
PauseBtn.TextSize = 12
PauseBtn.Font = Enum.Font.GothamBold
PauseBtn.Parent = ButtonsFrame

local PauseCorner = Instance.new("UICorner")
PauseCorner.CornerRadius = UDim.new(0, 8)
PauseCorner.Parent = PauseBtn

local PauseStroke = Instance.new("UIStroke")
PauseStroke.Thickness = 1.2
PauseStroke.Color = Color3.fromRGB(0, 240, 255)
PauseStroke.Parent = PauseBtn

local HopBtn = Instance.new("TextButton")
HopBtn.Name = "HopBtn"
HopBtn.Size = UDim2.new(0.48, 0, 1, 0)
HopBtn.Position = UDim2.new(0.52, 0, 0, 0)
HopBtn.BackgroundColor3 = Color3.fromRGB(22, 30, 55)
HopBtn.Text = "🚀 Nhảy Server"
HopBtn.TextColor3 = Color3.fromRGB(255, 0, 128)
HopBtn.TextSize = 12
HopBtn.Font = Enum.Font.GothamBold
HopBtn.Parent = ButtonsFrame

local HopCorner = Instance.new("UICorner")
HopCorner.CornerRadius = UDim.new(0, 8)
HopCorner.Parent = HopBtn

local HopStroke = Instance.new("UIStroke")
HopStroke.Thickness = 1.2
HopStroke.Color = Color3.fromRGB(255, 0, 128)
HopStroke.Parent = HopBtn

-- Hiệu ứng Hologram viền xoay
task.spawn(function()
    while true do
        for rot = 0, 360, 2 do
            StrokeGradient.Rotation = rot
            task.wait(0.04)
        end
    end
end)

-- Kéo thả Menu
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

Header.InputBegan:Connect(function(input)
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

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

-- Thu nhỏ / phóng to
local isMinimized = false
MinButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        ContentFrame.Visible = false
        ButtonsFrame.Visible = false
        MainFrame.Size = UDim2.new(0, 360, 0, 42)
        MinButton.Text = "+"
    else
        MainFrame.Size = UDim2.new(0, 360, 0, 260)
        ContentFrame.Visible = true
        ButtonsFrame.Visible = true
        MinButton.Text = "—"
    end
end)

PauseBtn.MouseButton1Click:Connect(function()
    STATE.IsPaused = not STATE.IsPaused
    if STATE.IsPaused then
        PauseBtn.Text = "▶️ Tiếp Tục"
        PauseBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
        StatusVal.Text = "Tạm dừng theo yêu cầu"
    else
        PauseBtn.Text = "⏸️ Tạm Dừng"
        PauseBtn.TextColor3 = Color3.fromRGB(0, 240, 255)
        StatusVal.Text = "Đang tiếp tục săn..."
    end
end)

local function setStatus(text, color)
    STATE.CurrentStatus = text
    StatusVal.Text = text
    if color then StatusVal.TextColor3 = color end
end

-- HIỂN THỊ TÊN TRÁI MÀU TRẮNG KÈM KHOẢNG CÁCH MÉT
local function updateFruitDisplay(fruitName, distance)
    if fruitName then
        STATE.FruitName = fruitName
        STATE.FruitDistance = distance or 0
        FruitVal.Text = string.format("%s - %d m", fruitName, distance or 0)
        FruitVal.TextColor3 = Color3.fromRGB(255, 255, 255) -- MÀU TRẮNG
    else
        FruitVal.Text = "Không có trái spawn"
        FruitVal.TextColor3 = Color3.fromRGB(160, 170, 190)
    end
end

SpeedVal.Text = tostring(CONFIG.FlySpeed) .. " studs/s (Chậm êm, chống văng biển)"
ServerVal.Text = string.format("%d/%d người chơi", #Players:GetPlayers(), Players.MaxPlayers)

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

-- Tự động chọn phe khi vào game
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
-- HỆ THỐNG NOCLIP & KHÓA VẬN TỐC
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

        -- TÊN TRÁI MÀU TRẮNG
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

        -- KHOẢNG CÁCH MÉT
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
        if item:IsA("Tool") or item:IsA("Model") then
            local isFruit = false
            if string.find(item.Name:lower(), "fruit") or item:FindFirstChild("EatRemote", true) then
                isFruit = true
            end
            
            if isFruit then
                local handle = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
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
    end
    return fruits
end

-- ==============================================================================
-- NHẶT TRÁI CHUẨN XÁC VÀO TÚI
-- ==============================================================================
local function pickFruitProperly(fruitData)
    local char = getCharacter()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")
    
    setStatus("🚀 Đang bay êm ái tới: " .. fruitData.Name, Color3.fromRGB(0, 240, 255))
    safeFlyTo(fruitData.Handle.Position)
    
    setStatus("🍎 Đang nhặt trái...", Color3.fromRGB(255, 0, 128))
    
    local touchPart = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or hrp
    local startTime = tick()
    
    while fruitData.Object.Parent == Workspace and (tick() - startTime < 6) do
        pcall(function()
            fruitData.Handle.CFrame = hrp.CFrame
        end)
        
        if firetouchinterest and fruitData.Handle then
            pcall(function()
                firetouchinterest(touchPart, fruitData.Handle, 0)
                task.wait(0.05)
                firetouchinterest(touchPart, fruitData.Handle, 1)
                firetouchinterest(hrp, fruitData.Handle, 0)
                task.wait(0.05)
                firetouchinterest(hrp, fruitData.Handle, 1)
            end)
        end
        
        if fruitData.Object:IsA("Tool") then
            pcall(function()
                hum:EquipTool(fruitData.Object)
            end)
        end
        
        task.wait(0.2)
    end
    
    setHoldVelocity(hrp, false)
    task.wait(0.4)
    setStatus("✅ Đã nhặt thành công: " .. fruitData.Name, Color3.fromRGB(0, 255, 120))
end

-- ==============================================================================
-- TỰ ĐỘNG BẤM ĐỂ HIỆN LƯU TRỮ VÀ TỰ ĐỘNG BẤM LƯU TRỮ (STORE FRUIT HOÀN TOÀN TỰ ĐỘNG)
-- ==============================================================================
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

-- Kiểm tra xem trái còn trên người không (Balo hoặc Cầm tay)
local function isFruitStillInHandsOrBackpack(tool)
    if not tool or not tool.Parent then return false end
    if tool.Parent == LocalPlayer.Backpack then return true end
    if LocalPlayer.Character and tool.Parent == LocalPlayer.Character then return true end
    return false
end

-- Hàm thực hiện: Cầm trái -> Nhấn để hiện menu -> Bấm Lưu trữ (Store)
local function performStoreAction(tool)
    local char = getCharacter()
    local hum = char:WaitForChild("Humanoid")
    local commF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
    local fruitId = getStandardFruitId(tool)

    print(string.format("[STORE] Đang thực hiện thao tác cất trái: %s (ID: %s)", tool.Name, fruitId))

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
    local clickedButton = false

    if pGui then
        for _, btn in pairs(pGui:GetDescendants()) do
            if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                local bName = btn.Name:lower()
                local bText = tostring(btn.Text or ""):lower()
                local isStoreBtn = false

                -- Nhận diện nút Lưu trữ
                if bText == "store" or bText == "lưu trữ" or string.find(bText, "store") or string.find(bText, "lưu trữ") or bName == "store" or bName == "option3" then
                    isStoreBtn = true
                else
                    -- Kiểm tra xem nút có chứa TextLabel chữ "Store" / "Lưu trữ" bên trong không
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
                    clickedButton = true
                    task.wait(0.2)
                    break
                end
            end
        end
    end

    -- 4. ĐỒNG THỜI GỌI REMOTE VỚI ID CHUẨN XÁC ĐỂ ĐẢM BẢO 100% CẤT THÀNH CÔNG
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
    -- Bỏ cầm tay để về lại Balo nếu chưa cất được
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

        -- Thử liên tục 8 lần cho đến khi trái biến mất khỏi người
        for attempt = 1, 8 do
            if not isFruitStillInHandsOrBackpack(fruitTool) then
                storedSuccess = true
                print("✅ Trái " .. fruitTool.Name .. " đã được cất vào kho đồ thành công!")
                break
            end

            performStoreAction(fruitTool)
            task.wait(0.6)
        end

        -- Nếu sau 8 lần vẫn chưa cất được: kiểm tra xem có bị trùng kho không
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
local function safeQueueOnTeleport(code)
    pcall(function()
        if syn and syn.queue_on_teleport then syn.queue_on_teleport(code) end
    end)
    pcall(function()
        if queue_on_teleport then queue_on_teleport(code) end
    end)
    pcall(function()
        if fluxus and fluxus.queue_on_teleport then fluxus.queue_on_teleport(code) end
    end)
end

local function setupAutoRestart()
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
            if isfile and isfile("FruitSniper.lua") then
                loadstring(readfile("FruitSniper.lua"))()
            end
        ]]
    end
    safeQueueOnTeleport(reloadCmd)
    print("[AUTO-RESTART] Đã đăng ký thành công lệnh nạp lại cho server mới!")
end

-- ==============================================================================
-- TÌM SERVER ÍT NGƯỜI CHƠI NHẤT & CHUYỂN SERVER (SERVER HOP)
-- ==============================================================================
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
        
        while task.wait(1) do
            pcall(function()
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

HopBtn.MouseButton1Click:Connect(function()
    task.spawn(hopToLowPlayerServer)
end)

-- ==============================================================================
-- QUY TRÌNH CHÍNH (MAIN WORKFLOW)
-- ==============================================================================
local function runFruitHunter()
    while STATE.IsPaused do task.wait(1) end
    
    setStatus("🔍 Đang quét trái ác quỷ trong map...", Color3.fromRGB(0, 240, 255))
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
            setStatus("✅ Đã cất toàn bộ trái vào rương thành công!", Color3.fromRGB(0, 255, 120))
            task.wait(1.5)
        else
            -- Bị trùng kho đồ
            if failedTool then
                local isRare, rareName = isRareFruit(failedTool.Name)
                if isRare and CONFIG.DuplicateHandling == "StopIfRare" then
                    setStatus("⚠️ TRÙNG TRÁI QUÝ - ĐÃ DỪNG LẠI!", Color3.fromRGB(255, 50, 50))
                    print("==================================================")
                    print("[BẢO VỆ] Phát hiện trái quý bị trùng kho! Đã dừng lại để bạn tự xử lý.")
                    print("==================================================")
                    return -- DỪNG HẲN, KHÔNG NHẢY SERVER ĐỂ BẢO VỆ TRÁI
                else
                    -- Trái thường -> Vứt ra đất để dọn túi đồ
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
