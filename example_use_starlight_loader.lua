-- Example usage for starlight_key_loader.lua
-- Place `starlight_key_loader.lua` in ServerStorage (or adapt require path)

local success, StarlightKeyLoader = pcall(function()
    return require(game:GetService("ServerStorage"):FindFirstChild("starlight_key_loader"))
end)

if not success or not StarlightKeyLoader then
    warn("StarlightKeyLoader module not found in ServerStorage; adjust require path in example_use_starlight_loader.lua")
    return
end

local KeySystem = {
    Enabled = true,
    Keys = { "STAR-KEY-1", "STAR-KEY-2" },
    SaveKey = true,
    KeyFile = "Key",
    HttpKey = false,
    KeyObtainLink = "",
    Title = "Starlight Key",
    Note = "Enter your key to continue",
}

local res = StarlightKeyLoader.Start({ KeySystem = KeySystem, StarlightFolder = "Starlight" , AutoShowUI = true })

-- Example: require HWID equal to your user id
-- (or provide a custom HWID checker function via HWIDChecker)
-- and auto-load a raw URL when key passes all checks
local Players = game:GetService("Players")
res = StarlightKeyLoader.Start({
    KeySystem = KeySystem,
    StarlightFolder = "Starlight",
    AutoShowUI = true,
    RequiredHWID = tostring(Players.LocalPlayer.UserId),
    OnSuccessLoadUrl = "https://raw.githubusercontent.com/example/repo/main/your_script.lua",
})

-- If Start returned a manual checker use it:
if res and res.check then
    -- Example manual check
    local ok, k = res.check("STAR-KEY-1")
    print("Manual check result:", ok, k)
end

print("Starlight loader returned success flag:", res and res.success)
