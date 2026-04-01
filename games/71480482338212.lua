--[[ BedFight ]]
local guiLibrary = loadfile("Haze/guis/HazeLibrary.lua")()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local uiParent = gethui and gethui() or game:GetService("CoreGui")

serclipboard('https://discord.gg/ERAgrx7gC')
print('aided copied to clipboard')

for _, uiName in {"HazeTargetInfo", "HazeSessionInfo"} do
    local oldUI = uiParent:FindFirstChild(uiName)
    if oldUI then 
        oldUI:Destroy() 
    end
end

local function getRandomUd()
    local length = math.random(10, 20)
    local name = ""
    for i = 1, length do
        name = name .. string.char(math.random(97, 122))
    end
    return name
end

--[[ Libraries ]]
local LocalLibrary = "Haze/libraries"
local modules = {
    Entity = loadfile(LocalLibrary .. "/modules/Entity.lua")(),
    SprintController = loadfile(LocalLibrary .. "/bedfight/SprintController.lua")(),
    ScaffoldController = loadfile(LocalLibrary .. "/bedfight/ScaffoldController.lua")(),
    PartyController = loadfile(LocalLibrary .. "/bedfight/PartyController.lua")(),
    EmotesController = loadfile(LocalLibrary .. "/bedfight/EmotesController.lua")(),
    StaffList = loadfile(LocalLibrary .. "/bedfight/StaffList.lua")(),
    Notifications = loadfile(LocalLibrary.."/Notifications.lua")(),
    ErrorHandler = loadfile(LocalLibrary.."/modules/ErrorHandler.lua")()
}

local remotes = {
    SwordHitRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ItemsRemotes"):WaitForChild("SwordHit"),
    MineBlockRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ItemsRemotes"):WaitForChild("MineBlock"),
    EquipRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ItemsRemotes"):WaitForChild("EquipTool"),
    EquipCape = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EquipCape"),
    TakeItemFromChest = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TakeItemFromChest"),
    PlaceBlock = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ItemsRemotes"):WaitForChild("PlaceBlock"),
    SetSettings = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ApplySettings")
}

--[[ Speed ]]
local SpeedVar = false
local SpeedValue = 28

RunService.Heartbeat:Connect(function()
    if not SpeedVar then return end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if root and hum then
        local moveDir = hum.MoveDirection
        
        if moveDir.Magnitude > 0 then
            local vel = moveDir * SpeedValue
            root.AssemblyLinearVelocity = Vector3.new(vel.X, root.AssemblyLinearVelocity.Y, vel.Z)
        else
            root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
        end
    end
end)

guiLibrary.Windows.Movement:createModule({
    ["Name"] = "Speed",
    ["Function"] = function(state)
        SpeedVar = state
    end,
    ["ExtraText"] = function()
        return tostring(SpeedValue)
    end
}).sliders.new({
    ["Name"] = "Speed",
    ["Minimum"] = 16,
    ["Maximum"] = 28,
    ["Default"] = 28,
    ["Function"] = function(val)
        SpeedValue = val
    end
})

--[[ Fly ]]
local flyVertical = false
local flyGlide = false
local flyConnection
local startTick = 0
local FlyModule = guiLibrary.Windows.Movement:createModule({
    ["Name"] = "Fly",
    ["Function"] = function(state)
        if state then
            startTick = tick()
            if flyConnection then flyConnection:Disconnect() end
            flyConnection = RunService.Heartbeat:Connect(function(deltaTime)
                local character = LocalPlayer.Character
                if not character then return end
                local root = character:FindFirstChild("HumanoidRootPart")
                if not root then return end
                local currentVelocity = root.AssemblyLinearVelocity
                local finalY = 0
                if flyGlide then
                    local flyVal = 1
                    if flyVertical then
                        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                            flyVal = 50
                        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                            flyVal = -50
                        end
                    end
                    finalY = (tick() - startTick) < 1 and flyVal or -4.06
                else
                    finalY = 0.8 + deltaTime
                    if flyVertical then
                        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                            finalY = finalY + 44
                        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                            finalY = finalY - 44
                        end
                    end
                end
                root.AssemblyLinearVelocity = Vector3.new(
                    currentVelocity.X,
                    finalY,
                    currentVelocity.Z
                )
            end)
        else
            if flyConnection then
                flyConnection:Disconnect()
                flyConnection = nil
            end
        end
    end
})
FlyModule.toggles.new({
    ["Name"] = "Vertical",
    ["Function"] = function(state)
        flyVertical = state
    end
})
FlyModule.toggles.new({
    ["Name"] = "Glide",
    ["Function"] = function(state)
        flyGlide = state
    end
})

--[[local function getRandomFolder()
    for i = 1, 20 do
        local Folder = workspace:GetChildren()[i]

        if Folder and typeof(Folder) == 'Instance' and Folder:IsA('Folder') then
            return Folder
        end
    end

    return Instance.new('Folder', workspace)
end]]

--[[ Killaura Rework ]]
local Swords = {"Emerald Sword", "Diamond Sword", "Iron Sword", "Stone Sword", "Wooden Sword"}
local KilLAuraVar = false
local FaceTargetVar = false
local SwingSoundVar = false
local SelectedDelay = "Respect Delay"
local SelectedAnim = "Vanilla3"
local SelectedMode = "Multi"
local SelectedPriority = "Health"
local oldCO = nil
local IsMining = false

local SwingAnimation = Instance.new("Animation")
SwingAnimation.AnimationId = "rbxassetid://123800159244236"
local SwingFPAnim = Instance.new('Animation')
SwingFPAnim.AnimationId = 'rbxassetid://80138703077151'
local SwingSound = Instance.new("Sound")
SwingSound.SoundId = "rbxassetid://104766549106531"
SwingSound.Volume = 1

local BlockAnimations = {
    ["Exotic"] = {
        {CFrame = CFrame.new(0.3, -1, -1) * CFrame.Angles(-math.rad(190), math.rad(55), -math.rad(90)), Timer = 0.2},
        {CFrame = CFrame.new(0.3, -1, -0.1) * CFrame.Angles(-math.rad(190), math.rad(110), -math.rad(90)), Timer = 0.2},
    },
    ["SlowExotic"] = {
        {CFrame = CFrame.new(0.6, -1.2, -1.2) * CFrame.Angles(-math.rad(200), math.rad(45), -math.rad(90)), Timer = 0.4},
        {CFrame = CFrame.new(0.6, -1.2, -0.2) * CFrame.Angles(-math.rad(200), math.rad(130), -math.rad(90)), Timer = 0.4},
    },
    ["Blocker"] = {
        {CFrame = CFrame.new(0.69, -0.7, -0.5) * CFrame.Angles(math.rad(295), math.rad(55), math.rad(290)), Timer = 0.05},
        {CFrame = CFrame.new(0.69, -0.71, -0.6) * CFrame.Angles(math.rad(200), math.rad(60), math.rad(1)), Timer = 0.05}
    }
}

local function getClosestPlayer()
    local Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") or not modules.Entity.isAlive(Character) then 
        return nil 
    end
    
    local myRoot = Character.HumanoidRootPart
    local closestPlayer = nil
    local shortestDistance = 20
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and modules.Entity.isAlive(player.Character) then
            local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if pRoot then
                local isSpectator = LocalPlayer.Team and LocalPlayer.Team.Name == "Spectators"
                local isSameTeam = LocalPlayer.Team == player.Team
                if isSpectator or not isSameTeam then
                    local distance = (myRoot.Position - pRoot.Position).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function getAuraTargets()
    local Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return {} end

    local targets = {}
    local myPos = Character.HumanoidRootPart.Position
    local maxRange = 20

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and modules.Entity.isAlive(player.Character) then
            local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local pHum = player.Character:FindFirstChildOfClass("Humanoid")
            
            if pRoot and pHum then
                local dist = (myPos - pRoot.Position).Magnitude
                if dist <= maxRange then
                    local isSpectator = LocalPlayer.Team and LocalPlayer.Team.Name == "Spectators"
                    local isSameTeam = LocalPlayer.Team == player.Team
                    
                    if isSpectator or not isSameTeam then
                        table.insert(targets, {player = player, dist = dist, health = pHum.Health})
                    end
                end
            end
        end
    end
    local priority = SelectedPriority
    table.sort(targets, function(a, b)
        if priority == "Health" then
            return a.health < b.health
        else
            return a.dist < b.dist
        end
    end)

    return targets
end

local function getBestSword()
    local Character = LocalPlayer.Character
    local Backpack = LocalPlayer:FindFirstChild("Backpack")
    if not Character then return nil end
    for _, swordName in ipairs(Swords) do
        local found = Character:FindFirstChild(swordName) or (Backpack and Backpack:FindFirstChild(swordName))
        if found then
            return {itemType = swordName, tool = found}
        end
    end
    return nil
end

local function getViewmodelSword()
    local viewmodel = workspace.CurrentCamera:FindFirstChild("ViewModel")
    local swordData = getBestSword()
    if viewmodel and swordData and viewmodel:FindFirstChild(swordData.itemType) then
        return viewmodel[swordData.itemType]
    end
    return nil
end

local KillAuraModule = guiLibrary.Windows.Combat:createModule({
    ["Name"] = "KillAura",
    ["Function"] = function(state)
        KilLAuraVar = state
        if state then
            task.spawn(function()
                while KilLAuraVar do
                    task.wait()
                    local Nearest = getClosestPlayer()
                    local Viewmodel = getViewmodelSword()
                    local isCustom = (SelectedAnim == "Exotic" or SelectedAnim == "SlowExotic" or SelectedAnim == "Blocker")

                    if isCustom and Nearest and Viewmodel then
                        pcall(function()
                            local motor = Viewmodel:FindFirstChild("ViewModelRootPart") and Viewmodel.ViewModelRootPart:FindFirstChild("RootMotor")
                            if motor then
                                if not oldCO then oldCO = motor.C0 end
                                for _, v in pairs(BlockAnimations[SelectedAnim]) do
                                    TweenService:Create(motor, TweenInfo.new(v.Timer), {
                                        C0 = oldCO * (v.CFrame * CFrame.Angles(-math.rad(90), math.rad(90), 0) + Vector3.new(0, 2, 0))
                                    }):Play()
                                    task.wait(v.Timer)
                                end
                            end
                        end)
                    elseif Viewmodel then
                        pcall(function()
                            local motor = Viewmodel:FindFirstChild("ViewModelRootPart") and Viewmodel.ViewModelRootPart:FindFirstChild("RootMotor")
                            if motor and oldCO then
                                TweenService:Create(motor, TweenInfo.new(0.5), {C0 = oldCO}):Play()
                            end
                        end)
                    end
                end
            end)
            task.spawn(function()
                local multiIndex = 1

                while KilLAuraVar do
                    if not IsMining then
                        local auraTargets = getAuraTargets()
                        local swordData = getBestSword()
                        local Character = LocalPlayer.Character
                        local mode = SelectedMode

                        if #auraTargets > 0 and swordData and Character then
                            local targetData
                            
                            if mode == "Multi" then
                                if multiIndex > #auraTargets then multiIndex = 1 end
                                targetData = auraTargets[multiIndex]
                                multiIndex = multiIndex + 1
                            else
                                targetData = auraTargets[1]
                            end

                            local target = targetData.player

                            if LocalPlayer:GetAttribute("PVP") == true then
                                if FaceTargetVar then
                                    local myRoot = Character.HumanoidRootPart
                                    local targetPos = target.Character.HumanoidRootPart.Position
                                    myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(targetPos.X, myRoot.Position.Y, targetPos.Z))
                                end

                                if SwingSoundVar then
                                    SwingSound.Parent = Character.HumanoidRootPart
                                    SwingSound:Play()
                                end

                                if SelectedAnim:sub(1, 7) == "Vanilla" then
                                    local humanoid = Character:FindFirstChildOfClass("Humanoid")
                                    local viewmodel = workspace.CurrentCamera:FindFirstChild("ViewModel")
                                    if (SelectedAnim == "Vanilla1" or SelectedAnim == "Vanilla3") and viewmodel then
                                        local vmAnimator = viewmodel:FindFirstChildOfClass("Animator") or viewmodel:FindFirstChild("AnimationController")
                                        if vmAnimator then vmAnimator:LoadAnimation(SwingFPAnim):Play() end
                                    end
                                    if (SelectedAnim == "Vanilla2" or SelectedAnim == "Vanilla3") and humanoid then
                                        local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid
                                        animator:LoadAnimation(SwingAnimation):Play()
                                    end
                                end

                                remotes.EquipRemote:FireServer(swordData.itemType)
                                remotes.SwordHitRemote:FireServer(swordData.itemType, target.Character)
                            end
                        else
                            multiIndex = 1
                        end
                    end

                    if SelectedDelay == "No Delay" then
                        RunService.Heartbeat:Wait()
                    else
                        task.wait(0.12)
                    end
                end
            end)
        else
            oldCO = nil
        end
    end
})

KillAuraModule.toggles.new({
    ["Name"] = "FaceTarget",
    ["Function"] = function(state) FaceTargetVar = state end
})
KillAuraModule.toggles.new({
    ["Name"] = "SwingSound",
    ["Function"] = function(state) SwingSoundVar = state end
})
KillAuraModule.selectors.new({
    ["Name"] = "Delay",
    ["Default"] = "Respect Delay",
    ["Selections"] = {"No Delay", "Respect Delay"},
    ["Function"] = function(val) SelectedDelay = val end
})
KillAuraModule.selectors.new({
    ["Name"] = "CustomAnim",
    ["Default"] = "Vanilla3",
    ["Selections"] = {"Vanilla1", "Vanilla2", "Vanilla3", "Exotic", "SlowExotic", "Blocker"},
    ["Function"] = function(val) SelectedAnim = val end
})
KillAuraModule.selectors.new({
    ["Name"] = "Mode",
    ["Default"] = "Multi",
    ["Selections"] = {"Multi", "Single"},
    ["Function"] = function(val) 
        SelectedMode = val 
    end
})
KillAuraModule.selectors.new({
    ["Name"] = "Priority",
    ["Default"] = "Health",
    ["Selections"] = {"Health", "Closer"},
    ["Function"] = function(val) 
        SelectedPriority = val 
    end
})

--[[ Nuker Rework ]]
local NukerVar = false
local lastMine = tick()

local function snapToGrid(pos)
    return Vector3.new(math.floor(pos.X + 0.5), math.floor(pos.Y + 0.5), math.floor(pos.Z + 0.5))
end

local function getNearBed(range)
    local bedsContainer = workspace:FindFirstChild("BedsContainer")
    local Character = LocalPlayer.Character
    if not bedsContainer or not Character or not Character:FindFirstChild("HumanoidRootPart") then 
        return nil 
    end

    local myPos = Character.HumanoidRootPart.Position
    local closestBed, closestDist = nil, range

    for _, bed in ipairs(bedsContainer:GetChildren()) do
        local hitbox = bed:FindFirstChild("BedHitbox")
        if hitbox then
            local dist = (myPos - hitbox.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestBed = hitbox
            end
        end
    end
    return closestBed
end

local function getPickaxe()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    local found = (char and char:FindFirstChildOfClass("Tool") and char:FindFirstChildOfClass("Tool").Name:lower():find("pickaxe") and char:FindFirstChildOfClass("Tool"))
    if found then return found end

    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item.Name:lower():find("pickaxe") then return item end
        end
    end
    return nil
end

local NukerModule = guiLibrary.Windows.Utility:createModule({
    ["Name"] = "Nuker",
    ["Description"] = "Automatically breaks nearby beds",
    ["Function"] = function(state)
        NukerVar = state
        if state then
            task.spawn(function()
                while NukerVar do
                    task.wait() 
                    
                    local bedHitbox = getNearBed(22)
                    local pickaxe = getPickaxe()
                    local swordData = getBestSword()

                    if bedHitbox and pickaxe then
                        if (tick() - lastMine) < 0.15 then continue end
                        lastMine = tick()

                        IsMining = true
                        
                        pcall(function()
                            local blockPos = snapToGrid(bedHitbox.Position)
                            
                            remotes.EquipRemote:FireServer(pickaxe.Name)
                            task.wait(0.05)

                            remotes.MineBlockRemote:FireServer(
                                pickaxe.Name,
                                bedHitbox.Parent,
                                blockPos,
                                blockPos + Vector3.new(0, 2, 0),
                                Vector3.new(0, -1, 0)
                            )
                            
                            if swordData then
                                task.wait(0.02)
                                remotes.EquipRemote:FireServer(swordData.itemType)
                            end
                        end)

                        IsMining = false
                    end
                end
            end)
        end
    end
})

--[[ Game Capes ]]
local CapesData = require(ReplicatedStorage.Modules.DataModules.CapesData)
local capeList = {}
local gameCapeVar = false
local currentCape = "Matrix"

for name, _ in pairs(CapesData) do
    if name ~= "Default" then
        table.insert(capeList, name)
    end
end
table.sort(capeList)

local function updCape(name)
    local CapeValue = LocalPlayer:FindFirstChild("Cape")
    if not CapeValue then
        CapeValue = Instance.new("StringValue")
        CapeValue.Name = "Cape"
        CapeValue.Parent = LocalPlayer
    end
    CapeValue.Value = name
end

guiLibrary.Windows.Visuals:createModule({
    ["Name"] = "GameCapes",
    ["Description"] = "not FE anymore :sob:",
    ["Function"] = function(callback)
        gameCapeVar = callback
        if callback then
            updCape(currentCape)
        else
            local CapeValue = LocalPlayer:FindFirstChild("Cape")
            if CapeValue then
                CapeValue.Value = ""
            end
        end
    end
}).selectors.new({
    ["Name"] = "Capes",
    ["Default"] = "Matrix",
    ["Selections"] = capeList,
    ["Function"] = function(selection)
        currentCape = selection
        if gameCapeVar then
            updCape(selection)
        end
    end
})

--[[ ChestStealer ]]
local TeamColors = {"Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Pink", "Brown"}
local CSVar = false
guiLibrary.Windows.Utility:createModule({
    ["Name"] = "Chest Stealer",
    ["Function"] = function(state)
        CSVar = state
        if state then
            task.spawn(function()
                while CSVar do
                    for _, color in ipairs(TeamColors) do
                        for num = 1, 20 do
                            if not CSVar then break end
                            remotes.TakeItemFromChest:FireServer(color, num, "1")
                            task.wait(.1)
                        end
                        if not CSVar then break end
                    end
                end
            end)
        end
    end
})

--[[ Velocity ]]
local VelocityUtils = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("VelocityUtils"))
local VelocityVar = false
local originalCreate
guiLibrary.Windows.Utility:createModule({
    ["Name"] = "Velocity",
    ["Description"] = "Remove knockback",
    ["Function"] = function(state)
        VelocityVar = state
        originalCreate = hookfunction(VelocityUtils.Create, function(...)
            if VelocityVar then
                return nil
            end
            return originalCreate(...)
        end)
    end
})

--[[ AutoSprint ]]
local SprintModule = guiLibrary.Windows.Movement:createModule({
    ["Name"] = "AutoSprint",
    ["Function"] = function(state)
        modules.SprintController:SetState(state)
    end
})

--[[ Scaffold ]]
local function hasWool()
    for i, v in LocalPlayer.Backpack:GetChildren() do
        if v.Name:lower():find('wool') or v.Name:lower():find('fake') then
            return true
        end
    end

    return false
end

local scaffTowerSpeed = 50
ScaffoldModule = guiLibrary.Windows.Utility:createModule({
    ["Name"] = "Scaffold",
    ["Function"] = function(state)
        modules.ScaffoldController:SetState(state)
    end
})
ScaffoldTower = ScaffoldModule.toggles.new({
    ['Name'] = 'Tower',
    ['Function'] = function(state)
        if state then
            RunService:BindToRenderStep('ScaffoldTowerStuff', math.huge, function()
                if not modules.Entity.isAlive(LocalPlayer.Character) then
                    return
                end



                if hasWool() and UserInputService:IsKeyDown(Enum.KeyCode.Space) and ScaffoldModule.enabled then
                    LocalPlayer.Character.PrimaryPart.AssemblyLinearVelocity = Vector3.new(LocalPlayer.Character.PrimaryPart.AssemblyLinearVelocity.X, scaffTowerSpeed, LocalPlayer.Character.PrimaryPart.AssemblyLinearVelocity.Z)
                end
            end)
        else
            RunService:UnbindFromRenderStep('ScaffoldTowerStuff')
        end
    end
})
ScaffoldTowerSpeed = ScaffoldModule.sliders.new({
    ["Name"] = "Tower Speed",
    ["Minimum"] = 1,
    ["Maximum"] = 50,
    ["Default"] = 50,
    ["Function"] = function(value)
        scaffTowerSpeed = value
    end
})

--[[ Spam Invites ]]
local InviteSpamVar = false
guiLibrary.Windows.Utility:createModule({
    ["Name"] = "Spam Invites",
    ["Description"] = "Invites everyone in your party",
    ["Function"] = function(state)
        InviteSpam = state
        task.spawn(function()
            while InviteSpam do
                modules.PartyController:InviteAll()
                task.wait(.1)
            end
        end)
    end
})

--[[ Kick Spam ]]
local KickExpVar = false
guiLibrary.Windows.Utility:createModule({
    ["Name"] = "KickExploit",
    ["Description"] = "Spam Kick everyone for party",
    ["Function"] = function(state)
        KickExpVar = state
        task.spawn(function()
            while KickExpVar do
                modules.PartyController:KickAll()
                task.wait(.1)
            end
        end)
    end
})

--[[ Emote Exploit ]]
local currentEmote
local EmoteEXPVar = false
local EmoteModule
EmoteModule = guiLibrary.Windows.Utility:createModule({
    ["Name"] = "EmoteExploit",
    ["Description"] = "Remake bedfight emotes in our ways",
    ["Function"] = function(state)
        EmoteEXPVar = state
        if not state then
            modules.EmotesController:StopAll()
            return
        end

        if currentEmote then
            modules.EmotesController:StopAll()
            modules.EmotesController:Play(currentEmote)
        end

        if currentEmote == "Makeup" then
            task.spawn(function()
                task.wait(5)
                if EmoteModule.enabled then
                    EmoteModule:toggle(true)
                end
            end)
        end
    end
})

local EmoteList = EmoteModule.selectors.new({
    ["Name"] = "Emotes",
    ["Default"] = "Crystal",
    ["Selections"] = {"Crystal", "Chair", "Make up"},
    ["Function"] = function(value)
        if value == "Crystal" then
            currentEmote = "CrystalIdle"
        elseif value == "Chair" then
            currentEmote = "Chair"
        elseif value == "Make up" then
            currentEmote = "Makeup"
        end

        if EmoteEXPVar then
            modules.EmotesController:StopAll()
            modules.EmotesController:Play(currentEmote)

            if currentEmote == "Makeup" then
                task.spawn(function()
                    task.wait(3)
                    if EmoteModule.enabled then
                        EmoteModule:toggle(true)
                    end
                end)
            end
        end
    end
})

--[[ StaffDetector ]]
local connection
local currentMethod = "Notify"
local staffList = {}
local ServerHopping = false

local function staffdetectHandle(playerName)
    if currentMethod == "Notify" then
        modules.Notifications:Notify("Staff Detected", playerName.." is in your server!", 10, Color3.fromRGB(255,0,0))
    elseif currentMethod == "ServerHop" and not ServerHopping then
        ServerHopping = true
        modules.Notifications:Notify("Staff Detected", playerName.." detected! Changing server...", 5, Color3.fromRGB(255,165,0))

        task.spawn(function()
            task.wait(1)
            local success, response = pcall(function() return game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100") end)

            if success then
                local data = HttpService:JSONDecode(response)
                
                for _,server in ipairs(data.data) do
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId,server.id,Players.LocalPlayer)
                        return
                    end
                end
                
                modules.Notifications:Notify("Staff Detected","No server found!",5,Color3.fromRGB(255,0,0))
            else
                modules.Notifications:Notify("Staff Detected","ServerHop failed, could not fetch servers",5,Color3.fromRGB(255,0,0))
            end

            ServerHopping = false    
        end)
    end
end

local function checkPlayer(player)
    if player and table.find(staffList,string.lower(player.Name)) then staffdetectHandle(player.Name) end
end

StaffDetectorModule = guiLibrary.Windows.Combat:createModule({
    ["Name"] = "StaffDetector",
    ["Function"] = function(state)
        if state then
            staffList = {}
            ServerHopping = false

            if type(modules)=="table" and type(modules.StaffList)=="table" then
                for _,name in ipairs(modules.StaffList) do table.insert(staffList,string.lower(name)) end
            else
                modules.Notifications:Notify("Staff Detector","StaffList failed to load",5,Color3.fromRGB(255,0,0))
                return
            end

            for _,player in ipairs(Players:GetPlayers()) do checkPlayer(player) end
            connection = Players.PlayerAdded:Connect(checkPlayer)
        else
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end
})
StaffDetectorModule.selectors.new({
    ["Name"]= "Method",
    ["Default"]= "Notify",
    ["Selections"]= {"Notify","ServerHop"},
    ["Function"]= function(value)
        currentMethod = value

        for _,player in Players:GetPlayers() do
            if table.find(staffList,string.lower(player.Name)) then
                if currentMethod == "Notify" then
                    modules.Notifications:Notify("Staff Detected",player.Name.." is in your server!",10,Color3.fromRGB(255,0,0))
                elseif currentMethod=="ServerHop" and not ServerHopping then
                    ServerHopping = true
                    modules.Notifications:Notify("Staff Detected",player.Name.." detected! Changing server...",5,Color3.fromRGB(255,165,0))

                    task.spawn(function()
                        task.wait(1)
                        local success, response = pcall(function() return game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100") end)

                        if success then
                            local data = HttpService:JSONDecode(response)

                            for _, server in ipairs(data.data) do
                                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                                    TeleportService:TeleportToPlaceInstance(game.PlaceId,server.id,Players.LocalPlayer)
                                    return
                                end
                            end

                            modules.Notifications:Notify("Staff Detector","No server found!",5,Color3.fromRGB(255,0,0))
                        else
                            modules.Notifications:Notify("Staff Detector","ServerHop failed, could not fetch servers",5,Color3.fromRGB(255,0,0))
                        end

                        ServerHopping = false
                    end)
                end
            end
        end
    end
})

--[[ Disabler ]]
guiLibrary.Windows.Exploit:createModule({
    ["Name"] = "Disabler",
    ["Description"] = "mrfridgebeater found this",
    ["Function"] = function(state)
        if state then
            if ReplicatedStorage.Remotes.AdminRemotes:FindFirstChild("RemoteEvent") then
                ReplicatedStorage.Remotes.AdminRemotes.RemoteEvent:Destroy()
            end
        end
    end
})

--[[ FastPickUp ]]
local FastPickUpVar = false
guiLibrary.Windows.Utility:createModule({
    ["Name"] = "FastPickUp",
    ["Function"] = function(state)
        FastPickUpVar = state
        if FastPickUpVar then
            task.spawn(function()
                while FastPickUpVar do 
                    task.wait()
                    local character = LocalPlayer.Character
                    if not character or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 then
                        continue
                    end

                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    if not rootPart then 
                        continue 
                    end

                    local container = workspace:FindFirstChild('DroppedItemsContainer')
                    if container then
                        for _, item in ipairs(container:GetChildren()) do
                            local itemPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                            
                            if itemPart then
                                local dist = (rootPart.Position - itemPart.Position).Magnitude

                                if dist <= 10 then
                                    itemPart.CFrame = rootPart.CFrame - Vector3.new(0, 4, 0)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
})

--[[ AntiVoid ]]
guiLibrary.Windows.Movement:createModule({
    ["Name"] = "AntiVoid",
    ["Function"] = function(state)
        if state then
            RunService:BindToRenderStep('AntiVoid', math.huge, function()
                local character = LocalPlayer.Character
                if not character or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 then
                    return
                end

                local rootPart = character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")
                if not rootPart then
                    return
                end

                if rootPart.CFrame.Y < 0 then
                    rootPart.Velocity = Vector3.new(0, 150, 0)
                end
            end)
        else
            RunService:UnbindFromRenderStep('AntiVoid')
        end
    end
})

--[[ LongJump ]]
local LongJumpMethodVal = "Bypass"
local LongJumpModule 

LongJumpModule = guiLibrary.Windows.Movement:createModule({
    ["Name"] = "LongJump",
    ["Description"] = "Beta",
    ["Function"] = function(state)
        if state then
            local startY = 26
            local startTick = tick()
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            
            if not root then 
                task.spawn(function()
                    if LongJumpModule.enabled then
                        LongJumpModule:toggle(false)
                    end
                end)
                return 
            end
            
            local startDist = root.Position
            
            RunService:BindToRenderStep("LongJumpBinding", 1, function(deltaTime)
                local char = LocalPlayer.Character
                local rootPart = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")

                if not rootPart or not hum then 
                    if LongJumpModule.enabled then
                        LongJumpModule:toggle(false)
                    end
                    return 
                end

                shared.overRiding = true
                local speedval = 20
                startY = startY - (42 * deltaTime) 

                local maxTime = (LongJumpMethodVal == "Bypass" and 0.5) or 0.375

                if (tick() - startTick) > maxTime or (LocalPlayer:DistanceFromCharacter(startDist)) >= 130 then
                    task.defer(function()
                        if LongJumpModule.enabled then
                            LongJumpModule:toggle(false)
                        end
                    end)
                    return
                end

                if LongJumpMethodVal == "Bypass" then
                    speedval = 400
                elseif LongJumpMethodVal == "Safe" then
                    speedval = 100
                end

                rootPart.AssemblyLinearVelocity = Vector3.new(
                    hum.MoveDirection.X * speedval, 
                    startY, 
                    hum.MoveDirection.Z * speedval
                )
            end)
        else
            RunService:UnbindFromRenderStep("LongJumpBinding")
            shared.overRiding = false
            
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
        end
    end,
    ["ExtraText"] = function()
        return tostring(LongJumpMethodVal)
    end
})
LongJumpModule.selectors.new({
    ["Name"] = "Method",
    ["Default"] = "Bypass",
    ["Selections"] = {"Bypass", "Safe"},
    ["Function"] = function(value)
        LongJumpMethodVal = value
    end
})

--[[ SessionInfo ]]
--[[
local SessionSG = nil
local SessionFrame = nil
guiLibrary.Windows.Visuals:createModule({
    ["Name"] = "SessionInfo",
    ["Function"] = function(state)
        if not SessionSG then
            local uiParent = gethui and gethui() or game:GetService("CoreGui")
            
            SessionSG = Instance.new("ScreenGui")
            SessionSG.Name = "HazeSessionInfo"
            SessionSG.ResetOnSpawn = false
            SessionSG.Parent = uiParent

            SessionFrame = Instance.new("Frame")
            SessionFrame.Parent = SessionSG
            SessionFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
            SessionFrame.BackgroundTransparency = 0.05
            SessionFrame.Position = UDim2.new(0.02, 0, 0.4, 0)
            SessionFrame.Size = UDim2.new(0, 215, 0, 185)
            SessionFrame.BorderSizePixel = 0
            SessionFrame.Active = true

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 5)
            corner.Parent = SessionFrame

            local AccentBar = Instance.new("Frame")
            AccentBar.Size = UDim2.new(1, 0, 0, 2)
            AccentBar.BorderSizePixel = 0
            AccentBar.Parent = SessionFrame

            task.spawn(function()
                while task.wait(0.1) do
                    AccentBar.BackgroundColor3 = guiLibrary.Pallete.Main
                end
            end)

            local Header = Instance.new("Frame")
            Header.Size = UDim2.new(1, 0, 0, 35)
            Header.BackgroundTransparency = 1
            Header.Parent = SessionFrame

            local Title = Instance.new("TextLabel")
            Title.Text = "HAZE"
            Title.Font = Enum.Font.GothamBold
            Title.TextSize = 13
            Title.TextColor3 = Color3.new(1, 1, 1)
            Title.Position = UDim2.new(0, 12, 0, 8)
            Title.Size = UDim2.new(0, 80, 0, 20)
            Title.BackgroundTransparency = 1
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Header

            local Timer = Instance.new("TextLabel")
            Timer.Size = UDim2.new(1, -12, 0, 20)
            Timer.Position = UDim2.new(0, 0, 0, 8)
            Timer.BackgroundTransparency = 1
            Timer.Font = Enum.Font.RobotoMono
            Timer.TextColor3 = Color3.fromRGB(220, 220, 225)
            Timer.TextXAlignment = Enum.TextXAlignment.Right
            Timer.Text = "00:00:00"
            Timer.Parent = Header

            local Content = Instance.new("Frame")
            Content.Position = UDim2.new(0, 0, 0, 40)
            Content.Size = UDim2.new(1, 0, 1, -40)
            Content.BackgroundTransparency = 1
            Content.Parent = SessionFrame

            local list = Instance.new("UIListLayout")
            list.Padding = UDim.new(0, 6)
            list.Parent = Content

            local pad = Instance.new("UIPadding")
            pad.PaddingLeft = UDim.new(0, 12)
            pad.PaddingRight = UDim.new(0, 12)
            pad.Parent = Content

            local function addStat(displayName, internalName)
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 20)
                row.BackgroundTransparency = 1
                row.Parent = Content

                local n = Instance.new("TextLabel")
                n.Text = displayName:upper()
                n.Font = Enum.Font.GothamBold
                n.TextSize = 10
                n.TextColor3 = Color3.fromRGB(170, 170, 175)
                n.Size = UDim2.new(0.5, 0, 1, 0)
                n.BackgroundTransparency = 1
                n.TextXAlignment = Enum.TextXAlignment.Left
                n.Parent = row

                local v = Instance.new("TextLabel")
                v.Text = "0"
                v.Font = Enum.Font.RobotoMono
                v.TextSize = 12
                v.TextColor3 = Color3.new(1, 1, 1)
                v.Size = UDim2.new(0.5, 0, 1, 0)
                v.Position = UDim2.new(0.5, 0, 0, 0)
                v.BackgroundTransparency = 1
                v.TextXAlignment = Enum.TextXAlignment.Right
                v.Parent = row

                task.spawn(function()
                    while task.wait(1) do
                        local statsFolder = LocalPlayer:FindFirstChild("Stats") or LocalPlayer:FindFirstChild("leaderstats")
                        if statsFolder then
                            local statObj = statsFolder:FindFirstChild(internalName)
                            if statObj then
                                v.Text = tostring(statObj.Value)
                            end
                        end
                    end
                end)
            end

            addStat("Rank Points", "Rank Points")
            addStat("Beds Broken", "Total Beds Broken")
            addStat("Wins", "Wins")
            addStat("Kills", "Total Kills")
            addStat("Winstreak", "Winstreak")

            local startTime = os.time()
            game:GetService("RunService").RenderStepped:Connect(function()
                if SessionSG and SessionSG.Enabled then
                    local diff = os.time() - startTime
                    Timer.Text = string.format("%02d:%02d:%02d", math.floor(diff/3600), math.floor((diff%3600)/60), diff%60)
                end
            end)
        end

        SessionSG.Enabled = state
    end
}).sliders.new({
    ["Name"] = "Transparency",
    ["Minimum"] = 0,
    ["Maximum"] = 100,
    ["Default"] = 5,
    ["Function"] = function(val)
        if SessionFrame then
            SessionFrame.BackgroundTransparency = val / 100
        end
    end
})]]

--[[ TargetInfo ]]
--[[
local TargetInfoSG = nil
local TargetFrame = nil
local lastTarget = nil
local TargetConnection = nil
local TargetHeight = 28
local TargetHorizontal = 28
local TargetTransparency = 0.1
local getTargetRange = 25
TargetInfo = guiLibrary.Windows.Visuals:createModule({
    ["Name"] = "TargetInfo",
    ["Function"] = function(state)
        if not TargetInfoSG then
            TargetInfoSG = Instance.new("ScreenGui")
            TargetInfoSG.Name = "HazeTargetInfo" 
            TargetInfoSG.ResetOnSpawn = false
            TargetInfoSG.Parent = uiParent

            TargetFrame = Instance.new("Frame")
            TargetFrame.Name = getRandomUd()
            TargetFrame.Parent = TargetInfoSG
            TargetFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            TargetFrame.BackgroundTransparency = TargetTransparency
            TargetFrame.Position = UDim2.new(0.5, TargetHorizontal - 125, 0.5, TargetHeight - 40)
            TargetFrame.Size = UDim2.new(0, 250, 0, 80)
            TargetFrame.BorderSizePixel = 0
            TargetFrame.Visible = false

            local UIScale = Instance.new("UIScale")
            UIScale.Name = getRandomUd()
            UIScale.Scale = 0
            UIScale.Parent = TargetFrame

            local corner = Instance.new("UICorner")
            corner.Parent = TargetFrame

            local stroke = Instance.new("UIStroke")
            stroke.Thickness = 1
            stroke.Color = Color3.new(1, 1, 1)
            stroke.Transparency = 0.9
            stroke.Parent = TargetFrame
            
            local AccentBar = Instance.new("Frame")
            AccentBar.Name = getRandomUd()
            AccentBar.Parent = TargetFrame
            AccentBar.Size = UDim2.new(1, 0, 0, 2)
            AccentBar.BorderSizePixel = 0

            task.spawn(function()
                while task.wait(0.1) do
                    AccentBar.BackgroundColor3 = guiLibrary.Pallete.Main
                end
            end)

            local Avatar = Instance.new("ImageLabel")
            Avatar.Name = getRandomUd()
            Avatar.Parent = TargetFrame
            Avatar.Position = UDim2.new(0.06, 0, 0.22, 0)
            Avatar.Size = UDim2.new(0, 46, 0, 46)
            Avatar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            Avatar.BorderSizePixel = 0
            Instance.new("UICorner", Avatar).CornerRadius = UDim.new(0, 4)

            local NameLabel = Instance.new("TextLabel")
            NameLabel.Name = getRandomUd()
            NameLabel.Parent = TargetFrame
            NameLabel.Position = UDim2.new(0.3, 0, 0.22, 0)
            NameLabel.Size = UDim2.new(0, 160, 0, 15)
            NameLabel.Font = Enum.Font.GothamBold
            NameLabel.TextColor3 = Color3.new(1, 1, 1)
            NameLabel.TextSize = 13
            NameLabel.BackgroundTransparency = 1
            NameLabel.TextXAlignment = Enum.TextXAlignment.Left
            NameLabel.Text = "PLAYER"

            local UserLabel = Instance.new("TextLabel")
            UserLabel.Name = getRandomUd()
            UserLabel.Parent = TargetFrame
            UserLabel.Position = UDim2.new(0.3, 0, 0.42, 0)
            UserLabel.Size = UDim2.new(0, 160, 0, 12)
            UserLabel.Font = Enum.Font.GothamMedium
            UserLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
            UserLabel.TextSize = 11
            UserLabel.BackgroundTransparency = 1
            UserLabel.TextXAlignment = Enum.TextXAlignment.Left
            UserLabel.Text = "@Username"

            local HealthBack = Instance.new("Frame")
            HealthBack.Name = getRandomUd()
            HealthBack.Parent = TargetFrame
            HealthBack.Position = UDim2.new(0.3, 0, 0.72, 0)
            HealthBack.Size = UDim2.new(0, 130, 0, 4)
            HealthBack.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            HealthBack.BorderSizePixel = 0
            Instance.new("UICorner", HealthBack).CornerRadius = UDim.new(0, 2)

            local HealthBar = Instance.new("Frame")
            HealthBar.Name = getRandomUd()
            HealthBar.Parent = HealthBack
            HealthBar.Size = UDim2.new(1, 0, 1, 0)
            HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
            HealthBar.BorderSizePixel = 0
            Instance.new("UICorner", HealthBar).CornerRadius = UDim.new(0, 2)

            local HealthText = Instance.new("TextLabel")
            HealthText.Name = getRandomUd()
            HealthText.Parent = TargetFrame
            HealthText.Position = UDim2.new(0.82, 0, 0.67, 0)
            HealthText.Size = UDim2.new(0, 35, 0, 12)
            HealthText.Font = Enum.Font.Code
            HealthText.TextColor3 = Color3.new(1, 1, 1)
            HealthText.TextSize = 12
            HealthText.BackgroundTransparency = 1
            HealthText.TextXAlignment = Enum.TextXAlignment.Right
            HealthText.Text = "100"

            TargetInfoUI = {Main = TargetFrame, Scale = UIScale, Avatar = Avatar, Name = NameLabel, User = UserLabel, Bar = HealthBar, HTxt = HealthText}
        end

        TargetInfoSG.Enabled = state

        if state then
            TargetConnection = game:GetService("RunService").RenderStepped:Connect(function()
                local ui = TargetInfoUI
                ui.Main.Position = UDim2.new(0.5, TargetHorizontal - 125, 0.5, TargetHeight - 40)
                ui.Main.BackgroundTransparency = TargetTransparency

                local target = getClosestPlayer(getTargetRange)

                if target and target.Character and target.Character:FindFirstChild("Humanoid") then
                    if target ~= lastTarget then
                        lastTarget = target
                        ui.Name.Text = target.Name:upper()
                        ui.User.Text = "@" .. target.DisplayName
                        task.spawn(function()
                            local content = game:GetService("Players"):GetUserThumbnailAsync(target.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                            ui.Avatar.Image = content
                        end)
                        ui.Main.Visible = true
                        game:GetService("TweenService"):Create(ui.Scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = 1}):Play()
                    end

                    local hum = target.Character.Humanoid
                    local hpScale = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    ui.Bar.Size = ui.Bar.Size:Lerp(UDim2.new(hpScale, 0, 1, 0), 0.15)
                    ui.HTxt.Text = math.floor(hum.Health)
                    local hpColor = hpScale > 0.7 and Color3.fromRGB(0, 255, 120) or (hpScale > 0.3 and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(255, 50, 70))
                    ui.Bar.BackgroundColor3 = ui.Bar.BackgroundColor3:Lerp(hpColor, 0.1)
                else
                    if lastTarget then
                        lastTarget = nil
                        local t = game:GetService("TweenService"):Create(ui.Scale, TweenInfo.new(0.2), {Scale = 0})
                        t:Play()
                        task.delay(0.2, function() if not lastTarget then ui.Main.Visible = false end end)
                    end
                end
            end)
        else
            if TargetConnection then TargetConnection:Disconnect() end
            if TargetFrame then TargetFrame.Visible = false end
            lastTarget = nil
        end
    end
})
TargetInfo.sliders.new({
    ["Name"] = "Height",
    ["Minimum"] = -500,
    ["Maximum"] = 500,
    ["Default"] = 28,
    ["Function"] = function(val)
        TargetHeight = val
    end
})
TargetInfo.sliders.new({
    ["Name"] = "Horizontal",
    ["Minimum"] = -500,
    ["Maximum"] = 500,
    ["Default"] = 28,
    ["Function"] = function(val)
        TargetHorizontal = val
    end
})
TargetInfo.sliders.new({
    ["Name"] = "Transparency",
    ["Minimum"] = 0,
    ["Maximum"] = 100,
    ["Default"] = 10,
    ["Function"] = function(val)
        TargetTransparency = val / 100
    end
})]]

--[[ NoFall ]]
guiLibrary.Windows.Utility:createModule({
    ["Name"] = "NoFall",
    ["Description"] = "You must have wool",
    ["Function"] = function(state)
        if state then
            local lastDebounce = tick()
            shared.NoFallConn = RunService.Heartbeat:Connect(function()
                local root = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
                if root and root.AssemblyLinearVelocity.Y < -80 and (tick() - lastDebounce) > 0.3 then
                    local blockName = nil
                    for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
                        if v.Name:lower():find("wool") or v.Name:lower():find("fake") then
                            blockName = v.Name
                            break
                        end
                    end
                    if blockName then
                        lastDebounce = tick()
                        local placePos = root.Position - Vector3.new(0, 6, 0)
                        local roundedPos = Vector3.new(
                            math.floor(placePos.X / 3 + 0.5) * 3,
                            math.floor(placePos.Y / 3) * 3,
                            math.floor(placePos.Z / 3 + 0.5) * 3
                        )
                        remotes.PlaceBlock:FireServer(blockName, nil, roundedPos, roundedPos + Vector3.new(0, 2, 0), Vector3.new(0, -1, 0))
                        root.CFrame = root.CFrame - Vector3.new(0, 6, 0)
                        root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, -35, root.AssemblyLinearVelocity.Z)
                    end
                end
            end)
        else
            if shared.NoFallConn then
                shared.NoFallConn:Disconnect()
                shared.NoFallConn = nil
            end
        end
    end
})

--[[ BangAura ]]
local BangAuraVar = false
local BangAuraConn

guiLibrary.Windows.Combat:createModule({
    ["Name"] = "BangAura",
    ["Description"] = "Teleport behind target",
    ["Function"] = function(state)
        BangAuraVar = state
        if BangAuraConn then
            BangAuraConn:Disconnect()
            BangAuraConn = nil
        end
        if state then
            BangAuraConn = RunService.Heartbeat:Connect(function()
                local myChar = LocalPlayer.Character
                if not myChar or not modules.Entity.isAlive(myChar) or LocalPlayer:GetAttribute("PVP") ~= true then 
                    return 
                end

                local myRoot = myChar:FindFirstChild("HumanoidRootPart")
                local target = getClosestPlayer()
                if target and target.Character and myRoot then
                    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                    if targetRoot and modules.Entity.isAlive(target.Character) then
                        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                        myRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        myRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end)
        end
    end
})

--[[ BedESP ]]
guiLibrary.Windows.Visuals:createModule({
    ["Name"] = "BedESP",
    ["Function"] = function(callback)
        local bedsContainer = workspace:FindFirstChild("BedsContainer")
        task.spawn(function()
            while callback do
                if not bedsContainer then break end
                local isSpectator = LocalPlayer.Team and (LocalPlayer.Team.Name == "Spectators" or LocalPlayer.Team.Name == "Spectator")
                
                if not isSpectator then
                    local beds = bedsContainer:GetChildren()
                    for _, bed in ipairs(beds) do
                        local hitbox = bed:FindFirstChild("BedHitbox")
                        local mattress = bed:FindFirstChild("Mattress")
                        
                        if hitbox and mattress then
                            local isMyTeam = (mattress.BrickColor.Name == LocalPlayer.TeamColor.Name)
                            local existingHighlight = hitbox:FindFirstChild("BedHighlight")

                            if isMyTeam then
                                if existingHighlight then existingHighlight:Destroy() end
                                hitbox.Transparency = 0
                            else
                                if not existingHighlight then
                                    local highlight = Instance.new("Highlight")
                                    highlight.Name = "BedHighlight"
                                    highlight.Adornee = hitbox
                                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                    highlight.FillColor = Color3.fromRGB(255, 255, 255)
                                    highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
                                    highlight.FillTransparency = 0
                                    highlight.OutlineTransparency = 0
                                    
                                    highlight.Parent = hitbox
                                end
                                hitbox.Transparency = 0
                            end
                        end
                    end
                end
                task.wait(1)
            end
            if bedsContainer then
                for _, bed in ipairs(bedsContainer:GetChildren()) do
                    local hb = bed:FindFirstChild("BedHitbox")
                    if hb and hb:FindFirstChild("BedHighlight") then
                        hb.BedHighlight:Destroy()
                    end
                end
            end
        end)
    end
})

--[[ NoNameTag ]]
guiLibrary.Windows.Utility:createModule({
    ["Name"] = "NoNameTag",
    ["Description"] = "literally just changes from your Settings",
    ["Function"] = function(state)
        remotes.SetSettings:FireServer("Name Tag", not state)
    end
})

--[[ FPSBoost ]]
FPSBoostModule = guiLibrary.Windows.Visuals:createModule({
    ["Name"] = "FPS Boost",
    ["Function"] = function(state)
        remotes.SetSettings:FireServer("Performance", state)
    end
})
FPSBoostModule.toggles.new({
    ["Name"] = "Shadows",
    ["Function"] = function(state)
        remotes.SetSettings:FireServer("Shadows", not state)
    end
})
FPSBoostModule.toggles.new({
    ["Name"] = "KillLog",
    ["Function"] = function(state)
        remotes.SetSettings:FireServer("Kill Log", not state)
    end
})
FPSBoostModule.toggles.new({
    ["Name"] = "Announcements",
    ["Function"] = function(state)
        remotes.SetSettings:FireServer("Global Announcements", not state)
    end
})
FPSBoostModule.toggles.new({
    ["Name"] = "PopUps",
    ["Function"] = function(state)
        remotes.SetSettings:FireServer("Kit Popups", not state)
    end
})
FPSBoostModule.toggles.new({
    ["Name"] = "Emotes",
    ["Function"] = function(state)
        remotes.SetSettings:FireServer("Disable Emotes", state)
    end
})
