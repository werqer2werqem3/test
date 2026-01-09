-- Example usage for rayfield_key_loader.lua
-- Place `rayfield_key_loader.lua` in ServerStorage (or adapt require path)

local success, RayfieldKeyLoader = pcall(function()
    return require(game:GetService("ServerStorage"):FindFirstChild("rayfield_key_loader"))
end)

if not success or not RayfieldKeyLoader then
    warn("RayfieldKeyLoader module not found in ServerStorage; adjust require path in example_use_rayfield_loader.lua")
    return
end

local Settings = {
    KeySystem = true,
    KeySettings = {
        Key = { "EXAMPLE-KEY-123" },
        SaveKey = true,
        FileName = "Key",
        GrabKeyFromSite = false,
        Title = "Example Rayfield Key",
    },
    Name = "ExampleScript",
}

local loader = RayfieldKeyLoader.Start({
    Settings = Settings,
    RayfieldFolder = "Rayfield", -- folder to save key file
    AutoShowUI = true, -- show simple UI
    MaxAttempts = 3,
    -- Example: require HWID equal to your user id (string)
    RequiredHWID = tostring(game:GetService("Players").LocalPlayer.UserId),
    -- Or provide a remote raw url to load on success
    OnSuccessLoadUrl = "https://raw.githubusercontent.com/example/repo/main/your_script.lua",
    RayfieldLibrary = { Notify = function(_, tbl) print("Notify:", tbl.Title, tbl.Content) end },
})

-- If you prefer manual checking:
-- local ok, key = loader.check("EXAMPLE-KEY-123")
-- print(ok, key)

print("Rayfield loader returned:", loader and (loader.info and (loader.info().Passthrough and "passthrough" or "no-passthrough") or "no-info") )
