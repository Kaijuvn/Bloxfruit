--[[
==========================================
          MAKE BY NDUNG HUB V3
          BLOX FRUITS MOBILE
          SEA 1 / SEA 2 / SEA 3
==========================================

Developer: NDung
Version: 3.0
Executor: Delta Mobile
UI: Custom Purple
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- SERVICES

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

-- REMOVE OLD HUB

if _G.NDungV3 then
    _G.NDungV3.Running = false

    if _G.NDungV3.Stop then
        pcall(_G.NDungV3.Stop)
    end
end

local OldGui = PlayerGui:FindFirstChild("NDungHubV3")

if OldGui then
    OldGui:Destroy()
end

-- HUB CORE

local Hub = {
    Running = true,
    Version = "3.0",
    Connections = {},
    CurrentTween = nil
}

_G.NDungV3 = Hub

local SeaIds = {
    [2753915549] = 1,
    [4442272183] = 2,
    [7449423635] = 3
}

Hub.Sea = SeaIds[game.PlaceId] or 0

Hub.Settings = {
    AutoFarm = false,
    AutoQuest = true,
    AutoHaki = true,
    FastAttack = true,
    BringMob = false,
    NoClip = true,

    AutoBoss = false,
    AutoChest = false,
    AutoFruit = false,
    FruitESP = false,

    AutoStats = false,
    SelectedStat = "Melee",
    SelectedWeapon = "Melee",

    AntiAFK = true,
    FPSBoost = false,

    TweenSpeed = 250,
    FarmDistance = 8
}

local S = Hub.Settings

-- CORE FUNCTIONS

function Hub.GetCharacter()
    return LP.Character
end

function Hub.GetRoot()
    local char = Hub.GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

function Hub.GetHumanoid()
    local char = Hub.GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function Hub.GetLevel()
    local data = LP:FindFirstChild("Data")
    local level = data and data:FindFirstChild("Level")
    return level and level.Value or 1
end

function Hub.GetPoints()
    local data = LP:FindFirstChild("Data")
    local points = data and data:FindFirstChild("Points")
    return points and points.Value or 0
end

function Hub.GetEnemies()
    return Workspace:FindFirstChild("Enemies")
end

function Hub.GetDistance(pos)
    local root = Hub.GetRoot()
    return root and (root.Position - pos).Magnitude or math.huge
end

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
Hub.CommF = Remotes and Remotes:FindFirstChild("CommF_")

function Hub.Invoke(...)
    if not Hub.CommF then
        return nil
    end

    local args = {...}

    local ok, result = pcall(function()
        return Hub.CommF:InvokeServer(unpack(args))
    end)

    if ok then
        return result
    end

    warn("[NDung Hub Remote]", result)
    return nil
end

function Hub.Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 4
        })
    end)
end

function Hub.AddConnection(connection)
    table.insert(Hub.Connections, connection)
    return connection
end

function Hub.CreateLoop(name, delay, callback)
    task.spawn(function()
        while Hub.Running do
            task.wait(delay)

            if not Hub.Running then
                break
            end

            local ok, err = pcall(callback)

            if not ok then
                warn("[NDung Hub][" .. name .. "]", err)
            end
        end
    end)
end

function Hub.Stop()
    Hub.Running = false

    if Hub.CurrentTween then
        pcall(function()
            Hub.CurrentTween:Cancel()
        end)
    end

    for _, connection in ipairs(Hub.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    if Hub.Gui then
        Hub.Gui:Destroy()
    end
end

-- UI COLORS

local Colors = {
    Background = Color3.fromRGB(15, 15, 24),
    Sidebar = Color3.fromRGB(22, 20, 35),
    Card = Color3.fromRGB(32, 30, 46),
    Purple = Color3.fromRGB(155, 95, 255),
    PurpleDark = Color3.fromRGB(85, 45, 155),
    White = Color3.fromRGB(245, 245, 255),
    Gray = Color3.fromRGB(165, 165, 185),
    Green = Color3.fromRGB(90, 235, 145),
    Red = Color3.fromRGB(255, 100, 120)
}

-- UI HELPERS

local function New(class, properties)
    local object = Instance.new(class)

    for key, value in pairs(properties) do
        object[key] = value
    end

    return object
end

local function Round(parent, radius)
    return New("UICorner", {
        CornerRadius = UDim.new(0, radius),
        Parent = parent
    })
end

local function Stroke(parent, color, thickness)
    return New("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Parent = parent
    })
end

local function Label(parent, text, size, color)
    return New("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or Colors.White,
        TextSize = size or 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent
    })
end

-- SCREEN GUI

local Gui = New("ScreenGui", {
    Name = "NDungHubV3",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = PlayerGui
})

Hub.Gui = Gui

-- MAIN WINDOW

local Main = New("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(350, 420),
    Position = UDim2.new(0.5, -175, 0.5, -210),
    BackgroundColor3 = Colors.Background,
    BorderSizePixel = 0,
    Active = true,
    Parent = Gui
})

Round(Main, 14)
Stroke(Main, Colors.Purple, 1.5)

-- HEADER

local Header = New("Frame", {
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = Colors.Sidebar,
    BorderSizePixel = 0,
    Active = true,
    Parent = Main
})

Round(Header, 14)

local Title = Label(
    Header,
    "MAKE By NDung",
    20,
    Colors.Purple
)

Title.Position = UDim2.fromOffset(15, 7)
Title.Size = UDim2.new(1, -65, 0, 26)

local Subtitle = Label(
    Header,
    "Blox Fruits | Sea " .. Hub.Sea .. " | V3",
    11,
    Colors.Gray
)

Subtitle.Position = UDim2.fromOffset(15, 34)
Subtitle.Size = UDim2.new(1, -65, 0, 16)

local Minimize = New("TextButton", {
    Size = UDim2.fromOffset(38, 38),
    Position = UDim2.new(1, -46, 0, 10),
    BackgroundTransparency = 1,
    Text = "−",
    TextColor3 = Colors.White,
    TextSize = 28,
    Font = Enum.Font.GothamBold,
    Parent = Header
})

-- FLOAT BUTTON

local Float = New("TextButton", {
    Name = "FloatingButton",
    Size = UDim2.fromOffset(55, 55),
    Position = UDim2.new(0, 15, 0.45, 0),
    BackgroundColor3 = Colors.PurpleDark,
    Text = "ND",
    TextSize = 20,
    TextColor3 = Colors.White,
    Font = Enum.Font.GothamBold,
    Visible = false,
    Active = true,
    Parent = Gui
})

Round(Float, 28)
Stroke(Float, Colors.Purple, 2)

Minimize.MouseButton1Click:Connect(function()
    Main.Visible = false
    Float.Visible = true
end)

Float.MouseButton1Click:Connect(function()
    Main.Visible = true
    Float.Visible = false
end)

-- DRAG SYSTEM

local function MakeDraggable(frame, handle)
    local dragging = false
    local dragInput
    local dragStart
    local startPosition

    Hub.AddConnection(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then

            dragging = true
            dragStart = input.Position
            startPosition = frame.Position
            dragInput = input
        end
    end))

    Hub.AddConnection(handle.InputEnded:Connect(function(input)
        if input == dragInput then
            dragging = false
        end
    end))

    Hub.AddConnection(UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseMovement then

            local delta = input.Position - dragStart

            frame.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end))
end

MakeDraggable(Main, Header)
MakeDraggable(Float, Float)

-- SIDEBAR

local Sidebar = New("ScrollingFrame", {
    Size = UDim2.new(0, 105, 1, -68),
    Position = UDim2.fromOffset(7, 62),
    BackgroundColor3 = Colors.Sidebar,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent = Main
})

Round(Sidebar, 9)

New("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = Sidebar
})

New("UIPadding", {
    PaddingTop = UDim.new(0, 7),
    PaddingLeft = UDim.new(0, 5),
    PaddingRight = UDim.new(0, 5),
    Parent = Sidebar
})

-- CONTENT HOLDER

local ContentHolder = New("Frame", {
    Size = UDim2.new(1, -125, 1, -70),
    Position = UDim2.fromOffset(118, 63),
    BackgroundTransparency = 1,
    Parent = Main
})

local Tabs = {}
local ActiveTab = nil

-- CREATE TAB

function Hub.CreateTab(name)
    local TabButton = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 37),
        BackgroundColor3 = Colors.Card,
        Text = name,
        TextColor3 = Colors.Gray,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Parent = Sidebar
    })

    Round(TabButton, 7)

    local Page = New("ScrollingFrame", {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Colors.Purple,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = ContentHolder
    })

    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Page
    })

    New("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 8),
        Parent = Page
    })

    local Tab = {
        Name = name,
        Button = TabButton,
        Page = Page
    }

    function Tab:Show()
        for _, other in pairs(Tabs) do
            other.Page.Visible = false
            other.Button.BackgroundColor3 = Colors.Card
            other.Button.TextColor3 = Colors.Gray
        end

        Page.Visible = true
        TabButton.BackgroundColor3 = Colors.PurpleDark
        TabButton.TextColor3 = Colors.White

        ActiveTab = Tab
    end

    TabButton.MouseButton1Click:Connect(function()
        Tab:Show()
    end)

    table.insert(Tabs, Tab)

    if not ActiveTab then
        Tab:Show()
    end

    return Tab
end

-- SECTION

function Hub.AddSection(tab, text)
    local section = Label(
        tab.Page,
        text,
        13,
        Colors.Purple
    )

    section.Size = UDim2.new(1, 0, 0, 25)

    return section
end

-- TOGGLE

function Hub.AddToggle(tab, name, setting)
    local Button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundColor3 = Colors.Card,
        Text = "",
        Parent = tab.Page
    })

    Round(Button, 8)

    local Text = Label(Button, name, 11, Colors.White)
    Text.Position = UDim2.fromOffset(9, 0)
    Text.Size = UDim2.new(1, -53, 1, 0)

    local Status = Label(Button, "", 11)
    Status.Position = UDim2.new(1, -43, 0, 0)
    Status.Size = UDim2.fromOffset(40, 45)
    Status.TextXAlignment = Enum.TextXAlignment.Center

    local function Update()
        Status.Text = S[setting] and "ON" or "OFF"

        Status.TextColor3 = S[setting]
            and Colors.Green
            or Colors.Red
    end

    Button.MouseButton1Click:Connect(function()
        S[setting] = not S[setting]
        Update()
    end)

    Update()

    return Button
end

-- DROPDOWN / SELECTOR

function Hub.AddDropdown(tab, name, setting, options)
    local index = 1

    for i, option in ipairs(options) do
        if option == S[setting] then
            index = i
            break
        end
    end

    local Button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundColor3 = Colors.Card,
        Text = "",
        TextColor3 = Colors.White,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        Parent = tab.Page
    })

    Round(Button, 8)

    local function Update()
        Button.Text = name .. "\n" .. options[index] .. "  >"
    end

    Button.MouseButton1Click:Connect(function()
        index = index % #options + 1
        S[setting] = options[index]
        Update()
    end)

    Update()

    return Button
end

-- BUTTON

function Hub.AddButton(tab, name, callback)
    local Button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 43),
        BackgroundColor3 = Colors.PurpleDark,
        Text = name,
        TextColor3 = Colors.White,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Parent = tab.Page
    })

    Round(Button, 8)

    Button.MouseButton1Click:Connect(function()
        local ok, err = pcall(callback)

        if not ok then
            warn("[NDung Button]", err)
        end
    end)

    return Button
end

-- CREATE ALL TABS

Hub.Tabs = {
    Farm = Hub.CreateTab("Farm"),
    Combat = Hub.CreateTab("Combat"),
    Boss = Hub.CreateTab("Boss"),
    Fruit = Hub.CreateTab("Fruit"),
    Stats = Hub.CreateTab("Stats"),
    Teleport = Hub.CreateTab("Teleport"),
    Settings = Hub.CreateTab("Settings")
}

local T = Hub.Tabs

-- FARM

Hub.AddSection(T.Farm, "AUTO FARM")

Hub.AddToggle(T.Farm, "Auto Farm Level", "AutoFarm")
Hub.AddToggle(T.Farm, "Auto Quest", "AutoQuest")
Hub.AddToggle(T.Farm, "Bring Mob", "BringMob")

Hub.AddDropdown(
    T.Farm,
    "Weapon",
    "SelectedWeapon",
    {"Melee", "Sword", "Fruit", "Gun"}
)

-- COMBAT

Hub.AddSection(T.Combat, "COMBAT")

Hub.AddToggle(T.Combat, "Fast Attack", "FastAttack")
Hub.AddToggle(T.Combat, "Auto Haki", "AutoHaki")
Hub.AddToggle(T.Combat, "NoClip", "NoClip")

-- BOSS

Hub.AddSection(T.Boss, "BOSS FARM")

Hub.AddToggle(T.Boss, "Auto Boss", "AutoBoss")

-- FRUIT

Hub.AddSection(T.Fruit, "BLOX FRUITS")

Hub.AddToggle(T.Fruit, "Auto Fruit", "AutoFruit")
Hub.AddToggle(T.Fruit, "Fruit ESP", "FruitESP")

-- STATS

Hub.AddSection(T.Stats, "AUTO STATS")

Hub.AddToggle(T.Stats, "Auto Stats", "AutoStats")

Hub.AddDropdown(
    T.Stats,
    "Select Stat",
    "SelectedStat",
    {"Melee", "Defense", "Sword", "Gun", "Demon Fruit"}
)

-- SETTINGS

Hub.AddSection(T.Settings, "PLAYER SETTINGS")

Hub.AddToggle(T.Settings, "Anti AFK", "AntiAFK")
Hub.AddToggle(T.Settings, "FPS Boost", "FPSBoost")

Hub.AddButton(T.Settings, "Rejoin Server", function()
    TeleportService:Teleport(game.PlaceId, LP)
end)

Hub.AddButton(T.Settings, "Stop Hub", function()
    Hub.Stop()
end)

-- INFO

Hub.AddSection(
    T.Settings,
    "MAKE By NDung V3"
)

-- LIVE LEVEL UPDATE

local LevelInfo = Label(
    Header,
    "",
    10,
    Colors.Gray
)

LevelInfo.Size = UDim2.fromOffset(110, 18)
LevelInfo.Position = UDim2.new(1, -120, 1, -20)
LevelInfo.TextXAlignment = Enum.TextXAlignment.Right

Hub.CreateLoop("LevelDisplay", 1, function()
    LevelInfo.Text = "Lv. " .. Hub.GetLevel()
end)

-- START MESSAGE

Hub.Notify(
    "MAKE By NDung V3",
    "Giao diện Mobile đã tải thành công!"
)

print("[MAKE By NDung] UI Loaded")