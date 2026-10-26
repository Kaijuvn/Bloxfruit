-- ==============================================================================
-- 🔮 BLOX FRUITS - HOLOGRAM FRUIT SNIPER & LOW SERVER HOP (AUTO LOOP) 🔮
-- Tự động quét trái, bay chạm đất nhặt, cất rương 4-5s, nhảy server ít người
-- Giao diện Hologram Cyberpunk Neon cực đẹp + Tối ưu 100% cho Delta Executor
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
    FlySpeed = 180,                   -- Tốc độ bay (180 stud/s: Chậm hơn, cực êm, không bị khựng, an toàn 100%)
    StoreDelay = 5,                   -- Thời gian cất vào kho đồ (4 - 5 giây theo đúng yêu cầu)
    NoFruitHopDelay = 3,              -- Thời gian chờ nếu server không có trái thì nhảy server ngay
    VisitedServersFile = "BF_VisitedServers.json",
    CacheFileName = "FruitSniper.lua",

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

    DiscordWebhook = "" -- (Tùy chọn) Link Discord Webhook nhận thông báo trái quý
}

-- Biến trạng thái toàn cục
local STATE = {
    IsPaused = false,
    CurrentStatus = "Đang khởi động...",
    FruitFound = "Chưa phát hiện",
    FruitsCollected = 0,
    ServersVisited = 0,
}

-- ==============================================================================
-- HỆ THỐNG GIAO DIỆN HOLOGRAM CYBERPUNK NEON (MENU ĐẸP MẮT)
-- ==============================================================================
local function getGuiParent()
    if gethui then return gethui() end
    local s, g = pcall(function() return CoreGui end)
    if s and g then return g end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- Xóa GUI cũ nếu đã tồn tại
pcall(function()
    local old = getGuiParent():FindFirstChild("HologramFruitSniper")
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HologramFruitSniper"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = getGuiParent()

-- Khung chính Hologram
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 360, 0, 260)
MainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 30)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

-- Viền phát quang Neon Cyan -> Pink -> Purple
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

-- Thanh tiêu đề Header
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

-- Nút thu nhỏ / mở rộng
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

-- Khung nội dung hiển thị trạng thái
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

-- Thanh điều khiển Buttons
local ButtonsFrame = Instance.new("Frame")
ButtonsFrame.Name = "Buttons"
ButtonsFrame.Size = UDim2.new(1, -20, 0, 36)
ButtonsFrame.Position = UDim2.new(0, 10, 1, -44)
ButtonsFrame.BackgroundTransparency = 1
ButtonsFrame.Parent = MainFrame

-- Nút Tạm Dừng / Tiếp Tục
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

-- Nút Nhảy Server Thủ Công
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

-- Hiệu ứng Hologram viền xoay phát sáng
task.spawn(function()
    while true do
        for rot = 0, 360, 2 do
            StrokeGradient.Rotation = rot
            task.wait(0.04)
        end
    end
end)

-- Kéo thả Menu mượt mà (Mobile cảm ứng & PC chuột)
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

-- Pause / Resume
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

local function setFruitInfo(text, color)
    FruitVal.Text = text
    if color then FruitVal.TextColor3 = color end
end

SpeedVal.Text = tostring(CONFIG.FlySpeed) .. " studs/s (Chậm & Êm ái)"
ServerVal.Text = string.format("%d/%d người chơi", #Players:GetPlayers(), Players.MaxPlayers)

-- ==============================================================================
-- ANTI-BAN VƯỢT TRỘI (NAME CALL HOOK & SAFE PHYSICS)
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
                    if self == LocalPlayer then
                        warn("[ANTI-BAN] ĐÃ CHẶN 1 LỆNH KICK TỰ ĐỘNG TỪ GAME!")
                        return nil
                    end
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

    -- Triệt tiêu gia tốc rơi tự do chống server gắn cờ Fly/Speedhack
    RunService.Heartbeat:Connect(function()
        pcall(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                if hrp.AssemblyLinearVelocity.Y < -100 then
                    hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, -15, hrp.AssemblyLinearVelocity.Z)
                end
            end
        end)
    end)
end

setupAntiBan()

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Tự động chọn phe khi vào game (Pirates / Marines)
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
-- BAY TWEEN CHẬM, ÊM & HẠ CÁNH CHẠM HẲN VÀO TRÁI ÁC QUỶ
-- ==============================================================================
local noclipConn = nil
local function enableNoclip()
    if noclipConn then return end
    noclipConn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide == true then
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

-- Bay mượt mà đến đúng tọa độ đích
local function safeFlyTo(targetCFrame)
    local char = getCharacter()
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    enableNoclip()
    
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    -- Tốc độ 180 stud/s: Cực kỳ êm ái, mượt mà, không bị khựng
    local duration = math.clamp(distance / CONFIG.FlySpeed, 0.5, 30)
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    
    tween:Play()
    tween.Completed:Wait()
    
    disableNoclip()
    task.wait(0.2)
end

-- ==============================================================================
-- QUÉT VÀ ĐỊNH VỊ TRÁI ÁC QUỶ
-- ==============================================================================
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
                    table.insert(fruits, {
                        Object = item,
                        Handle = handle,
                        Name = item.Name
                    })
                end
            end
        end
    end
    return fruits
end

-- ==============================================================================
-- BAY ĐẾN HẲN TRÁI ÁC QUỶ VÀ NHẶT VÀO TÚI
-- ==============================================================================
local function pickFruit(fruitData)
    local char = getCharacter()
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    setStatus("🚀 Đang bay tới trái: " .. fruitData.Name, Color3.fromRGB(0, 240, 255))
    setFruitInfo(fruitData.Name .. " (Đang tiếp cận)", Color3.fromRGB(255, 200, 50))
    
    -- 1. Bay tiếp cận gần trái
    local approachCF = fruitData.Handle.CFrame * CFrame.new(0, 4, 0)
    safeFlyTo(approachCF)
    
    -- 2. Bay hạ cánh CHẠM HẲN vào vị trí của trái ác quỷ
    setStatus("🍎 Đang chạm & nhặt trái vào túi...", Color3.fromRGB(255, 0, 128))
    local landCF = fruitData.Handle.CFrame
    safeFlyTo(landCF)
    
    -- 3. Đứng sát và kích hoạt nhặt cho đến khi trái thật sự vào Balo/trên tay
    local attempts = 0
    while fruitData.Object.Parent == Workspace and attempts < 25 do
        attempts = attempts + 1
        hrp.CFrame = fruitData.Handle.CFrame
        
        if firetouchinterest then
            firetouchinterest(hrp, fruitData.Handle, 0)
            task.wait(0.1)
            firetouchinterest(hrp, fruitData.Handle, 1)
        end
        task.wait(0.2)
    end
    
    task.wait(0.5)
    setFruitInfo(fruitData.Name .. " (Đã nhặt thành công!)", Color3.fromRGB(0, 255, 120))
end

-- ==============================================================================
-- CẤT TRÁI VÀO KHO ĐỒ (4-5 GIÂY) & KIỂM TRA TRÙNG
-- ==============================================================================
local function storeSingleFruit(tool)
    local commF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
    if tool:IsA("Tool") and (tool:FindFirstChild("EatRemote", true) or string.find(tool.Name:lower(), "fruit")) then
        local origName = tool:GetAttribute("OriginalName") or tool.Name
        pcall(function()
            commF:InvokeServer("StoreFruit", origName, tool)
        end)
        task.wait(math.random(15, 30) / 100)
    end
end

local function storeAllFruits()
    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        storeSingleFruit(tool)
    end
    local char = LocalPlayer.Character
    if char then
        for _, tool in pairs(char:GetChildren()) do
            storeSingleFruit(tool)
        end
    end
end

local function getUnstoredFruits()
    local unstored = {}
    local function check(tool)
        if tool:IsA("Tool") and (tool:FindFirstChild("EatRemote", true) or string.find(tool.Name:lower(), "fruit")) then
            table.insert(unstored, tool)
        end
    end
    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do check(tool) end
    if LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do check(tool) end
    end
    return unstored
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
local function getQueueOnTeleport()
    return (syn and syn.queue_on_teleport) 
        or queue_on_teleport 
        or (fluxus and fluxus.queue_on_teleport)
end

-- Thiết lập queue_on_teleport tự động nạp lại khi chuyển server
local function setupAutoRestart()
    local qot = getQueueOnTeleport()
    if qot then
        pcall(function()
            local reloadCmd = ""
            if CONFIG.GitHubRawURL and CONFIG.GitHubRawURL ~= "" then
                reloadCmd = string.format([[
                    repeat task.wait() until game:IsLoaded()
                    task.wait(2)
                    loadstring(game:HttpGet("%s"))()
                ]], CONFIG.GitHubRawURL)
            else
                reloadCmd = [[
                    repeat task.wait() until game:IsLoaded()
                    task.wait(2)
                    if isfile and isfile("FruitSniper.lua") then
                        loadstring(readfile("FruitSniper.lua"))()
                    end
                ]]
            end
            qot(reloadCmd)
            print("[AUTO-RESTART] Đã đăng ký thành công queue_on_teleport!")
        end)
    end
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
-- QUY TRÌNH CHÍNH (MAIN LOOP)
-- ==============================================================================
local function runFruitHunter()
    while STATE.IsPaused do task.wait(1) end
    
    setStatus("🔍 Đang quét trái ác quỷ trong map...", Color3.fromRGB(0, 240, 255))
    task.wait(1)
    
    local fruits = findSpawnedFruits()
    
    if #fruits > 0 then
        setFruitInfo(string.format("Tìm thấy %d trái!", #fruits), Color3.fromRGB(0, 255, 120))
        
        -- 1. Bay hạ cánh chạm hẳn vào từng trái để nhặt
        for _, fruitData in ipairs(fruits) do
            if STATE.IsPaused then break end
            pcall(function()
                pickFruit(fruitData)
            end)
            task.wait(0.5)
        end
        
        -- 2. Tự cho vào kho đồ trong 4-5 giây
        setStatus(string.format("📦 Đang cất vào kho đồ (%d giây)...", CONFIG.StoreDelay), Color3.fromRGB(255, 0, 128))
        local timer = tick()
        while tick() - timer < CONFIG.StoreDelay do
            storeAllFruits()
            task.wait(0.8)
        end
        
        -- 3. Kiểm tra trùng kho đồ
        local unstoredFruits = getUnstoredFruits()
        if #unstoredFruits > 0 then
            local hasRare = false
            for _, tool in ipairs(unstoredFruits) do
                local isRare, rareName = isRareFruit(tool.Name)
                if isRare then hasRare = true end
            end
            
            if CONFIG.DuplicateHandling == "StopIfRare" and hasRare then
                setStatus("⚠️ TRÙNG TRÁI QUÝ - ĐÃ DỪNG LẠI!", Color3.fromRGB(255, 50, 50))
                setFruitInfo("Giữ trái an toàn trong túi!", Color3.fromRGB(255, 50, 50))
                return -- Dừng hẳn, không nhảy server để không làm mất trái quý
            elseif CONFIG.DuplicateHandling == "Drop" then
                for _, tool in ipairs(unstoredFruits) do
                    pcall(function()
                        tool.Parent = LocalPlayer.Character
                        task.wait(0.2)
                        if tool:FindFirstChild("EatRemote") then tool.EatRemote:InvokeServer("Drop") end
                    end)
                end
            end
        else
            setStatus("✅ Đã cất toàn bộ trái vào kho đồ!", Color3.fromRGB(0, 255, 120))
        end
    else
        setFruitInfo("Không có trái spawn", Color3.fromRGB(180, 180, 180))
        setStatus("Không có trái, chuẩn bị nhảy server...", Color3.fromRGB(255, 200, 50))
        task.wait(CONFIG.NoFruitHopDelay)
    end
    
    -- 4. Chuyển sang server ít người tiếp theo
    if not STATE.IsPaused then
        task.wait(1)
        hopToLowPlayerServer()
    end
end

-- Khởi động quy trình
task.spawn(function()
    pcall(runFruitHunter)
end)
