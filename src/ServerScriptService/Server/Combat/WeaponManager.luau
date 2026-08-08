--!strict
--[[
    WeaponManager.luau
    Location: src/ServerScriptService/Server/Combat/WeaponManager.luau
    Master 3D Weapon & Back Armor Attachment Engine.
    Standardizes imported FBX bounds scale for consistent weapon sizing.
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
		equippedWeapons[player] = "MYTHIC_SUN_SLAYER_SWORD"
		equippedBackArmors[player] = "MYTHIC_SUN_SLAYER_CREST"

		player.CharacterAdded:Connect(function(character)
			task.wait(0.3)
			WeaponManager.AttachWeaponModel(player, equippedWeapons[player] or "MYTHIC_SUN_SLAYER_SWORD")
			WeaponManager.AttachBackArmor(player, equippedBackArmors[player] or "MYTHIC_SUN_SLAYER_CREST")
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

	print("[ASCEND] WeaponManager Engine Initialized with Bounds Scale Normalization.")
end

function WeaponManager.GetEquippedWeapon(player: Player): string
	return equippedWeapons[player] or "MYTHIC_SUN_SLAYER_SWORD"
end

function WeaponManager.GetEquippedBackArmor(player: Player): string
	return equippedBackArmors[player] or "MYTHIC_SUN_SLAYER_CREST"
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

-- Normalize 3D Mesh Part size bounds for consistent scale
local function NormalizeModelScale(modelInst: Instance, maxDimension: number)
	for _, desc in ipairs(modelInst:GetDescendants()) do
		if desc:IsA("MeshPart") then
			local currentSize = desc.Size
			local maxSide = math.max(currentSize.X, math.max(currentSize.Y, currentSize.Z))
			if maxSide > 12 or maxSide < 1 then
				local scaleFactor = maxDimension / math.max(0.1, maxSide)
				desc.Size = currentSize * scaleFactor
			end
		end
	end
end

-- ============================================================================
-- 1. HAND FLYING SWORD ATTACHMENT
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

	-- Search model template RECURSIVELY in ReplicatedStorage
	local weaponTemplate: Instance? = ReplicatedStorage:FindFirstChild(modelName, true)
		or ReplicatedStorage:FindFirstChild("Sun-Slayer Crimson Sword", true)
		or ReplicatedStorage:FindFirstChild("FlyingSword", true)

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

		-- Normalize sword scale to 4.5 studs max blade length
		NormalizeModelScale(cloned, 4.5)

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

	EnableModelEffects(activeWeapon)

	-- 1. Read Arm Palm Attachment
	local armGrip = rightHand:FindFirstChild("RightGripAttachment")
	local c0CFrame = if armGrip and armGrip:IsA("Attachment") 
		then (armGrip :: Attachment).CFrame 
		else (CFrame.new(0, -0.25, 0) * CFrame.Angles(-math.pi/2, 0, 0))

	-- 2. Read Studio-placed RightGripAttachment
	local customGripAtt = activeHandle:FindFirstChild("RightGripAttachment")
		or activeHandle:FindFirstChild("Grip")
		or activeWeapon:FindFirstChild("RightGripAttachment", true)
		or activeWeapon:FindFirstChild("Grip", true)

	local gripCFrame: CFrame
	if customGripAtt and customGripAtt:IsA("Attachment") then
		gripCFrame = (customGripAtt :: Attachment).CFrame
	else
		gripCFrame = if itemData and itemData.GripOffset then itemData.GripOffset else CFrame.new(-2.4, 0.7, 0) * CFrame.Angles(math.rad(90), math.rad(-110), math.rad(90))
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
	print(string.format("[WeaponManager] Equipped '%s' to %s with bounds scale normalization.", activeWeapon.Name, player.Name))
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

	-- Search ReplicatedStorage RECURSIVELY for actual custom 3D Back Armor Model
	local armorTemplate: Instance? = ReplicatedStorage:FindFirstChild(modelName, true)
		or ReplicatedStorage:FindFirstChild("Sun-Slayer Crimson Crest Array", true)
		or ReplicatedStorage:FindFirstChild("BasicBackCrest", true)

	if armorTemplate then
		local cloned = armorTemplate:Clone()
		cloned.Name = "EquippedBackArmor"

		for _, scriptInst in ipairs(cloned:GetDescendants()) do
			if scriptInst:IsA("LuaSourceContainer") then
				scriptInst:Destroy()
			end
		end

		-- Normalize crest scale to 4.0 studs max dimension
		NormalizeModelScale(cloned, 4.0)

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

			local customBackAtt = primaryPart:FindFirstChild("BodyBackAttachment")
				or primaryPart:FindFirstChild("BackAttachment")
				or cloned:FindFirstChild("BodyBackAttachment", true)

			local backOffset: CFrame
			if customBackAtt and customBackAtt:IsA("Attachment") then
				backOffset = (customBackAtt :: Attachment).CFrame
			else
				backOffset = if itemData and itemData.GripOffset then itemData.GripOffset else (CFrame.new(0, 2.0, 1.2) * CFrame.Angles(0.1, 0, 0))
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