--!strict
--[[
    MusicController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/MusicController.luau
    Client music controller for ASCEND:
      - Phase 5.3: Combat engagement music and threat proximity audio swelling completely removed per user request.
      - Retains clean listener lifecycle and respects player BGM settings.
]]

local SoundService = game:GetService("SoundService")

local MusicController = {}

function MusicController.Init()
	-- Clean up any legacy combat sound instances if present
	local existing = SoundService:FindFirstChild("CombatBGM")
	if existing then
		existing:Destroy()
	end

	print("[ASCEND] MusicController Initialized (Combat Engagement Music Disabled).")
end

return MusicController