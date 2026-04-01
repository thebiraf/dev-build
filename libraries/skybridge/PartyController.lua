local PartyController = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InviteRemote = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Request_Invite_Party")
local KickRemote = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Request_KickOrLeave_Party")

function PartyController:InvitePlayer(userId)
    InviteRemote:FireServer(userId)
end

function PartyController:InviteAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            self:InvitePlayer(player.UserId)
        end
    end
end

function PartyController:KickPlayer(userId)
    KickRemote:FireServer(userId)
end

function PartyController:KickAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            self:KickPlayer(player.UserId)
        end
    end
end

return PartyController