local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Network = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Packages"):WaitForChild("Client"):WaitForChild("Network"))
local BowModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Bow"):WaitForChild("BowConfig"))

local BowController = {}

function BowController.Shoot(targetCharacter)
    if not targetCharacter then return end
    local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local character = LocalPlayer.Character
    if not character then return end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not hrp or not targetRoot then return end

    local direction = (targetRoot.Position - hrp.Position).Unit
    local force = BowModule.MAX_CHARGE_FORCE

    Network.Fire("RequestBowHit", targetCharacter, direction, force)
end

function BowController.GetNearestPlayer(range)
    range = range or 100
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

function BowController.AutoShoot(range)
    local target = BowController.GetNearestPlayer(range)
    if target then
        BowController.Shoot(target)
    end
end

return BowController