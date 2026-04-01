--[[ SkyBridge Duels Lobby ]]
local guiLibrary = loadfile("Haze/guis/HazeLibrary.lua")()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

--[[ Libraries ]]
local LocalLibrary = "Haze/libraries"
local modules = {
    PartyController = loadfile(LocalLibrary .. "/skybridge/PartyController.lua")()
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

--[[ Spam Invites ]]
local InviteSpamVar = false
local InvitesModule = guiLibrary.Windows.Utility:createModule({
    ["Name"] = "Spam Invites",
    ["Function"] = function(state)
        InviteSpamVar = state

        task.spawn(function()
            while InviteSpamVar do
                modules.PartyController:InviteAll()
                task.wait(.1)
            end
        end)
    end
})

--[[ Party Kick ]]
local KickSpamVar = false
local KicksModule = guiLibrary.Windows.Utility:createModule({
    ["Name"] = "Spam Kicks",
    ["Function"] = function(state)
        KickSpamVar = state

        task.spawn(function()
            while KickSpamVar do
                modules.PartyController:KickAll()
                task.wait(.1)
            end
        end)
    end
})

--[[ FakeWS ]]
local FakeWSVar = false
local FakeWSVal = 0
local oldWS = 0

local FakeWSModule = guiLibrary.Windows.Visuals:createModule({
    ["Name"] = "Fake Winstreak",
    ["Function"] = function(state)
        FakeWSVar = state
        if state then
            oldWS = LocalPlayer:GetAttribute("Streak") or 0
            LocalPlayer:SetAttribute("Streak", FakeWSVal)
        else
            LocalPlayer:SetAttribute("Streak", oldWS)
        end
    end,
    ["ExtraText"] = function()
        return tostring(FakeWSVal)
    end
})
local WinstreakValue = FakeWSModule.sliders.new({
    ["Name"] = "Winstreaks",
    ["Minimum"] = 0,
    ["Maximum"] = 1000,
    ["Default"] = 1000,
    ["Function"] = function(value)
        FakeWSVal = value
        if FakeWSVar then
            LocalPlayer:SetAttribute("Streak", value)
        end
    end
})

--[[ Device Spoofer ]]
local DeviceVar = false
local currentDevice = "PC"

local DeviceSpoofModule = guiLibrary.Windows.Visuals:createModule({
    ["Name"] = "Device Spoofer",
    ["Function"] = function(state)
        DeviceVar = state

        if DeviceVar then
            LocalPlayer:SetAttribute("Platform", currentDevice)
        else
            LocalPlayer:SetAttribute("Platform", nil)
        end
    end
})

DeviceSpoofModule.selectors.new({
    ["Name"] = "Devices",
    ["Default"] = "PC",
    ["Selections"] = {"PC", "Mobile", "Console"},
    ["Function"] = function(value)
        currentDevice = value

        if DeviceVar then
            LocalPlayer:SetAttribute("Platform", value)
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