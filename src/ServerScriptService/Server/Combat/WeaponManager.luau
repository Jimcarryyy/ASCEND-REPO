--!strict
--[[\n    WeaponManager.luau\n    Location: src/ServerScriptService/Server/Combat/WeaponManager.luau\n    Server-authoritative weapon lifecycle manager:\n      - Classic Upper Back Sword Sheath Mount (CFrame 0, 0.35, 0.68, 135 deg).\n      - Dual NewWeapons / Weapons lookup pipeline with normalized string matching.\n      - Preservation of AnimationConstraint on weapon models.\n      - Replaces LeftFootAttachment for flight mounting.\n      - RigidConstraint + AnimationConstraint flight mounting.\n      - Hides combat sword during flight to eliminate visual clutter.\n      - Dynamic Realm-Scaled Flight Speed & In-Combat Mount Gate.\n]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")

local FlyingSwordConfig = require(ReplicatedStorage.Shared.Configs.Weapons.FlyingSwordConfig)

local WeaponManager = {}

-- Audio IDs
local SWORD_EQUIP_SOUND_ID   = "rbxassetid://114060318185092"
local SWORD_UNEQUIP_SOUND_ID = "rbxassetid://97568182472477"

type WeaponData = {
	Model: Instance?,
	SwordMesh: MeshPart?,
	CurrentState: "Hand" | "Back" | "Hidden",
	WeaponId: string,
}

local activeCombatWeapons: { [Player]: WeaponData } = {}
local activeFlightSwords: { [Player]: Model } = {}

local function Play3DWeaponSound(character: Model, soundId: string)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.75
	sound.RollOffMaxDistance = 60
	sound.RollOffMinDistance = 5
	sound.Parent = hrp
	sound:Play()

	Debris:AddItem(sound, 2.0)
end

local function ClearExistingGripConstraints(part: Instance)
	for _, desc in ipairs(part:GetDescendants()) do
		if desc.Name == "WeaponGripConstraint" or desc:IsA("RigidConstraint") or desc:IsA("WeldConstraint") then
			desc:Destroy()
		end
	end
end

local function SnapToHand(character: Model, swordMesh: MeshPart)
	local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand") :: BasePart?
	if not rightArm then return end

	local handAtt = rightArm:FindFirstChild("RightGripAttachment") :: Attachment?
	if not handAtt then
		handAtt = Instance.new("Attachment")
		handAtt.Name = "RightGripAttachment"
		handAtt.CFrame = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0)
		handAtt.Parent = rightArm
	end

	local swordAtt = swordMesh:FindFirstChild("SwordAttachment") :: Attachment?
	if not swordAtt then
		swordAtt = (swordMesh:FindFirstChild("FeetAttachment") or swordMesh:FindFirstChildWhichIsA("Attachment")) :: Attachment?
		if not swordAtt then
			swordAtt = Instance.new("Attachment")
			swordAtt.Name = "SwordAttachment"
			swordAtt.CFrame = CFrame.new(0, 0, 0)
			swordAtt.Parent = swordMesh
		end
	end

	swordMesh.Anchored = false
	swordMesh.CanCollide = false
	swordMesh.Massless = true

	ClearExistingGripConstraints(swordMesh)

	local constraint = Instance.new("RigidConstraint")
	constraint.Name = "WeaponGripConstraint"
	constraint.Attachment0 = handAtt
	constraint.Attachment1 = swordAtt
	constraint.Parent = swordMesh
end

-- Sheathed on the Upper Back (Classic Cultivator Back Mount)
local function SnapToBack(character: Model, swordMesh: MeshPart)
	local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") :: BasePart?
	if not torso then return end

	local torsoBackAtt = torso:FindFirstChild("BackSwordMount") :: Attachment?
	if not torsoBackAtt then
		torsoBackAtt = Instance.new("Attachment")
		torsoBackAtt.Name = "BackSwordMount"
		torsoBackAtt.CFrame = CFrame.new(0, 0.35, 0.68) * CFrame.Angles(0, 0, math.rad(135))
		torsoBackAtt.Parent = torso
	else
		torsoBackAtt.CFrame = CFrame.new(0, 0.35, 0.68) * CFrame.Angles(0, 0, math.rad(135))
	end

	local swordAtt = (swordMesh:FindFirstChild("BackSwordAttachment") or swordMesh:FindFirstChild("SwordAttachment") or swordMesh:FindFirstChildWhichIsA("Attachment")) :: Attachment?
	if not swordAtt then
		swordAtt = Instance.new("Attachment")
		swordAtt.Name = "BackSwordAttachment"
		swordAtt.CFrame = CFrame.new(0, 0, 0)
		swordAtt.Parent = swordMesh
	end

	swordMesh.Anchored = false
	swordMesh.CanCollide = false
	swordMesh.Massless = true

	ClearExistingGripConstraints(swordMesh)

	local constraint = Instance.new("RigidConstraint")
	constraint.Name = "WeaponGripConstraint"
	constraint.Attachment0 = torsoBackAtt
	constraint.Attachment1 = swordAtt
	constraint.Parent = swordMesh
end

local function NormalizeWeaponKey(name: string): string
	return name:gsub("^%d+%.%s*", ""):gsub("[%s%-_.]+", ""):lower()
end

local function InspectWeaponCandidate(candidate: Instance): (Instance?, MeshPart?)
	if candidate:IsA("MeshPart") then
		return candidate, candidate
	elseif candidate:IsA("Model") then
		local mesh = candidate:FindFirstChildWhichIsA("MeshPart", true)
		if mesh then return candidate, mesh end
	end
	return nil, nil
end

local function FindCombatWeaponTemplate(weaponId: string): (Instance?, MeshPart?)
	local weaponsFolder = ReplicatedStorage:FindFirstChild("Weapons") :: Folder?
	if not weaponsFolder then return nil, nil end

	local searchFolders: { Folder } = {}
	local newWeapons = weaponsFolder:FindFirstChild("NewWeapons") :: Folder?
	if newWeapons and newWeapons:IsA("Folder") then
		table.insert(searchFolders, newWeapons)
	end
	table.insert(searchFolders, weaponsFolder)

	-- 1. Exact Name match across search folders
	for _, folder in ipairs(searchFolders) do
		local exact = folder:FindFirstChild(weaponId)
		if exact then
			local root, mesh = InspectWeaponCandidate(exact)
			if root and mesh then return root, mesh end
		end
	end

	local targetNorm = NormalizeWeaponKey(weaponId)

	-- 2. Normalized match (e.g. "IronReed" matches "1.Iron Reed", "HeavenPiercing" matches "10.Heaven-Piercing")
	for _, folder in ipairs(searchFolders) do
		for _, child in ipairs(folder:GetChildren()) do
			if NormalizeWeaponKey(child.Name) == targetNorm then
				local root, mesh = InspectWeaponCandidate(child)
				if root and mesh then return root, mesh end
			end
		end
	end

	-- 3. Fallback to first available weapon model in NewWeapons or Weapons
	for _, folder in ipairs(searchFolders) do
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("Model") or child:IsA("MeshPart") then
				local root, mesh = InspectWeaponCandidate(child)
				if root and mesh then return root, mesh end
			end
		end
	end

	return nil, nil
end

function WeaponManager.SetWeaponState(player: Player, state: "Hand" | "Back" | "Hidden", suppressAudio: boolean?)
	local character = player.Character
	if not character then return end

	local weaponData = activeCombatWeapons[player]
	if not weaponData or not weaponData.SwordMesh then return end

	local swordMesh = weaponData.SwordMesh
	weaponData.CurrentState = state

	local trail = swordMesh:FindFirstChildOfClass("Trail")

	if state == "Hidden" then
		swordMesh.Transparency = 1
		if trail then trail.Enabled = false end
	elseif state == "Hand" then
		swordMesh.Transparency = 0
		if trail then trail.Enabled = false end
		SnapToHand(character, swordMesh)
		character:SetAttribute("IsWeaponDrawn", true)
		if not suppressAudio then Play3DWeaponSound(character, SWORD_EQUIP_SOUND_ID) end
	elseif state == "Back" then
		swordMesh.Transparency = 0
		if trail then trail.Enabled = false end
		SnapToBack(character, swordMesh)
		character:SetAttribute("IsWeaponDrawn", false)
		if not suppressAudio then Play3DWeaponSound(character, SWORD_UNEQUIP_SOUND_ID) end
	end
end

function WeaponManager.ToggleSheath(player: Player)
	local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
	local pData = CultivationManager.GetPlayerData(player)
	if pData and pData.IsMeditating then return end

	local character = player.Character
	if character and character:GetAttribute("IsFlying") == true then return end

	local weaponData = activeCombatWeapons[player]
	if not weaponData then return end

	if weaponData.CurrentState == "Hand" then
		WeaponManager.SetWeaponState(player, "Back")
	else
		WeaponManager.SetWeaponState(player, "Hand")
	end
end

function WeaponManager.GetEquippedWeapon(player: Player): string
	local weaponData = activeCombatWeapons[player]
	return (weaponData and weaponData.WeaponId) or "IronReed"
end

function WeaponManager.GetWeaponState(player: Player): string
	local weaponData = activeCombatWeapons[player]
	return (weaponData and weaponData.CurrentState) or "Hand"
end

function WeaponManager.EquipWeapon(player: Player, weaponId: string, initialState: ("Hand" | "Back")?)
	local character = player.Character
	if not character then return end

	if activeCombatWeapons[player] and activeCombatWeapons[player].Model then
		activeCombatWeapons[player].Model:Destroy()
		activeCombatWeapons[player] = nil
	end

	local templateRoot, templateMesh = FindCombatWeaponTemplate(weaponId)
	if not templateMesh then
		templateRoot, templateMesh = FindCombatWeaponTemplate("IronReed")
	end
	if not templateMesh then
		templateRoot, templateMesh = FindCombatWeaponTemplate("1.Iron Reed")
	end
	if not templateMesh then
		templateRoot, templateMesh = FindCombatWeaponTemplate("MortalIronJian")
	end

	if not templateMesh then
		warn("[WeaponManager] No combat sword found in ReplicatedStorage.Weapons or NewWeapons!")
		return
	end

	local instanceToClone = templateRoot or templateMesh
	local swordClone = instanceToClone:Clone()
	swordClone.Name = "EquippedSword"

	local swordMesh: MeshPart? = if swordClone:IsA("MeshPart") then swordClone else swordClone:FindFirstChildWhichIsA("MeshPart", true)
	if not swordMesh then return end

	swordMesh.Anchored = false
	swordMesh.CanCollide = false
	swordMesh.Massless = true

	local trail = swordMesh:FindFirstChildOfClass("Trail")
	if trail then trail.Enabled = false end

	swordClone.Parent = character

	local targetState = initialState or "Hand"
	activeCombatWeapons[player] = {
		Model = swordClone,
		SwordMesh = swordMesh,
		CurrentState = targetState,
		WeaponId = weaponId,
	}

	character:SetAttribute("EquippedWeapon", weaponId)
	WeaponManager.SetWeaponState(player, targetState)
end

function WeaponManager.ToggleFlight(player: Player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
	local pData = CultivationManager.GetPlayerData(player)
	if pData and pData.IsMeditating then return end

	local CombatStateManager = require(ServerScriptService.Server.State.CombatStateManager)

	local isCurrentlyFlying = (character:GetAttribute("IsFlying") == true)
	if not isCurrentlyFlying then
		if CombatStateManager.IsInCombat and CombatStateManager.IsInCombat(player) then
			print(string.format("⚔️ [%s] Cannot mount Flying Sword while In Combat!", player.Name))
			return
		end

		if (pData and pData.CurrentQi or 0) <= 10 then
			print(string.format("⚠️ [%s] Insufficient Qi to mount Flying Sword!", player.Name))
			return
		end
	end

	if character:GetAttribute("CCState") == "Stunned" or character:GetAttribute("CCState") == "GuardBroken" then
		return
	end

	if isCurrentlyFlying then
		character:SetAttribute("IsFlying", false)

		if activeFlightSwords[player] then
			activeFlightSwords[player]:Destroy()
			activeFlightSwords[player] = nil
		end

		WeaponManager.SetWeaponState(player, "Hand")

		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		humanoid.JumpPower = 76
		humanoid.JumpHeight = 8.5
		humanoid.WalkSpeed = (character:GetAttribute("InArena") == true) and 14 or 16

		print(string.format("🛬 [%s] Dismounted flight mode.", player.Name))
	else
		local flightTemplate = ReplicatedStorage:FindFirstChild("FlyingSword") :: Model?
		if not flightTemplate then
			warn("[WeaponManager] ReplicatedStorage.FlyingSword model not found!")
			return
		end

		local leftLeg = character:FindFirstChild("Left Leg") or character:FindFirstChild("LeftFoot") :: BasePart?
		if not leftLeg then
			warn("[WeaponManager] Character Left Leg not found for flight mount!")
			return
		end

		local flightModel = flightTemplate:Clone()
		flightModel.Name = "ActiveFlightSword"

		local flightMesh = flightModel:FindFirstChildWhichIsA("MeshPart", true)
		if not flightMesh then
			warn("[WeaponManager] No MeshPart found inside FlyingSword!")
			flightModel:Destroy()
			return
		end

		local feetAtt = flightMesh:FindFirstChild("FeetAttachment", true) :: Attachment?
		if not feetAtt then
			warn("[WeaponManager] 'FeetAttachment' not found in FlyingSword!")
			flightModel:Destroy()
			return
		end

		local customLeftAtt = flightMesh:FindFirstChild("LeftFootAttachment", true) :: Attachment?
		if not customLeftAtt then
			warn("[WeaponManager] 'LeftFootAttachment' not found in FlyingSword!")
			flightModel:Destroy()
			return
		end

		local existingAtt = leftLeg:FindFirstChild("LeftFootAttachment")
		if existingAtt then
			existingAtt:Destroy()
		end

		local leftFootAtt = customLeftAtt:Clone()
		leftFootAtt.Name = "LeftFootAttachment"
		leftFootAtt.Parent = leftLeg

		flightMesh.Anchored = false
		flightMesh.CanCollide = false
		flightMesh.Massless = true

		local rigid = Instance.new("RigidConstraint")
		rigid.Name = "FlightRigidWeld"
		rigid.Attachment0 = leftFootAtt
		rigid.Attachment1 = feetAtt
		rigid.Parent = flightMesh

		local animConstraint = flightMesh:FindFirstChildOfClass("AnimationConstraint")
		if not animConstraint then
			animConstraint = Instance.new("AnimationConstraint")
			animConstraint.Name = "FlightAnimationConstraint"
			animConstraint.Parent = flightMesh
		end
		animConstraint.Attachment0 = leftFootAtt
		animConstraint.Attachment1 = feetAtt
		animConstraint.Enabled = true

		flightModel.Parent = character
		activeFlightSwords[player] = flightModel

		WeaponManager.SetWeaponState(player, "Hidden", true)

		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0

		character:SetAttribute("IsFlying", true)

		local flightCfg = FlyingSwordConfig.Flight
		local realmFlight = if flightCfg and flightCfg.Realms and pData then flightCfg.Realms[pData.Realm] else nil
		local targetFlightSpeed = if realmFlight then realmFlight.Velocity else 50.0

		humanoid.WalkSpeed = targetFlightSpeed
		print(string.format("🚀 [%s] Mounted FlyingSword at %.1f studs/s (%s Tier).",
			player.Name, targetFlightSpeed, pData and pData.Realm or "Mortal"))
	end
end

function WeaponManager.Init()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid")
			local rightArm = character:WaitForChild("Right Arm", 5) or character:WaitForChild("RightHand", 5)
			if rightArm then
				task.wait(0.15)
				WeaponManager.EquipWeapon(player, "IronReed", "Hand")
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		if activeFlightSwords[player] then
			activeFlightSwords[player]:Destroy()
			activeFlightSwords[player] = nil
		end
		if activeCombatWeapons[player] and activeCombatWeapons[player].Model then
			activeCombatWeapons[player].Model:Destroy()
			activeCombatWeapons[player] = nil
		end
	end)

	print("[ASCEND] WeaponManager Initialized (Upper Back Sheath Mount Suite & NewWeapons Dual Pipeline Active).")
end

return WeaponManager