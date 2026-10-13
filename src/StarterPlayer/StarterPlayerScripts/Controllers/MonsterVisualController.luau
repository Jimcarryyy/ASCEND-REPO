--!strict
--[[
    MonsterVisualController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/MonsterVisualController.luau
    Authoritative Client-side Quadruped Kinematics Engine.
    Features:
      - Wolf Airborne Leap Pounce & Bite Attack.
      - Auto-Obstacle Jump Kinematics (bounding up terrain lips).
      - Stroll vs Aggro Sprint cadence.
      - 1.0-stud kinetic hit flinch.
      - Grounded fallen carcass death pose.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MonsterVisualController = {}

type QuadrupedBones = {
	Hips: Bone,
	Chest: Bone?,
	Head: Bone?,
	HeadEnd: Bone?,
	Tail: { Bone },
	LF_Upper: Bone?,
	LF_Knee: Bone?,
	LF_Ankle: Bone?,
	LF_Paw: Bone?,
	RF_Upper: Bone?,
	RF_Knee: Bone?,
	RF_Ankle: Bone?,
	RF_Paw: Bone?,
	LB_Upper: Bone?,
	LB_Knee: Bone?,
	LB_Ankle: Bone?,
	LB_Paw: Bone?,
	RB_Upper: Bone?,
	RB_Knee: Bone?,
	RB_Ankle: Bone?,
	RB_Paw: Bone?,
}

type MonsterEntity = {
	Model: Model,
	RootPart: BasePart,
	Bones: QuadrupedBones,
	CurrentState: string,
	StepCycle: number,
	StateTimer: number,
	AttackTime: number,
	HitDirection: number,
	DeathProgress: number,
	Billboard: BillboardGui?,
	HpFill: Frame?,
	PostureFill: Frame?,
}

local activeMonsters: { [Model]: MonsterEntity } = {}
local camera = Workspace.CurrentCamera
local MAX_ANIM_DISTANCE = 160.0

-- =============================================================================
-- 1. OVERHEAD BILLBOARD GUI
-- =============================================================================

local function AttachMonsterOverhead(model: Model, rootPart: BasePart): (BillboardGui, Frame, Frame)
	local existing = rootPart:FindFirstChild("MonsterOverhead")
	if existing then existing:Destroy() end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "MonsterOverhead"
	billboard.Size = UDim2.new(0, 160, 0, 32)
	billboard.StudsOffset = Vector3.new(0, (rootPart.Size.Y * 0.5) + 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 55
	billboard.Adornee = rootPart
	billboard.Parent = rootPart

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = billboard

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "MonsterName"
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.Bangers
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = Color3.fromRGB(255, 230, 110)
	nameLabel.Text = string.upper(tostring(model:GetAttribute("DisplayName") or model.Name))
	nameLabel.Parent = container

	local stroke = Instance.new("UIStroke", nameLabel)
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 1.4

	local hpTrack = Instance.new("Frame")
	hpTrack.Name = "HPTrack"
	hpTrack.Size = UDim2.new(1, -10, 0, 7)
	hpTrack.Position = UDim2.new(0, 5, 0, 17)
	hpTrack.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
	hpTrack.BorderSizePixel = 0
	hpTrack.Parent = container
	Instance.new("UICorner", hpTrack).CornerRadius = UDim.new(0, 2)

	local hpFill = Instance.new("Frame")
	hpFill.Name = "Fill"
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpTrack
	Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 2)

	local postureTrack = Instance.new("Frame")
	postureTrack.Name = "PostureTrack"
	postureTrack.Size = UDim2.new(1, -10, 0, 3)
	postureTrack.Position = UDim2.new(0, 5, 0, 26)
	postureTrack.BackgroundColor3 = Color3.fromRGB(15, 18, 22)
	postureTrack.BorderSizePixel = 0
	postureTrack.Parent = container
	Instance.new("UICorner", postureTrack).CornerRadius = UDim.new(0, 1)

	local postureFill = Instance.new("Frame")
	postureFill.Name = "Fill"
	postureFill.Size = UDim2.new(1, 0, 1, 0)
	postureFill.BackgroundColor3 = Color3.fromRGB(255, 170, 35)
	postureFill.BorderSizePixel = 0
	postureFill.Parent = postureTrack
	Instance.new("UICorner", postureFill).CornerRadius = UDim.new(0, 1)

	return billboard, hpFill, postureFill
end

-- =============================================================================
-- 2. BONE RESOLUTION
-- =============================================================================

local function ResolveBones(model: Model): QuadrupedBones?
	local hips = model:FindFirstChild("Hips", true) :: Bone?
	if not hips then return nil end

	local chest = model:FindFirstChild("chest", true) :: Bone?
	local head = model:FindFirstChild("head", true) :: Bone?
	local headEnd = model:FindFirstChild("headend", true) :: Bone?

	local tailChain: { Bone } = {}
	local tailNames = { "tail", "tailstart", "tail1", "tail2", "tail3" }
	for _, tName in ipairs(tailNames) do
		local tb = model:FindFirstChild(tName, true) :: Bone?
		if tb then table.insert(tailChain, tb) end
	end

	local bones: QuadrupedBones = {
		Hips = hips,
		Chest = chest,
		Head = head,
		HeadEnd = headEnd,
		Tail = tailChain,
		LF_Upper = model:FindFirstChild("frontleg", true) :: Bone?,
		LF_Knee = model:FindFirstChild("frontleg0", true) :: Bone?,
		LF_Ankle = model:FindFirstChild("frontleg1", true) :: Bone?,
		LF_Paw = model:FindFirstChild("frontleg2", true) :: Bone?,
		RF_Upper = model:FindFirstChild("R_frontleg", true) :: Bone?,
		RF_Knee = model:FindFirstChild("R_frontleg0", true) :: Bone?,
		RF_Ankle = model:FindFirstChild("R_frontleg1", true) :: Bone?,
		RF_Paw = model:FindFirstChild("R_frontleg2", true) :: Bone?,
		LB_Upper = model:FindFirstChild("backleg", true) :: Bone?,
		LB_Knee = model:FindFirstChild("backleg0", true) :: Bone?,
		LB_Ankle = model:FindFirstChild("backleg1", true) :: Bone?,
		LB_Paw = model:FindFirstChild("backleg2", true) :: Bone?,
		RB_Upper = model:FindFirstChild("R_backleg", true) :: Bone?,
		RB_Knee = model:FindFirstChild("R_backleg0", true) :: Bone?,
		RB_Ankle = model:FindFirstChild("R_backleg1", true) :: Bone?,
		RB_Paw = model:FindFirstChild("R_backleg2", true) :: Bone?,
	}

	return bones
end

-- =============================================================================
-- 3. REGISTRATION
-- =============================================================================

local function RegisterMonster(model: Model)
	if activeMonsters[model] then return end

	local rootPart = model.PrimaryPart or model:FindFirstChild("char1") :: BasePart?
	if not rootPart then return end

	local bones = ResolveBones(model)
	if not bones then return end

	local bb, hpF, postF = AttachMonsterOverhead(model, rootPart)

	local entity: MonsterEntity = {
		Model = model,
		RootPart = rootPart,
		Bones = bones,
		CurrentState = tostring(model:GetAttribute("ActionState") or "Idle"),
		StepCycle = math.random() * math.pi * 2,
		StateTimer = 0,
		AttackTime = 0,
		HitDirection = 1,
		DeathProgress = 0,
		Billboard = bb,
		HpFill = hpF,
		PostureFill = postF,
	}

	activeMonsters[model] = entity

	model:GetAttributeChangedSignal("ActionState"):Connect(function()
		local newState = tostring(model:GetAttribute("ActionState") or "Idle")
		if entity.CurrentState ~= newState then
			entity.CurrentState = newState
			entity.StateTimer = 0
			if newState == "Attacking" or newState == "LeapAttack" then
				entity.AttackTime = 0
			elseif newState == "Hit" then
				entity.HitDirection = if math.random() > 0.5 then 1 else -1
			end
		end
	end)

	model:GetAttributeChangedSignal("Health"):Connect(function()
		local hp = tonumber(model:GetAttribute("Health")) or 0
		local maxHp = tonumber(model:GetAttribute("MaxHealth")) or 100
		if entity.HpFill then
			entity.HpFill.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
		end
	end)

	model:GetAttributeChangedSignal("Posture"):Connect(function()
		local p = tonumber(model:GetAttribute("Posture")) or 100
		local maxP = tonumber(model:GetAttribute("MaxPosture")) or 100
		if entity.PostureFill then
			entity.PostureFill.Size = UDim2.new(math.clamp(p / maxP, 0, 1), 0, 1, 0)
		end
	end)
end

local function UnregisterMonster(model: Model)
	local entity = activeMonsters[model]
	if entity and entity.Billboard then
		entity.Billboard:Destroy()
	end
	activeMonsters[model] = nil
end

-- =============================================================================
-- 4. KINEMATICS ENGINE
-- =============================================================================

local function SolveLegLimb(upper: Bone?, knee: Bone?, phase: number, isFront: boolean, swingAmp: number)
	if not upper then return end

	local swing = math.sin(phase)
	local lift = math.clamp(swing, 0, 1)

	if isFront then
		upper.Transform = CFrame.Angles(swing * swingAmp, 0, 0)
		if knee then
			knee.Transform = CFrame.Angles(-lift * (swingAmp * 1.3), 0, 0)
		end
	else
		upper.Transform = CFrame.Angles(swing * swingAmp, 0, 0)
		if knee then
			knee.Transform = CFrame.Angles(lift * (swingAmp * 1.2), 0, 0)
		end
	end
end

local function ResetLegs(b: QuadrupedBones)
	local function ResetBone(bone: Bone?)
		if bone then bone.Transform = CFrame.identity end
	end
	ResetBone(b.LF_Upper); ResetBone(b.LF_Knee)
	ResetBone(b.RF_Upper); ResetBone(b.RF_Knee)
	ResetBone(b.LB_Upper); ResetBone(b.LB_Knee)
	ResetBone(b.RB_Upper); ResetBone(b.RB_Knee)
end

local function UpdateQuadrupedKinematics(entity: MonsterEntity, dt: number, now: number)
	local b = entity.Bones
	local state = entity.CurrentState
	entity.StateTimer += dt

	-- =========================================================================
	-- A. WOLF AIRBORNE LEAP POUNCE (POUNCE & BITE)
	-- =========================================================================
	if state == "LeapAttack" or state == "Jumping" then
		entity.AttackTime += dt
		local t = entity.AttackTime

		if t < 0.35 then
			-- Airborne leap arc: limbs reach forward & back
			b.Hips.Transform = CFrame.new(0, 0.4, -0.4) * CFrame.Angles(0.2, 0, 0)
			if b.Head then b.Head.Transform = CFrame.Angles(-0.35, 0, 0) end
			-- Front paws reach forward for the pounce
			if b.LF_Upper then b.LF_Upper.Transform = CFrame.Angles(0.65, 0, 0) end
			if b.RF_Upper then b.RF_Upper.Transform = CFrame.Angles(0.65, 0, 0) end
			-- Hind limbs kick back in propulsion
			if b.LB_Upper then b.LB_Upper.Transform = CFrame.Angles(-0.60, 0, 0) end
			if b.RB_Upper then b.RB_Upper.Transform = CFrame.Angles(-0.60, 0, 0) end
		else
			-- Landing pounce: paws slam down, jaws snap shut
			local landT = math.clamp((t - 0.35) / 0.25, 0, 1)
			b.Hips.Transform = CFrame.new(0, -landT * 0.3, 0)
			if b.Head then b.Head.Transform = CFrame.Angles(landT * 0.40, 0, 0) end
			if b.LF_Upper then b.LF_Upper.Transform = CFrame.Angles(-landT * 0.45, 0, 0) end
			if b.RF_Upper then b.RF_Upper.Transform = CFrame.Angles(-landT * 0.45, 0, 0) end
		end

	-- =========================================================================
	-- B. RUNNING (FAST CHARGE SPRINT, 38 studs/s)
	-- =========================================================================
	elseif state == "Running" then
		entity.StepCycle += dt * 14.0
		local cycle = entity.StepCycle

		SolveLegLimb(b.LF_Upper, b.LF_Knee, cycle, true, 0.48)
		SolveLegLimb(b.RB_Upper, b.RB_Knee, cycle, false, 0.52)

		SolveLegLimb(b.RF_Upper, b.RF_Knee, cycle + math.pi, true, 0.48)
		SolveLegLimb(b.LB_Upper, b.LB_Knee, cycle + math.pi, false, 0.52)

		local bounceY = -math.abs(math.sin(cycle)) * 0.22
		b.Hips.Transform = CFrame.new(0, bounceY, 0)

		if b.Chest then
			b.Chest.Transform = CFrame.new(0, bounceY * 0.5, 0)
		end

		for i, tb in ipairs(b.Tail) do
			tb.Transform = CFrame.Angles(0, math.sin(cycle * 0.5 - (i * 0.4)) * 0.22, 0)
		end

	-- =========================================================================
	-- C. WALKING (CALM SLOW STROLL, 12 studs/s)
	-- =========================================================================
	elseif state == "Walking" then
		entity.StepCycle += dt * 5.5
		local cycle = entity.StepCycle

		SolveLegLimb(b.LF_Upper, b.LF_Knee, cycle, true, 0.28)
		SolveLegLimb(b.RB_Upper, b.RB_Knee, cycle, false, 0.30)

		SolveLegLimb(b.RF_Upper, b.RF_Knee, cycle + math.pi, true, 0.28)
		SolveLegLimb(b.LB_Upper, b.LB_Knee, cycle + math.pi, false, 0.30)

		local bounceY = -math.abs(math.sin(cycle)) * 0.08
		b.Hips.Transform = CFrame.new(0, bounceY, 0)

		if b.Chest then
			b.Chest.Transform = CFrame.new(0, bounceY * 0.5, 0)
		end

		for i, tb in ipairs(b.Tail) do
			tb.Transform = CFrame.Angles(0, math.sin(cycle * 0.5 - (i * 0.4)) * 0.12, 0)
		end

	-- =========================================================================
	-- D. IDLE (BREATHING & REST)
	-- =========================================================================
	elseif state == "Idle" then
		ResetLegs(b)
		local breathTime = now * 1.8 + entity.StepCycle
		local breathY = math.sin(breathTime) * 0.035

		b.Hips.Transform = CFrame.new(0, breathY, 0)
		if b.Chest then
			b.Chest.Transform = CFrame.new(0, breathY * 0.5, 0)
		end
		if b.Head then
			b.Head.Transform = CFrame.Angles(math.sin(now * 0.8) * 0.02, math.sin(now * 0.5) * 0.04, 0)
		end

		for i, tb in ipairs(b.Tail) do
			tb.Transform = CFrame.Angles(0, math.sin(now * 1.2 - (i * 0.4)) * 0.08, 0)
		end

	-- =========================================================================
	-- E. PROMINENT HIT FLINCH (1.0-STUD RECOIL)
	-- =========================================================================
	elseif state == "Hit" then
		local progress = math.clamp(entity.StateTimer / 0.38, 0, 1)
		local recoilWeight = math.sin((1 - progress) * math.pi)

		local side = entity.HitDirection
		b.Hips.Transform = CFrame.new(0, -0.15 * recoilWeight, 1.0 * recoilWeight)

		if b.Chest then
			b.Chest.Transform = CFrame.Angles(0.25 * recoilWeight, 0, -side * 0.18 * recoilWeight)
		end

		if b.Head then
			b.Head.Transform = CFrame.Angles(-0.35 * recoilWeight, side * 0.45 * recoilWeight, 0)
		end

		if b.LF_Upper then b.LF_Upper.Transform = CFrame.Angles(-0.45 * recoilWeight, 0, 0) end
		if b.RF_Upper then b.RF_Upper.Transform = CFrame.Angles(-0.45 * recoilWeight, 0, 0) end

	-- =========================================================================
	-- F. BASIC ATTACK LUNGE
	-- =========================================================================
	elseif state == "Attacking" then
		entity.AttackTime += dt
		local t = entity.AttackTime

		if t < 0.35 then
			local progress = t / 0.35
			b.Hips.Transform = CFrame.new(0, -progress * 0.15, progress * 0.35)
			if b.Head then b.Head.Transform = CFrame.Angles(progress * 0.25, 0, 0) end
			if b.LF_Upper then b.LF_Upper.Transform = CFrame.Angles(-progress * 0.40, 0, 0) end
			if b.RF_Upper then b.RF_Upper.Transform = CFrame.Angles(-progress * 0.40, 0, 0) end
		elseif t < 0.65 then
			local slamT = (t - 0.35) / 0.30
			b.Hips.Transform = CFrame.new(0, 0, -slamT * 0.65)
			if b.Head then b.Head.Transform = CFrame.Angles(-slamT * 0.40, 0, 0) end
			if b.LF_Upper then b.LF_Upper.Transform = CFrame.Angles(slamT * 0.55, 0, 0) end
			if b.RF_Upper then b.RF_Upper.Transform = CFrame.Angles(slamT * 0.55, 0, 0) end
		else
			ResetLegs(b)
			b.Hips.Transform = CFrame.identity
			if b.Head then b.Head.Transform = CFrame.identity end
		end

	-- =========================================================================
	-- G. GROUNDED FALLEN CARCASS DEATH
	-- =========================================================================
	elseif state == "Dead" then
		entity.DeathProgress = math.clamp(entity.DeathProgress + (dt * 2.2), 0, 1)
		local p = entity.DeathProgress

		local sinkY = -1.90 * p
		b.Hips.Transform = CFrame.new(0, sinkY, 0)

		if b.Chest then
			b.Chest.Transform = CFrame.new(0, sinkY * 0.25, 0)
		end

		if b.Head then
			b.Head.Transform = CFrame.Angles(0.35 * p, 0, 0)
		end

		if b.LF_Upper then b.LF_Upper.Transform = CFrame.Angles(0.65 * p, 0, 0) end
		if b.RF_Upper then b.RF_Upper.Transform = CFrame.Angles(0.65 * p, 0, 0) end
		if b.LB_Upper then b.LB_Upper.Transform = CFrame.Angles(-0.55 * p, 0, 0) end
		if b.RB_Upper then b.RB_Upper.Transform = CFrame.Angles(-0.55 * p, 0, 0) end
	end
end

-- =============================================================================
-- 5. RENDER TICK
-- =============================================================================

local function OnRenderStep(dt: number)
	local now = os.clock()
	local camPos = if camera then camera.CFrame.Position else Vector3.zero

	for model, entity in pairs(activeMonsters) do
		if not model.Parent then
			UnregisterMonster(model)
			continue
		end

		local dist = (entity.RootPart.Position - camPos).Magnitude
		if dist <= MAX_ANIM_DISTANCE then
			UpdateQuadrupedKinematics(entity, dt, now)
		end
	end
end

function MonsterVisualController.Init()
	CollectionService:GetInstanceAddedSignal("Monster"):Connect(function(inst)
		if inst:IsA("Model") then RegisterMonster(inst) end
	end)

	CollectionService:GetInstanceRemovedSignal("Monster"):Connect(function(inst)
		if inst:IsA("Model") then UnregisterMonster(inst) end
	end)

	task.spawn(function()
		while true do
			task.wait(1.0)
			for _, inst in ipairs(CollectionService:GetTagged("Monster")) do
				if inst:IsA("Model") and not activeMonsters[inst] then
					RegisterMonster(inst)
				end
			end
			local activeFolder = Workspace:FindFirstChild("ActiveMonsters")
			if activeFolder then
				for _, m in ipairs(activeFolder:GetChildren()) do
					if m:IsA("Model") and not activeMonsters[m] then
						RegisterMonster(m)
					end
				end
			end
		end
	end)

	RunService.RenderStepped:Connect(OnRenderStep)

	print("[ASCEND] MonsterVisualController Initialized (Airborne Pounce, Jump Cadence & True Hitstun Active).")
end

return MonsterVisualController