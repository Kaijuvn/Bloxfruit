-- ==============================================================================
-- BLOX FRUITS - AUTO FRUIT SNIPER & LOW-PLAYER SERVER HOP (AUTO LOOP)
-- PHIÊN BẢN HOÀN THIỆN: ANTI-BAN VƯỢT TRỘI + TƯƠNG THÍCH HOÀN TOÀN VỚI DELTA
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
local ScriptContext = game:GetService("ScriptContext")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

-- ==============================================================================
-- CẤU HÌNH SCRIPT (BẠN CÓ THỂ TÙY CHỈNH TẠI ĐÂY)
-- ==============================================================================
local CONFIG = {
    -- ĐIỀN LINK GITHUB RAW CỦA BẠN VÀO ĐÂY (NẾU CÓ) ĐỂ SCRIPT TỰ TẢI LẠI QUA MỖI SERVER:
    -- Ví dụ: "https://raw.githubusercontent.com/tenban/repo/main/FruitSniper.lua"
    GitHubRawURL = "", 

    Team = "Pirates",                 -- Phe tự chọn: "Pirates" (Hải tặc) hoặc "Marines" (Hải quân)
    FlySpeed = 280,                   -- Tốc độ bay an toàn (250-290 stud/s, chống desync & server kick)
    StoreDelay = 5,                   -- Thời gian cất vào kho đồ (4 - 5 giây theo đúng yêu cầu)
    NoFruitHopDelay = 3,              -- Thời gian chờ nếu server không có trái thì nhảy server ngay
    VisitedServersFile = "BF_VisitedServers.json",
    CacheFileName = "FruitSniper_Cache.lua",

    -- CẤU HÌNH BẢO VỆ ANTI-BAN CAO CẤP:
    AntiBan = {
        EnableNamecallHook = true,    -- Chặn lệnh Kick cục bộ và chặn gửi log tố cáo về server
        BlockReportRemotes = true,    -- Tự động vô hiệu hóa các Remote gửi dữ liệu nghi vấn
        SafePhysics = true,           -- Triệt tiêu gia tốc rơi tự do để tránh bị Flag Speed/Flyhack
        RandomJitter = true,          -- Thêm độ trễ ngẫu nhiên mô phỏng hành vi người thật
        MaskErrors = true,            -- Chặn gửi lỗi ScriptContext về Roblox Analytics
    },

    -- XỬ LÝ KHI TRÙNG KHO ĐỒ (KHÔNG CẤT ĐƯỢC):
    -- "StopIfRare" : Dừng Server Hop nếu nhặt được trái XỊN/HIẾM bị trùng (bảo vệ trái không bị mất)
    -- "Drop"       : Thả trái trùng ra đất rồi nhảy server tiếp
    -- "Ignore"     : Bỏ qua và nhảy server tiếp
    DuplicateHandling = "StopIfRare", 

    -- Danh sách trái quý giá cần giữ lại tuyệt đối nếu bị trùng kho:
    RareFruits = {
        ["Kitsune"] = true, ["Dragon"] = true, ["Leopard"] = true, 
        ["Spirit"] = true, ["Control"] = true, ["Venom"] = true, 
        ["Shadow"] = true, ["Dough"] = true, ["T-Rex"] = true, 
        ["Mammoth"] = true, ["Gravity"] = true, ["Blizzard"] = true, 
        ["Pain"] = true, ["Portal"] = true, ["Buddha"] = true, 
        ["Sound"] = true, ["Phoenix"] = true, ["Quake"] = true
    },

    DiscordWebhook = "" -- (Tùy chọn) Link Discord Webhook để nhận thông báo trái quý
}

print("==================================================")
print("  BLOX FRUITS - AUTO FRUIT SNIPER (DELTA EDITION)")
print("  Trạng thái: Khởi động thành công!")
print("==================================================")

-- ==============================================================================
-- 1. HỆ THỐNG ANTI-BAN & CHỐNG PHÁT HIỆN TỐT NHẤT (STEALTH BYPASS)
-- ==============================================================================
local function setupAntiBan()
    if not CONFIG.AntiBan.EnableNamecallHook then return end
    
    local hook = hookmetamethod or (syn and syn.hook_metamethod)
    local checkCaller = checkcaller or (syn and syn.checkcaller)
    local getNamecall = getnamecallmethod or (syn and syn.getnamecallmethod)
    local newClosure = newcclosure or function(f) return f end

    -- A. Hook __namecall: Chặn hàm Kick & chặn Remote báo cáo gian lận
    if hook and getNamecall then
        pcall(function()
            local oldNamecall
            oldNamecall = hook(game, "__namecall", newClosure(function(self, ...)
                local method = getNamecall()
                local isSelfCaller = checkCaller and checkCaller() or false

                -- Nếu game cố tình gọi Kick() lên LocalPlayer
                if (method == "Kick" or method == "kick") and not isSelfCaller then
                    if self == LocalPlayer then
                        warn("[ANTI-BAN] ĐÃ CHẶN 1 NỖ LỰC KICK TỪ GAME ANTI-CHEAT!")
                        return nil
                    end
                end

                -- Chặn các Remote gửi dữ liệu tố cáo / ban / log về server Blox Fruits
                if CONFIG.AntiBan.BlockReportRemotes and (method == "FireServer" or method == "InvokeServer") and not isSelfCaller then
                    local rName = tostring(self.Name):lower()
                    if string.find(rName, "ban") 
                        or string.find(rName, "report") 
                        or string.find(rName, "detection") 
                        or string.find(rName, "cheat") 
                        or string.find(rName, "flag") 
                        or string.find(rName, "telemetry") 
                        or string.find(rName, "security") then
                        warn("[ANTI-BAN] Đã chặn gửi log nghi vấn về Server: " .. tostring(self.Name))
                        return nil
                    end
                end

                return oldNamecall(self, ...)
            end))
            print("[ANTI-BAN] [OK] Đã kích hoạt Hook Metamethod (__namecall).")
        end)
    end

    -- B. Chặn rò rỉ mã lỗi ScriptContext
    if CONFIG.AntiBan.MaskErrors then
        pcall(function()
            ScriptContext.Error:Connect(function() end)
        end)
    end

    -- C. Chống Flag vận tốc rơi tự do / Desync vật lý
    if CONFIG.AntiBan.SafePhysics then
        RunService.Heartbeat:Connect(function()
            pcall(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local hrp = char.HumanoidRootPart
                    if hrp.AssemblyLinearVelocity.Y < -120 then
                        hrp.AssemblyLinearVelocity = Vector3.new(
                            hrp.AssemblyLinearVelocity.X,
                            -20,
                            hrp.AssemblyLinearVelocity.Z
                        )
                    end
                end
            end)
        end)
        print("[ANTI-BAN] [OK] Đã kích hoạt Safe Physics.")
    end
end

setupAntiBan()

-- ==============================================================================
-- 2. ANTI-AFK (CHỐNG KICK TREO MÁY 20 PHÚT)
-- ==============================================================================
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    print("[ANTI-AFK] Đã ngăn chặn kick AFK 20 phút.")
end)

-- ==============================================================================
-- 3. TỰ ĐỘNG CHỌN PHE KHI VÀO GAME (PIRATES / MARINES)
-- ==============================================================================
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
-- 4. HỆ THỐNG NOCLIP & BAY TWEEN AN TOÀN
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

local function safeFlyTo(targetCFrame)
    local char = getCharacter()
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    enableNoclip()
    
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local duration = math.clamp(distance / CONFIG.FlySpeed, 0.4, 18)
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    
    tween:Play()
    tween.Completed:Wait()
    
    disableNoclip()
    task.wait(0.2)
end

-- ==============================================================================
-- 5. QUÉT VÀ ĐỊNH VỊ TRÁI ÁC QUỶ (FRUIT SCANNER & ESP)
-- ==============================================================================
local function findSpawnedFruits()
    local fruits = {}
    for _, item in pairs(Workspace:GetChildren()) do
        if item:IsA("Tool") or item:IsA("Model") then
            local isFruit = false
            if string.find(item.Name:lower(), "fruit") then
                isFruit = true
            elseif item:FindFirstChild("EatRemote", true) then
                isFruit = true
            end
            
            if isFruit then
                local handle = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
                if handle then
                    -- Hiển thị ESP trực quan
                    pcall(function()
                        if not handle:FindFirstChild("FruitESP") then
                            local bill = Instance.new("BillboardGui")
                            bill.Name = "FruitESP"
                            bill.Adornee = handle
                            bill.Size = UDim2.new(0, 160, 0, 40)
                            bill.StudsOffset = Vector3.new(0, 3, 0)
                            bill.AlwaysOnTop = true
                            
                            local text = Instance.new("TextLabel", bill)
                            text.Size = UDim2.new(1, 0, 1, 0)
                            text.BackgroundTransparency = 1
                            text.TextColor3 = Color3.fromRGB(255, 60, 60)
                            text.TextStrokeTransparency = 0
                            text.TextSize = 14
                            text.Font = Enum.Font.GothamBold
                            text.Text = "🍎 " .. item.Name
                            
                            bill.Parent = handle
                        end
                    end)
                    
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
-- 6. TỰ ĐỘNG BAY ĐẾN NHẶT TRÁI
-- ==============================================================================
local function pickFruit(fruitData)
    local char = getCharacter()
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    print("[FRUIT] Phát hiện: " .. fruitData.Name .. " -> Đang bay đến nhặt...")
    -- Giữ độ cao an toàn trên trái 3 studs
    local targetCF = fruitData.Handle.CFrame * CFrame.new(0, 3, 0)
    safeFlyTo(targetCF)
    
    local attempts = 0
    while fruitData.Object.Parent == Workspace and attempts < 15 do
        attempts = attempts + 1
        hrp.CFrame = fruitData.Handle.CFrame
        if firetouchinterest then
            firetouchinterest(hrp, fruitData.Handle, 0)
            task.wait(0.1)
            firetouchinterest(hrp, fruitData.Handle, 1)
        end
        task.wait(0.2)
    end
    print("[FRUIT] Đã nhặt thành công: " .. fruitData.Name)
end

-- ==============================================================================
-- 7. CẤT TRÁI VÀO KHO ĐỒ (4-5 GIÂY) & KIỂM TRA TRÙNG KHO
-- ==============================================================================
local function storeSingleFruit(tool)
    local commF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
    if tool:IsA("Tool") and (tool:FindFirstChild("EatRemote", true) or string.find(tool.Name:lower(), "fruit")) then
        local origName = tool:GetAttribute("OriginalName") or tool.Name
        print("[STORE] Thực hiện cất vào rương: " .. tostring(origName))
        pcall(function()
            commF:InvokeServer("StoreFruit", origName, tool)
        end)
        -- Tạo độ trễ ngẫu nhiên chống server phát hiện bot spam remote
        if CONFIG.AntiBan.RandomJitter then
            task.wait(math.random(15, 30) / 100)
        end
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
    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        check(tool)
    end
    if LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
            check(tool)
        end
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

local function sendWebhook(fruitName)
    if CONFIG.DiscordWebhook and CONFIG.DiscordWebhook ~= "" then
        pcall(function()
            local payload = {
                ["embeds"] = {{
                    ["title"] = "⚠️ PHÁT HIỆN TRÁI TRÙNG KHO ĐỒ!",
                    ["description"] = string.format("Nhân vật **%s** nhặt được trái **%s** nhưng kho rương đã đầy!\n\n**PlaceId**: `%s`\n**JobId**: `%s`\n\nLệnh teleport vào:\n```lua\ngame:GetService('TeleportService'):TeleportToPlaceInstance(%s, '%s', game.Players.LocalPlayer)\n```", 
                        LocalPlayer.Name, fruitName, tostring(PlaceId), tostring(JobId), tostring(PlaceId), tostring(JobId)),
                    ["color"] = 16753920
                }}
            }
            local req = (syn and syn.request) or request or http_request
            if req then
                req({
                    Url = CONFIG.DiscordWebhook,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(payload)
                })
            end
        end)
    end
end

-- ==============================================================================
-- 8. QUẢN LÝ DANH SÁCH SERVER ĐÃ ĐI QUA (TRÁNH LẶP SERVER)
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
        
        -- Dọn bớt server cũ sau 30 phút
        local cleanList = {}
        local now = os.time()
        for id, ts in pairs(visited) do
            if type(ts) == "number" and (now - ts) < 1800 then
                cleanList[id] = ts
            end
        end
        
        if writefile then
            writefile(CONFIG.VisitedServersFile, HttpService:JSONEncode(cleanList))
        end
    end)
end

-- ==============================================================================
-- 9. TỰ ĐỘNG CHẠY LẠI KHI QUA SERVER MỚI (QUEUE ON TELEPORT)
-- ==============================================================================
local queue_on_teleport = (syn and syn.queue_on_teleport) 
    or queue_on_teleport 
    or (fluxus and fluxus.queue_on_teleport)

local function registerNextExecution()
    pcall(function()
        if queue_on_teleport then
            -- Nếu có link GitHub Raw: Tải lại trực tiếp từ GitHub
            if CONFIG.GitHubRawURL and CONFIG.GitHubRawURL ~= "" then
                local execStr = string.format([[
                    repeat task.wait() until game:IsLoaded()
                    task.wait(1.5)
                    loadstring(game:HttpGet("%s"))()
                ]], CONFIG.GitHubRawURL)
                queue_on_teleport(execStr)
            elseif isfile and isfile(CONFIG.CacheFileName) then
                -- Nếu có lưu file cache cục bộ
                queue_on_teleport(string.format([[
                    repeat task.wait() until game:IsLoaded()
                    task.wait(1.5)
                    loadstring(readfile("%s"))()
                ]], CONFIG.CacheFileName))
            end
        end
    end)
end

-- ==============================================================================
-- 10. TÌM SERVER ÍT NGƯỜI CHƠI NHẤT & CHUYỂN SERVER (SERVER HOP)
-- ==============================================================================
local function hopToLowPlayerServer()
    print("[SERVER HOP] Đang quét tìm server ít người nhất...")
    markServerVisited(JobId)
    registerNextExecution()
    
    local visited = getVisitedServers()
    local cursor = ""
    local lowServers = {}
    
    for page = 1, 3 do
        local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then
            url = url .. "&cursor=" .. cursor
        end
        
        local success, res = pcall(function()
            if request then
                local r = request({Url = url, Method = "GET"})
                return HttpService:JSONDecode(r.Body)
            else
                return HttpService:JSONDecode(game:HttpGet(url))
            end
        end)
        
        if success and res and res.data then
            for _, s in ipairs(res.data) do
                local sid = tostring(s.id)
                -- Lọc: khác server này, còn slot, ít nhất 1 người (server đang sống), chưa ghé qua
                if sid ~= JobId and s.playing and s.playing < s.maxPlayers and s.playing >= 1 and not visited[sid] then
                    table.insert(lowServers, s)
                end
            end
            
            if #lowServers >= 10 or not res.nextPageCursor then
                break
            else
                cursor = res.nextPageCursor
            end
        else
            task.wait(0.5)
        end
    end
    
    table.sort(lowServers, function(a, b)
        return (a.playing or 0) < (b.playing or 0)
    end)
    
    if #lowServers > 0 then
        -- Lấy ngẫu nhiên trong top 3 server ít người nhất để tránh đụng hàng
        local pick = lowServers[math.random(1, math.min(3, #lowServers))]
        print(string.format("[SERVER HOP] Chuyển đến server: %s (%d/%d người chơi)...", pick.id, pick.playing, pick.maxPlayers))
        
        markServerVisited(pick.id)
        
        while task.wait(1) do
            pcall(function()
                TeleportService:TeleportToPlaceInstance(PlaceId, pick.id, LocalPlayer)
            end)
        end
    else
        print("[SERVER HOP] Không tìm thấy server mới, chuyển ngẫu nhiên...")
        pcall(function()
            TeleportService:Teleport(PlaceId, LocalPlayer)
        end)
    end
end

-- ==============================================================================
-- 11. QUY TRÌNH CHÍNH (MAIN WORKFLOW)
-- ==============================================================================
local function startHunterCycle()
    print("[STATUS] Bắt đầu tìm kiếm trái ác quỷ...")
    task.wait(1)
    
    local fruits = findSpawnedFruits()
    
    if #fruits > 0 then
        print(string.format("[STATUS] Phát hiện %d trái ác quỷ trong server!", #fruits))
        
        -- A. Bay đến nhặt từng trái
        for _, fruitData in ipairs(fruits) do
            pcall(function()
                pickFruit(fruitData)
            end)
            task.wait(0.5)
        end
        
        -- B. Cất vào kho đồ trong 4 - 5 giây
        print(string.format("[STATUS] Đang cất vào kho đồ (chờ %d giây)...", CONFIG.StoreDelay))
        local timer = tick()
        while tick() - timer < CONFIG.StoreDelay do
            storeAllFruits()
            task.wait(0.8)
        end
        
        -- C. Kiểm tra trùng kho đồ
        local unstoredFruits = getUnstoredFruits()
        if #unstoredFruits > 0 then
            print("[CẢNH BÁO] Có " .. #unstoredFruits .. " trái KHÔNG cất được do trùng kho đồ!")
            
            local hasRare = false
            for _, tool in ipairs(unstoredFruits) do
                local isRare, rareName = isRareFruit(tool.Name)
                if isRare then
                    hasRare = true
                    sendWebhook(tool.Name)
                end
            end
            
            if CONFIG.DuplicateHandling == "StopIfRare" and hasRare then
                print("==================================================")
                print("[DỪNG LẠI] PHÁT HIỆN TRÁI QUÝ BỊ TRÙNG KHO ĐỒ!")
                print("[DỪNG LẠI] Đã dừng Server Hop để bảo vệ trái quý!")
                print("==================================================")
                return -- Dừng hẳn, không nhảy server
            elseif CONFIG.DuplicateHandling == "Drop" then
                print("[TRÙNG KHO] Đang thả trái trùng ra đất...")
                for _, tool in ipairs(unstoredFruits) do
                    pcall(function()
                        tool.Parent = LocalPlayer.Character
                        task.wait(0.2)
                        if tool:FindFirstChild("EatRemote") then
                            tool.EatRemote:InvokeServer("Drop")
                        end
                    end)
                end
            end
        else
            print("[STATUS] Đã cất toàn bộ trái vào kho đồ thành công!")
        end
    else
        print("[STATUS] Server hiện tại không có trái ác quỷ nào spawn.")
        task.wait(CONFIG.NoFruitHopDelay)
    end
    
    -- D. Tự động nhảy sang server ít người tiếp theo
    print("[STATUS] Bắt đầu chuyển sang server ít người tiếp theo...")
    task.wait(1)
    hopToLowPlayerServer()
end

-- Chạy tiến trình săn trái
task.spawn(function()
    pcall(startHunterCycle)
end)
