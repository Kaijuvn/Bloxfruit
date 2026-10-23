-- [[ NDUNG HUB - FRAMEWORK SEA 1 TO SEA 3 ]] --
-- [[ TỐI ƯU HÓA 100% CHO DELTA EXECUTOR MOBILE ]] --

pcall(function()
    setthreadidentity(8)
end)

-- 1. XÁC ĐỊNH SEA HIỆN TẠI QUA PLACE ID
local PlaceId = game.PlaceId
local CurrentSea = 0
if PlaceId == 2753915549 then
    CurrentSea = 1
elseif PlaceId == 4442272183 then
    CurrentSea = 2
elseif PlaceId == 7449423635 then
    CurrentSea = 3
else
    CurrentSea = 1 -- Mặc định nếu test server
end

-- 2. TẢI REDZ UI LIBRARY (THƯ VIỆN CHUYÊN DÀNH CHO MOBILE CỰC MƯỢT)
local RedzLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/realredz/RedzLibV5/refs/heads/main/Source.lua"))()

local Window = RedzLib:MakeWindow({
    Title = "NDung Hub | Sea " .. tostring(CurrentSea),
    SubTitle = "Mobile Ultimate Edition",
    SaveFolder = "NDungHub_BF"
})

-- Nút nổi thu nhỏ/mở menu trên màn hình cảm ứng
Window:AddMinimizeButton({
    Button = { Image = "rbxassetid://18751483361", BackgroundColor3 = Color3.fromRGB(20, 20, 20) },
    Corner = { CornerRadius = UDim.new(0, 8) }
})

-- 3. CÁC BIẾN TOÀN CỤC & SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

_G.Settings = {
    AutoFarm = false,
    AutoQuest = true,
    BringMob = true,
    FastAttack = true,
    AutoHaki = true,
    SelectedWeapon = "Melee", -- Melee, Sword, Blox Fruit
    AutoStats = false,
    SelectedStat = "Melee", -- Melee, Defense, Sword, Gun, Demon Fruit
    TweenSpeed = 300,
    DistanceFarm = 12 -- Khoảng cách đứng trên đầu quái
}

-- Tìm Remote CommF_
local CommF = nil
for _, v in pairs(ReplicatedStorage:GetDescendants()) do
    if v.Name == "CommF_" then
        CommF = v
        break
    end
end

-- 4. CƠ SỞ DỮ LIỆU NHIỆM VỤ (SEA 1, 2, 3)
local Database = {
    [1] = { -- SEA 1
        {Level = 0, QuestName = "BanditQuest1", QuestNum = 1, MobName = "Bandit", Pos = Vector3.new(1059, 16, 1549)},
        {Level = 15, QuestName = "JungleQuest", QuestNum = 1, MobName = "Monkey", Pos = Vector3.new(-1601, 37, 153)},
        {Level = 30, QuestName = "JungleQuest", QuestNum = 2, MobName = "Gorilla", Pos = Vector3.new(-1601, 37, 153)},
        {Level = 60, QuestName = "DesertQuest", QuestNum = 1, MobName = "Desert Bandit", Pos = Vector3.new(896, 6, 4388)},
        {Level = 90, QuestName = "SnowQuest", QuestNum = 1, MobName = "Snow Bandit", Pos = Vector3.new(1385, 87, -1298)},
        {Level = 120, QuestName = "MarineQuest2", QuestNum = 1, MobName = "Chief Petty Officer", Pos = Vector3.new(-5030, 28, 4324)},
        {Level = 190, QuestName = "PrisonerQuest", QuestNum = 1, MobName = "Prisoner", Pos = Vector3.new(5308, 1, 475)},
        {Level = 300, QuestName = "MagmaQuest", QuestNum = 1, MobName = "Military Soldier", Pos = Vector3.new(-5313, 12, 8515)},
        {Level = 450, QuestName = "SkyDiveQuest", QuestNum = 1, MobName = "God's Guard", Pos = Vector3.new(-7861, 5545, -380)},
        {Level = 625, QuestName = "FountainQuest", QuestNum = 1, MobName = "Galley Pirate", Pos = Vector3.new(5258, 38, 4050)}
    },
    [2] = { -- SEA 2
        {Level = 700, QuestName = "Area1Quest", QuestNum = 1, MobName = "Raider [Lv. 700]", Pos = Vector3.new(-4295, 73, 1836)},
        {Level = 775, QuestName = "Area2Quest", QuestNum = 1, MobName = "Swan Pirate [Lv. 775]", Pos = Vector3.new(638, 73, 918)},
        {Level = 875, QuestName = "MarineQuest3", QuestNum = 1, MobName = "Marine Lieutenant [Lv. 875]", Pos = Vector3.new(-2440, 73, -3216)},
        {Level = 1000, QuestName = "SnowMountainQuest", QuestNum = 1, MobName = "Snow Trooper [Lv. 1000]", Pos = Vector3.new(609, 401, -5372)},
        {Level = 1250, QuestName = "ShipQuest1", QuestNum = 1, MobName = "Ship Deckhand [Lv. 1250]", Pos = Vector3.new(1038, 125, 32911)},
        {Level = 1425, QuestName = "FrostQuest", QuestNum = 1, MobName = "Arctic Warrior [Lv. 1425]", Pos = Vector3.new(5667, 28, -6486)}
    },
    [3] = { -- SEA 3
        {Level = 1500, QuestName = "PiratePortQuest", QuestNum = 1, MobName = "Pirate Millionaire [Lv. 1500]", Pos = Vector3.new(-290, 44, 5580)},
        {Level = 1600, QuestName = "AmazonQuest", QuestNum = 1, MobName = "Dragon Crew Warrior [Lv. 1600]", Pos = Vector3.new(5833, 52, -1103)},
        {Level = 1775, QuestName = "MarineTreeIsland", QuestNum = 1, MobName = "Marine Commodore [Lv. 1775]", Pos = Vector3.new(2181, 29, -6739)},
        {Level = 1975, QuestName = "HauntedQuest1", QuestNum = 1, MobName = "Reborn Skeleton [Lv. 1975]", Pos = Vector3.new(-9482, 142, 5567)},
        {Level = 2200, QuestName = "PeanutQuest", QuestNum = 1, MobName = "Peanut Scout [Lv. 2200]", Pos = Vector3.new(-2104, 38, -10194)},
        {Level = 2450, QuestName = "CandyQuest1", QuestNum = 1, MobName = "Candy Rebel [Lv. 2450]", Pos = Vector3.new(-2323, 38, -12128)}
    }
}

-- 5. HÀM TÍNH TOÁN LOGIC
local function GetPlayerLevel()
    local level = 1
    pcall(function()
        level = LP.Data.Level.Value
    end)
    return level
end

local function GetCurrentQuestData()
    local myLevel = GetPlayerLevel()
    local seaData = Database[CurrentSea] or Database[1]
    local target = seaData[1]
    
    for i = 1, #seaData do
        if myLevel >= seaData[i].Level then
            target = seaData[i]
        end
    end
    return target
end

-- Hệ thống NoClip (Xuyên vật cản)
RunService.Stepped:Connect(function()
    if _G.Settings.AutoFarm then
        pcall(function()
            local char = LP.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end)

-- Hệ thống Bay / Tween an toàn không bị Kick
local currentTween = nil
local function TweenTo(targetCFrame)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local distance = (targetCFrame.Position - hrp.Position).Magnitude
    local speed = _G.Settings.TweenSpeed
    local duration = distance / speed

    if distance < 15 then
        hrp.CFrame = targetCFrame
        if currentTween then currentTween:Cancel() end
        return
    end

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    if currentTween then currentTween:Cancel() end
    currentTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    currentTween:Play()
end

-- Tự động bật Buso Haki
local function EnableBuso()
    if _G.Settings.AutoHaki then
        local char = LP.Character
        if char and not char:FindFirstChild("HasBuso") then
            if CommF then CommF:InvokeServer("Buso") end
        end
    end
end

-- Tự động cầm vũ khí chỉ định
local function EquipWeapon()
    pcall(function()
        local char = LP.Character
        local bp = LP:FindFirstChild("Backpack")
        if not char or not bp then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        for _, tool in pairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local tType = tool.ToolTip:lower()
                local name = tool.Name:lower()
                local choose = _G.Settings.SelectedWeapon
                
                if (choose == "Melee" and (tType:find("melee") or name:find("combat") or name:find("style") or name:find("godhuman") or name:find("dragon"))) or
                   (choose == "Sword" and (tType:find("sword") or name:find("blade") or name:find("katana") or name:find("saber") or name:find("cdk"))) or
                   (choose == "Blox Fruit" and (tType:find("fruit") or name:find("fruit"))) then
                    hum:EquipTool(tool)
                    break
                end
            end
        end
    end)
end

-- Fast Attack Packet (Tốc độ đánh cao nhất không văng)
local function DoAttack()
    pcall(function()
        local char = LP.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate()
            local net = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
            if net and net:FindFirstChild("RegisterAttack") then
                net.RegisterAttack:InvokeServer(0)
            end
        else
            EquipWeapon()
        end
    end)
end

-- Lấy danh sách quái mục tiêu
local function GetMob(mobName)
    for _, v in pairs(Workspace.Enemies:GetChildren()) do
        if v.Name == mobName and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
            return v
        end
    end
    for _, v in pairs(Workspace:GetChildren()) do
        if v.Name == mobName and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
            return v
        end
    end
    return nil
end

-- 6. TẠO TABS GIAO DIỆN (UI)
local MainTab = Window:MakeTab({"Auto Farm", "swords"})
local StatsTab = Window:MakeTab({"Nâng Điểm (Stats)", "barchart"})
local SettingsTab = Window:MakeTab({"Cài Đặt", "settings"})

-- Tab Farm
MainTab:AddToggle({
    Name = "Bật Auto Farm Level",
    Default = false,
    Callback = function(val)
        _G.Settings.AutoFarm = val
        if not val and currentTween then
            currentTween:Cancel()
        end
    end
})

MainTab:AddDropdown({
    Name = "Chọn Vũ Khí Cày",
    Options = {"Melee", "Sword", "Blox Fruit"},
    Default = "Melee",
    Callback = function(val)
        _G.Settings.SelectedWeapon = val
    end
})

MainTab:AddToggle({
    Name = "Tự Động Bật Haki",
    Default = true,
    Callback = function(val)
        _G.Settings.AutoHaki = val
    end
})

MainTab:AddToggle({
    Name = "Gom Quái (Bring Mob)",
    Default = true,
    Callback = function(val)
        _G.Settings.BringMob = val
    end
})

-- Tab Stats
StatsTab:AddToggle({
    Name = "Tự Động Nâng Điểm",
    Default = false,
    Callback = function(val)
        _G.Settings.AutoStats = val
    end
})

StatsTab:AddDropdown({
    Name = "Chọn Loại Chỉ Số",
    Options = {"Melee", "Defense", "Sword", "Demon Fruit"},
    Default = "Melee",
    Callback = function(val)
        _G.Settings.SelectedStat = val
    end
})

-- 7. CÁC TIẾN TRÌNH CHẠY NGẦM (BACKGROUND THREADS)

-- Thread: Auto Stats
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.Settings.AutoStats and CommF then
            pcall(function()
                local points = LP.Data.Points.Value
                if points > 0 then
                    local statName = _G.Settings.SelectedStat
                    CommF:InvokeServer("AddPoint", statName, points)
                end
            end)
        end
    end
end)

-- Thread: Tấn Công (Fast Attack)
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.Settings.AutoFarm then
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local quest = GetCurrentQuestData()
                local mob = GetMob(quest.MobName)
                if mob and (mob.HumanoidRootPart.Position - hrp.Position).Magnitude <= 35 then
                    DoAttack()
                end
            end
        end
    end
end)

-- Thread: Vòng Lặp Farm Cốt Lõi (Core Farming Loop)
task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if _G.Settings.AutoFarm then
            pcall(function()
                EnableBuso()
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                -- Cố định trọng lực chống rơi rớt
                hrp.AssemblyLinearVelocity = Vector3.zero

                local questGui = LP.PlayerGui.Main.Quest
                local currentQuest = GetCurrentQuestData()

                -- Kiểm tra nhận nhiệm vụ
                if _G.Settings.AutoQuest and not questGui.Visible then
                    local distToNPC = (hrp.Position - currentQuest.Pos).Magnitude
                    if distToNPC > 15 then
                        TweenTo(CFrame.new(currentQuest.Pos + Vector3.new(0, 5, 0)))
                    else
                        if currentTween then currentTween:Cancel() end
                        CommF:InvokeServer("StartQuest", currentQuest.QuestName, currentQuest.QuestNum)
                    end
                    return
                end

                -- Tìm và tiếp cận quái
                local targetMob = GetMob(currentQuest.MobName)
                if targetMob and targetMob:FindFirstChild("HumanoidRootPart") then
                    local mobHRP = targetMob.HumanoidRootPart
                    local targetPos = mobHRP.CFrame * CFrame.new(0, _G.Settings.DistanceFarm, 0)

                    if (hrp.Position - targetPos.Position).Magnitude > 8 then
                        TweenTo(targetPos)
                    else
                        if currentTween then currentTween:Cancel() end
                        hrp.CFrame = targetPos

                        -- Gom quái xung quanh về cùng một chỗ
                        if _G.Settings.BringMob then
                            for _, enemy in pairs(Workspace.Enemies:GetChildren()) do
                                if enemy.Name == currentQuest.MobName and enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                                    if (enemy.HumanoidRootPart.Position - mobHRP.Position).Magnitude <= 200 then
                                        enemy.HumanoidRootPart.CFrame = mobHRP.CFrame
                                        enemy.HumanoidRootPart.CanCollide = false
                                        enemy.Humanoid.WalkSpeed = 0
                                    end
                                end
                            end
                        end
                    end
                else
                    -- Nếu quái chưa hồi sinh, đứng đợi tại điểm Spawn
                    TweenTo(CFrame.new(currentQuest.Pos + Vector3.new(0, 30, 0)))
                end
            end)
        end
    end
end)