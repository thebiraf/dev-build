local ScaffoldController = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlaceRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ItemsRemotes"):WaitForChild("PlaceBlock")
local BlocksFolder = ReplicatedStorage:WaitForChild("Blocks")

local IsEnabled = false
local Connection = nil

local TeamColors = {
    "Red",
    "Orange",
    "Yellow",
    "Green",
    "Blue",
    "Purple",
    "Pink",
    "Brown"
}

local function roundPos(pos: Vector3)
    local x = math.floor(pos.X / 3 + 0.5) * 3
    local y = math.floor(pos.Y / 3) * 3
    local z = math.floor(pos.Z / 3 + 0.5) * 3
    return Vector3.new(x, y, z)
end

local function DetectBlock()
    local blocks = {}
    for _, color in ipairs(TeamColors) do
        table.insert(blocks, color .. " Wool")
    end
    table.insert(blocks, "Fake Block")
    return blocks[math.random(#blocks)]
end

local function ScaffoldPos()
    local char = Players.LocalPlayer.Character
    if not char then return nil end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return nil end

    local moveDir = hum.MoveDirection
    if moveDir.Magnitude <= 0 then return nil end

    local targetPos = hrp.Position - Vector3.new(0, 3.5, 0) + moveDir
    return roundPos(targetPos)
end

local function PlaceBlock(blockName, pos)
    if not blockName or not pos then return end

    PlaceRemote:FireServer(blockName, 1, pos)

    local cloneTemplate = BlocksFolder:FindFirstChild(blockName)
    if cloneTemplate then
        local clone = cloneTemplate:Clone()
        clone.Parent = workspace:FindFirstChild('PlayersBlocksContainer') or workspace:WaitForChild('FakeBlocksContainer')
        clone.Position = pos

        task.delay(0.5, function()
            clone:Destroy()
        end)
    end
end

function ScaffoldController:SetState(state: boolean)
    IsEnabled = state

    RunService:UnbindFromRenderStep('Scaffold')

    if not state then return end

    RunService:BindToRenderStep('Scaffold', math.huge, function()
        if not IsEnabled then return end

        local pos = ScaffoldPos()
        if not pos then return end

        local blockName = DetectBlock()
        PlaceBlock(blockName, pos)
    end)
end

return ScaffoldController
