-- Starlight key loader (non-UI helper)
local StarlightKeyLoader = {}

-- Start(opts)
-- opts.KeySystem : table from Starlight `KeySystem` settings
-- opts.StarlightFolder : folder path for saving key file
-- Returns table { success = bool, key = string|nil, reason = string }
function StarlightKeyLoader.Start(opts)
    opts = opts or {}
    local KS = opts.KeySystem or {}
    local StarlightFolder = opts.StarlightFolder or (KS.RootFolder or "Starlight")

    local isfile = isfile
    local readfile = readfile
    local writefile = writefile
    local makefolder = makefolder
    local isfolder = isfolder

    if KS.Enabled == false then
        return { success = true, reason = "disabled" }
    end

    local Keys = KS.Keys or {}
    if type(Keys) == "string" then Keys = { Keys } end

    -- If HttpKey true and KeyObtainLink is provided, try to fetch
    if KS.HttpKey and KS.KeyObtainLink and KS.KeyObtainLink ~= "" then
        local ok, resp = pcall(function() return game:HttpGet(KS.KeyObtainLink) end)
        if ok and type(resp) == "string" then
            -- assume raw content contains key(s) separated by newlines
            Keys = {}
            for line in resp:gmatch("([^\n]+)") do
                line = line:gsub("\s+","")
                if line ~= "" then table.insert(Keys, line) end
            end
        end
    end

    -- Check saved key file
    local filename = KS.KeyFile or "Key"
    if isfolder and not isfolder(StarlightFolder) then
        if makefolder then makefolder(StarlightFolder) end
    end
    if isfile and isfile(StarlightFolder.."/"..filename..".txt") then
        local saved = readfile(StarlightFolder.."/"..filename..".txt")
        saved = tostring(saved):gsub("\s+","")
        for _, k in ipairs(Keys) do
            if saved == tostring(k) then
                return { success = true, key = saved }
            end
        end
    end

    -- No saved key; return helper that can be used to check and optionally save key
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
        local Players = game:GetService("Players")
        if Players and Players.LocalPlayer then
            return tostring(Players.LocalPlayer.UserId)
        end
        return nil
    end

    local function CheckAndSave(entered)
        entered = tostring(entered or "")
        entered = entered:gsub("\s+","")
        for _, k in ipairs(Keys) do
            if entered == tostring(k) then
                -- HWID check support: KS.RequiredHWID or opts.RequiredHWID or opts.HWIDChecker
                local requiredHWID = opts.RequiredHWID or KS.RequiredHWID
                local hwidOk = true
                if opts.HWIDChecker and type(opts.HWIDChecker) == "function" then
                    local ok, res = pcall(opts.HWIDChecker, computeLocalHWID(), k)
                    hwidOk = ok and res
                elseif requiredHWID then
                    local localHw = computeLocalHWID()
                    hwidOk = (localHw ~= nil and tostring(localHw) == tostring(requiredHWID))
                end

                if not hwidOk then
                    return false, nil, "hwid"
                end

                if KS.SaveKey and writefile then
                    writefile(StarlightFolder.."/"..filename..".txt", entered)
                end

                -- Auto-load if provided
                local loadUrl = opts.OnSuccessLoadUrl or KS.OnSuccessLoadUrl
                if loadUrl and loadUrl ~= "" then
                    performLoad(loadUrl)
                end

                return true, entered
            end
        end
        return false, nil
    end
    -- Optional UI similar to library: simple input box and submit
    local function CreateUI()
        local MaxAttempts = opts.MaxAttempts or 3
        local AttemptsRemaining = MaxAttempts

        local screen = Instance.new("ScreenGui")
        screen.Name = "Starlight_KeyUI"
        screen.ResetOnSpawn = false

        local main = Instance.new("Frame")
        main.Size = UDim2.new(0, 420, 0, 160)
        main.Position = UDim2.new(0.5, -210, 0.5, -80)
        main.BackgroundColor3 = Color3.fromRGB(28,28,28)
        main.Parent = screen

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -20, 0, 28)
        title.Position = UDim2.new(0, 10, 0, 8)
        title.BackgroundTransparency = 1
        title.Text = KS.Title or "Starlight Key System"
        title.TextColor3 = Color3.new(1,1,1)
        title.TextScaled = true
        title.Parent = main

        local note = Instance.new("TextLabel")
        note.Size = UDim2.new(1, -20, 0, 20)
        note.Position = UDim2.new(0, 10, 0, 40)
        note.BackgroundTransparency = 1
        note.Text = KS.Note or "Enter your key"
        note.TextColor3 = Color3.new(0.8,0.8,0.8)
        note.TextScaled = false
        note.Parent = main

        local input = Instance.new("TextBox")
        input.Size = UDim2.new(1, -40, 0, 30)
        input.Position = UDim2.new(0, 20, 0, 72)
        input.Text = ""
        input.PlaceholderText = "Key"
        input.BackgroundColor3 = Color3.fromRGB(40,40,40)
        input.TextColor3 = Color3.new(1,1,1)
        input.Parent = main

        local submit = Instance.new("TextButton")
        submit.Size = UDim2.new(0, 90, 0, 28)
        submit.Position = UDim2.new(1, -110, 1, -40)
        submit.Text = "Submit"
        submit.Parent = main

        submit.MouseButton1Click:Connect(function()
            local ok, k = CheckAndSave(input.Text)
            if ok then
                screen:Destroy()
            else
                AttemptsRemaining = AttemptsRemaining - 1
                input.Text = ""
                if AttemptsRemaining <= 0 then
                    if Players and Players.LocalPlayer then pcall(function() Players.LocalPlayer:Kick("No Attempts Remaining") end) end
                    pcall(function() game:Shutdown() end)
                end
            end
        end)

        if gethui then
            screen.Parent = gethui()
        else
            screen.Parent = game:GetService("CoreGui")
        end

        return { Screen = screen, Check = CheckAndSave }
    end

    if opts.AutoShowUI then
        return { success = false, check = CheckAndSave, keys = Keys, ui = CreateUI() }
    end

    return { success = false, check = CheckAndSave, keys = Keys }
end

return StarlightKeyLoader
