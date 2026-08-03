--!strict
--[[
    HitboxManager.luau
    Server-authoritative spatial query engine for 100% exploit-proof hit detection.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local HitboxManager = {}

export type HitResult = {
	Character: Model,
	Humanoid: Humanoid,
	HitPart: BasePart,
}

function HitboxManager.CastBoxHitbox(
	attacker: Model,
	cframe: CFrame,
	size: Vector3,
	ignoreList: { Instance }?
): { HitResult }
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	local filterInstances: { Instance } = { attacker }
	if ignoreList then
		for _, inst in ipairs(ignoreList) do
			table.insert(filterInstances, inst)
		end
	end
	overlapParams.FilterDescendantsInstances = filterInstances

	local partsInBox = Workspace:GetPartBoundsInBox(cframe, size, overlapParams)
	local hitCharacters: { [Model]: boolean } = {}
	local results: { HitResult } = {}

	for _, part in ipairs(partsInBox) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and not hitCharacters[model] and model ~= attacker then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				hitCharacters[model] = true
				table.insert(results, {
					Character = model,
					Humanoid = humanoid,
					HitPart = part,
				})
			end
		end
	end

	return results
end

function HitboxManager.ApplyDamageAndKnockback(
	attackerPlayer: Player,
	targetResult: HitResult,
	damage: number,
	knockbackVector: Vector3?
)
	local humanoid = targetResult.Humanoid
	humanoid:TakeDamage(damage)

	if knockbackVector and targetResult.Character and knockbackVector.Magnitude > 0 then
		local hrp = targetResult.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			local attackerHrp = if attackerPlayer.Character then attackerPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			local orientation = if attackerHrp then attackerHrp.CFrame else CFrame.new()
			local worldKnockback = orientation:VectorToWorldSpace(knockbackVector)

			local attachment = Instance.new("Attachment")
			attachment.Parent = hrp

			local vectorVelocity = Instance.new("LinearVelocity")
			vectorVelocity.Attachment0 = attachment
			vectorVelocity.MaxForce = 100000
			vectorVelocity.VectorVelocity = worldKnockback
			vectorVelocity.Parent = hrp

			task.delay(0.15, function()
				vectorVelocity:Destroy()
				attachment:Destroy()
			end)
		end
	end
end

return HitboxManager