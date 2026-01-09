-- Rayfield key loader module (extracted/adapted)
local RayfieldKeyLoader = {}

-- Start(opts)
-- opts.Settings : table containing KeySettings (same shape as Rayfield)
-- opts.RayfieldFolder : string path for saved key file
-- opts.RayfieldLibrary : table with Notify function (optional)
-- optional dependencies may be omitted and defaulted to globals
function RayfieldKeyLoader.Start(opts)
    opts = opts or {}
    local Settings = opts.Settings or {}
    local KeySettings = Settings.KeySettings or {}
    local RayfieldFolder = opts.RayfieldFolder or (Settings.RayfieldFolder or "Rayfield")
    local RayfieldLibrary = opts.RayfieldLibrary

    local TweenService = opts.TweenService or game:GetService("TweenService")
    local Players = opts.Players or game:GetService("Players")
    local CoreGui = opts.CoreGui or game:GetService("CoreGui")
    local HttpService = opts.HttpService or game:GetService("HttpService")

    local isfile = isfile
    local writefile = writefile
    local readfile = readfile
    local makefolder = makefolder
    local isfolder = isfolder

    local Passthrough = false

    if not Settings.KeySystem then
        return { success = true, reason = "Key system disabled" }
    end

    if type(KeySettings.Key) == "string" then KeySettings.Key = { KeySettings.Key } end

    if KeySettings.GrabKeyFromSite or KeySettings.GrabKeyFromSite == true then
        for i, Key in ipairs(KeySettings.Key) do
            local Success, Response = pcall(function()
                KeySettings.Key[i] = tostring(game:HttpGet(Key):gsub("[\n\r]", " "))
                KeySettings.Key[i] = string.gsub(KeySettings.Key[i], " ", "")
            end)
            if not Success then
                warn('Rayfield key fetch error: ' .. tostring(Response))
            end
        end
    end

    if not KeySettings.FileName then
        KeySettings.FileName = KeySettings.KeyFile or "Key"
    end

    if isfolder and not isfolder(RayfieldFolder.."/Key System") then
        if makefolder then makefolder(RayfieldFolder.."/Key System") end
    end

    if isfile and isfile(RayfieldFolder.."/Key System".."/"..KeySettings.FileName..".json") then
        for _, MKey in ipairs(KeySettings.Key) do
            if string.find(readfile(RayfieldFolder.."/Key System".."/"..KeySettings.FileName..".json"), MKey) then
                Passthrough = true
            end
        end
    end

    if Passthrough then
        return { success = true, key = true }
    end

    -- NOTE: This module does not create the GUI automatically in all environments.
    -- If you want the same GUI as Rayfield, pass in `KeyUI` in opts (a ScreenGui instance),
    -- or integrate this logic into your UI. Here we provide the core check+save behavior.

    -- Provide a helper for checking an entered key
    local function performLoad(url)
        if not url or url == "" then return false, "no url" end
        local ok, res = pcall(function()
            local body = game:HttpGet(url)
            local fn = loadstring and loadstring(body) or load(body)
            if fn then fn() end
        end)
        return ok, res
    end

    local function computeLocalHWID()
        if Players and Players.LocalPlayer then
            return tostring(Players.LocalPlayer.UserId)
        end
        return nil
    end

    local function CheckKey(entered)
        for _, MKey in ipairs(KeySettings.Key) do
            if entered == MKey then
                -- HWID check: can be provided via opts.RequiredHWID or opts.HWIDChecker
                local requiredHWID = opts.RequiredHWID or KeySettings.RequiredHWID
                local hwidOk = true
                if opts.HWIDChecker and type(opts.HWIDChecker) == "function" then
                    local ok, res = pcall(opts.HWIDChecker, computeLocalHWID(), MKey)
                    hwidOk = ok and res
                elseif requiredHWID then
                    local localHw = computeLocalHWID()
                    hwidOk = (localHw ~= nil and tostring(localHw) == tostring(requiredHWID))
                end

                if not hwidOk then
                    if RayfieldLibrary and RayfieldLibrary.Notify then
                        pcall(RayfieldLibrary.Notify, RayfieldLibrary, { Title = "Key System", Content = "HWID mismatch.", Image = 3605522284 })
                    end
                    return false, nil, "hwid"
                end

                if KeySettings.SaveKey and writefile then
                    writefile(RayfieldFolder.."/Key System".."/"..KeySettings.FileName..".json", MKey)
                end
                if RayfieldLibrary and RayfieldLibrary.Notify then
                    pcall(RayfieldLibrary.Notify, RayfieldLibrary, { Title = "Key System", Content = "The key for this script has been saved successfully.", Image = 3605522284 })
                end

                -- Auto-load remote code if requested
                local loadUrl = opts.OnSuccessLoadUrl or KeySettings.OnSuccessLoadUrl
                if loadUrl and loadUrl ~= "" then
                    performLoad(loadUrl)
                end

                return true, MKey
            end
        end
        return false, nil
    end
    -- Optional UI: create a simple key input UI similar to Rayfield's if requested
    local function CreateKeyUI()
        local MaxAttempts = opts.MaxAttempts or math.random(2, 5)
        local AttemptsRemaining = MaxAttempts

        local screen = Instance.new("ScreenGui")
        screen.Name = "Rayfield_KeyUI"
        screen.ResetOnSpawn = false

        local main = Instance.new("Frame")
        main.Size = UDim2.new(0, 480, 0, 200)
        main.Position = UDim2.new(0.5, -240, 0.5, -100)
        main.BackgroundColor3 = Color3.fromRGB(30,30,30)
        main.Parent = screen

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -20, 0, 32)
        title.Position = UDim2.new(0, 10, 0, 10)
        title.BackgroundTransparency = 1
        title.Text = KeySettings.Title or Settings.Name or "Key System"
        title.TextColor3 = Color3.new(1,1,1)
        title.TextScaled = true
        title.Parent = main

        local input = Instance.new("TextBox")
        input.Size = UDim2.new(1, -40, 0, 32)
        input.Position = UDim2.new(0, 20, 0, 80)
        input.Text = ""
        input.ClearTextOnFocus = false
        input.PlaceholderText = "Enter key..."
        input.TextColor3 = Color3.new(1,1,1)
        input.BackgroundColor3 = Color3.fromRGB(40,40,40)
        input.Parent = main

        local submit = Instance.new("TextButton")
        submit.Size = UDim2.new(0, 100, 0, 30)
        submit.Position = UDim2.new(1, -120, 1, -40)
        submit.Text = "Submit"
        submit.Parent = main

        local hide = Instance.new("TextButton")
        hide.Size = UDim2.new(0, 60, 0, 24)
        hide.Position = UDim2.new(1, -80, 0, 10)
        hide.Text = "Hide"
        hide.Parent = main

        local function onSuccess(foundKey)
            pcall(function()
                TweenService:Create(main, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
            end)
            task.wait(0.5)
            screen:Destroy()
        end

        local function onFailure()
            AttemptsRemaining = AttemptsRemaining - 1
            input.Text = ""
            if AttemptsRemaining <= 0 then
                -- replicate Rayfield behaviour: kick/shutdown when out of attempts
                if Players and Players.LocalPlayer then
                    pcall(function() Players.LocalPlayer:Kick("No Attempts Remaining") end)
                end
                pcall(function() game:Shutdown() end)
            end
        end

        submit.MouseButton1Click:Connect(function()
            local ok, found = CheckKey(input.Text)
            if ok then
                onSuccess(found)
            else
                onFailure()
            end
        end)

        hide.MouseButton1Click:Connect(function()
            screen.Enabled = false
        end)

        -- attach to player UI
        if gethui then
            screen.Parent = gethui()
        else
            screen.Parent = CoreGui
        end

        return { Screen = screen, Check = CheckKey }
    end

    local result = { check = CheckKey, info = function() return { Passthrough = Passthrough, Keys = KeySettings.Key } end }

    if opts.AutoShowUI then
        result.ui = CreateKeyUI()
    end

    return result
end

return RayfieldKeyLoader
