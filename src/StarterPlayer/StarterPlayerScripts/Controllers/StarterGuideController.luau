--!strict
--[[
    StarterGuideController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/StarterGuideController.luau
    Client UI controller for StarterGui.StarterGuideGui.
]]

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local StarterGuideController = {}

local gui: ScreenGui?
local backdrop: Frame?
local window: Frame?
local closeBtn: TextButton?
local confirmBtn: TextButton?
local tabHeader: TextLabel?
local contentPanel: Frame?
local tabBar: Frame?

local isInitialized = false

local TAB_DATA = {
	[1] = {
		Header = "SECTION 1: MARTIAL COMBAT & MOVEMENT CONTROLS",
		Rows = {
			{ key = "[M1 Attack]", desc = "Perform 5-hit Light Sword Combo (Rapidly builds Sword Intent)" },
			{ key = "[R - Draw / Sheathe]", desc = "Draw your flying sword to enter active martial combat stance" },
			{ key = "[B - Guard Break]", desc = "Heavy posture-breaking strike to shatter blocking opponents" },
			{ key = "[V - Sword Flight]", desc = "Mount your flying sword to soar across the sect mountain tiers" },
			{ key = "[C - Qi Meditation]", desc = "Sit in seclusion to absorb ambient Spirit Qi and restore meridians" },
			{ key = "[Shift - Dash Evade]", desc = "High-speed tactical dash with invulnerability frames" },
		}
	},
	[2] = {
		Header = "SECTION 2: CULTIVATION & REALM BREAKTHROUGHS",
		Rows = {
			{ key = "[Realm Progression]", desc = "Qi Condensation ➔ Foundation ➔ Core Formation ➔ Nascent Soul ➔ Immortal" },
			{ key = "[2.0x Qi Nodes]", desc = "Meditate in the enclosed Sakura Garden for double Qi Condensation speed" },
			{ key = "[Alchemy Elixirs]", desc = "Craft breakthrough pills with Master Shen to survive heavenly tribulation" },
			{ key = "[Health & Qi Scaling]", desc = "Higher cultivation orders multiply your maximum HP, Qi, and sword power" },
			{ key = "[Seclusion Bonus]", desc = "Channel Ancestor Han's avatar for long-term seclusion multiplier bonuses" },
			{ key = "[Tribulation Lightning]", desc = "Endure heavenly tribulation lightning bolts during major breakthroughs" },
		}
	},
	[3] = {
		Header = "SECTION 3: SWORD INTENT & FLYING SWORDS",
		Rows = {
			{ key = "[100% Sword Intent]", desc = "Charge your Sword Intent bar during M1 combos to unlock ultimate arts" },
			{ key = "[Sword Altar Gacha]", desc = "Commune at the Tier 2 Sword Altar to awaken legendary flying sword blades" },
			{ key = "[5 Sword Families]", desc = "Master Jade Dragon, Crimson Flame, Frost Lotus, Cosmic Void, or Thunder blades" },
			{ key = "[Refine & Sharpen]", desc = "Visit Madame Tie at the forge to permanently upgrade sword attack power" },
			{ key = "[Flight Maneuvers]", desc = "Control ascent, descent, and high-speed banking while riding your sword" },
			{ key = "[Sword Clashing]", desc = "Simultaneous M1 strikes against foes trigger blade clashes with particle bursts" },
		}
	},
	[4] = {
		Header = "SECTION 4: SECT DUTIES & CONTRIBUTION REPUTATION",
		Rows = {
			{ key = "[Notice Board Tasks]", desc = "Accept daily foraging and sparring duties from Deacon Zhao on Tier 1" },
			{ key = "[Sect Contribution CP]", desc = "Earn CP by completing duties, sparring, and winning 1v1 arena duels" },
			{ key = "[Treasury Exchange]", desc = "Spend CP at Steward Jin's treasury on rare flying swords and manuals" },
			{ key = "[Disciple Ranks]", desc = "Promote from Outer ➔ Inner ➔ Core ➔ Direct Disciple ➔ Sect Elder" },
			{ key = "[1v1 Sparring Arena]", desc = "Step onto the duel pads on Tier 2 to enter sealed matchmaking combat" },
			{ key = "[Wilderness Portal]", desc = "Speak to Daoist Feng to venture into Zone 2 Beast Domain when ready" },
		}
	}
}

local function EnsureUI(): boolean
	if isInitialized and gui and backdrop then return true end

	gui = (playerGui:FindFirstChild("StarterGuideGui") or playerGui:WaitForChild("StarterGuideGui", 8)) :: ScreenGui?
	if not gui then return false end
	gui.DisplayOrder = 50

	backdrop = (gui:FindFirstChild("ModalBackdrop") or gui:FindFirstChildWhichIsA("Frame")) :: Frame?
	if not backdrop then return false end

	window = (backdrop:FindFirstChild("GuideWindow") or backdrop:FindFirstChildWhichIsA("Frame")) :: Frame?
	if not window then return false end

	closeBtn = window:FindFirstChild("CloseButton") :: TextButton?
	confirmBtn = window:FindFirstChild("ConfirmButton") :: TextButton?
	tabBar = window:FindFirstChild("TabBar") :: Frame?
	contentPanel = window:FindFirstChild("ContentPanel") :: Frame?
	if contentPanel then
		tabHeader = contentPanel:FindFirstChild("TabHeader") :: TextLabel?
	end

	local function ShowTab(idx: number)
		local data = TAB_DATA[idx]
		if not data or not tabHeader or not tabBar or not contentPanel then return end

		tabHeader.Text = data.Header

		for t = 1, 4 do
			local tBtn = tabBar:FindFirstChild("Tab_" .. t)
			if tBtn and tBtn:IsA("TextButton") then
				tBtn.BackgroundColor3 = (t == idx) and Color3.fromRGB(0, 150, 190) or Color3.fromRGB(25, 32, 44)
			end
		end

		for r = 1, 6 do
			local row = contentPanel:FindFirstChild("KeybindRow_" .. r)
			if row then
				local rowData = data.Rows[r]
				if rowData then
					local badge = row:FindFirstChild("KeyBadge") :: TextLabel?
					local desc = row:FindFirstChild("KeyDesc") :: TextLabel?
					if badge then badge.Text = rowData.key end
					if desc then desc.Text = rowData.desc end
					row.Visible = true
				else
					row.Visible = false
				end
			end
		end
	end

	if tabBar then
		for i = 1, 4 do
			local tabBtn = tabBar:FindFirstChild("Tab_" .. i)
			if tabBtn and tabBtn:IsA("TextButton") then
				tabBtn.Activated:Connect(function()
					ShowTab(i)
				end)
			end
		end
	end

	if closeBtn then
		closeBtn.Activated:Connect(function()
			if backdrop then backdrop.Visible = false end
		end)
	end

	if confirmBtn then
		confirmBtn.Activated:Connect(function()
			if backdrop then backdrop.Visible = false end
		end)
	end

	isInitialized = true
	return true
end

function StarterGuideController.Init()
	EnsureUI()
	if backdrop then backdrop.Visible = false end

	ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
		if who ~= localPlayer then return end
		local act = prompt.ActionText:lower()
		if act == "seek guidance" or (prompt.Parent and prompt.Parent.Name == "Sect_NPC_ElderQing") then
			if EnsureUI() and backdrop then
				backdrop.Visible = true
			end
		end
	end)

	print("[ASCEND] StarterGuideController Initialized.")
end

return StarterGuideController