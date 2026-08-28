--!strict
--[[
    WeaponManager.luau
    Location: src/ServerScriptService/Server/Combat/WeaponManager.luau
    Server-authoritative weapon lifecycle manager with 3D Draw/Sheath/Equip Audio.
    Supports Hand / Back / Hidden / Flight (standing on the sword) mount states.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")

local WeaponManager = {}
local weaponsFolder = ReplicatedStorage:WaitForChild("Weapons") :: Folder

-- Audio IDs
local SWORD_EQUIP_SOUND_ID   = "rbxassetid://114060318185092" -- Draw to Hand / Equip
local SWORD_UNEQUIP_SOUND_ID = "rbxassetid://97568182472477"  -- Sheath to Back / Unequip

-- Flight mount tuning. This vertical offset is a STARTING ESTIMATE for a standard R6
-- rig (HumanoidRootPart sits roughly at hip height, ~3 studs above the feet) — not
-- pulled from any confirmed rig measurement. Nudge FLIGHT_MOUNT_OFFSET_Y if the
-- character sits inside the blade or floats above it once you test in Studio.
local FLIGHT_MOUNT_OFFSET_Y = -3

-- Cache active sword per player
local activeWeapons: { [Player]: { Model: MeshPart?, CurrentState: "Hand" | "Back" | "Hidden" | "Flight", WeaponId: string } } = {}

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

local function ClearExistingConstraint(sword: MeshPart)
	local existingConstraint = sword:FindFirstChildOfClass("RigidConstraint")
	if existingConstraint then existingConstraint:Destroy() end
end

-- Snap Sword to Hand (Right Arm.RightGripAttachment -> Sword.SwordAttachment)
local function SnapToHand(character: Model, sword: MeshPart)
	local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand") :: BasePart?
	if not rightArm then return end

	local handAtt = rightArm:FindFirstChild("RightGripAttachment") :: Attachment?
	local swordAtt = sword:FindFirstChild("SwordAttachment") :: Attachment?

	if handAtt and swordAtt then
		sword.Anchored = false
		sword.CanCollide = false
		sword.CanTouch = false
		sword.CanQuery = false
		sword.Massless = true

		ClearExistingConstraint(sword)

		local constraint = Instance.new("RigidConstraint")
		constraint.Name = "WeaponGripConstraint"
		constraint.Attachment0 = handAtt
		constraint.Attachment1 = swordAtt
		constraint.Parent = sword
	end
end

-- Snap Sword to Back (Torso.BackSwordMount -> Sword.BackSwordAttachment)
local function SnapToBack(character: Model, sword: MeshPart)
	local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") :: BasePart?
	if not torso then return end

	local torsoBackAtt = torso:FindFirstChild("BackSwordMount") :: Attachment?
	if not torsoBackAtt then
		torsoBackAtt = Instance.new("Attachment")
		torsoBackAtt.Name = "BackSwordMount"
		torsoBackAtt.CFrame = CFrame.new(0, 0.35, 0.68) * CFrame.Angles(0, 0, math.rad(135))
		torsoBackAtt.Parent = torso
	end

	local swordBackAtt = sword:FindFirstChild("BackSwordAttachment") or sword:FindFirstChild("SwordAttachment") :: Attachment?
	if not swordBackAtt then return end

	sword.Anchored = false
	sword.CanCollide = false
	sword.CanTouch = false
	sword.CanQuery = false
	sword.Massless = true

	ClearExistingConstraint(sword)

	local constraint = Instance.new("RigidConstraint")
	constraint.Name = "WeaponGripConstraint"
	constraint.Attachment0 = torsoBackAtt
	constraint.Attachment1 = swordBackAtt
	constraint.Parent = sword
end

-- Snap Sword to Feet (HumanoidRootPart.FlightMount -> Sword.FeetAttachment)
-- Sword is still massless and follows the character rigidly, same topology as
-- Hand/Back — the character's own Humanoid drives movement, the sword just
-- visually trails beneath the feet. FeetAttachment's position AND rotation
-- (set by hand in Studio, on the sword mesh) fully determine how the character
-- is oriented relative to the blade once constrained.
local function SnapToFeet(character: Model, sword: MeshPart)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local flightMountAtt = hrp:FindFirstChild("FlightMount") :: Attachment?
	if not flightMountAtt then
		flightMountAtt = Instance.new("Attachment")
		flightMountAtt.Name = "FlightMount"
		flightMountAtt.CFrame = CFrame.new(0, FLIGHT_MOUNT_OFFSET_Y, 0)
		flightMountAtt.Parent = hrp
	end

	local swordFeetAtt = sword:FindFirstChild("FeetAttachment") :: Attachment?
	if not swordFeetAtt then
		warn("[WeaponManager] No FeetAttachment found on sword:", sword.Name, "— cannot enter Flight state.")
		return
	end

	sword.Anchored = false
	sword.CanCollide = false
	sword.CanTouch = false
	sword.CanQuery = false
	sword.Massless = true

	ClearExistingConstraint(sword)

	local constraint = Instance.new("RigidConstraint")
	constraint.Name = "WeaponGripConstraint"
	constraint.Attachment0 = flightMountAtt
	constraint.Attachment1 = swordFeetAtt
	constraint.Parent = sword
end

-- Set Weapon State: "Hand" | "Back" | "Hidden" | "Flight" (Triggers 3D Audio where applicable)
function WeaponManager.SetWeaponState(player: Player, state: "Hand" | "Back" | "Hidden" | "Flight", suppressAudio: boolean?)
	local character = player.Character
	if not character then return end

	local weaponData = activeWeapons[player]
	if not weaponData or not weaponData.Model then return end

	local sword = weaponData.Model
	weaponData.CurrentState = state

	local trail = sword:FindFirstChildOfClass("Trail")

	if state == "Hidden" then
		sword.Transparency = 1
		if trail then trail.Enabled = false end
	elseif state == "Hand" then
		sword.Transparency = 0
		if trail then trail.Enabled = false end
		SnapToHand(character, sword)
		if not suppressAudio then
			Play3DWeaponSound(character, SWORD_EQUIP_SOUND_ID)
		end
	elseif state == "Back" then
		sword.Transparency = 0
		if trail then trail.Enabled = false end
		SnapToBack(character, sword)
		if not suppressAudio then
			Play3DWeaponSound(character, SWORD_UNEQUIP_SOUND_ID)
		end
	elseif state == "Flight" then
		sword.Transparency = 0
		if trail then trail.Enabled = true end -- Flight trail effect; disable here if you don't want it yet
		SnapToFeet(character, sword)
		-- No dedicated flight SFX exists yet — add one to SetWeaponState here once you have an asset ID.
	end
end

function WeaponManager.ToggleSheath(player: Player)
	local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
	local pData = CultivationManager.GetPlayerData(player)
	if pData and pData.IsMeditating then
		return
	end

	local weaponData = activeWeapons[player]
	if not weaponData then return end

	-- Flight is a separate mode from the Hand/Back sheath toggle — R while flying
	-- currently falls through to "not Hand" -> Hand. Revisit this once the V-key
	-- flight toggle exists, so R has defined behavior while flying.
	if weaponData.CurrentState == "Hand" then
		WeaponManager.SetWeaponState(player, "Back")
	else
		WeaponManager.SetWeaponState(player, "Hand")
	end
end

function WeaponManager.GetEquippedWeapon(player: Player): string
	local weaponData = activeWeapons[player]
	return (weaponData and weaponData.WeaponId) or "MortalIronJian"
end

function WeaponManager.GetWeaponState(player: Player): string
	local weaponData = activeWeapons[player]
	return (weaponData and weaponData.CurrentState) or "Hand"
end

function WeaponManager.EquipWeapon(player: Player, weaponId: string, initialState: ("Hand" | "Back")?)
	local character = player.Character
	if not character then return end

	if activeWeapons[player] and activeWeapons[player].Model then
		activeWeapons[player].Model:Destroy()
		activeWeapons[player] = nil
	end

	local template = weaponsFolder:FindFirstChild(weaponId) :: MeshPart?
	if not template then
		template = weaponsFolder:FindFirstChild("MortalIronJian") :: MeshPart?
		if not template then
			warn("[WeaponManager] No template found in ReplicatedStorage.Weapons for:", weaponId)
			return
		end
		weaponId = "MortalIronJian"
	end

	local swordClone = template:Clone()
	swordClone.Name = "EquippedSword"
	swordClone.Anchored = false
	swordClone.CanCollide = false
	swordClone.CanTouch = false
	swordClone.CanQuery = false
	swordClone.Massless = true

	local trail = swordClone:FindFirstChildOfClass("Trail")
	if trail then
		trail.Enabled = false
	end

	swordClone.Parent = character

	local targetState = initialState or "Hand"
	activeWeapons[player] = {
		Model = swordClone,
		CurrentState = targetState,
		WeaponId = weaponId,
	}

	WeaponManager.SetWeaponState(player, targetState)
end

function WeaponManager.SetWeaponVisibility(player: Player, isVisible: boolean)
	if isVisible then
		local lastState = (activeWeapons[player] and activeWeapons[player].CurrentState) or "Hand"
		if lastState == "Hidden" then lastState = "Hand" end
		WeaponManager.SetWeaponState(player, lastState, true)
	else
		WeaponManager.SetWeaponState(player, "Hidden", true)
	end
end

function WeaponManager.Init()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid")
			local rightArm = character:WaitForChild("Right Arm", 5) or character:WaitForChild("RightHand", 5)
			if rightArm then
				task.wait(0.1)
				WeaponManager.EquipWeapon(player, "MortalIronJian", "Hand")
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		activeWeapons[player] = nil
	end)

	print("[ASCEND] WeaponManager Initialized (3D Equip/Unequip SFX, Hand/Back/Flight Mounts Connected).")
end

return WeaponManager