--!strict
--[[
    WeaponManager.luau
    Location: src/ServerScriptService/Server/Combat/WeaponManager.luau
    Master 3D Weapon & Back Armor Attachment Engine.
    Studio-Authoritative Grip Engine: Reads RightGripAttachment positioned in Studio.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)

export type WeaponType = "FlyingSword" | "BackArmor"

export type BackArmorStats = {
	MaxHPBonus: number,
	DefPercentBonus: number,
	QiRegenBonus: number,
}

local WeaponManager = {}
local equippedWeapons: { [Player]: string } = {}
local equippedBackArmors: { [Player]: string } = {}
local updateSkillStateRemote: RemoteEvent

function WeaponManager.Init()
	updateSkillStateRemote = RemoteEvents.GetRemote("UpdateSkillState")

	Players.PlayerAdded:Connect(function(player)
		equippedWeapons[player] = "SunSlayerCrimsonSword"
		equippedBackArmors[player] = "SunSlayerCrimsonCrestArray"

		player.CharacterAdded:Connect(function(character)
			task.wait(0.3)
			WeaponManager.AttachWeaponModel(player, equippedWeapons[player] or "SunSlayerCrimsonSword")
			WeaponManager.AttachBackArmor(player, equippedBackArmors[player] or "SunSlayerCrimsonCrestArray")
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		equippedWeapons[player] = nil
		equippedBackArmors[player] = nil
	end)

	local combatActionRemote = RemoteEvents.GetRemote("CombatAction")
	combatActionRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) == "table" then
			if payload.RequestWeaponSwap then
				WeaponManager.EquipWeapon(player, payload.RequestWeaponSwap)
			elseif payload.RequestBackArmorSwap then
				WeaponManager.EquipBackArmor(player, payload.RequestBackArmorSwap)
			end
		end
	end)

	print("[ASCEND] WeaponManager Studio-Authoritative Grip Engine Initialized.")
end

function WeaponManager.GetEquippedWeapon(player: Player): string
	return equippedWeapons[player] or "SunSlayerCrimsonSword"
end

function WeaponManager.GetEquippedBackArmor(player: Player): string
	return equippedBackArmors[player] or "SunSlayerCrimsonCrestArray"
end

function WeaponManager.GetBackArmorStats(player: Player): BackArmorStats
	local armorId = equippedBackArmors[player]
	local itemData = if armorId then ItemConfig[armorId] else nil

	if itemData then
		local rawItem: any = itemData
		local statBonus = rawItem.StatBonus
		if type(statBonus) == "table" then
			return {
				MaxHPBonus = typeof(statBonus.MaxHP) == "number" and statBonus.MaxHP or 0,
				DefPercentBonus = typeof(statBonus.DefPercent) == "number" and statBonus.DefPercent or 0,
				QiRegenBonus = typeof(statBonus.QiRegen) == "number" and statBonus.QiRegen or 0,
			}
		end
	end

	return { MaxHPBonus = 0, DefPercentBonus = 0, QiRegenBonus = 0 }
end

local function WeldModelAssembly(model: Model, primaryPart: BasePart)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant ~= primaryPart then
			descendant.CanCollide = false
			descendant.Massless = true
			
			local weld = Instance.new("WeldConstraint")
			weld.Name = "AssemblyWeld_" .. descendant.Name
			weld.Part0 = primaryPart
			weld.Part1 = descendant
			weld.Parent = descendant
		end
	end
end

local function EnableModelEffects(modelInst: Instance)
	for _, desc in ipairs(modelInst:GetDescendants()) do
		if desc:IsA("ParticleEmitter") then
			desc.Enabled = true
		elseif desc:IsA("Light") then
			desc.Enabled = true
		end
	end
end

-- ============================================================================
-- 1. HAND FLYING SWORD ATTACHMENT (STUDIO AUTHORITATIVE GRIP)
-- ============================================================================
function WeaponManager.AttachWeaponModel(player: Player, weaponItemId: string)
	local character = player.Character
	if not character then return end

	local foundHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not foundHand or not foundHand:IsA("BasePart") then return end
	local rightHand: BasePart = foundHand :: BasePart

	-- Clean up old weapon & old grip motor
	local oldWeapon = character:FindFirstChild("Equipped3DWeapon")
	if oldWeapon then oldWeapon:Destroy() end

	local oldGripRight = rightHand:FindFirstChild("WeaponGrip")
	if oldGripRight then oldGripRight:Destroy() end

	local itemData = ItemConfig[weaponItemId]
	local modelName = if itemData and itemData.ModelName then itemData.ModelName else "Sun-Slayer Crimson Sword"

	-- Search model template in ReplicatedStorage
	local weaponTemplate: Instance? = ReplicatedStorage:FindFirstChild(modelName)
		or ReplicatedStorage:FindFirstChild("Sun-Slayer Crimson Sword")
		or ReplicatedStorage:FindFirstChild("FlyingSword")

	if not weaponTemplate then
		local weaponsFolder = ReplicatedStorage:FindFirstChild("Weapons")
		if weaponsFolder then
			weaponTemplate = weaponsFolder:FindFirstChild(modelName)
		end
	end

	local weaponInstance: Instance? = nil
	local handle: BasePart? = nil

	if weaponTemplate then
		local cloned = weaponTemplate:Clone()
		cloned.Name = "Equipped3DWeapon"

		for _, scriptInst in ipairs(cloned:GetDescendants()) do
			if scriptInst:IsA("LuaSourceContainer") then
				scriptInst:Destroy()
			end
		end

		if cloned:IsA("Model") then
			local modelInst = cloned :: Model
			local primary = modelInst.PrimaryPart 
				or (modelInst:FindFirstChild("Mesh1.0") :: BasePart?)
				or (modelInst:FindFirstChild("Handle") :: BasePart?)
				or (modelInst:FindFirstChildOfClass("MeshPart") :: BasePart?)
				or (modelInst:FindFirstChildOfClass("BasePart") :: BasePart?)

			if primary then
				handle = primary
				modelInst.PrimaryPart = primary
				WeldModelAssembly(modelInst, primary)
			end
		elseif cloned:IsA("BasePart") then
			handle = cloned :: BasePart
		end

		weaponInstance = cloned
	end

	if not handle or not weaponInstance then return end
	local activeHandle: BasePart = handle :: BasePart
	local activeWeapon: Instance = weaponInstance :: Instance

	activeHandle.CanCollide = false
	activeHandle.Massless = true

	-- Enable embedded particles & lights
	EnableModelEffects(activeWeapon)

	-- 1. Read Arm Palm Attachment
	local armGrip = rightHand:FindFirstChild("RightGripAttachment")
	local c0CFrame = if armGrip and armGrip:IsA("Attachment") 
		then (armGrip :: Attachment).CFrame 
		else (CFrame.new(0, -0.25, 0) * CFrame.Angles(-math.pi/2, 0, 0))

	-- 2. Read Studio-placed RightGripAttachment directly from the sword model
	local customGripAtt = activeHandle:FindFirstChild("RightGripAttachment")
		or activeHandle:FindFirstChild("Grip")
		or activeWeapon:FindFirstChild("RightGripAttachment", true)
		or activeWeapon:FindFirstChild("Grip", true)

	local gripCFrame: CFrame
	if customGripAtt and customGripAtt:IsA("Attachment") then
		gripCFrame = (customGripAtt :: Attachment).CFrame
		print(string.format("[WeaponManager] Using Studio-placed RightGripAttachment on '%s'.", activeWeapon.Name))
	else
		-- Fallback offset if model lacks RightGripAttachment
		gripCFrame = if itemData and itemData.GripOffset then itemData.GripOffset else CFrame.new(0, 0, 0)
	end

	-- Connect Motor6D Joint
	local motor = Instance.new("Motor6D")
	motor.Name = "WeaponGrip"
	motor.Part0 = rightHand
	motor.Part1 = activeHandle
	motor.C0 = c0CFrame
	motor.C1 = gripCFrame
	motor.Parent = rightHand

	activeWeapon.Parent = character
	print(string.format("[WeaponManager] Equipped '%s' to %s using Studio Grip Attachment.", activeWeapon.Name, player.Name))
end

-- ============================================================================
-- 2. 3D BACK ARMOR ATTACHMENT
-- ============================================================================
function WeaponManager.AttachBackArmor(player: Player, armorItemId: string)
	local character = player.Character
	if not character then return end

	local torsoPart = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not torsoPart or not torsoPart:IsA("BasePart") then return end
	local torso: BasePart = torsoPart :: BasePart

	-- Clean up previous Back Armor
	local oldArmor = character:FindFirstChild("EquippedBackArmor")
	if oldArmor then oldArmor:Destroy() end

	local itemData = ItemConfig[armorItemId]
	local modelName = if itemData and itemData.ModelName then itemData.ModelName else "Sun-Slayer Crimson Crest Array"

	-- Search ReplicatedStorage for actual custom 3D Back Armor Model
	local armorTemplate: Instance? = ReplicatedStorage:FindFirstChild(modelName)
		or ReplicatedStorage:FindFirstChild("Sun-Slayer Crimson Crest Array")
		or ReplicatedStorage:FindFirstChild("BasicBackCrest")

	if not armorTemplate then
		local armorsFolder = ReplicatedStorage:FindFirstChild("Armors")
		if armorsFolder then
			armorTemplate = armorsFolder:FindFirstChild(modelName)
		end
	end

	if armorTemplate then
		local cloned = armorTemplate:Clone()
		cloned.Name = "EquippedBackArmor"

		for _, scriptInst in ipairs(cloned:GetDescendants()) do
			if scriptInst:IsA("LuaSourceContainer") then
				scriptInst:Destroy()
			end
		end

		local primaryPart: BasePart? = nil
		if cloned:IsA("Model") then
			local mInst = cloned :: Model
			primaryPart = mInst.PrimaryPart 
				or (mInst:FindFirstChild("Mesh1.0") :: BasePart?)
				or (mInst:FindFirstChildOfClass("MeshPart") :: BasePart?)
				or (mInst:FindFirstChildOfClass("BasePart") :: BasePart?)

			if primaryPart then
				mInst.PrimaryPart = primaryPart
				WeldModelAssembly(mInst, primaryPart)
			end
		elseif cloned:IsA("BasePart") then
			primaryPart = cloned :: BasePart
		end

		if primaryPart then
			primaryPart.CanCollide = false
			primaryPart.Massless = true

			EnableModelEffects(cloned)

			-- Read Studio-placed BodyBackAttachment or BackAttachment if present
			local customBackAtt = primaryPart:FindFirstChild("BodyBackAttachment")
				or primaryPart:FindFirstChild("BackAttachment")
				or cloned:FindFirstChild("BodyBackAttachment", true)

			local backOffset: CFrame
			if customBackAtt and customBackAtt:IsA("Attachment") then
				backOffset = (customBackAtt :: Attachment).CFrame
			else
				backOffset = if itemData and itemData.GripOffset then itemData.GripOffset else CFrame.new(0, 2.0, 1.2)
			end

			local motor = Instance.new("Motor6D")
			motor.Name = "BackArmorMotor"
			motor.Part0 = torso
			motor.Part1 = primaryPart
			motor.C0 = CFrame.new(0, 0, 0)
			motor.C1 = backOffset:Inverse()
			motor.Parent = torso

			cloned.Parent = character
			equippedBackArmors[player] = armorItemId
			print(string.format("[WeaponManager] Attached 3D Back Crest Array '%s' to %s.", cloned.Name, player.Name))
			return
		end
	end
end

function WeaponManager.EquipWeapon(player: Player, weaponItemId: string)
	local character = player.Character
	if not character then return end

	character:SetAttribute("WeaponType", "FlyingSword")
	equippedWeapons[player] = weaponItemId

	WeaponManager.AttachWeaponModel(player, weaponItemId)

	local skillIcons = {
		M1 = UIAssets.Skills.M1_SwordArt,
		F = UIAssets.Skills.M2_HeavySlam,
		Q = UIAssets.Skills.SwordTempest,
		E = UIAssets.Skills.DragonRoar,
		R = UIAssets.Skills.TribulationBolt,
		Shift = UIAssets.Skills.DodgeWindstep,
	}

	updateSkillStateRemote:FireClient(player, "FlyingSword", skillIcons)
end

function WeaponManager.EquipBackArmor(player: Player, armorItemId: string)
	equippedBackArmors[player] = armorItemId
	WeaponManager.AttachBackArmor(player, armorItemId)
end

return WeaponManager