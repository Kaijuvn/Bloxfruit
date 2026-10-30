task.spawn(function()
    repeat task.wait(0.5) until game:IsLoaded()
    task.wait(1)
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Kaijuvn/Bloxfruit/refs/heads/main/MarisHub_NoKey.lua"))()
    end)
    if not ok then
        pcall(function()
            loadstring(game:HttpGet("https://pastefy.app/z1SiCisw/raw"))()
        end)
    end
end)
