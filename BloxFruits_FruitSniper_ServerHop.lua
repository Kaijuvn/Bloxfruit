if getgenv then
    getgenv().FruitSniperURL = "https://raw.githubusercontent.com/Kaijuvn/Bloxfruit/refs/heads/main/BloxFruits_FruitSniper_ServerHop.lua"
end
_G.FruitSniperURL = "https://raw.githubusercontent.com/Kaijuvn/Bloxfruit/refs/heads/main/BloxFruits_FruitSniper_ServerHop.lua"

if getgenv then
    if getgenv().VipFruitSniperActive then
        pcall(function()
            if getgenv().VipFruitSniperGui and getgenv().VipFruitSniperGui.Parent then
                getgenv().VipFruitSniperGui:Destroy()
            end
        end)
    end
    getgenv().VipFruitSniperActive = true
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
    GitHubRawURL = "https://raw.githubusercontent.com/Kaijuvn/Bloxfruit/refs/heads/main/BloxFruits_FruitSniper_ServerHop.lua",
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

    local url = CONFIG.GitHubRawURL
    if (not url or url == "") and getgenv and getgenv().FruitSniperURL then
        url = getgenv().FruitSniperURL
    end
    if (not url or url == "") and _G.FruitSniperURL then
        url = _G.FruitSniperURL
    end
    if (not url or url == "") and isfile and isfile("BF_ScriptURL.txt") then
        pcall(function() url = readfile("BF_ScriptURL.txt") end)
    end
    if not url or url == "" then
        url = "https://raw.githubusercontent.com/Kaijuvn/Bloxfruit/refs/heads/main/BloxFruits_FruitSniper_ServerHop.lua"
    end

    teleportQueued = true
    pcall(function()
        if writefile then writefile("BF_ScriptURL.txt", url) end
    end)

    local payload = string.format('task.spawn(function() repeat task.wait(0.5) until game:IsLoaded(); task.wait(2.5); pcall(function() loadstring(game:HttpGet("%s"))() end) end)', url)
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
    local old = getGuiParent():FindFirstChild("VipAnimeFruitSniper")
    if old then old:Destroy() end
end)

local ScreenGui
local ValAction
local ValFruit

do
ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VipAnimeFruitSniper"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = getGuiParent()
if getgenv then getgenv().VipFruitSniperGui = ScreenGui end

local MiniFrame = Instance.new("Frame")
MiniFrame.Name = "MiniFrame"
MiniFrame.Size = UDim2.new(0, 220, 0, 84)
MiniFrame.Position = UDim2.new(0.5, -110, 0.30, -42)
MiniFrame.BackgroundColor3 = Color3.fromRGB(10, 13, 24)
MiniFrame.BackgroundTransparency = 0.12
MiniFrame.BorderSizePixel = 0
MiniFrame.ClipsDescendants = true
MiniFrame.Parent = ScreenGui

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(0, 10)
MiniCorner.Parent = MiniFrame

local MiniStroke = Instance.new("UIStroke")
MiniStroke.Thickness = 1.6
MiniStroke.Color = Color3.fromRGB(0, 240, 255)
MiniStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MiniStroke.Parent = MiniFrame

local MiniStrokeGrad = Instance.new("UIGradient")
MiniStrokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(0, 240, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 240, 120)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 0, 128))
})
MiniStrokeGrad.Rotation = 90
MiniStrokeGrad.Parent = MiniStroke

task.spawn(function()
    local rot = 0
    while scriptActive and MiniFrame and MiniFrame.Parent do
        rot = (rot + 4) % 360
        MiniStrokeGrad.Rotation = rot
        task.wait(0.1)
    end
end)

local TitleRow = Instance.new("Frame")
TitleRow.Size = UDim2.new(1, -12, 0, 20)
TitleRow.Position = UDim2.new(0, 6, 0, 5)
TitleRow.BackgroundTransparency = 1
TitleRow.Parent = MiniFrame

local PulseDot = Instance.new("Frame")
PulseDot.Size = UDim2.new(0, 8, 0, 8)
PulseDot.Position = UDim2.new(0, 2, 0.5, -4)
PulseDot.BackgroundColor3 = Color3.fromRGB(0, 255, 140)
PulseDot.BorderSizePixel = 0
PulseDot.Parent = TitleRow

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = PulseDot

task.spawn(function()
    local t = 0
    while scriptActive and PulseDot and PulseDot.Parent do
        t = t + 0.15
        local a = (math.sin(t) + 1) / 2
        PulseDot.BackgroundTransparency = 0.15 + a * 0.55
        task.wait(0.06)
    end
end)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -40, 1, 0)
TitleLbl.Position = UDim2.new(0, 14, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "\u{1F34E} FINDER FRUIT \u{2022} nd.\u{26A1}"
TitleLbl.TextColor3 = Color3.fromRGB(0, 240, 255)
TitleLbl.TextSize = 11
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Parent = TitleRow

local TitleGrad = Instance.new("UIGradient")
TitleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(0, 240, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 240, 120)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 0, 160))
})
TitleGrad.Parent = TitleLbl

local HideBtn = Instance.new("TextButton")
HideBtn.Size = UDim2.new(0, 18, 0, 18)
HideBtn.Position = UDim2.new(1, -22, 0.5, -9)
HideBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 55)
HideBtn.Text = "-"
HideBtn.TextColor3 = Color3.fromRGB(0, 240, 255)
HideBtn.TextSize = 12
HideBtn.Font = Enum.Font.GothamBold
HideBtn.Parent = TitleRow

local HideCorner = Instance.new("UICorner")
HideCorner.CornerRadius = UDim.new(0, 5)
HideCorner.Parent = HideBtn

ValFruit = Instance.new("TextLabel")
ValFruit.Name = "ValFruit"
ValFruit.Size = UDim2.new(1, -16, 0, 20)
ValFruit.Position = UDim2.new(0, 8, 0, 27)
ValFruit.BackgroundTransparency = 1
ValFruit.Text = "Tr\u{00E1}i: Ch\u{01B0}a ph\u{00E1}t hi\u{1EC7}n"
ValFruit.TextColor3 = Color3.fromRGB(255, 255, 255)
ValFruit.TextSize = 12
ValFruit.Font = Enum.Font.GothamBold
ValFruit.TextXAlignment = Enum.TextXAlignment.Left
ValFruit.Parent = MiniFrame

ValAction = Instance.new("TextLabel")
ValAction.Name = "ValAction"
ValAction.Size = UDim2.new(1, -16, 0, 16)
ValAction.Position = UDim2.new(0, 8, 0, 47)
ValAction.BackgroundTransparency = 1
ValAction.Text = "\u{0110}ang qu\u{00E9}t map..."
ValAction.TextColor3 = Color3.fromRGB(0, 220, 255)
ValAction.TextSize = 9
ValAction.Font = Enum.Font.GothamMedium
ValAction.TextXAlignment = Enum.TextXAlignment.Left
ValAction.TextTruncate = Enum.TextTruncate.AtEnd
ValAction.Parent = MiniFrame

local FootSep = Instance.new("Frame")
FootSep.Size = UDim2.new(1, -16, 0, 1)
FootSep.Position = UDim2.new(0, 8, 0, 66)
FootSep.BackgroundColor3 = Color3.fromRGB(40, 55, 100)
FootSep.BorderSizePixel = 0
FootSep.Parent = MiniFrame

local FootLbl = Instance.new("TextLabel")
FootLbl.Size = UDim2.new(1, -16, 0, 12)
FootLbl.Position = UDim2.new(0, 8, 0, 69)
FootLbl.BackgroundTransparency = 1
FootLbl.Text = "T\u{1EF1} qu\u{00E9}t \u{2022} T\u{1EF1} nh\u{1EB7}t \u{2022} T\u{1EF1} c\u{1EA5}t \u{2022} T\u{1EF1} hop server"
FootLbl.TextColor3 = Color3.fromRGB(120, 150, 200)
FootLbl.TextSize = 8
FootLbl.Font = Enum.Font.GothamMedium
FootLbl.TextXAlignment = Enum.TextXAlignment.Center
FootLbl.Parent = MiniFrame

local DotBtn = Instance.new("ImageButton")
DotBtn.Name = "FloatingGojoBtn"
DotBtn.Size = UDim2.new(0, 44, 0, 44)
DotBtn.Position = UDim2.new(0.03, 0, 0.3, 0)
DotBtn.BackgroundColor3 = Color3.fromRGB(12, 15, 28)
DotBtn.Image = GojoIconAsset
DotBtn.ScaleType = Enum.ScaleType.Crop
DotBtn.Visible = false
DotBtn.ClipsDescendants = true
DotBtn.Parent = ScreenGui

local DotBtnCorner = Instance.new("UICorner")
DotBtnCorner.CornerRadius = UDim.new(0, 10)
DotBtnCorner.Parent = DotBtn

local DotBtnStroke = Instance.new("UIStroke")
DotBtnStroke.Thickness = 1.6
DotBtnStroke.Color = Color3.fromRGB(0, 240, 255)
DotBtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
DotBtnStroke.Parent = DotBtn

local DotBtnGrad = Instance.new("UIGradient")
DotBtnGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(0, 240, 255)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 0, 128))
})
DotBtnGrad.Parent = DotBtnStroke

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
            if delta.Magnitude > 6 then hasMoved = true end
            targetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    return function() return hasMoved end
end

makeDraggable(MiniFrame, MiniFrame)
local getDotMoved = makeDraggable(DotBtn, DotBtn)

HideBtn.MouseButton1Click:Connect(function()
    MiniFrame.Visible = false
    DotBtn.Visible = true
end)

DotBtn.MouseButton1Click:Connect(function()
    if getDotMoved and getDotMoved() then return end
    DotBtn.Visible = false
    MiniFrame.Visible = true
end)

end

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
            local tUp = TweenService:Create(hrp, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {CFrame = upCF})
            tUp:Play()
            tUp.Completed:Wait()
        end)
    end

    if not hrp or not hrp.Parent then disableNoclip() return end

    local skyTarget = Vector3.new(targetPos.X, safeY, targetPos.Z)
    local distHoriz = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude

    if distHoriz > 15 then
        local durHoriz = math.clamp(distHoriz / CONFIG.FlySpeed, 0.4, 30)
        pcall(function()
            local currentTween = TweenService:Create(hrp, TweenInfo.new(durHoriz, Enum.EasingStyle.Linear), {CFrame = CFrame.new(skyTarget)})
            currentTween:Play()
            currentTween.Completed:Wait()
        end)
    end

    if not hrp or not hrp.Parent then disableNoclip() return end

    local landCF = CFrame.new(targetPos + Vector3.new(0, 1.2, 0))
    local landDist = (hrp.Position - landCF.Position).Magnitude
    local durLand = math.clamp(landDist / (CONFIG.FlySpeed * 0.8), 0.3, 3)

    pcall(function()
        local landTween = TweenService:Create(hrp, TweenInfo.new(durLand, Enum.EasingStyle.Linear), {CFrame = landCF})
        landTween:Play()
        landTween.Completed:Wait()
    end)

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
        if anc.Name == "VipAnimeFruitSniper" then return true end
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
        local ok, err = pcall(runFruitHunter)
        if not ok then
            task.wait(3)
        else
            break
        end
    end
end)
