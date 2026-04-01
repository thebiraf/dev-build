local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local LicensePath = "Haze/assets/data/License.json"
local WhitelistURL = "https://raw.githubusercontent.com/7Smoker/whitelisted/refs/heads/main/private.json"

local SALT = "HazeWhitelistCrypted"
local whitelistData = nil

local function hashData(str, rounds)
    rounds = rounds or 10
    str = tostring(str)

    local out = {}

    for r = 1, rounds do
        local hash = 5381 + r * 97
        for i = 1, #str do
            hash = (hash * 33 + string.byte(str, i) + r) % 9007199254740991
        end
        out[#out + 1] = string.format("%016x", hash)
        str = tostring(hash) .. str
    end

    return table.concat(out)
end

local function whitelistLoad()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(WhitelistURL))
    end)

    if ok and type(data) == "table" then
        whitelistData = data
    else
        warn("whitelist failed to load")
    end
end

local function verifyPlayer()
    if not whitelistData then return nil end

    local uid = tostring(LocalPlayer.UserId)
    local data = whitelistData[uid]
    if not data then return nil end

    local hash = hashData(uid, 10)
    local saltHash = hashData(uid .. SALT, 14)

    if data.hash ~= hash or data.saltHash ~= saltHash then return nil end
    return data
end

local function updLicense(rank)
    local data = { Default = false, Private = false, Developer = false }
    if data[rank] ~= nil then
        data[rank] = true
    else
        data.Default = true
    end
    writefile(LicensePath, HttpService:JSONEncode(data))
end

local function runGodmode(player)
    local function hookChar(char)
        local hum = char:WaitForChild("Humanoid")
        RunService.Stepped:Connect(function()
            if hum then
                hum.MaxHealth = math.huge
                hum.Health = math.huge
            end
        end)
    end

    if player.Character then
        hookChar(player.Character)
    end

    player.CharacterAdded:Connect(hookChar)
end

local function tagHandler(player, license, colors)
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    if head:FindFirstChild("HAZE_TAG") then
        head.HAZE_TAG:Destroy()
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "HAZE_TAG"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 600, 0, 80)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 200
    billboard.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 40
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.6
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Text = "[HAZE " .. string.upper(license) .. "]"
    label.Parent = billboard

    local glow = Instance.new("UIStroke")
    glow.Thickness = 2
    glow.Color = Color3.fromRGB(255, 255, 255)
    glow.Transparency = 0.4
    glow.Parent = label

    local gradient = Instance.new("UIGradient")
    local seq = {}

    if type(colors) ~= "table" or #colors < 2 then
        colors = {{255,255,255},{255,255,255}}
    end

    for i, rgb in ipairs(colors) do
        seq[#seq + 1] = ColorSequenceKeypoint.new(
            (i - 1) / (#colors - 1),
            Color3.fromRGB(rgb[1], rgb[2], rgb[3])
        )
    end

    gradient.Color = ColorSequence.new(seq)
    gradient.Parent = label

    task.spawn(function()
        local rot = 0
        while label.Parent do
            rot = (rot + 0.7) % 360
            gradient.Rotation = rot
            task.wait(0.02)
        end
    end)
end

local function persistentTag(player, data)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        tagHandler(player, data.license, data.colors)
    end)
    if player.Character then
        task.wait(0.1)
        tagHandler(player, data.license, data.colors)
    end
end

local function applyTags()
    for _, player in ipairs(Players:GetPlayers()) do
        local data = whitelistData[tostring(player.UserId)]
        if data then
            persistentTag(player, data)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    local data = whitelistData[tostring(player.UserId)]
    if data then
        persistentTag(player, data)
    end
end)

whitelistLoad()

local verified = verifyPlayer()
if verified then
    LocalPlayer:SetAttribute("HazeLicense", verified.license)
    updLicense(verified.license)
    if verified.godmode then
        runGodmode(LocalPlayer)
    end
    task.wait(0.4)
    persistentTag(LocalPlayer, verified)
end

applyTags()