--!strict
--[[
    WeaponManager.luau
    Location: src/ServerScriptService/Server/Combat/WeaponManager.luau
    Server-authoritative manager for equipping, welding, scaling, and activating weapon models.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)

export type WeaponType = string

local WeaponManager = {}

local equippedWeaponsMap: { [Player]: string } = {}
local spawnedWeaponModels: { [Player]: Model } = {}

-- Standardized maximum bounding box dimensions for character hand weapons
local TARGET_MAX_WEAPON_SIZE = Vector3.new(1.5, 6.0, 1.5)

-- Helper: Recursive model lookup across ReplicatedStorage & ServerStorage
local function FindWeaponModelTemplate(modelName: string): Model?
	local found = ReplicatedStorage:FindFirstChild(modelName, true)
	if not found then
		found = ServerStorage:FindFirstChild(modelName, true)
	end

	if found and found:IsA("Model") then
		return found :: Model
	end
	return nil
end

-- Helper: Automatically enable embedded particle emitters, beams, and trails
local function EnableWeaponEffects(model: Model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Beam") then
			descendant.Enabled = true
		end
	end
end

-- Helper: Normalize model size to standard weapon bounds
local function NormalizeWeaponBounds(model: Model)
	local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if not primary then
		return
	end

	local _, currentSize = model:GetBoundingBox()
	if currentSize.X <= 0 or currentSize.Y <= 0 or currentSize.Z <= 0 then
		return
	end

	local scaleX = TARGET_MAX_WEAPON_SIZE.X / currentSize.X
	local scaleY = TARGET_MAX_WEAPON_SIZE.Y / currentSize.Y
	local scaleZ = TARGET_MAX_WEAPON_SIZE.Z / currentSize.Z

	-- Select conservative scaling factor to avoid distorting proportions
	local uniformScale = math.min(scaleX, math.min(scaleY, scaleZ))

	if uniformScale > 0 and math.abs(uniformScale - 1) > 0.05 then
		model:ScaleTo(uniformScale)
	end
end

function WeaponManager.GetEquippedWeapon(player: Player): string
	return equippedWeaponsMap[player] or "FlyingSwordItem"
end

function WeaponManager.UnequipWeapon(player: Player)
	local existingModel = spawnedWeaponModels[player]
	if existingModel then
		existingModel:Destroy()
		spawnedWeaponModels[player] = nil
	end
	equippedWeaponsMap[player] = "None"

	if player.Character then
		player.Character:SetAttribute("EquippedWeapon", "None")
	end
end

function WeaponManager.EquipWeapon(player: Player, itemId: string): boolean
	local itemData = ItemConfig.GetItem(itemId)
	if not itemData then
		warn(string.format("[WeaponManager] Cannot equip unknown item ID: %s", tostring(itemId)))
		return false
	end

	local character = player.Character
	if not character or not character:FindFirstChild("Humanoid") then
		return false
	end

	-- Unequip existing active model
	WeaponManager.UnequipWeapon(player)

	local modelName = itemData.ModelName or itemId
	local templateModel = FindWeaponModelTemplate(modelName)

	if not templateModel then
		-- Fallback search for default FlyingSword if specific item mesh is not loaded in place
		templateModel = FindWeaponModelTemplate("FlyingSword")
	end

	if templateModel then
		local weaponClone = templateModel:Clone()
		weaponClone.Name = "Equipped_" .. itemId

		-- Ensure model has a valid PrimaryPart
		if not weaponClone.PrimaryPart then
			weaponClone.PrimaryPart = weaponClone:FindFirstChildWhichIsA("BasePart")
		end

		if weaponClone.PrimaryPart then
			-- 1. Bounds Scale Normalization
			NormalizeWeaponBounds(weaponClone)

			-- 2. Embedded Particle Activation
			EnableWeaponEffects(weaponClone)

			-- 3. Weld to Character Right Hand
			local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
			if rightHand then
				weaponClone.PrimaryPart.CFrame = (rightHand :: BasePart).CFrame
				weaponClone.PrimaryPart.CanCollide = false
				weaponClone.PrimaryPart.Anchored = false

				local weld = Instance.new("WeldConstraint")
				weld.Name = "WeaponWeld"
				weld.Part0 = rightHand :: BasePart
				weld.Part1 = weaponClone.PrimaryPart
				weld.Parent = weaponClone.PrimaryPart

				weaponClone.Parent = character
				spawnedWeaponModels[player] = weaponClone
			end
		end
	end

	equippedWeaponsMap[player] = itemId
	character:SetAttribute("EquippedWeapon", itemId)
	print(string.format("[WeaponManager] Equipped %s on %s.", itemData.Name, player.Name))

	return true
end

function WeaponManager.Init()
	Players.PlayerRemoving:Connect(function(player)
		equippedWeaponsMap[player] = nil
		if spawnedWeaponModels[player] then
			spawnedWeaponModels[player]:Destroy()
			spawnedWeaponModels[player] = nil
		end
	end)

	print("[WeaponManager] Engine Initialized.")
end

return WeaponManager