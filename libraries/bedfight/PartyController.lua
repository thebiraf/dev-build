local PartyController = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartyR = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PartyRemotes")
local Invite = PartyR:WaitForChild("InvitePlayer")
local Kick = PartyR:WaitForChild("KickMember")

function PartyController:InviteAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            Invite:FireServer(player.UserId)
        end
    end
end

function PartyController:KickAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            Kick:FireServer(player.UserId)
        end
    end
end

return PartyController