local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Network = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Packages"):WaitForChild("Client"):WaitForChild("Network"))

local SwordController = {}

function SwordController.Attack(targetCharacter)
    if not targetCharacter then return end
    local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        Network.Fire("RequestSwordHit", targetCharacter)
    end
end

function SwordController.GetNearestPlayer(range)
    range = range or 18
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local myTeam = LocalPlayer:GetAttribute("Team")

    local closest, closestDist
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            if plr:GetAttribute("Team") ~= myTeam then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")

                if root and hum and hum.Health > 0 then
                    local dist = (root.Position - hrp.Position).Magnitude
                    if dist <= range and (not closestDist or dist < closestDist) then
                        closest = plr.Character
                        closestDist = dist
                    end
                end
            end
        end
    end

    return closest
end

return SwordController