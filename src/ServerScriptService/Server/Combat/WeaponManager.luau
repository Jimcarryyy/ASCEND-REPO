--!strict
--[[
    WeaponManager.luau
    Location: src/ServerScriptService/Server/Combat/WeaponManager.luau
    Server-side equipment manager for ASCEND.
    Attaches Pure Flying Sword models to character Right Arm (R6) or RightHand (R15)
    with dynamic rig detection, CFrame orientation, and Massless physics safeguards.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)

local WeaponManager = {}

export type WeaponType = "FlyingSword" | "Spear" | "Gauntlet"

local equippedWeapons: { [Player]: WeaponType } = {}

function WeaponManager.Init()
	print("[WeaponManager] Engine Initialized with Dual R6/R15 Rig Detection & Massless Physics.")
end

function WeaponManager.GetEquippedWeapon(player: Player): WeaponType
	return equippedWeapons[player] or "FlyingSword"
end

function WeaponManager.SetWeaponVisibility(player: Player, visible: boolean)
	local character = player.Character
	if not character then return end

	local swordModel = character:FindFirstChild("EquippedFlyingSword")
	if swordModel then
		for _, part in ipairs(swordModel:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = if visible then 0 else 1
			elseif part:IsA("ParticleEmitter") or part:IsA("Light") then
				part.Enabled = visible
			end
		end
	end
end

function WeaponManager.EquipWeapon(player: Player, weaponItemName: string)
	local character = player.Character
	if not character then return end

	-- Dynamic Rig Detection: R6 uses 'Right Arm', R15 uses 'RightHand'
	local rightHand = (character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand")) :: BasePart?
	if not rightHand then return end

	local isR6 = (rightHand.Name == "Right Arm")

	-- Remove existing equipped sword
	local existingSword = character:FindFirstChild("EquippedFlyingSword")
	if existingSword then
		existingSword:Destroy()
	end

	-- Get item definition from ItemConfig
	local itemDef = ItemConfig.GetItem(weaponItemName)
	local modelName = if itemDef and itemDef.ModelName then itemDef.ModelName else "Master_FlyingSword_Tier1"

	local masterModel = ReplicatedStorage:FindFirstChild(modelName)
	if not masterModel or not masterModel:IsA("Model") then
		-- Fallback to Master_FlyingSword_Tier1
		masterModel = ReplicatedStorage:FindFirstChild("Master_FlyingSword_Tier1") :: Model?
	end

	if not masterModel then return end

	local swordClone = masterModel:Clone()
	swordClone.Name = "EquippedFlyingSword"

	local handle = swordClone:FindFirstChild("Handle") :: BasePart? or swordClone.PrimaryPart
	if not handle then
		for _, part in ipairs(swordClone:GetChildren()) do
			if part:IsA("BasePart") then
				handle = part
				break
			end
		end
	end

	if not handle then return end

	-- Apply Physics Safeguards: Massless = true, CanCollide = false
	for _, part in ipairs(swordClone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
		end
	end

	-- Apply ItemConfig Scale & Tint if specified
	if itemDef then
		if itemDef.Scale then
			swordClone:ScaleTo(itemDef.Scale.Y or 1.0)
		end
		if itemDef.ParticleTint then
			for _, emitter in ipairs(swordClone:GetDescendants()) do
				if emitter:IsA("ParticleEmitter") then
					emitter.Color = ColorSequence.new(itemDef.ParticleTint)
				end
			end
		end
	end

	swordClone.Parent = character

	-- CFrame Offset:
	-- R6 Right Arm offset: (0, -1.0, 0)
	-- R15 RightHand offset: (0, -0.8, -0.2)
	local offsetVector = if isR6 then Vector3.new(0, -1.0, 0) else Vector3.new(0, -0.8, -0.2)
	handle.CFrame = rightHand.CFrame * CFrame.new(offsetVector) * CFrame.Angles(math.rad(-90), 0, 0)

	local weld = Instance.new("WeldConstraint")
	weld.Name = "SwordWeldConstraint"
	weld.Part0 = rightHand
	weld.Part1 = handle
	weld.Parent = handle

	equippedWeapons[player] = "FlyingSword"
	print(string.format("[WeaponManager] Equipped %s on %s (%s Rig).", weaponItemName, player.Name, if isR6 then "R6" else "R15"))
end

return WeaponManager