--[[ Skybridge Duels Game ]]
local guiLibrary = loadfile("Haze/guis/HazeLibrary.lua")()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--[[ Libraries ]]
local LocalLibrary = "Haze/libraries"
local modules = {
    SwordController = loadfile(LocalLibrary .. "/skybridge/SwordController.lua")(),
    BowController = loadfile(LocalLibrary .. "/skybridge/BowController.lua")()
}
local humanoidvalues = {
    ['JumpPower'] = 50,
    ['WalkSpeed'] = 16
}

--[[ Speed ]]
local SpeedVar = false
local SpeedValue = 16

local oldindex;oldindex = hookmetamethod(game,"__index",newcclosure(function(self,key)
    if self:IsA("Humanoid") and humanoidvalues[key] then return humanoidvalues[key] end
    return oldindex(self,key)
end))
local oldnewindex;oldnewindex = hookmetamethod(game,"__newindex",newcclosure(function(self,key,value)
    if not checkcaller() and self:IsA("Humanoid") and humanoidvalues[key] then
        humanoidvalues[key] = value
        return
    end
    return oldnewindex(self,key,value)
end))


RunService.Heartbeat:Connect(function()
    if SpeedVar then
        local Character = LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            Humanoid.WalkSpeed = SpeedValue
        end
    end
end)

local SpeedModule = guiLibrary.Windows.Movement:createModule({
    ["Name"] = "Speed",
    ["Description"] = "Makes you walk faster",
    ["Function"] = function(state)
        SpeedVar = state
        if not state then
            local Character = LocalPlayer.Character
            local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then
                Humanoid.WalkSpeed = 16
            end
        end
    end,
    ["ExtraText"] = function()
        return tostring(SpeedValue)
    end
})

local SpeedValueMod = SpeedModule.sliders.new({
    ["Name"] = "Speed Value",
    ["Minimum"] = 16,
    ["Maximum"] = 50,
    ["Default"] = 16,
    ["Function"] = function(value)
        SpeedValue = value
    end
})

--[[ AutoWin ]]--
local Teams = {"Red", "Blue"}
local AutoWinVar = false
guiLibrary.Windows.Combat:createModule({
    ["Name"] = "AutoWin",
    ["Function"] = function(state)
        AutoWinVar = state
        if state then
            if workspace:FindFirstChild("Blocks") then
                workspace.Blocks:Destroy()
            end
            local tpIndex = 1
            task.spawn(function()
                while AutoWinVar do
                    local character = LocalPlayer.Character
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        local currentTeam = Teams[tpIndex]
                        local teamFolder = workspace.WORLDPARTS.Teams:FindFirstChild(currentTeam)
                        local GoalHitbox = teamFolder and teamFolder:FindFirstChild("GoalHitbox")
                        if GoalHitbox then
                            character.HumanoidRootPart.CFrame = GoalHitbox.CFrame + Vector3.new(0,5,0)
                        end
                        tpIndex = tpIndex % #Teams + 1
                    end
                    task.wait(.5)
                end
            end)
        end
    end
})

--[[ Killaura ]]
local KAVar = false
local KAConnection = nil
local SelectedAnim = "Exotic"
local AttackSpeedVal = 50
local AffectAnim = false
local Animating = false
local LastAttack = tick()

local BlockAnimations = {
    ["Exotic"] = {
        {CFrame = CFrame.new(0.3, -1, -1) * CFrame.Angles(-math.rad(190), math.rad(55), -math.rad(90)), Timer = 0.2},
        {CFrame = CFrame.new(0.3, -1, -0.1) * CFrame.Angles(-math.rad(190), math.rad(110), -math.rad(90)), Timer = 0.2},
    },
    ["Vanish"] = {
        {CFrame = CFrame.new(-0.5, -0.8, -1.2) * CFrame.Angles(-math.rad(190), math.rad(45), -math.rad(90)), Timer = 0.15},
        {CFrame = CFrame.new(0.5, -0.8, -1.2) * CFrame.Angles(-math.rad(190), math.rad(135), -math.rad(90)), Timer = 0.15}
    }
}

local function cframecustom()
    if Animating then return end
    local char = game.Players.LocalPlayer.Character
    local hand = char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"))
    local grip = hand and hand:FindFirstChild("RightGrip")
    
    if grip and BlockAnimations[SelectedAnim] then
        Animating = true
        local originalC0 = grip.C0
        local speedMult = AffectAnim and ((101 - AttackSpeedVal) / 50) or 1
        
        task.spawn(function()
            for _, v in pairs(BlockAnimations[SelectedAnim]) do
                local duration = v.Timer * speedMult
                local targetC0 = originalC0 * (v.CFrame * CFrame.Angles(-math.rad(90), math.rad(90), 0) + Vector3.new(0, 1.5, 0))
                local tween = game:GetService("TweenService"):Create(grip, TweenInfo.new(duration, Enum.EasingStyle.Linear), {C0 = targetC0})
                tween:Play()
                task.wait(duration)
            end
            local reset = game:GetService("TweenService"):Create(grip, TweenInfo.new(0.1 * speedMult), {C0 = originalC0})
            reset:Play()
            reset.Completed:Wait()
            Animating = false
        end)
    end
end

local function runka()
    if KAConnection then KAConnection:Disconnect() end
    KAConnection = RunService.Heartbeat:Connect(function()
        if not KAVar then
            if KAConnection then KAConnection:Disconnect() KAConnection = nil end
            return
        end
        
        local cooldown = (101 - AttackSpeedVal) / 100
        if tick() - LastAttack >= cooldown then
            local target = modules.SwordController.GetNearestPlayer()
            if target then
                LastAttack = tick()
                modules.SwordController.Attack(target)
                cframecustom()
            end
        end
    end)
end

KillAuraModule = guiLibrary.Windows.Combat:createModule({
    ["Name"] = "KillAura",
    ["Description"] = "attacks players around you",
    ["Function"] = function(state)
        KAVar = state
        if state then
            runka()
        else
            if KAConnection then KAConnection:Disconnect() KAConnection = nil end
            Animating = false
        end
    end
})
KillAuraModule.sliders.new({
    ["Name"] = "Attack Speed",
    ["Minimum"] = 1,
    ["Maximum"] = 100,
    ["Default"] = 80,
    ["Function"] = function(val)
        AttackSpeedVal = val
    end
})
KillAuraModule.toggles.new({
    ["Name"] = "Affect Animation",
    ["Function"] = function(state)
        AffectAnim = state
    end
})
KillAuraModule.selectors.new({
    ["Name"] = "CustomAnim",
    ["Default"] = "Exotic",
    ["Selections"] = {"Exotic", "Vanish"},
    ["Function"] = function(val) SelectedAnim = val end
})

--[[ Crasher ]]
local CrasherVar = false
local CrashConnection = nil

local function runCrasher()
    if CrashConnection then CrashConnection:Disconnect() end
    CrashConnection = RunService.Heartbeat:Connect(function()
        if not CrasherVar then
            if CrashConnection then
                CrashConnection:Disconnect()
                CrashConnection = nil
            end
            return
        end
        local target = modules.BowController.GetNearestPlayer()
        if target then
            modules.BowController.Shoot(target)
        end
    end)
end

guiLibrary.Windows.Exploit:createModule({
    ["Name"] = "Crasher",
    ["Function"] = function(state)
        CrasherVar = state
        if state then
            runCrasher()
        else
            if CrashConnection then
                CrashConnection:Disconnect()
                CrashConnection = nil
            end
        end
    end
})

--[[ AutoLobby ]]
local endMatch = PlayerGui:WaitForChild("MatchEnd"):WaitForChild("Canvas")
local AutoLobbyConnect
guiLibrary.Windows.Utility:createModule({
    ["Name"] = "AutoLobby",
    ["Function"] = function(state)
        if state then
            AutoLobbyConnect = endMatch:GetPropertyChangedSignal("Visible"):Connect(function()
                if endMatch.Visible then
                    ReplicatedStorage.Network.Request_ReturnToLobby:FireServer()
                end
            end)
            if endMatch.Visible then
                ReplicatedStorage.Network.Request_ReturnToLobby:FireServer()
            end
        else
            if AutoLobbyConnect then
                AutoLobbyConnect:Disconnect()
                AutoLobbyConnect = nil
            end
        end
    end
})

--[[ Fly ]]
local flyVertical = false
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
                local flyVal = 1
                if flyVertical then
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        flyVal = 50
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        flyVal = -50
                    end
                end
                finalY = (tick() - startTick) < 1 and flyVal or -4.06
                root.AssemblyLinearVelocity = Vector3.new(
                    currentVelocity.X,
                    finalY,
                    currentVelocity.Z
                )
            end)
        else
            if flyConnection then
                local character = LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if root then
                    root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
                end
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