--!strict
--[[
    ModalWindowManager.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/ModalWindowManager.luau
    Centralized mutual exclusion window manager for ASCEND.
    Enforces single-active-window policy across all HUD modals and facility menus.
]]

local ModalWindowManager = {}
local activeWindowName: string? = nil
local closeCallbacks: { [string]: () -> () } = {}

function ModalWindowManager.Init()
	print("[ASCEND] ModalWindowManager Initialized (Single-Window Exclusion Policy Active).")
end

function ModalWindowManager.Register(windowName: string, closeCallback: () -> ())
	closeCallbacks[windowName] = closeCallback
end

function ModalWindowManager.RequestOpen(windowName: string)
	if activeWindowName and activeWindowName ~= windowName then
		local closePrevious = closeCallbacks[activeWindowName]
		if closePrevious then
			pcall(closePrevious)
		end
	end
	activeWindowName = windowName
end

function ModalWindowManager.NotifyClosed(windowName: string)
	if activeWindowName == windowName then
		activeWindowName = nil
	end
end

function ModalWindowManager.GetActiveWindow(): string?
	return activeWindowName
end

function ModalWindowManager.CloseActiveWindow()
	if activeWindowName then
		local closeCurrent = closeCallbacks[activeWindowName]
		if closeCurrent then
			pcall(closeCurrent)
		end
		activeWindowName = nil
	end
end

return ModalWindowManager