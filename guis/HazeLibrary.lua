--[[
    Haze Library

    Original Author: mrfridgebeater
    Reworked By: ScriptIsFocus
    Improvements: tinnlol
]]

local players = game:GetService('Players')
local runService = game:GetService('RunService')
local textService = game:GetService('TextService')
local httpService = game:GetService('HttpService')
local tweenService = game:GetService('TweenService')
local userInputService = game:GetService('UserInputService')
local lighting = game:GetService('Lighting')
local collectionService = game:GetService("CollectionService")
local coreGui = game:GetService('CoreGui')
local robloxGui = coreGui:FindFirstChild("RobloxGui")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = players.LocalPlayer
local WCam = workspace.CurrentCamera
local SoundService = game:GetService("SoundService")

local LocalLibrary = "Haze/libraries"
local modules = {
    Whitelist = loadfile(LocalLibrary .. "/Whitelist.lua")(),
    Notifications = loadfile(LocalLibrary .. "/Notifications.lua")(),
    ESPController = loadfile(LocalLibrary .. "/modules/EspController.lua")(),
	Discord = loadfile(LocalLibrary .. "/discord.lua")()
}

local HazeRegistry = {}

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
    
    inst.Name = "" 
    inst.Archivable = false

    for prop, val in pairs(properties) do
        inst[prop] = val
    end

    table.insert(HazeRegistry, inst)
    return inst
end

local function cleanHaze()
    for i, obj in ipairs(HazeRegistry) do
        if obj then
            pcall(function() obj:Destroy() end)
        end
    end
    HazeRegistry = {}
end

cleanHaze()

local screenGui = createUd("ScreenGui", {
    Parent = (gethui and gethui()) or coreGui, 
    ResetOnSpawn = false, 
    DisplayOrder = math.random(150000, 999999),
    IgnoreGuiInset = true
})

local clickGui = createUd("Frame", {
    Parent = screenGui, 
    Size = UDim2.fromScale(1, 1), 
    BackgroundTransparency = 1, 
    Visible = false
})

local blur = createUd("BlurEffect", {
    Parent = lighting, 
    Size = 0
})

local arrayList = createUd("Frame", {
    Parent = screenGui,
    Position = UDim2.new(1, -10, 0, 60),
    Size = UDim2.new(0, 200, 1, 0),
    AnchorPoint = Vector2.new(1, 0),
    BackgroundTransparency = 1,
    Visible = false
})

local mobileToggleButton = createUd("TextButton", {
    Parent = screenGui,
    Size = UDim2.fromOffset(100, 42),
    Position = UDim2.new(0, 25, 0, 0),
    BackgroundColor3 = Color3.fromRGB(15, 15, 15),
    Text = "",
    AutoButtonColor = false,
    Visible = userInputService.TouchEnabled
})

local btnCorner = createUd("UICorner", {
    CornerRadius = UDim.new(0, 10),
    Parent = mobileToggleButton
})

local textLabel = createUd("TextLabel", {
    Parent = mobileToggleButton,
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "HAZE",
    Font = Enum.Font.BuilderSansExtraBold,
    TextSize = 24,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local textGradient = createUd("UIGradient", {
    Parent = textLabel,
    Rotation = 0,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(66, 245, 108)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(66, 245, 108))
    })
})

local textStroke = createUd("UIStroke", {
    Parent = textLabel,
    Thickness = 1,
    Color = Color3.fromRGB(66, 245, 108),
    Transparency = 0.8
})

task.spawn(function()
	while true do
		textGradient.Offset = Vector2.new(-1, 0)
		local tween = tweenService:Create(textGradient, TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {
			Offset = Vector2.new(1, 0)
		})
		tween:Play()
		tween.Completed:Wait()

		task.wait(0.5)
	end
end)

mobileToggleButton.MouseButton1Click:Connect(function()
	local shrink = tweenService:Create(mobileToggleButton, TweenInfo.new(0.1), {Size = UDim2.fromOffset(95, 38)})
	shrink:Play()
	shrink.Completed:Wait()
	tweenService:Create(mobileToggleButton, TweenInfo.new(0.3, Enum.EasingStyle.Bounce), {Size = UDim2.fromOffset(100, 42)}):Play()
	clickGui.Visible = not clickGui.Visible
	local targetBlur = clickGui.Visible and 20 or 0
	tweenService:Create(blur, TweenInfo.new(0.3), {Size = targetBlur}):Play()
end)

local dragging, dragInput, dragStart, startPos

mobileToggleButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mobileToggleButton.Position
	end
end)

userInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		mobileToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

userInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

local arraylistSort = Instance.new('UIListLayout')
arraylistSort.Parent = arrayList
arraylistSort.SortOrder = Enum.SortOrder.LayoutOrder
arraylistSort.HorizontalAlignment = Enum.HorizontalAlignment.Right
arraylistSort.Padding = UDim.new(0, 2)

local logoFrame = Instance.new('Frame')
logoFrame.Parent = arrayList
logoFrame.Size = UDim2.new(1, 0, 0, 60)
logoFrame.BackgroundTransparency = 1
logoFrame.LayoutOrder = -1

local logoText = Instance.new('TextLabel')
logoText.Parent = logoFrame
logoText.Size = UDim2.fromScale(1, 1)
logoText.Position = UDim2.fromOffset(-10, 0)
logoText.BackgroundTransparency = 1
logoText.Text = "HAZE"
logoText.TextColor3 = Color3.fromRGB(255, 255, 255)
logoText.TextSize = 45
logoText.Font = Enum.Font.BuilderSansExtraBold
logoText.TextXAlignment = Enum.TextXAlignment.Right
logoText.RichText = true

local uiStroke = Instance.new("UIStroke")
uiStroke.Parent = logoText
uiStroke.Thickness = 0.5
uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
uiStroke.Color = Color3.fromRGB(0, 0, 0)

local subLogoText = Instance.new('TextLabel')
subLogoText.Name = "SubLogoText"
subLogoText.Parent = logoFrame
subLogoText.Size = UDim2.new(1, 0, 0, 20)
subLogoText.Position = UDim2.new(0, -10, 0, 55)
subLogoText.BackgroundTransparency = 1
subLogoText.Text = ""
subLogoText.TextColor3 = Color3.fromRGB(200, 200, 200)
subLogoText.TextSize = 16
subLogoText.Font = Enum.Font.BuilderSansExtraBold
subLogoText.TextXAlignment = Enum.TextXAlignment.Right
subLogoText.RichText = true

local uiStroke = Instance.new("UIStroke")
uiStroke.Parent = subLogoText
uiStroke.Thickness = 1.5
uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
uiStroke.Color = Color3.fromRGB(0, 0, 0)

local subStroke = Instance.new("UIStroke")
subStroke.Parent = subLogoText
subStroke.Thickness = 1
subStroke.Transparency = 0.8

local uiStroke = Instance.new("UIStroke")
uiStroke.Parent = logoText
uiStroke.Thickness = 2
uiStroke.Transparency = 0.8
uiStroke.Color = Color3.fromRGB(0, 0, 0)

local uiScale = Instance.new('UIScale')
uiScale.Parent = screenGui
uiScale.Scale = math.clamp(screenGui.AbsoluteSize.X / 1920, 0.8, 1.2)

local function updateScale()
	uiScale.Scale = math.clamp(screenGui.AbsoluteSize.X / 1920, 0.5, 1.2)
end
screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale)
updateScale()

if not runService:IsStudio() then
	local folders = {'Haze', 'Haze/configs', 'Haze/libraries'}

	for i,v in folders do
		if not isfolder(v) then
			makefolder(v)
		end
	end

	if not isfile('Haze/config.txt') then
		writefile('Haze/config.txt', 'Default')
	end
end

local guiLibrary = {
	Info = {
		Name = 'Haze',
		Ver = 'BETA',
	},
	Pallete = {
		Main = Color3.fromRGB(66, 245, 108),
		Changed = Instance.new('BindableEvent'),
	},
	Collection = {},
	Windows = {},
	Config = {},
	CfgName = readfile and readfile('Haze/config.txt') or 'Default',
}

table.insert(guiLibrary.Collection, userInputService.InputBegan:Connect(function(Input: InputObject)
	if not userInputService:GetFocusedTextBox() and Input.KeyCode == Enum.KeyCode.RightShift then
		clickGui.Visible = not clickGui.Visible
		local targetBlur = clickGui.Visible and 20 or 0
		tweenService:Create(blur, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetBlur}):Play()
	end
end))

local aids = {}
local function sortArray()
    table.sort(aids, function(a, b)
        return a.Size.X.Offset > b.Size.X.Offset
    end)

    for i, v in ipairs(aids) do
        v.LayoutOrder = i
    end
end

function addToArray(Name: string, ExtraText)
    local Obj = Instance.new('Frame')
    Obj.Name = Name
    Obj.Parent = arrayList
    Obj.BorderSizePixel = 0
    Obj.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Obj.BackgroundTransparency = (ArrayBackground and ArrayBackground.value / 100 or 0.5)
    Obj.Size = UDim2.new(0, 0, 0, 28)
    Obj.ClipsDescendants = false

    local SideLine = Instance.new('Frame')
    SideLine.Parent = Obj
    SideLine.Position = UDim2.fromScale(1, 0)
    SideLine.AnchorPoint = Vector2.new(1, 0)
    SideLine.Size = UDim2.new(0, 3, 1, 0)
    SideLine.BorderSizePixel = 0
    SideLine.BackgroundColor3 = guiLibrary.Pallete.Main

    local ModuleText = Instance.new('TextLabel')
    ModuleText.Parent = Obj
    ModuleText.Size = UDim2.new(1, -5, 1, 0)
    ModuleText.Position = UDim2.fromScale(0, 0)
    ModuleText.BackgroundTransparency = 1
    ModuleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    ModuleText.TextSize = 17
    ModuleText.Font = Enum.Font.BuilderSans
    ModuleText.TextXAlignment = Enum.TextXAlignment.Center
    ModuleText.RichText = true

    local aider = guiLibrary.Pallete.Changed.Event:Connect(function()
        SideLine.BackgroundColor3 = guiLibrary.Pallete.changeColor(guiLibrary.Pallete.Main, 0.7)
    end)

    task.spawn(function()
        local lastWidth = 0
        repeat
            task.wait()
            local textContent = Name
            local pureText = Name
            if ExtraText and typeof(ExtraText()) == 'string' then
                textContent = Name .. ' <font color="rgb(180,180,180)">' .. ExtraText() .. '</font>'
                pureText = Name .. " " .. ExtraText()
            end

            ModuleText.Text = textContent
            local textSize = textService:GetTextSize(pureText, ModuleText.TextSize, ModuleText.Font, Vector2.new(1000, 1000))
            local newWidth = textSize.X + 18
            
            Obj.Size = UDim2.fromOffset(newWidth, 28)

            if newWidth ~= lastWidth then
                lastWidth = newWidth
                sortArray()
            end
        until Obj == nil or Obj:GetAttribute('Destroying')
    end)

    Obj.Destroying:Once(function() aider:Disconnect() end)
    table.insert(aids, Obj)
    sortArray()
end

local function removeFromArray(Name: string)
	for i,v in aids do
		if v.Name == Name then
			table.remove(aids, i)
			tweenService:Create(v, TweenInfo.new(0.15), {
				Transparency = 1
				--Size = UDim2.fromOffset(0, 30)
			}):Play()
			v:SetAttribute('Destroying', true)

			task.delay(0.1, function()
				tweenService:Create(v.Frame, TweenInfo.new(0.05), {Transparency = 1}):Play()
			end)

			task.delay(0.15, function()
				v:Destroy()
			end)
		end
	end
end

function guiLibrary.saveCFG(Name: string)
	if runService:IsStudio() then return end

	writefile('Haze/configs/'..game.PlaceId..'.json', httpService:JSONEncode(guiLibrary.Config))
end

function guiLibrary.loadCFG(Name: string)
	if runService:IsStudio() then return end

	if isfile('Haze/configs/'..game.PlaceId..'.json') then
		guiLibrary.Config = httpService:JSONDecode(readfile('Haze/configs/'..game.PlaceId..'.json'))
	end
end

function guiLibrary.Pallete.changeColor(Color: Color3, Decided: number)
	assert(typeof(Color) == 'Color3', 'Color sent is not valid Color3 Value.')
	assert(typeof(Decided) == 'number', 'Change value is not number.')

	local R = math.round(Color.R * 255) * Decided
	local G = math.round(Color.G * 255) * Decided
	local B = math.round(Color.B * 255) * Decided

	return Color3.fromRGB(R, G, B)
end

local aidedFrame = 0
function guiLibrary:getWindow(Name: string)
	assert(typeof(Name) == 'string', 'Name variable is not string')

	return self.Windows[Name] or {}
end
function guiLibrary:createWindow(Name: string)
	assert(typeof(Name) == 'string', 'Name variable is not string')

	local Frame = Instance.new('Frame')
	Frame.Parent = clickGui
	Frame.Position = UDim2.fromOffset(50 + (aidedFrame * 235), 70)
	Frame.Size = UDim2.fromOffset(210, 40)
	Frame.BorderSizePixel = 0
	Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Frame
	local Accent = Instance.new("Frame")
	Accent.Size = UDim2.new(1, 0, 0, 2)
	Accent.Position = UDim2.new(0, 0, 1, -2)
	Accent.BackgroundColor3 = Color3.fromRGB(0, 255, 106)
	Accent.BorderSizePixel = 0
	Accent.Parent = Frame

	table.insert(guiLibrary.Collection, guiLibrary.Pallete.Changed.Event:Connect(function()
		Accent.BackgroundColor3 = guiLibrary.Pallete.Main
	end))
	local Label = Instance.new('TextLabel')
	Label.Parent = Frame
	Label.Position = UDim2.fromOffset(10, 0)
	Label.Size = UDim2.new(1, -70, 1, 0)
	Label.BackgroundTransparency = 1
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.TextColor3 = Color3.fromRGB(255, 255, 255)
	Label.TextSize = 18
	Label.Text = Name
	Label.Font = Enum.Font.BuilderSansMedium
	local StateIndicator = Instance.new("TextLabel")
	StateIndicator.Name = "Indicator"
	StateIndicator.Text = "-"
	StateIndicator.Size = UDim2.fromOffset(30, 40)
	StateIndicator.Position = UDim2.new(1, -30, 0, 0)
	StateIndicator.BackgroundTransparency = 1
	StateIndicator.TextColor3 = Color3.fromRGB(200, 200, 200)
	StateIndicator.TextSize = 22
	StateIndicator.Font = Enum.Font.BuilderSans
	StateIndicator.Parent = Frame
	local Modules = Instance.new('Frame')
	Modules.Parent = Frame
	Modules.Position = UDim2.fromScale(0, 1)
	Modules.Size = UDim2.fromScale(1, 0)
	Modules.AutomaticSize = Enum.AutomaticSize.Y
	Modules.BackgroundTransparency = 1
	
	local collapsed = false
	Frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
			collapsed = not collapsed
			local easingStyle = collapsed and Enum.EasingStyle.Quart or Enum.EasingStyle.Back
			local duration = 0.3

			StateIndicator.Text = collapsed and "+" or "-"

			if collapsed then
				Modules.AutomaticSize = Enum.AutomaticSize.None
				Modules.ClipsDescendants = true

				tweenService:Create(Modules, TweenInfo.new(duration, easingStyle, Enum.EasingDirection.In), {
					Size = UDim2.new(1, 0, 0, 0)
				}):Play()

				for _, child in ipairs(Modules:GetChildren()) do
					if child:IsA("Frame") then
						tweenService:Create(child, TweenInfo.new(duration/2), {BackgroundTransparency = 1}):Play()
					end
				end

				task.delay(duration, function() 
					if collapsed then Modules.Visible = false end 
				end)
			else
				Modules.Visible = true
				Modules.Size = UDim2.new(1, 0, 0, 0)

				for _, child in ipairs(Modules:GetChildren()) do
					if child:IsA("Frame") then
						child.BackgroundTransparency = 1
						tweenService:Create(child, TweenInfo.new(duration), {BackgroundTransparency = 0}):Play()
					end
				end

				local tween = tweenService:Create(Modules, TweenInfo.new(duration, easingStyle, Enum.EasingDirection.Out), {
					Size = UDim2.new(1, 0, 0, 150)
				})
				tween:Play()

				tween.Completed:Once(function()
					if not collapsed then
						Modules.AutomaticSize = Enum.AutomaticSize.Y
					end
				end)
			end
		end
	end)
	
	local ModulesSort = Instance.new('UIListLayout')
	ModulesSort.Parent = Modules
	ModulesSort.SortOrder = Enum.SortOrder.LayoutOrder

	aidedFrame += 1

	self.Windows[Name] = {
		modules = {},
		createModule = function(self, Table)
			assert(typeof(Table) == 'table', 'Variable Table is not table type')
			assert(typeof(Table.Name) == 'string', 'Name variable is not string')

			if not guiLibrary.Config[Table.Name] then
				guiLibrary.Config[Table.Name] = {
					enabled = false,
					keybind = 'Unknown',
					toggles = {},
					sliders = {},
					selectors = {},
				}
			end

			local ModuleFrame = Instance.new('Frame')
			ModuleFrame.Parent = Modules
			ModuleFrame.Size = UDim2.new(1, 0, 0, 35)
			ModuleFrame.BorderSizePixel = 0
			ModuleFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
			local ModuleLabel = Instance.new('TextButton')
			ModuleLabel.Parent = ModuleFrame
			ModuleLabel.Position = UDim2.fromOffset(8, 0)
			ModuleLabel.Size = UDim2.fromScale(1, 1)
			ModuleLabel.BackgroundTransparency = 1
			ModuleLabel.TextXAlignment = Enum.TextXAlignment.Left
			ModuleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			ModuleLabel.TextSize = 17
			ModuleLabel.Text = Table.Name
			ModuleLabel.Font = Enum.Font.BuilderSans
			ModuleLabel.RichText = true
			local ModuleDots = Instance.new('ImageButton')
			ModuleDots.Parent = ModuleFrame
			ModuleDots.AnchorPoint = Vector2.new(0.5, 0.5)
			ModuleDots.Position = UDim2.fromScale(0.92, 0.5)
			ModuleDots.Size = UDim2.fromOffset(24, 25)
			ModuleDots.Image = 'rbxassetid://12974354280'
			ModuleDots.BackgroundTransparency = 1
			local ModuleSide = Instance.new('Frame')
			ModuleSide.Parent = ModuleFrame
			ModuleSide.Size = UDim2.new(0, 3, 1, 0)
			ModuleSide.BorderSizePixel = 0
			ModuleSide.BackgroundColor3 = guiLibrary.Pallete.changeColor(guiLibrary.Pallete.Main, 0.7)
			ModuleSide.BackgroundTransparency = 1
			local Dropdown = Instance.new('Frame')
			Dropdown.Parent = Modules
			Dropdown.Size = UDim2.fromScale(1, 0)
			Dropdown.AutomaticSize = Enum.AutomaticSize.Y
			Dropdown.BackgroundTransparency =1 
			Dropdown.Visible = false
			local DropdownSort = Instance.new('UIListLayout')
			DropdownSort.Parent = Dropdown
			DropdownSort.SortOrder = Enum.SortOrder.LayoutOrder
			local HideModule

			if Table.Description then
				local Description = Instance.new('TextLabel')
				Description.Parent = screenGui
				Description.Position = UDim2.fromOffset(userInputService:GetMouseLocation().X, userInputService:GetMouseLocation().Y)
				Description.BorderSizePixel = 0
				Description.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
				Description.TextColor3 = Color3.fromRGB(255,255,255)
				Description.TextSize = 13
				Description.Text = Table.Description
				Description.Font = Enum.Font.BuilderSans
				Description.Size = UDim2.new(0, textService:GetTextSize('  ' .. Table.Description .. '  ', Description.TextSize, Description.Font, Vector2.zero).X, 0, 20)
				Description.Visible = false
				Description.AnchorPoint = Vector2.new(-0.5, 0.5)

				local isHovering = false
				table.insert(guiLibrary.Collection, ModuleFrame.MouseEnter:Connect(function()
					isHovering = true
					Description.Visible = true

					repeat
						task.wait()
						local pos = UDim2.fromOffset(userInputService:GetMouseLocation().X + 10, userInputService:GetMouseLocation().Y)

						tweenService:Create(Description, TweenInfo.new(0.15), {Position = pos}):Play()
					until not isHovering
				end))
				table.insert(guiLibrary.Collection, ModuleFrame.MouseLeave:Connect(function()
					isHovering = false
					Description.Visible = false
				end))
			end

			local ModuleReturn = {enabled = false, collection = {}}
			function ModuleReturn:Clean(v1, v2)
				task.spawn(function()
					if typeof(v1) == 'function' then
						table.insert(self.collection, runService.Heartbeat:Connect(v1))
					elseif v1 and v2 and typeof(v2) == 'function' then
						table.insert(self.collection, v1:Connect(v2))
					elseif v1 then
						table.insert(self.collection, v1)
					end
				end)
			end
			function ModuleReturn:CleanTable()
				for i,v in self.collection do
					if typeof(v) == 'RBXScriptConnection' then
						v:Disconnect()
					elseif typeof(v) == 'Instance' then
						v:Destroy()
					end
					table.remove(self.collection, i)
				end
			end
			function ModuleReturn:toggle(silent: boolean)
				self.enabled = not self.enabled
				guiLibrary.Config[Table.Name].enabled = self.enabled

				tweenService:Create(ModuleSide, TweenInfo.new(0.15), {BackgroundTransparency = self.enabled and 0 or 1}):Play()
				tweenService:Create(ModuleLabel, TweenInfo.new(0.15), {TextColor3 = self.enabled and guiLibrary.Pallete.Main or Color3.fromRGB(200,200,200)}):Play()

				if not self.enabled then
					self:CleanTable()
				end

				if Table.Function then
					task.spawn(pcall, function()
						Table.Function(self.enabled)
					end)
				end

				if not silent then
					local stateText = self.enabled and "Enabled" or "Disabled"
					local stateColor = self.enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
					
					modules.Notifications:Notify(
						Table.Name, 
						Table.Name .. " has been " .. stateText, 
						3, 
						stateColor
					)
				end

				if self.enabled then
					addToArray(Table.Name, Table.ExtraText or nil)
				else
					removeFromArray(Table.Name)
				end

				guiLibrary.saveCFG(guiLibrary.CfgName)
			end

			ModuleReturn.toggles = {}
			function ModuleReturn.toggles.new(Tab)
				if not guiLibrary.Config[Table.Name].toggles[Tab.Name] then
					guiLibrary.Config[Table.Name].toggles[Tab.Name] = {enabled = false}
				end

				local ToggleFrame = Instance.new('Frame')
				ToggleFrame.Parent = Dropdown
				ToggleFrame.Size = UDim2.new(1, 0, 0, 30)
				ToggleFrame.BorderSizePixel = 0
				ToggleFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
				local ToggleLabel = Instance.new('TextButton')
				ToggleLabel.Parent = ToggleFrame
				ToggleLabel.Position = UDim2.fromOffset(8, 0)
				ToggleLabel.Size = UDim2.fromScale(1, 1)
				ToggleLabel.BackgroundTransparency = 1
				ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
				ToggleLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
				ToggleLabel.TextSize = 16
				ToggleLabel.Text = Tab.Name
				ToggleLabel.Font = Enum.Font.BuilderSans
				local ToggleSide = Instance.new('Frame')
				ToggleSide.Parent = ToggleFrame
				ToggleSide.Size = UDim2.new(0, 3, 1, 0)
				ToggleSide.BorderSizePixel = 0
				ToggleSide.BackgroundColor3 = guiLibrary.Pallete.changeColor(guiLibrary.Pallete.Main, 0.7)

				local ToggleReturn = {enabled = false, inst = ToggleFrame}
				function ToggleReturn:toggle()
					self.enabled = not self.enabled
					guiLibrary.Config[Table.Name].toggles[Tab.Name].enabled = self.enabled

					tweenService:Create(ToggleLabel, TweenInfo.new(0.15), {TextColor3 = self.enabled and guiLibrary.Pallete.changeColor(guiLibrary.Pallete.Main, 0.7) or Color3.fromRGB(150, 150, 150)}):Play()

					if Tab.Function then
						task.spawn(pcall, function()
							Tab.Function(self.enabled)
						end)
					end

					guiLibrary.saveCFG(guiLibrary.CfgName)
				end

				table.insert(guiLibrary.Collection, ToggleLabel.MouseButton1Down:Connect(function()
					ToggleReturn:toggle()
				end))
				table.insert(guiLibrary.Collection, guiLibrary.Pallete.Changed.Event:Connect(function()
					ToggleSide.BackgroundColor3 = guiLibrary.Pallete.changeColor(guiLibrary.Pallete.Main, 0.7)

					if ToggleReturn.enabled then
						ToggleLabel.TextColor3 = guiLibrary.Pallete.Main
					end
				end))

				if guiLibrary.Config[Table.Name].toggles[Tab.Name].enabled then
					task.delay(0.1, function()
						ToggleReturn:toggle()
					end)
				end

				return ToggleReturn
			end

			ModuleReturn.selectors = {}
			function ModuleReturn.selectors.new(Tab)
				if not guiLibrary.Config[Table.Name].selectors[Tab.Name] then
					guiLibrary.Config[Table.Name].selectors[Tab.Name] = {value = Tab.Default or Tab.Selections[1] or 'nil'}
				end

				local SelectorFrame = Instance.new('Frame')
				SelectorFrame.Parent = Dropdown
				SelectorFrame.Size = UDim2.new(1, 0, 0, 30)
				SelectorFrame.BorderSizePixel = 0
				SelectorFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
				local SelectorLabel = Instance.new('TextButton')
				SelectorLabel.Parent = SelectorFrame
				SelectorLabel.Position = UDim2.fromOffset(8, 0)
				SelectorLabel.Size = UDim2.fromScale(1, 1)
				SelectorLabel.BackgroundTransparency = 1
				SelectorLabel.TextXAlignment = Enum.TextXAlignment.Left
				SelectorLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
				SelectorLabel.TextSize = 16
				SelectorLabel.Text = Tab.Name
				SelectorLabel.Font = Enum.Font.BuilderSans
				local SelectedLabel = Instance.new('TextLabel')
				SelectedLabel.Parent = SelectorFrame
				SelectedLabel.Position = UDim2.fromOffset(-8, 0)
				SelectedLabel.Size = UDim2.fromScale(1, 1)
				SelectedLabel.BackgroundTransparency = 1
				SelectedLabel.TextXAlignment = Enum.TextXAlignment.Right
				SelectedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
				SelectedLabel.TextSize = 16
				SelectedLabel.Text = 'cooked'
				SelectedLabel.Font = Enum.Font.BuilderSans
				local SelectorSide = Instance.new('Frame')
				SelectorSide.Parent = SelectorFrame
				SelectorSide.Size = UDim2.new(0, 3, 1, 0)
				SelectorSide.BorderSizePixel = 0
				SelectorSide.BackgroundColor3 = guiLibrary.Pallete.changeColor(guiLibrary.Pallete.Main, 0.7)

				local SelectorReturn = {value = guiLibrary.Config[Table.Name].selectors[Tab.Name].value, inst = SelectorFrame}
				function SelectorReturn:select(Name: string)
					self.value = Name
					guiLibrary.Config[Table.Name].selectors[Tab.Name].value = self.value

					SelectedLabel.Text = self.value

					if Tab.Function then
						task.spawn(pcall, function()
							Tab.Function(self.value)
						end)
					end

					guiLibrary.saveCFG(guiLibrary.CfgName)
				end

				local Index = 1
				for i,v in Tab.Selections do
					if v == SelectorReturn.value then
						Index = i
					end
				end
				table.insert(guiLibrary.Collection, SelectorLabel.MouseButton1Down:Connect(function()
					Index += 1
					if Index > #Tab.Selections then
						Index = 1
					end

					SelectorReturn:select(Tab.Selections[Index])
				end))
				table.insert(guiLibrary.Collection, SelectorLabel.MouseButton2Down:Connect(function()
					Index -= 1
					if Index < 1 then
						Index = #Tab.Selections
					end

					SelectorReturn:select(Tab.Selections[Index])
				end))
				table.insert(guiLibrary.Collection, guiLibrary.Pallete.Changed.Event:Connect(function()
					SelectorSide.BackgroundColor3 = guiLibrary.Pallete.changeColor(guiLibrary.Pallete.Main, 0.7)
				end))

				SelectorReturn:select(SelectorReturn.value)

				return SelectorReturn
			end
			ModuleReturn.textboxes = {}
			function ModuleReturn.textboxes.new(Tab)
				if not guiLibrary.Config[Table.Name].textboxes then guiLibrary.Config[Table.Name].textboxes = {} end
				if not guiLibrary.Config[Table.Name].textboxes[Tab.Name] then
					guiLibrary.Config[Table.Name].textboxes[Tab.Name] = {value = Tab.Default or ""}
				end

				local BoxFrame = Instance.new('Frame')
				BoxFrame.Parent = Dropdown
				BoxFrame.Size = UDim2.new(1, 0, 0, 35)
				BoxFrame.BorderSizePixel = 0
				BoxFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)

				local BoxLabel = Instance.new('TextLabel')
				BoxLabel.Parent = BoxFrame
				BoxLabel.Position = UDim2.fromOffset(8, 0)
				BoxLabel.Size = UDim2.new(0.4, 0, 1, 0)
				BoxLabel.BackgroundTransparency = 1
				BoxLabel.TextXAlignment = Enum.TextXAlignment.Left
				BoxLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
				BoxLabel.TextSize = 15
				BoxLabel.Text = Tab.Name
				BoxLabel.Font = Enum.Font.BuilderSans

				local TextBox = Instance.new('TextBox')
				TextBox.Parent = BoxFrame
				TextBox.Size = UDim2.new(0.5, -8, 0.7, 0)
				TextBox.Position = UDim2.new(1, -8, 0.5, 0)
				TextBox.AnchorPoint = Vector2.new(1, 0.5)
				TextBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
				TextBox.Text = guiLibrary.Config[Table.Name].textboxes[Tab.Name].value
				TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextBox.TextSize = 14
				TextBox.Font = Enum.Font.BuilderSans
				TextBox.PlaceholderText = "..."
				TextBox.ClipsDescendants = true
				TextBox.TextTruncate = Enum.TextTruncate.AtEnd
				TextBox.ClearTextOnFocus = false 

				local BoxCorner = Instance.new("UICorner")
				BoxCorner.CornerRadius = UDim.new(0, 4)
				BoxCorner.Parent = TextBox

				local BoxSide = Instance.new('Frame')
				BoxSide.Parent = BoxFrame
				BoxSide.Size = UDim2.new(0, 3, 1, 0)
				BoxSide.BorderSizePixel = 0
				BoxSide.BackgroundColor3 = guiLibrary.Pallete.changeColor(guiLibrary.Pallete.Main, 0.7)

				table.insert(guiLibrary.Collection, guiLibrary.Pallete.Changed.Event:Connect(function()
					BoxSide.BackgroundColor3 = guiLibrary.Pallete.changeColor(guiLibrary.Pallete.Main, 0.7)
				end))

				local BoxReturn = {value = TextBox.Text, inst = BoxFrame}

				local function update(val)
					BoxReturn.value = val
					guiLibrary.Config[Table.Name].textboxes[Tab.Name].value = val
					if Tab.Function then
						task.spawn(pcall, function() Tab.Function(val) end)
					end
					guiLibrary.saveCFG(guiLibrary.CfgName)
				end

				TextBox.FocusLost:Connect(function()
					update(TextBox.Text)
				end)

				task.delay(0.1, function()
					update(guiLibrary.Config[Table.Name].textboxes[Tab.Name].value)
				end)

				return BoxReturn
			end
			ModuleReturn.sliders = {}
			function ModuleReturn.sliders.new(Tab)
				if not guiLibrary.Config[Table.Name].sliders[Tab.Name] then
					guiLibrary.Config[Table.Name].sliders[Tab.Name] = {value = (Tab.Default or Tab.Maximum)}
				end

				Tab.Step = Tab.Step or 1

				local SliderFrame = Instance.new('Frame')
				SliderFrame.Parent = Dropdown
				SliderFrame.Size = UDim2.new(1, 0, 0, 42)
				SliderFrame.BorderSizePixel = 0
				SliderFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)

				local SliderLabel = Instance.new('TextLabel')
				SliderLabel.Parent = SliderFrame
				SliderLabel.Position = UDim2.fromOffset(8, 0)
				SliderLabel.Size = UDim2.new(1, 0, 0, 30)
				SliderLabel.BackgroundTransparency = 1
				SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
				SliderLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
				SliderLabel.TextSize = 16
				SliderLabel.Text = Tab.Name .. ' <font color="rgb(200,200,200)">(' .. (Tab.Default or Tab.Maximum) .. ')</font>'
				SliderLabel.Font = Enum.Font.BuilderSans
				SliderLabel.RichText = true

				local SliderSide = Instance.new('Frame')
				SliderSide.Parent = SliderFrame
				SliderSide.Size = UDim2.new(0, 3, 1, 0)
				SliderSide.BorderSizePixel = 0
				SliderSide.BackgroundColor3 = guiLibrary.Pallete.changeColor(guiLibrary.Pallete.Main, 0.7)

				local SliderBG = Instance.new('TextButton')
				SliderBG.Parent = SliderFrame
				SliderBG.Position = UDim2.fromOffset(8, 29)
				SliderBG.Size = UDim2.new(1, -16, 0, 7)
				SliderBG.BorderSizePixel = 0
				SliderBG.BackgroundColor3 = guiLibrary.Pallete.changeColor(guiLibrary.Pallete.Main, 0.7)
				SliderBG.Text = ''
				SliderBG.AutoButtonColor = false

				local SliderInvis = Instance.new('Frame')
				SliderInvis.Parent = SliderBG
				SliderInvis.Size = UDim2.fromScale(0.5, 1)
				SliderInvis.BorderSizePixel = 0
				SliderInvis.BackgroundColor3 = guiLibrary.Pallete.Main

				local SliderCircle = Instance.new('Frame')
				SliderCircle.Parent = SliderInvis
				SliderCircle.Size = UDim2.fromOffset(9, 9)
				SliderCircle.BackgroundColor3 = Color3.fromRGB(66, 245, 108)
				SliderCircle.Position = UDim2.fromScale(1, 0.5)
				SliderCircle.AnchorPoint = Vector2.new(0.5, 0.5)

				Instance.new('UICorner', SliderBG).CornerRadius = UDim.new(1, 0)
				Instance.new('UICorner', SliderInvis).CornerRadius = UDim.new(1, 0)
				Instance.new('UICorner', SliderCircle).CornerRadius = UDim.new(1, 0)

				local function snap(v)
					return math.clamp(math.round(v / Tab.Step) * Tab.Step, Tab.Minimum, Tab.Maximum)
				end

				local function setValue(v)
					v = snap(v)
					local pct = (v - Tab.Minimum) / (Tab.Maximum - Tab.Minimum)
					guiLibrary.Config[Table.Name].sliders[Tab.Name].value = v

					tweenService:Create(SliderInvis, TweenInfo.new(0.15), {Size = UDim2.fromScale(pct, 1)}):Play()

					SliderLabel.Text = Tab.Name .. ' <font color="rgb(200,200,200)">(' .. v .. ')</font>'
					if Tab.Function then
						Tab.Function(v)
					end
					guiLibrary.saveCFG(guiLibrary.CfgName)
				end

				local dragging = false
				
				local function updateInput(input)
					local pos = input.Position.X
					local rel = math.clamp((pos - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
					setValue(Tab.Minimum + (Tab.Maximum - Tab.Minimum) * rel)
				end

				table.insert(guiLibrary.Collection, SliderBG.InputBegan:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						updateInput(i)
					end
				end))

				table.insert(guiLibrary.Collection, userInputService.InputEnded:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
						dragging = false
					end
				end))

				table.insert(guiLibrary.Collection, userInputService.InputChanged:Connect(function(i)
					if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
						updateInput(i)
					end
				end))

				table.insert(guiLibrary.Collection, guiLibrary.Pallete.Changed.Event:Connect(function()
					SliderInvis.BackgroundColor3 = guiLibrary.Pallete.Main
					SliderSide.BackgroundColor3 = guiLibrary.Pallete.changeColor(guiLibrary.Pallete.Main, 0.7)
					SliderBG.BackgroundColor3 = guiLibrary.Pallete.changeColor(guiLibrary.Pallete.Main, 0.7)
				end))

				local SliderReturn = {value = guiLibrary.Config[Table.Name].sliders[Tab.Name].value, inst = SliderFrame}
				
				function SliderReturn:set(val)
					val = snap(val)
					self.value = val
					SliderInvis.Size = UDim2.fromScale((val - Tab.Minimum) / (Tab.Maximum - Tab.Minimum), 1)
					SliderLabel.Text = Tab.Name .. ' <font color="rgb(200,200,200)">(' .. val .. ')</font>'
					if Tab.Function then
						Tab.Function(val)
					end
				end

				task.delay(0.2, function()
					SliderReturn:set(SliderReturn.value)
				end)

				return SliderReturn
			end
			ModuleReturn.colorpickers = {}
			function ModuleReturn.colorpickers.new(Tab)
				if not guiLibrary.Config[Table.Name].colorpickers then 
					guiLibrary.Config[Table.Name].colorpickers = {} 
				end
				
				if not guiLibrary.Config[Table.Name].colorpickers[Tab.Name] then
					local def = Tab.Default or Color3.new(1, 1, 1)
					guiLibrary.Config[Table.Name].colorpickers[Tab.Name] = {
						color = {def.R, def.G, def.B}
					} 
				end

				local saved = guiLibrary.Config[Table.Name].colorpickers[Tab.Name].color
				local h, s, v = Color3.new(saved[1], saved[2], saved[3]):ToHSV()

				local PickerContainer = Instance.new('Frame', Dropdown)
				PickerContainer.Size = UDim2.new(1, 0, 0, 35)
				PickerContainer.BackgroundTransparency = 1
				PickerContainer.ClipsDescendants = true

				local PickerSide = Instance.new('Frame', PickerContainer)
				PickerSide.Size = UDim2.new(0, 3, 0, 35)
				PickerSide.BorderSizePixel = 0
				PickerSide.BackgroundColor3 = guiLibrary.Pallete.changeColor(guiLibrary.Pallete.Main, 0.7)
				PickerSide.ZIndex = 2

				local MainButton = Instance.new('TextButton', PickerContainer)
				MainButton.Size = UDim2.new(1, 0, 0, 35)
				MainButton.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
				MainButton.BorderSizePixel = 0
				MainButton.Text = ""
				MainButton.AutoButtonColor = false

				local ButtonLabel = Instance.new('TextLabel', MainButton)
				ButtonLabel.Position = UDim2.fromOffset(12, 0)
				ButtonLabel.Size = UDim2.new(1, -60, 1, 0)
				ButtonLabel.BackgroundTransparency = 1
				ButtonLabel.Text = Tab.Name
				ButtonLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
				ButtonLabel.TextSize = 15
				ButtonLabel.Font = Enum.Font.BuilderSans
				ButtonLabel.TextXAlignment = Enum.TextXAlignment.Left

				local ColorPreview = Instance.new('Frame', MainButton)
				ColorPreview.AnchorPoint = Vector2.new(1, 0.5)
				ColorPreview.Position = UDim2.new(1, -12, 0.5, 0)
				ColorPreview.Size = UDim2.fromOffset(28, 16)
				ColorPreview.BackgroundColor3 = Color3.fromHSV(h, s, v)
				local PreviewCorner = Instance.new("UICorner", ColorPreview)
				PreviewCorner.CornerRadius = UDim.new(0, 4)
				
				local PreviewStroke = Instance.new("UIStroke", ColorPreview)
				PreviewStroke.Color = Color3.fromRGB(255, 255, 255)
				PreviewStroke.Transparency = 0.8
				PreviewStroke.Thickness = 1

				local Content = Instance.new('Frame', PickerContainer)
				Content.Position = UDim2.fromOffset(0, 35)
				Content.Size = UDim2.new(1, 0, 0, 140)
				Content.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
				Content.BorderSizePixel = 0

				local Canvas = Instance.new('ImageLabel', Content)
				Canvas.Size = UDim2.fromOffset(170, 110)
				Canvas.Position = UDim2.fromOffset(12, 10)
				Canvas.Image = getcustomasset("Haze/assets/lib/saturation.png")
				Canvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				Canvas.BorderSizePixel = 0
				Instance.new("UICorner", Canvas).CornerRadius = UDim.new(0, 4)

				local Cursor = Instance.new('Frame', Canvas)
				Cursor.Size = UDim2.fromOffset(8, 8)
				Cursor.AnchorPoint = Vector2.new(0.5, 0.5)
				Cursor.Position = UDim2.fromScale(s, 1-v)
				Cursor.BackgroundColor3 = Color3.new(1, 1, 1)
				local CursorStroke = Instance.new("UIStroke", Cursor)
				CursorStroke.Thickness = 2
				CursorStroke.Color = Color3.new(0,0,0)
				Instance.new("UICorner", Cursor).CornerRadius = UDim.new(1, 0)

				local HueBar = Instance.new('ImageButton', Content)
				HueBar.Size = UDim2.fromOffset(14, 110)
				HueBar.Position = UDim2.fromOffset(190, 10)
				HueBar.Image = getcustomasset("Haze/assets/lib/huebar.png")
				HueBar.BorderSizePixel = 0
				Instance.new("UICorner", HueBar).CornerRadius = UDim.new(0, 4)

				table.insert(guiLibrary.Collection, guiLibrary.Pallete.Changed.Event:Connect(function()
					PickerSide.BackgroundColor3 = guiLibrary.Pallete.changeColor(guiLibrary.Pallete.Main, 0.7)
				end))

				local PickerObject = {
					inst = PickerContainer,
					color = Color3.fromHSV(h, s, v)
				}

				local function updpickers()
					local color = Color3.fromHSV(h, s, v)
					PickerObject.color = color
					Canvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
					ColorPreview.BackgroundColor3 = color
					guiLibrary.Config[Table.Name].colorpickers[Tab.Name].color = {color.R, color.G, color.B}

					if Tab.Function then task.spawn(pcall, function() Tab.Function(color) end) end
					guiLibrary.saveCFG(guiLibrary.CfgName)
				end

				local open = false
				MainButton.MouseButton1Click:Connect(function()
					open = not open
					local info = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
					tweenService:Create(PickerContainer, info, {
						Size = open and UDim2.new(1, 0, 0, 175) or UDim2.new(1, 0, 0, 35)
					}):Play()
					tweenService:Create(PickerSide, info, {
						Size = open and UDim2.new(0, 3, 0, 175) or UDim2.new(0, 3, 0, 35)
					}):Play()
				end)

				local function inputLogic(frame, callback)
					frame.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							local conn
							conn = userInputService.InputChanged:Connect(function(m)
								if m.UserInputType == Enum.UserInputType.MouseMovement then callback(m) end
							end)
							userInputService.InputEnded:Connect(function(e)
								if e.UserInputType == Enum.UserInputType.MouseButton1 then conn:Disconnect() end
							end)
							callback(input)
						end
					end)
				end

				inputLogic(Canvas, function(input)
					s = math.clamp((input.Position.X - Canvas.AbsolutePosition.X) / Canvas.AbsoluteSize.X, 0, 1)
					v = 1 - math.clamp((input.Position.Y - Canvas.AbsolutePosition.Y) / Canvas.AbsoluteSize.Y, 0, 1)
					Cursor.Position = UDim2.fromScale(s, 1-v)
					updpickers()
				end)

				inputLogic(HueBar, function(input)
					h = 1 - math.clamp((input.Position.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
					updpickers()
				end)

				return PickerObject
			end

			HideModule = ModuleReturn.toggles.new({
				['Name'] = 'HideModule',
				['Function'] = function(called)
					for i,v in aids do
						if v.Name == Table.Name then
							v.Visible = not called
						end
					end
				end,
			})

			local Hovering = false
			table.insert(guiLibrary.Collection, guiLibrary.Pallete.Changed.Event:Connect(function()
				if ModuleReturn.enabled then
					ModuleLabel.TextColor3 = guiLibrary.Pallete.Main
				end

				ModuleSide.BackgroundColor3 = guiLibrary.Pallete.changeColor(guiLibrary.Pallete.Main, 0.7)
			end))
			table.insert(guiLibrary.Collection, ModuleFrame.MouseEnter:Connect(function()
				Hovering = true
			end))
			table.insert(guiLibrary.Collection, ModuleFrame.MouseLeave:Connect(function()
				Hovering = false
			end))
			table.insert(guiLibrary.Collection, ModuleLabel.MouseButton1Down:Connect(function()
				ModuleReturn:toggle(false)
			end))
			table.insert(guiLibrary.Collection, ModuleDots.MouseButton1Down:Connect(function()
				Dropdown.Visible = not Dropdown.Visible
			end))
			table.insert(guiLibrary.Collection, ModuleLabel.MouseButton2Down:Connect(function()
				Dropdown.Visible = not Dropdown.Visible
			end))
			local UserInputService = game:GetService("UserInputService")
			if UserInputService.KeyboardEnabled then
				local BindLabel = Instance.new('TextButton')
				BindLabel.Parent = ModuleFrame
				BindLabel.AnchorPoint = Vector2.new(1, 0.5)
				BindLabel.Position = UDim2.new(0.95, -28, 0.5, 0)
				BindLabel.Size = UDim2.fromOffset(20, 20)
				BindLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
				BindLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
				BindLabel.TextSize = 13
				BindLabel.Font = Enum.Font.BuilderSans
				BindLabel.AutoButtonColor = false
				BindLabel.BorderSizePixel = 0
				BindLabel.Text = ""

				local BindCorner = Instance.new("UICorner", BindLabel)
				BindCorner.CornerRadius = UDim.new(0, 4)

				local BindStroke = Instance.new("UIStroke")
				BindStroke.Thickness = 1
				BindStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				BindStroke.Transparency = 0.3
				BindStroke.Parent = BindLabel

				local function updKeyBinds()
					local currentBind = guiLibrary.Config[Table.Name].keybind
					if currentBind ~= 'Unknown' then
						BindLabel.Text = currentBind:sub(1,1):upper()
						BindLabel.Visible = true
						BindStroke.Color = guiLibrary.Pallete.Main
					else
						BindLabel.Text = ""
						BindLabel.Visible = false
						BindStroke.Color = Color3.fromRGB(60, 60, 60)
					end
				end

				table.insert(guiLibrary.Collection, guiLibrary.Pallete.Changed.Event:Connect(function()
					if guiLibrary.Config[Table.Name].keybind ~= 'Unknown' then
						BindStroke.Color = guiLibrary.Pallete.Main
					end
				end))

				local binding = false

				table.insert(guiLibrary.Collection, ModuleFrame.MouseEnter:Connect(function()
					BindLabel.Visible = true
				end))

				table.insert(guiLibrary.Collection, ModuleFrame.MouseLeave:Connect(function()
					if not binding and guiLibrary.Config[Table.Name].keybind == 'Unknown' then
						BindLabel.Visible = false
					end
				end))

				table.insert(guiLibrary.Collection, BindLabel.MouseButton1Down:Connect(function()
					binding = true
					BindLabel.Text = "..."
					ModuleLabel.Text = '<font color="rgb(150,150,150)">PRESS A KEY</font>'
				end))

				table.insert(guiLibrary.Collection, userInputService.InputBegan:Connect(function(Input, GPE)
					if GPE then return end
					
					if binding then
						binding = false
						local key = Input.KeyCode.Name
						
						if key == "Escape" or key == guiLibrary.Config[Table.Name].keybind then
							guiLibrary.Config[Table.Name].keybind = 'Unknown'
						else
							guiLibrary.Config[Table.Name].keybind = key
						end
						
						updKeyBinds()
						ModuleLabel.Text = Table.Name
						
						guiLibrary.saveCFG(guiLibrary.CfgName)
						return
					end

					if not userInputService:GetFocusedTextBox() and Input.KeyCode.Name == guiLibrary.Config[Table.Name].keybind then
						if guiLibrary.Config[Table.Name].keybind ~= 'Unknown' then
							ModuleReturn:toggle(false)
						end
					end
				end))

				updKeyBinds()
			end
			if guiLibrary.Config[Table.Name].enabled then
				ModuleReturn:toggle(true)
			end

			ModuleReturn.inst = ModuleFrame

			return ModuleReturn
		end,
	}

	return self.Windows[Name]
end

guiLibrary.loadCFG(guiLibrary.CfgName)

guiLibrary:createWindow('Combat')
guiLibrary:createWindow('Movement')
guiLibrary:createWindow('Utility')
guiLibrary:createWindow('Visuals')
guiLibrary:createWindow('Exploit')
guiLibrary:createWindow('Settings')

local function getColorFixed(numb)
	return math.round(numb * 255)
end
--66, 245, 108
local RainbowLoop
local ColorMode = "Custom Color"
Interface = guiLibrary.Windows.Settings:createModule({
    ['Name'] = 'Interface',
    ['Function'] = function(called)
        if not called then
            if RainbowLoop then task.cancel(RainbowLoop) RainbowLoop = nil end
            guiLibrary.Pallete.Main = Color3.fromRGB(66, 245, 108)
            guiLibrary.Pallete.Changed:Fire()
        end
    end,
})
InterfaceColorPicker = Interface.colorpickers.new({
    ['Name'] = 'Interface Color',
    ['Default'] = Color3.fromRGB(66, 245, 108),
    ['Function'] = function(color)
        if ColorMode == "Custom Color" then
            guiLibrary.Pallete.Main = color
            guiLibrary.Pallete.Changed:Fire()
        end
    end
})
Interface.selectors.new({
    ["Name"] = "Color Mode",
    ["Default"] = "Custom Color",
    ["Selections"] = {"Custom Color", "Rainbow"},
    ["Function"] = function(val)
        ColorMode = val
        
        local isCustomColor = (val == "Custom Color")
        local isRainbow = (val == "Rainbow")

        InterfaceColorPicker.inst.Visible = isCustomColor

        if RainbowLoop then task.cancel(RainbowLoop) RainbowLoop = nil end

        if isRainbow then
            RainbowLoop = task.spawn(function()
                while true do
                    local hue = (tick() * 0.5 % 1)
                    guiLibrary.Pallete.Main = Color3.fromHSV(hue, 0.7, 1)
                    guiLibrary.Pallete.Changed:Fire()
                    task.wait()
                end
            end)
        else
            guiLibrary.Pallete.Main = InterfaceColorPicker.color
            guiLibrary.Pallete.Changed:Fire()
        end
    end
})

Arraylist = guiLibrary.Windows.Settings:createModule({
	['Name'] = 'Arraylist',
	['Function'] = function(called)
		arrayList.Visible = called
	end,
})
Arraylist.sliders.new({
    ['Name'] = 'Position',
    ['Minimum'] = 0,
    ['Maximum'] = 500,
    ['Default'] = 0,
    ['Function'] = function(val)
        arrayList.Position = UDim2.new(arrayList.Position.X.Scale, arrayList.Position.X.Offset, 0, val)
    end,
})
Arraylist.textboxes.new({
    ['Name'] = 'Custom Text',
    ['Default'] = '',
    ['Function'] = function(val)
        subLogoText.Text = val
        logoFrame.Size = (val ~= "") and UDim2.new(1, 0, 0, 75) or UDim2.new(1, 0, 0, 60)
    end,
})
ArrayBackground = Arraylist.sliders.new({
	['Name'] = 'Background',
	['Minimum'] = 0,
	['Maximum'] = 100,
	['Default'] = 50,
	['Function'] = function(val)
		for i,v in aids do
			v.BackgroundTransparency = (val / 100)
		end
	end,
})

modules.Notifications:Notify("HAZE", "Loaded! Press Right Shift to open the UI.", 8)
modules.Notifications:Notify("HAZE", "Remember to join our discord server to support the development of Haze!", 10, Color3.fromRGB(0, 136, 255))

local DiscordModule
DiscordModule = guiLibrary.Windows.Settings:createModule({
	["Name"] = "Discord",
	["Function"] = function(state)
		if not state then return end

		modules.Discord:Join("https://discord.gg/W92SXVmB5X")
		modules.Discord:Copy("https://discord.gg/W92SXVmB5X")

		task.defer(function()
			if DiscordModule.enabled then
				DiscordModule:toggle(true)
			end
		end)
	end
})

ESPModule = guiLibrary.Windows.Visuals:createModule({
    ["Name"] = "ESP",
    ["Function"] = function(state)
        modules.ESPController.Enabled = state
    end
})
ESPModule.toggles.new({
    ["Name"] = "Gradient",
    ["Function"] = function(state)
        modules.ESPController.UseGradient = state
    end
})
ESPModule.selectors.new({
    ["Name"] = "Themes",
    ["Default"] = "Haze",
    ["Selections"] = {"Haze", "Aqua", "Nova"},
    ["Function"] = function(val)
        if val and val ~= "" then
            modules.ESPController.Theme = val
        else
            modules.ESPController.Theme = "Haze"
        end
    end
})
ESPModule.toggles.new({
    ["Name"] = "Team Check",
    ["Function"] = function(state)
        modules.ESPController.TeamCheck = state
    end
})
ESPModule.toggles.new({
    ["Name"] = "Ignore Team",
    ["Function"] = function(state)
        modules.ESPController.NoTeam = state
    end
})

local RevertReverbs = SoundService.AmbientReverb
guiLibrary.Windows.Visuals:createModule({
    ["Name"] = "Reverbs",
    ["Function"] = function(state)
        if state then
            SoundService.AmbientReverb = Enum.ReverbType.SewerPipe
        else
            SoundService.AmbientReverb = RevertReverbs
        end
    end
})

local Capevar = false
local CapePNG = "Haze/assets/capes/Haze.png"
local CapeColor = Color3.fromRGB(255,255,255)

local Cape, Motor

local function torso(char)
    return char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("HumanoidRootPart")
end

local function clear()
    if Cape then Cape:Destroy() Cape = nil end
    if Motor then Motor:Destroy() Motor = nil end
end

local function build(char)
    clear()
    if not char.Parent then char.AncestryChanged:Wait() end
    
    local t = torso(char)
    if not t then 
        task.wait(0.5) 
        t = torso(char) 
    end
    if not t then return end

    Cape = Instance.new("Part")
    Cape.Size = Vector3.new(2,4,0.1)
    Cape.Color = CapeColor
    Cape.Material = Enum.Material.SmoothPlastic
    Cape.Massless = true
    Cape.CanCollide = false
    Cape.CastShadow = false
    Cape.Parent = char

    local gui = Instance.new("SurfaceGui", Cape)
    gui.Adornee = Cape
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud

    local img = Instance.new("ImageLabel", gui)
    img.Size = UDim2.fromScale(1,1)
    img.BackgroundTransparency = 1
    img.Image = CapePNG:find("rbxasset") and CapePNG or getcustomasset(CapePNG)

    Motor = Instance.new("Motor6D", Cape)
    Motor.Part0 = Cape
    Motor.Part1 = t
    Motor.MaxVelocity = 0.08
    Motor.C0 = CFrame.new(0,2,0) * CFrame.Angles(0, math.rad(-90), 0)
    Motor.C1 = CFrame.new(0, t.Size.Y/2, 0.45) * CFrame.Angles(0, math.rad(90), 0)

    task.spawn(function()
		while Capevar and Cape and Motor and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 do
			local root = char:FindFirstChild("HumanoidRootPart")
			if root and Cape and Motor then
				local v = math.min(root.Velocity.Magnitude, 90)
				Motor.DesiredAngle = math.rad(6 + v) + (v > 1 and math.abs(math.cos(tick()*5))/3 or 0)
				
				local cam = workspace.CurrentCamera
				local distance = (cam.CFrame.Position - t.Position).Magnitude
				
				if distance < 2 or (cam.Focus.Position - cam.CFrame.Position).Magnitude < 0.7 then 
					Cape.Transparency = 1
					gui.Enabled = false
				else
					Cape.Transparency = 0
					gui.Enabled = true
				end
			end
			task.wait()
		end
	end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if Capevar then
        build(char)
    end
end)

guiLibrary.Windows.Visuals:createModule({
    ["Name"] = "Cape",
    ["Function"] = function(v)
        Capevar = v
        if v then
            if LocalPlayer.Character then
                build(LocalPlayer.Character)
            end
        else
            clear()
        end
    end
}).selectors.new({
    ["Name"] = "Capes",
    ["Default"] = "Haze",
    ["Selections"] = {"Haze", "Cat", "Waifu", "Troll", "Wave"},
    ["Function"] = function(v)
        local path = "Haze/assets/capes/"..v..".png"
        if isfile(path) then
            CapePNG = path
            if Capevar and LocalPlayer.Character then
                build(LocalPlayer.Character)
            end
        end
    end
})

guiLibrary.Windows.Visuals:createModule({
    ["Name"] = "Vibe",
    ["Function"] = function(state)
        if state then
            lighting.TimeOfDay = "00:00:00"
            lighting.Technology = Enum.Technology.Future

            if not lighting:FindFirstChild("VibeSky") then
                local sky = Instance.new("Sky")
                sky.Name = "VibeSky"
                sky.SkyboxBk = ""; sky.SkyboxDn = ""; sky.SkyboxFt = ""
                sky.SkyboxLf = ""; sky.SkyboxRt = ""; sky.SkyboxUp = ""
                sky.Parent = lighting

                local atm = Instance.new("Atmosphere")
                atm.Density = 0.3
                atm.Offset = 0
                atm.Color = Color3.fromRGB(255,182,193)
                atm.Decay = Color3.fromRGB(50,0,80)
                atm.Glare = 0.5
                atm.Haze = 0.1
                atm.Parent = lighting
            end

            if not Workspace:FindFirstChild("Snowing") then
                local p = Instance.new("Part")
                p.Name = "Snowing"
                p.Anchored = true
                p.CanCollide = false
                p.Size = Vector3.new(500,1,500)
                p.Position = Vector3.new(0,150,0)
                p.Transparency = 1
                p.Parent = Workspace

                local e = Instance.new("ParticleEmitter")
                e.Texture = "rbxassetid://258128463"
                e.Rate = 200
                e.Lifetime = NumberRange.new(8,15)
                e.Speed = NumberRange.new(5,10)
                e.SpreadAngle = Vector2.new(360,0)
                e.Size = NumberSequence.new(2)
                e.VelocityInheritance = 0
                e.Acceleration = Vector3.new(0,-50,0)
                e.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,182,193)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(173,216,230)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(50,0,80))
                }
                e.LightEmission = 0.9
                e.Parent = p
            end
        else
            lighting.TimeOfDay = "14:00:00"
            lighting.Technology = Enum.Technology.Compatibility

            if Workspace:FindFirstChild("Snowing") then Workspace.Snowing:Destroy() end
            if lighting:FindFirstChild("VibeSky") then lighting.VibeSky:Destroy() end
            for _, a in pairs(lighting:GetChildren()) do if a:IsA("Atmosphere") then a:Destroy() end end
        end
    end
})

local FOVVar = false
local FOVValue = 90
local FOVConnection

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    WCam = workspace.CurrentCamera
end)

local function ManageFOV()
    if FOVConnection then FOVConnection:Disconnect() end
    
    if FOVVar then
        FOVConnection = runService.RenderStepped:Connect(function()
            WCam.FieldOfView = FOVValue
        end)
    else
        WCam.FieldOfView = 70
    end
end

guiLibrary.Windows.Visuals:createModule({
    ["Name"] = "FOV",
    ["Function"] = function(state)
        FOVVar = state
        ManageFOV()
    end,
    ["ExtraText"] = function()
        return tostring(FOVValue)
    end
}).sliders.new({
    ["Name"] = "FOV",
    ["Minimum"] = 90,
    ["Maximum"] = 120,
    ["Default"] = 120,
    ["Function"] = function(value)
        FOVValue = value
    end
})

shared.guiLibrary = guiLibrary

return guiLibrary