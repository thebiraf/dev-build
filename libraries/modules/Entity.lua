local Players = game:GetService("Players")

local Entity = {}

local LocalPlayer = Players.LocalPlayer

function Entity.isAlive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid ~= nil and humanoid.Health > 0
end

function Entity.nearPlayer(maxDistance)
    maxDistance = maxDistance or 20

    local closestPlayer = nil
    local closestDist = math.huge

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not Entity.isAlive(myChar) then
        return nil
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and Entity.isAlive(player.Character) then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local distance = (root.Position - myRoot.Position).Magnitude
                if distance <= maxDistance and distance < closestDist then
                    closestDist = distance
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

return Entity