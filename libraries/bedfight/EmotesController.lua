local Emotes = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local ChairM = ReplicatedStorage.Modules.EmoteHandler.Chair
local CrystalM = ReplicatedStorage.Modules.EmoteHandler.Crystal
local MakeupM = ReplicatedStorage.Modules.EmoteHandler.Makeup

local active = {}

local function getChar()
    local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    if not h or not r then return end
    local a = h:FindFirstChildOfClass("Animator")
    if not a then
        a = Instance.new("Animator")
        a.Parent = h
    end
    return c, h, r, a
end

function Emotes:Play(name)
    if name == "Chair" then
        self:Stop("Chair")
        local c, _, r, a = getChar()
        if not c then return end

        local chair = ChairM.Chair:Clone()
        if chair:FindFirstChild("Motor6D") then
            chair.Motor6D.Part1 = r
        end
        chair.Parent = c

        local action = a:LoadAnimation(ChairM.Action)
        local idle = a:LoadAnimation(ChairM.Idle)
        action.Priority = Enum.AnimationPriority.Action
        idle.Priority = Enum.AnimationPriority.Action

        local conns = {}
        local sound = chair:FindFirstChild("ChairSound")
        if sound then
            conns.Crack = action:GetMarkerReachedSignal("Crack"):Once(function()
                sound:Play()
            end)
        end

        conns.Done = action.Stopped:Once(function()
            idle:Play(0.1)
        end)

        action:Play(0.1)

        active.Chair = {
            Obj = chair,
            Tracks = { action, idle },
            Conns = conns
        }

    elseif name == "CrystalIdle" then
        self:Stop("CrystalIdle")
        local _, _, r, a = getChar()
        if not r then return end

        local track = a:LoadAnimation(CrystalM.Idle)
        track.Priority = Enum.AnimationPriority.Action
        track:Play(0.1)

        local p = CrystalM.Particles:Clone()
        if p:FindFirstChild("SparklesMotor") then
            p.SparklesMotor.Part0 = r
        end
        p.Parent = r

        for _, d in ipairs(p:GetDescendants()) do
            if d:IsA("ParticleEmitter") then
                d:Emit(1)
            end
        end

        active.CrystalIdle = {
            Track = track,
            Obj = p
        }

    elseif name == "Makeup" then
        self:Stop("Makeup")
        local c, _, r, a = getChar()
        if not c then return end

        local mirror = MakeupM.Mirror:Clone()
        mirror.MirrorMotor.Part0 = r
        mirror.Parent = c

        local perfume = MakeupM.Perfume:Clone()
        perfume.PerfumeMotor.Part0 = r
        perfume.Parent = c

        local emitter = perfume.Spray.ParticleAttachment.ParticleEmitter
        local sound = perfume.SpraySound

        local track = a:LoadAnimation(MakeupM.Action)
        track.Priority = Enum.AnimationPriority.Action
        track:Play(0.1)

        local conns = {}
        conns.Spray = track:GetMarkerReachedSignal("Spray"):Connect(function()
            emitter:Emit(1)
            sound:Play()
        end)

        conns.End = track.Stopped:Once(function()
            Emotes:Stop("Makeup")
        end)

        active.Makeup = {
            Objs = { mirror, perfume },
            Track = track,
            Conns = conns
        }
    end
end

function Emotes:Stop(name)
    local d = active[name]
    if not d then return end
    active[name] = nil

    if d.Conns then
        for _, c in pairs(d.Conns) do
            c:Disconnect()
        end
    end

    if d.Tracks then
        for _, t in ipairs(d.Tracks) do
            t:Stop()
            t:Destroy()
        end
    end

    if d.Track then
        d.Track:Stop()
        d.Track:Destroy()
    end

    if d.Obj then
        d.Obj:Destroy()
    end

    if d.Objs then
        for _, o in ipairs(d.Objs) do
            o:Destroy()
        end
    end
end

function Emotes:StopAll()
    for k in pairs(active) do
        self:Stop(k)
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.2)
    for k in pairs(active) do
        Emotes:Play(k)
    end
end)

return Emotes