local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local repo = "https://raw.githubusercontent.com/7Smoker/Haze/main/"

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.IgnoreGuiInset = true
local Main = Instance.new("Frame", ScreenGui)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.Size = UDim2.fromOffset(360, 140)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
local UICorner = Instance.new("UICorner", Main)
UICorner.CornerRadius = UDim.new(0, 10)
local TopLine = Instance.new("Frame", Main)
TopLine.BackgroundColor3 = Color3.fromRGB(0, 255, 140)
TopLine.BorderSizePixel = 0
TopLine.Size = UDim2.new(1, 0, 0, 2)
local Shine = Instance.new("UIGradient", TopLine)
Shine.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 140)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 255, 230)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 140))
})
Shine.Enabled = false
local Title = Instance.new("TextLabel", Main)
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(25, 20)
Title.Size = UDim2.fromOffset(65, 30)
Title.Font = Enum.Font.GothamBold
Title.Text = "HAZE"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 24
Title.TextXAlignment = Enum.TextXAlignment.Left
local VersionT = Instance.new("TextLabel", Main)
VersionT.BackgroundTransparency = 1
VersionT.Position = UDim2.fromOffset(94, 28)
VersionT.Size = UDim2.fromOffset(150, 20)
VersionT.Font = Enum.Font.GothamBold
VersionT.TextColor3 = Color3.fromRGB(0, 255, 140)
VersionT.TextSize = 10
VersionT.TextXAlignment = Enum.TextXAlignment.Left
local Status = Instance.new("TextLabel", Main)
Status.BackgroundTransparency = 1
Status.Position = UDim2.fromOffset(25, 65)
Status.Size = UDim2.new(1, -50, 0, 20)
Status.Font = Enum.Font.GothamMedium
Status.Text = "Initializing..."
Status.TextColor3 = Color3.fromRGB(255, 255, 255)
Status.TextSize = 11
Status.TextXAlignment = Enum.TextXAlignment.Left
local Welcome = Instance.new("TextLabel", Main)
Welcome.BackgroundTransparency = 1
Welcome.Position = UDim2.new(0, 0, 0, 75)
Welcome.Size = UDim2.new(1, 0, 0, 20)
Welcome.Font = Enum.Font.GothamMedium
--Welcome.Text = "Welcome, " .. Players.LocalPlayer.DisplayName
Welcome.Text = "Welcome."
Welcome.TextColor3 = Color3.fromRGB(255, 255, 255)
Welcome.TextSize = 15
Welcome.TextTransparency = 1
Welcome.TextXAlignment = Enum.TextXAlignment.Center
local Preparing = Instance.new("TextLabel", Main)
Preparing.BackgroundTransparency = 1
Preparing.Position = UDim2.new(0, 0, 0, 98)
Preparing.Size = UDim2.new(1, 0, 0, 20)
Preparing.Font = Enum.Font.GothamMedium
Preparing.Text = "Preparing Haze for you..."
Preparing.TextColor3 = Color3.fromRGB(150, 150, 150)
Preparing.TextSize = 11
Preparing.TextTransparency = 1
Preparing.TextXAlignment = Enum.TextXAlignment.Center
local Logo = Instance.new("ImageLabel", Main)
Logo.BackgroundTransparency = 1
Logo.AnchorPoint = Vector2.new(0.5, 0)
Logo.Position = UDim2.new(0.5, 0, 0, 25)
Logo.Size = UDim2.fromOffset(100, 45)
Logo.ImageTransparency = 1
Logo.ScaleType = Enum.ScaleType.Fit
local Track = Instance.new("Frame", Main)
Track.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Track.BorderSizePixel = 0
Track.Position = UDim2.new(0, 25, 1, -35)
Track.Size = UDim2.new(1, -50, 0, 3)
local Bar = Instance.new("Frame", Track)
Bar.BackgroundColor3 = Color3.fromRGB(0, 255, 140)
Bar.BorderSizePixel = 0
Bar.Size = UDim2.fromScale(0, 1)
Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)
Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

local function SetStatus(mode, file, prc)
    local colors = {
        Checking = Color3.fromRGB(255, 255, 255), 
        Updated = Color3.fromRGB(0, 255, 255), 
        Downloading = Color3.fromRGB(150, 255, 150),
        Cache = Color3.fromRGB(255, 70, 70)
    }
    Status.Text = mode .. ": " .. file:match("([^/]+)$")
    Status.TextColor3 = colors[mode] or colors.Checking
    if prc then 
        TweenService:Create(Bar, TweenInfo.new(0.15), {Size = UDim2.fromScale(prc, 1)}):Play() 
    end
end

local function httpGet(url) 
    local s, r = pcall(game.HttpGet, game, url) 
    return s and r or nil 
end

task.spawn(function()
    if not isfolder("Haze") then makefolder("Haze") end

    task.spawn(function()
        local repo_info = httpGet("https://api.github.com/repos/7Smoker/Haze")
        if repo_info then
            local s, res = pcall(function() return HttpService:JSONDecode(repo_info) end)
            if s and res.size then VersionT.Text = "v" .. tostring(res.size) end
        end
    end)

    local manifestRaw = httpGet(repo .. "assets/Default.json")
    if not manifestRaw then Main:Destroy() return end

    local files = {}
    local function parse(t, p)
        p = p or ""
        for k, v in pairs(t) do
            if type(v) == "table" then 
                parse(v, (k == "root" and "" or (p ~= "" and p .. "/" or "") .. k))
            else 
                table.insert(files, (p ~= "" and p .. "/" or "") .. v) 
            end
        end
    end
    parse(HttpService:JSONDecode(manifestRaw))

    for i, f in ipairs(files) do
        local path = "Haze/" .. f
        local content = httpGet(repo .. f)
        if content then
            local folder = path:match("(.+)/[^/]+$")
            if folder and not isfolder(folder) then makefolder(folder) end
            local current = isfile(path) and readfile(path) or nil
            
            if not current then
                writefile(path, content)
                SetStatus("Downloading", f, i / #files)
                task.wait(0.02)
            elseif current ~= content then
                writefile(path, content)
                SetStatus("Updated", f, i / #files)
                task.wait(0.02)
            else
                SetStatus("Checking", f, i / #files)
            end
        end
        task.wait()
    end

    local valid_map = {}
    for _, f in ipairs(files) do valid_map["Haze/" .. f] = true end
    
    local function scan(dir)
        for _, item in ipairs(listfiles(dir)) do
            local normalized = item:gsub("\\", "/")
            if not normalized:match("/configs/") and not normalized:match("/assets/audios/") and not normalized:match("config.txt") then
                if isfolder(item) then
                    scan(item)
                    if #listfiles(item) == 0 then pcall(delfolder, item) end
                elseif isfile(item) and not valid_map[normalized] then
                    SetStatus("Cache", normalized)
                    pcall(delfile, item)
                    task.wait(0.02)
                end
            end
        end
    end
    scan("Haze")

    task.wait(0.2)

    for _, obj in ipairs({Title, VersionT, Status, Track, Bar}) do
        TweenService:Create(obj, TweenInfo.new(0.3), {
            [(obj:IsA("TextLabel") and "TextTransparency" or "BackgroundTransparency")] = 1
        }):Play()
    end

    task.wait(0.3)

    if isfile("Haze/assets/lib/lightlogo.png") then 
        Logo.Image = getcustomasset("Haze/assets/lib/lightlogo.png") 
    end

    Shine.Enabled = true
    task.spawn(function()
        while Shine.Enabled do
            Shine.Offset = Vector2.new(-1, 0)
            local t = TweenService:Create(Shine, TweenInfo.new(1.2, Enum.EasingStyle.Linear), {Offset = Vector2.new(1, 0)})
            t:Play()
            t.Completed:Wait()
        end
    end)

    TweenService:Create(Logo, TweenInfo.new(0.5), {ImageTransparency = 0}):Play()
    TweenService:Create(Welcome, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    TweenService:Create(Preparing, TweenInfo.new(0.5), {TextTransparency = 0}):Play()

    task.wait(3)

    TweenService:Create(Main, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Size = UDim2.fromOffset(360, 0), BackgroundTransparency = 1}):Play()
    TweenService:Create(Logo, TweenInfo.new(0.3), {ImageTransparency = 1}):Play()
    TweenService:Create(Welcome, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    TweenService:Create(Preparing, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    TweenService:Create(TopLine, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()

    task.wait(0.7)
    Shine.Enabled = false
    ScreenGui:Destroy()

    if isfile("Haze/loader.lua") then 
        local f = loadfile("Haze/loader.lua")
        if f then pcall(f) end 
    end
end)