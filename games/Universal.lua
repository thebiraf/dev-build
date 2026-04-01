--[[ Universal ]]
local guiLibrary = loadfile("Haze/guis/HazeLibrary.lua")()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

--[[ Speed ]]
local SpeedVar = false
local SpeedValue = 16

local humanoidvalues = {
    ['JumpPower'] = 50,
    ['WalkSpeed'] = 16
}

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
    ["Maximum"] = 100,
    ["Default"] = 16,
    ["Function"] = function(value)
        SpeedValue = value
    end
})