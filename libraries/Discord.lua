local Discord = {}

local HttpService = game:GetService("HttpService")

local Notifications = loadfile("Haze/libraries/Notifications.lua")()

local http_request = (syn and syn.request) or (http and http.request) or request

local function getInviteCode(url)
    return url:match("discord%.gg/([%w-]+)") or url:match("discord%.com/invite/([%w-]+)")
end

function Discord:Join(inviteUrl, silent)
    local inviteCode = getInviteCode(inviteUrl)

    if not inviteCode then
        if not silent then
            Notifications:Notify("Error", "Discord invite has expired! Report this to the devs, ScriptIsFocus", 5, Color3.fromRGB(255, 0, 0))
        end
        return false
    end

    if not http_request then
        if not silent then
            Notifications:Notify("Warning", "Executor doesnt support http_request!", 5, Color3.fromRGB(255, 150, 0))
        end
        return false
    end

    local success = pcall(function()
        http_request({
            Url = "http://127.0.0.1:6463/rpc?v=1",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Origin"] = "https://discord.com"
            },
            Body = HttpService:JSONEncode({
                cmd = "INVITE_BROWSER",
                args = { code = inviteCode },
                nonce = HttpService:GenerateGUID(false)
            })
        })
    end)

    if not silent then
        if success then
            Notifications:Notify("Discord", "Make sure to join our discord server!", 5, Color3.fromRGB(0, 255, 0))
        else
            Notifications:Notify("Error", "Discord RPC failed, open manually", 5, Color3.fromRGB(255, 0, 0))
        end
    end
    return success
end

function Discord:Copy(inviteUrl)
    if setclipboard then
        setclipboard(inviteUrl)
        return true
    end
    return false
end

return Discord