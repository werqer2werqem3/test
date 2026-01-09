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
        screen.Name = "KeyUI"
        screen.ResetOnSpawn = false

        -- Main container (KeyMain)
        local KeyMain = Instance.new("Frame")
        KeyMain.Name = "Main"
        KeyMain.Size = UDim2.new(0, 467, 0, 175)
        KeyMain.AnchorPoint = Vector2.new(0.5, 0.5)
        KeyMain.Position = UDim2.new(0.5, 0.5, 0, 0)
        KeyMain.BackgroundColor3 = Color3.fromRGB(20,20,20)
        KeyMain.BackgroundTransparency = 1
        KeyMain.Parent = screen

        local Shadow = Instance.new("ImageLabel")
        Shadow.Name = "Shadow"
        Shadow.Size = UDim2.new(1, 60, 1, 60)
        Shadow.Position = UDim2.new(-0.05, 0, -0.05, 0)
        Shadow.Image = "rbxassetid://0"
        Shadow.BackgroundTransparency = 1
        Shadow.ImageTransparency = 1
        Shadow.Parent = KeyMain

        local Title = Instance.new("TextLabel")
        Title.Name = "Title"
        Title.Size = UDim2.new(1, -20, 0, 28)
        Title.Position = UDim2.new(0, 10, 0, 8)
        Title.BackgroundTransparency = 1
        Title.Text = KeySettings.Title or Settings.Name or "Key System"
        Title.TextColor3 = Color3.fromRGB(255,255,255)
        Title.TextTransparency = 1
        Title.TextScaled = true
        Title.Parent = KeyMain

        local Subtitle = Instance.new("TextLabel")
        Subtitle.Name = "Subtitle"
        Subtitle.Size = UDim2.new(1, -20, 0, 20)
        Subtitle.Position = UDim2.new(0, 10, 0, 36)
        Subtitle.BackgroundTransparency = 1
        Subtitle.Text = KeySettings.Subtitle or "Key System"
        Subtitle.TextColor3 = Color3.fromRGB(200,200,200)
        Subtitle.TextTransparency = 1
        Subtitle.TextScaled = false
        Subtitle.Parent = KeyMain

        local KeyNote = Instance.new("TextLabel")
        KeyNote.Name = "KeyNote"
        KeyNote.Size = UDim2.new(1, -20, 0, 20)
        KeyNote.Position = UDim2.new(0, 10, 0, 60)
        KeyNote.BackgroundTransparency = 1
        KeyNote.Text = KeySettings.Note or "No instructions"
        KeyNote.TextColor3 = Color3.fromRGB(180,180,180)
        KeyNote.TextTransparency = 1
        KeyNote.Parent = KeyMain

        local Input = Instance.new("Frame")
        Input.Name = "Input"
        Input.Size = UDim2.new(1, -40, 0, 36)
        Input.Position = UDim2.new(0, 20, 0, 86)
        Input.BackgroundColor3 = Color3.fromRGB(40,40,40)
        Input.BackgroundTransparency = 1
        Input.Parent = KeyMain

        local UIStroke = Instance.new("UIStroke")
        UIStroke.Name = "UIStroke"
        UIStroke.Parent = Input
        UIStroke.Transparency = 1

        local InputBox = Instance.new("TextBox")
        InputBox.Name = "InputBox"
        InputBox.Size = UDim2.new(1, -10, 1, -6)
        InputBox.Position = UDim2.new(0, 5, 0, 3)
        InputBox.BackgroundTransparency = 1
        InputBox.Text = ""
        InputBox.TextTransparency = 1
        InputBox.PlaceholderText = "Enter key..."
        InputBox.TextColor3 = Color3.fromRGB(255,255,255)
        InputBox.Parent = Input

        local NoteTitle = Instance.new("TextLabel")
        NoteTitle.Name = "NoteTitle"
        NoteTitle.Size = UDim2.new(1, -20, 0, 18)
        NoteTitle.Position = UDim2.new(0, 10, 0, 126)
        NoteTitle.BackgroundTransparency = 1
        NoteTitle.Text = "Note"
        NoteTitle.TextColor3 = Color3.fromRGB(200,200,200)
        NoteTitle.TextTransparency = 1
        NoteTitle.Parent = KeyMain

        local NoteMessage = Instance.new("TextLabel")
        NoteMessage.Name = "NoteMessage"
        NoteMessage.Size = UDim2.new(1, -20, 0, 24)
        NoteMessage.Position = UDim2.new(0, 10, 0, 144)
        NoteMessage.BackgroundTransparency = 1
        NoteMessage.Text = KeySettings.Note or "No instructions"
        NoteMessage.TextColor3 = Color3.fromRGB(180,180,180)
        NoteMessage.TextTransparency = 1
        NoteMessage.Parent = KeyMain

        local Hide = Instance.new("ImageButton")
        Hide.Name = "Hide"
        Hide.Size = UDim2.new(0, 28, 0, 28)
        Hide.Position = UDim2.new(1, -40, 0, 8)
        Hide.BackgroundTransparency = 1
        Hide.Image = "rbxassetid://0"
        Hide.ImageTransparency = 1
        Hide.Parent = KeyMain

        -- initial animate in (matching Rayfield timings)
        KeyMain.Size = UDim2.new(0, 467, 0, 175)
        KeyMain.BackgroundTransparency = 1
        Shadow.ImageTransparency = 1
        Title.TextTransparency = 1
        Subtitle.TextTransparency = 1
        KeyNote.TextTransparency = 1
        Input.BackgroundTransparency = 1
        UIStroke.Transparency = 1
        InputBox.TextTransparency = 1
        NoteTitle.TextTransparency = 1
        NoteMessage.TextTransparency = 1
        Hide.ImageTransparency = 1

        TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
        TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 187)}):Play()
        TweenService:Create(Shadow, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0.5}):Play()
        task.wait(0.05)
        TweenService:Create(Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
        TweenService:Create(Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
        task.wait(0.05)
        TweenService:Create(KeyNote, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
        TweenService:Create(Input, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
        TweenService:Create(UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
        TweenService:Create(InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
        task.wait(0.05)
        TweenService:Create(NoteTitle, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
        TweenService:Create(NoteMessage, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
        task.wait(0.15)
        TweenService:Create(Hide, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 0.3}):Play()

        -- Connect behavior
        InputBox.FocusLost:Connect(function(enterPressed)
            if #InputBox.Text == 0 then return end
            local KeyFound, FoundKey = false, ''
            for _, MKey in ipairs(KeySettings.Key) do
                if InputBox.Text == MKey then
                    KeyFound = true
                    FoundKey = MKey
                end
            end
            if KeyFound then
                TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
                TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 467, 0, 175)}):Play()
                TweenService:Create(Shadow, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
                TweenService:Create(Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
                TweenService:Create(Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
                TweenService:Create(KeyNote, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
                TweenService:Create(Input, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
                TweenService:Create(UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
                TweenService:Create(InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
                TweenService:Create(NoteTitle, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
                TweenService:Create(NoteMessage, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
                TweenService:Create(Hide, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
                task.wait(0.51)
                Passthrough = true
                KeyMain.Visible = false
                if KeySettings.SaveKey then
                    if writefile then
                        writefile(RayfieldFolder.."/Key System".."/"..KeySettings.FileName..".json", FoundKey)
                    end
                    if RayfieldLibrary and RayfieldLibrary.Notify then
                        pcall(RayfieldLibrary.Notify, RayfieldLibrary, {Title = "Key System", Content = "The key for this script has been saved successfully.", Image = 3605522284})
                    end
                end
            else
                if AttemptsRemaining == 0 then
                    TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
                    TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 467, 0, 175)}):Play()
                    TweenService:Create(Shadow, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
                    TweenService:Create(Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
                    TweenService:Create(Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
                    TweenService:Create(KeyNote, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
                    TweenService:Create(Input, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
                    TweenService:Create(UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
                    TweenService:Create(InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
                    TweenService:Create(NoteTitle, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
                    TweenService:Create(NoteMessage, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
                    TweenService:Create(Hide, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
                    task.wait(0.45)
                    if Players and Players.LocalPlayer then pcall(function() Players.LocalPlayer:Kick("No Attempts Remaining") end) end
                    pcall(function() game:Shutdown() end)
                end
                InputBox.Text = ""
                AttemptsRemaining = AttemptsRemaining - 1
                TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 467, 0, 175)}):Play()
                TweenService:Create(KeyMain, TweenInfo.new(0.4, Enum.EasingStyle.Elastic), {Position = UDim2.new(0.495,0,0.5,0)}):Play()
                task.wait(0.1)
                TweenService:Create(KeyMain, TweenInfo.new(0.4, Enum.EasingStyle.Elastic), {Position = UDim2.new(0.505,0,0.5,0)}):Play()
                task.wait(0.1)
                TweenService:Create(KeyMain, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Position = UDim2.new(0.5,0,0.5,0)}):Play()
                TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 187)}):Play()
            end
        end)

        Hide.MouseButton1Click:Connect(function()
            TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
            TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 467, 0, 175)}):Play()
            TweenService:Create(Shadow, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
            TweenService:Create(Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
            TweenService:Create(Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
            TweenService:Create(KeyNote, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
            TweenService:Create(Input, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
            TweenService:Create(UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
            TweenService:Create(InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
            TweenService:Create(NoteTitle, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
            TweenService:Create(NoteMessage, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
            TweenService:Create(Hide, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
            task.wait(0.51)
            if RayfieldLibrary and RayfieldLibrary.Destroy then pcall(RayfieldLibrary.Destroy, RayfieldLibrary) end
            screen:Destroy()
        end)

        -- attach to player UI
        if gethui then
            screen.Parent = gethui()
        elseif syn and syn.protect_gui then
            syn.protect_gui(screen)
            screen.Parent = CoreGui
        elseif not useStudio and CoreGui:FindFirstChild("RobloxGui") then
            screen.Parent = CoreGui:FindFirstChild("RobloxGui")
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
