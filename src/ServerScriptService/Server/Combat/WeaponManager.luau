--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponManager = {}
local weaponsFolder = ReplicatedStorage:WaitForChild("Weapons") :: Folder

-- Cache active sword per player
local activeWeapons: { [Player]: { Model: MeshPart?, CurrentState: string, WeaponId: string } } = {}

-- Snap Sword to Hand (Right Arm.RightGripAttachment)
local function SnapToHand(character: Model, sword: MeshPart)
	local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand") :: BasePart?
	if not rightArm then return end

	local handAtt = rightArm:FindFirstChild("RightGripAttachment") :: Attachment?
	local swordAtt = sword:FindFirstChild("SwordAttachment") :: Attachment?

	if handAtt and swordAtt then
		-- Automatically enforce zero-jitter physics properties
		sword.Anchored = false
		sword.CanCollide = false
		sword.CanTouch = false
		sword.CanQuery = false
		sword.Massless = true

		-- Remove old constraint to prevent conflicts
		local existingConstraint = sword:FindFirstChildOfClass("RigidConstraint") 
			or sword:FindFirstChildOfClass("AnimationConstraint")
		if existingConstraint then existingConstraint:Destroy() end

		local constraint = Instance.new("RigidConstraint")
		constraint.Name = "WeaponGripConstraint"
		constraint.Attachment0 = handAtt
		constraint.Attachment1 = swordAtt
		constraint.Parent = sword
	end
end

-- Set Weapon State: "Hand" | "Hidden"
function WeaponManager.SetWeaponState(player: Player, state: "Hand" | "Hidden")
	local character = player.Character
	if not character then return end

	local weaponData = activeWeapons[player]
	if not weaponData or not weaponData.Model then return end

	local sword = weaponData.Model
	weaponData.CurrentState = state

	if state == "Hidden" then
		sword.Transparency = 1
		local trail = sword:FindFirstChildOfClass("Trail")
		if trail then trail.Enabled = false end
	elseif state == "Hand" then
		sword.Transparency = 0
		SnapToHand(character, sword)
	end
end

-- Equip Sword by ID from ReplicatedStorage.Weapons
function WeaponManager.EquipWeapon(player: Player, weaponId: string)
	local character = player.Character
	if not character then return end

	-- Cleanup existing sword
	if activeWeapons[player] and activeWeapons[player].Model then
		activeWeapons[player].Model:Destroy()
		activeWeapons[player] = nil
	end

	local template = weaponsFolder:FindFirstChild(weaponId) :: MeshPart?
	if not template then
		template = weaponsFolder:FindFirstChild("AzureCloudDiscipleJian") or weaponsFolder:FindFirstChild("MortalIronJian") :: MeshPart?
		if not template then
			warn("[WeaponManager] No template found in ReplicatedStorage.Weapons for:", weaponId)
			return
		end
		weaponId = template.Name
	end

	local swordClone = template:Clone()
	swordClone.Name = "EquippedSword"
	swordClone.Anchored = false
	swordClone.CanCollide = false
	swordClone.CanTouch = false
	swordClone.CanQuery = false
	swordClone.Massless = true
	swordClone.Parent = character

	activeWeapons[player] = {
		Model = swordClone,
		CurrentState = "Hand",
		WeaponId = weaponId,
	}

	SnapToHand(character, swordClone)
end

function WeaponManager.SetWeaponVisibility(player: Player, isVisible: boolean)
	WeaponManager.SetWeaponState(player, if isVisible then "Hand" else "Hidden")
end

function WeaponManager.Init()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid")
			local rightArm = character:WaitForChild("Right Arm", 5) or character:WaitForChild("RightHand", 5)
			if rightArm then
				task.wait(0.1)
				-- Equips Azure Cloud Disciple Jian on spawn for testing
				WeaponManager.EquipWeapon(player, "AzureCloudDiscipleJian")
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		activeWeapons[player] = nil
	end)
end

return WeaponManager