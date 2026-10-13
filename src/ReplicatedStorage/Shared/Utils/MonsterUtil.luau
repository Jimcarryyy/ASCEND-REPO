--!strict
--[[
    MonsterUtil.luau
    Location: src/ReplicatedStorage/Shared/Utils/MonsterUtil.luau
    Shared utility module for non-humanoid monsters and sovereign bosses.
    Provides attribute-driven health, posture, CC states, and animation interfaces
    usable by both Server and Client without requiring a Humanoid instance.
]]

local CollectionService = game:GetService("CollectionService")

export type MonsterState = "Idle" | "Running" | "Attacking" | "Stunned" | "Dead"

export type MonsterInitData = {
	Id: string,
	DisplayName: string?,
	Zone: string?,
	MaxHealth: number,
	MaxPosture: number?,
	IsBoss: boolean?,
	CultivationRealm: string?,
}

local MonsterUtil = {}

local MONSTER_TAG = "Monster"

-- =============================================================================
-- IDENTIFICATION & QUERY
-- =============================================================================

--- Checks whether an instance is an initialized Monster or belongs to one
function MonsterUtil.IsMonster(instance: Instance?): boolean
	if not instance then return false end

	local model = if instance:IsA("Model") then instance else instance:FindFirstAncestorOfClass("Model")
	if not model then return false end

	if model:GetAttribute("IsMonster") == true then
		return true
	end

	if CollectionService:HasTag(model, MONSTER_TAG) then
		return true
	end

	-- Structural fallback: Has AnimationController and char1, but no Humanoid
	if model:FindFirstChildOfClass("AnimationController")
		and not model:FindFirstChildOfClass("Humanoid")
		and (model:FindFirstChild("char1") or model.PrimaryPart ~= nil) then
		return true
	end

	return false
end

--- Resolves the root Monster model from any descendant part or returns nil
function MonsterUtil.GetMonsterModel(descendant: Instance?): Model?
	if not descendant then return nil end
	local model = if descendant:IsA("Model") then descendant else descendant:FindFirstAncestorOfClass("Model")
	if model and MonsterUtil.IsMonster(model) then
		return model
	end
	return nil
end

--- Resolves the primary root part of a monster (char1 or PrimaryPart)
function MonsterUtil.GetRootPart(model: Model?): BasePart?
	if not model then return nil end
	if model.PrimaryPart then
		return model.PrimaryPart
	end
	local char1 = model:FindFirstChild("char1")
	if char1 and char1:IsA("BasePart") then
		return char1
	end
	local anyPart = model:FindFirstChildWhichIsA("BasePart")
	return anyPart
end

--- Returns the Animator instance under AnimationController (creating one if missing)
function MonsterUtil.GetAnimator(model: Model?): Animator?
	if not model then return nil end
	local animCtrl = model:FindFirstChildOfClass("AnimationController")
	if not animCtrl then return nil end

	local animator = animCtrl:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = animCtrl
	end
	return animator
end

-- =============================================================================
-- INITIALIZATION (SERVER-SIDE)
-- =============================================================================

--- Initializes a monster model with replicated combat attributes and physics tags
function MonsterUtil.InitMonster(model: Model, data: MonsterInitData)
	local rootPart = MonsterUtil.GetRootPart(model)
	if rootPart and model.PrimaryPart ~= rootPart then
		model.PrimaryPart = rootPart
	end

	CollectionService:AddTag(model, MONSTER_TAG)

	model:SetAttribute("IsMonster", true)
	model:SetAttribute("MonsterId", data.Id)
	model:SetAttribute("DisplayName", data.DisplayName or data.Id)
	model:SetAttribute("Zone", data.Zone or "Wilderness")
	model:SetAttribute("IsBoss", data.IsBoss == true)

	local maxHp = math.max(1, data.MaxHealth)
	model:SetAttribute("MaxHealth", maxHp)
	model:SetAttribute("Health", maxHp)

	local maxPosture = math.max(1, data.MaxPosture or 100)
	model:SetAttribute("MaxPosture", maxPosture)
	model:SetAttribute("Posture", maxPosture)

	model:SetAttribute("ActionState", "Idle")
	model:SetAttribute("IsStunned", false)
	model:SetAttribute("CultivationRealm", data.CultivationRealm or "QiCondensation")

	-- Ensure Animator is available for animations
	MonsterUtil.GetAnimator(model)
end

-- =============================================================================
-- HEALTH & DAMAGE
-- =============================================================================

function MonsterUtil.GetHealth(model: Model): (number, number)
	local hp = model:GetAttribute("Health")
	local maxHp = model:GetAttribute("MaxHealth")
	local cur = if typeof(hp) == "number" then hp else 0
	local max = if typeof(maxHp) == "number" then maxHp else 100
	return cur, max
end

function MonsterUtil.SetHealth(model: Model, health: number): number
	local _, maxHp = MonsterUtil.GetHealth(model)
	local clamped = math.clamp(health, 0, maxHp)
	model:SetAttribute("Health", clamped)

	if clamped <= 0 then
		model:SetAttribute("ActionState", "Dead")
	end
	return clamped
end

--- Applies damage directly to the monster. Returns (newHealth, isDead)
function MonsterUtil.TakeDamage(model: Model, amount: number): (number, boolean)
	if amount <= 0 then
		local hp = MonsterUtil.GetHealth(model)
		return hp, hp <= 0
	end

	local curHp, maxHp = MonsterUtil.GetHealth(model)
	local newHp = math.clamp(curHp - amount, 0, maxHp)
	model:SetAttribute("Health", newHp)

	local isDead = (newHp <= 0)
	if isDead then
		model:SetAttribute("ActionState", "Dead")
	end

	return newHp, isDead
end

-- =============================================================================
-- POSTURE & GUARD BREAK
-- =============================================================================

function MonsterUtil.GetPosture(model: Model): (number, number)
	local posture = model:GetAttribute("Posture")
	local maxPosture = model:GetAttribute("MaxPosture")
	local cur = if typeof(posture) == "number" then posture else 0
	local max = if typeof(maxPosture) == "number" then maxPosture else 100
	return cur, max
end

function MonsterUtil.SetPosture(model: Model, posture: number): number
	local _, maxP = MonsterUtil.GetPosture(model)
	local clamped = math.clamp(posture, 0, maxP)
	model:SetAttribute("Posture", clamped)
	return clamped
end

--- Inflicts posture damage. Returns (newPosture, wasGuardBroken)
function MonsterUtil.DamagePosture(model: Model, amount: number): (number, boolean)
	local curP, maxP = MonsterUtil.GetPosture(model)
	local newP = curP - amount

	if newP <= 0 then
		-- Guard Broken: Reset posture to 30% after break
		local recovered = math.floor(maxP * 0.3)
		model:SetAttribute("Posture", recovered)
		return recovered, true
	else
		local clamped = math.clamp(newP, 0, maxP)
		model:SetAttribute("Posture", clamped)
		return clamped, false
	end
end

-- =============================================================================
-- CC STATES & ACTION STATE
-- =============================================================================

function MonsterUtil.IsStunned(model: Model): boolean
	return model:GetAttribute("IsStunned") == true
end

function MonsterUtil.SetStunned(model: Model, stunned: boolean, duration: number?)
	model:SetAttribute("IsStunned", stunned)
	if stunned then
		model:SetAttribute("ActionState", "Stunned")
		if duration and duration > 0 then
			task.delay(duration, function()
				if model and model.Parent and model:GetAttribute("IsStunned") == true then
					model:SetAttribute("IsStunned", false)
					if model:GetAttribute("ActionState") == "Stunned" then
						model:SetAttribute("ActionState", "Idle")
					end
				end
			end)
		end
	else
		if model:GetAttribute("ActionState") == "Stunned" then
			model:SetAttribute("ActionState", "Idle")
		end
	end
end

function MonsterUtil.GetActionState(model: Model): MonsterState
	local state = model:GetAttribute("ActionState")
	return (if typeof(state) == "string" then state else "Idle") :: MonsterState
end

function MonsterUtil.SetActionState(model: Model, state: MonsterState)
	model:SetAttribute("ActionState", state)
end

return MonsterUtil