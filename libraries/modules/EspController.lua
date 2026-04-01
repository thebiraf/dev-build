local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local EspController = {
    Enabled = false,
    TeamCheck = false,
    NoTeam = false,
    UseGradient = true,
    Theme = "Haze",
    Cache = {}
}

local Themes = {
    Haze  = {Color1 = Color3.fromRGB(31, 226, 130), Color2 = Color3.fromRGB(245, 66, 200)},
    Aqua  = {Color1 = Color3.fromRGB(0, 255, 255), Color2 = Color3.fromRGB(0, 100, 255)},
    Nova  = {Color1 = Color3.fromRGB(255, 100, 0), Color2 = Color3.fromRGB(200, 0, 255)}
}

local BoxLines = {
    {1,2},{2,3},{3,4},{4,1},
    {5,6},{6,7},{7,8},{8,5},
    {1,5},{2,6},{3,7},{4,8}
}

local function GetCorners(cf, size)
    local x, y, z = size.X/2, size.Y/2, size.Z/2
    return {
        cf * Vector3.new(-x,  y, -z),
        cf * Vector3.new( x,  y, -z),
        cf * Vector3.new( x, -y, -z),
        cf * Vector3.new(-x, -y, -z),
        cf * Vector3.new(-x,  y,  z),
        cf * Vector3.new( x,  y,  z),
        cf * Vector3.new( x, -y,  z),
        cf * Vector3.new(-x, -y,  z),
    }
end

local function CreateEsp(player)
    local drawings = {
        Box = {},
        Name = Drawing.new("Text"),
        HealthBarBG = Drawing.new("Square"),
        HealthBar = Drawing.new("Square")
    }

    for i = 1, 12 do
        local line = Drawing.new("Line")
        line.Thickness = 1
        drawings.Box[i] = line
    end

    drawings.Name.Size = 14
    drawings.Name.Center = true
    drawings.Name.Outline = true

    drawings.HealthBarBG.Filled = true
    drawings.HealthBarBG.Color = Color3.new(0,0,0)

    drawings.HealthBar.Filled = true

    EspController.Cache[player] = drawings
end

local function RemoveEsp(player)
    local esp = EspController.Cache[player]
    if not esp then return end
    for _, obj in pairs(esp.Box) do obj:Remove() end
    esp.Name:Remove()
    esp.HealthBar:Remove()
    esp.HealthBarBG:Remove()
    EspController.Cache[player] = nil
end

function EspController:GetThemeColor()
    local theme = Themes[self.Theme] or Themes.Haze
    if self.UseGradient then
        local t = (math.sin(tick() * 3) + 1) / 2
        return theme.Color1:Lerp(theme.Color2, t)
    end
    return theme.Color1
end

function EspController:Update()
    local mainColor = self:GetThemeColor()

    for player, esp in pairs(self.Cache) do
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")

        if not (self.Enabled and char and hum and root and hum.Health > 0 and player ~= LocalPlayer) then
            for _, l in pairs(esp.Box) do l.Visible = false end
            esp.Name.Visible = false
            esp.HealthBar.Visible = false
            esp.HealthBarBG.Visible = false
            continue
        end

        local isTeammate = player.Team == LocalPlayer.Team
        if self.NoTeam and isTeammate then
            for _, l in pairs(esp.Box) do l.Visible = false end
            esp.Name.Visible = false
            esp.HealthBar.Visible = false
            esp.HealthBarBG.Visible = false
            continue
        end

        local cf, size = char:GetBoundingBox()
        local corners = GetCorners(cf, size)
        local screen = {}
        local allCornersInFront = true

        for i, corner in ipairs(corners) do
            local v, visible = Camera:WorldToViewportPoint(corner)
            
            if v.Z < 0 then 
                allCornersInFront = false 
                break 
            end
            
            screen[i] = Vector2.new(v.X, v.Y)
        end

        if not allCornersInFront then
            for _, l in pairs(esp.Box) do l.Visible = false end
            esp.Name.Visible = false
            esp.HealthBar.Visible = false
            esp.HealthBarBG.Visible = false
            continue
        end

        local color = (self.TeamCheck and player.TeamColor.Color) or mainColor

        for i, link in ipairs(BoxLines) do
            local line = esp.Box[i]
            line.From = screen[link[1]]
            line.To = screen[link[2]]
            line.Color = color
            line.Visible = true
        end

        local topPos = cf.Position + Vector3.new(0, size.Y/2 + 0.5, 0)
        local topScreen, onScreen2 = Camera:WorldToViewportPoint(topPos)

        if onScreen2 and topScreen.Z > 0 then
            local screenPos = Vector2.new(topScreen.X, topScreen.Y)

            esp.Name.Text = string.format("%s (@%s)", player.DisplayName, player.Name)
            esp.Name.Position = screenPos + Vector2.new(0, -20)
            esp.Name.Color = color
            esp.Name.Visible = true

            local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local width = (screen[2] - screen[1]).Magnitude
            local healthPos = screenPos + Vector2.new(-width/2, -8)

            esp.HealthBarBG.Size = Vector2.new(width, 4)
            esp.HealthBarBG.Position = healthPos
            esp.HealthBarBG.Visible = true

            esp.HealthBar.Size = Vector2.new(width * hp, 4)
            esp.HealthBar.Position = healthPos
            esp.HealthBar.Color = Color3.fromRGB(255,0,0):Lerp(Color3.fromRGB(0,255,0), hp)
            esp.HealthBar.Visible = true
        else
            esp.Name.Visible = false
            esp.HealthBar.Visible = false
            esp.HealthBarBG.Visible = false
        end
    end
end

for _, p in ipairs(Players:GetPlayers()) do CreateEsp(p) end
Players.PlayerAdded:Connect(CreateEsp)
Players.PlayerRemoving:Connect(RemoveEsp)

RunService.RenderStepped:Connect(function()
    EspController:Update()
end)

return EspController