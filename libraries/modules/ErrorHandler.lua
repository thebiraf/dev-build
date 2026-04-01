return function()
    select(2,pcall(loadfile,"Haze/libraries/Notifications.lua"))():Notify("Error","Check console! (F9)", 10, Color3.fromRGB(255,0,0))
	warn(debug.traceback())
    coroutine.yield()
end