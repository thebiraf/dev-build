local NotifyLib = {}
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

_G.HazeNotifCount = _G.HazeNotifCount or 0

local function udcrypt()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local length = math.random(15, 25)
    local str = ""
    for i = 1, length do
        local rand = math.random(1, #chars)
        str = str .. string.sub(chars, rand, rand)
    end
    return str
end

local function createUd(class, properties)
    local inst = Instance.new(class)
    inst.Name = udcrypt()
    pcall(function() inst.Archivable = false end)
    inst:SetAttribute(udcrypt(), math.random(1, 100))
    for prop, val in pairs(properties) do
        inst[prop] = val
    end
    return inst
end

function NotifyLib:Initialize()
    local parent = (gethui and gethui()) or CoreGui
    if self.screenGui then return end
    
    self.screenGui = createUd("ScreenGui", {
        DisplayOrder = math.random(1000, 9999),
        Parent = parent,
        ResetOnSpawn = false
    })
    
    local isMobile = UserInputService.TouchEnabled
    self.container = createUd("Frame", {
        Name = udcrypt(),
        Size = isMobile and UDim2.new(0.9, 0, 1, -40) or UDim2.new(0, 300, 1, -50),
        Position = isMobile and UDim2.new(0.5, 0, 1, -20) or UDim2.new(1, -25, 1, -25),
        AnchorPoint = isMobile and Vector2.new(0.5, 1) or Vector2.new(1, 1),
        BackgroundTransparency = 1,
        Parent = self.screenGui
    })
    
    local layout = createUd("UIListLayout", {
        Parent = self.container,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = isMobile and Enum.HorizontalAlignment.Center or Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10)
    })
end

function NotifyLib:Notify(title, text, duration, customColor)
    self:Initialize()
    local duration = duration or 4
    local accentColor = customColor or Color3.fromRGB(0, 255, 140)
    
    local notif = createUd("CanvasGroup", {
        Size = UDim2.new(1, 0, 0, 65),
        BackgroundColor3 = Color3.fromRGB(5, 5, 5),
        GroupTransparency = 1,
        BorderSizePixel = 0,
        Parent = self.container
    })
    
    _G.HazeNotifCount = _G.HazeNotifCount + 1
    notif.LayoutOrder = _G.HazeNotifCount
    
    local corner = createUd("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = notif
    })
    
    local topLine = createUd("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Parent = notif
    })
    
    local shine = createUd("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, accentColor), 
            ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)), 
            ColorSequenceKeypoint.new(1, accentColor)
        }),
        Parent = topLine
    })
    
    local brand = createUd("TextLabel", {
        Size = UDim2.new(0, 50, 0, 20),
        Position = UDim2.new(1, -55, 0, 8),
        BackgroundTransparency = 1,
        Text = "HAZE",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = notif
    })
    
    local brandGrad = createUd("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, accentColor), 
            ColorSequenceKeypoint.new(0.5, Color3.new(1,1,1)), 
            ColorSequenceKeypoint.new(1, accentColor)
        }),
        Parent = brand
    })
    
    local titleL = createUd("TextLabel", {
        Size = UDim2.new(1, -65, 0, 20),
        Position = UDim2.new(0, 15, 0, 8),
        BackgroundTransparency = 1,
        Text = title:upper(),
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif
    })
    
    local contentL = createUd("TextLabel", {
        Size = UDim2.new(1, -30, 0, 25),
        Position = UDim2.new(0, 15, 0, 28),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(180, 180, 180),
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = notif
    })
    
    local bar = createUd("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Parent = notif
    })
    
    notif.Position = UDim2.new(1.5, 0, 0, 0)
    TweenService:Create(notif, TweenInfo.new(0.8, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0}):Play()
    
    task.spawn(function()
        local t = 0
        while notif and notif.Parent do
            brandGrad.Offset = Vector2.new(math.sin(t * 3) * 0.8, 0)
            shine.Offset = Vector2.new(math.cos(t * 2) * 1, 0)
            t = t + RunService.RenderStepped:Wait()
        end
    end)
    
    TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
    
    task.delay(duration, function()
        if not notif or not notif.Parent then return end
        local ex = TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(1.5, 0, 0, 0), GroupTransparency = 1})
        ex:Play()
        ex.Completed:Connect(function() notif:Destroy() end)
    end)
end

return NotifyLib