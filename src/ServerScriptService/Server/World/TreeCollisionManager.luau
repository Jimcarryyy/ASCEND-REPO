--!strict
--[[
    TreeCollisionManager.luau
    Location: src/ServerScriptService/Server/World/TreeCollisionManager.luau
    Server manager for ASCEND world tree & bamboo collision cleanup.
    Ensures foliage and canopies do not create invisible box walls while keeping tree trunks
    and individual bamboo stalks physically collidable.
]]

local Workspace = game:GetService("Workspace")

local TreeCollisionManager = {}

local FOLIAGE_NAME_PATTERNS = {
	"leaf", "leaves", "canopy", "foliage", "crown", "branch", "pineleaves", "top", "bush"
}

local TRUNK_NAME_PATTERNS = {
	"trunk", "stem", "base", "log", "bark", "wood", "stalk", "pole", "bamboo"
}

local function IsFoliagePart(partName: string): boolean
	local lower = partName:lower()
	for _, pattern in ipairs(FOLIAGE_NAME_PATTERNS) do
		if lower:find(pattern) then
			return true
		end
	end
	return false
end

local function IsTrunkOrStalkPart(partName: string): boolean
	local lower = partName:lower()
	for _, pattern in ipairs(TRUNK_NAME_PATTERNS) do
		if lower:find(pattern) and not IsFoliagePart(lower) then
			return true
		end
	end
	return false
end

function TreeCollisionManager.ProcessTreeInstance(instance: Instance)
	if not instance:IsA("Model") and not instance:IsA("BasePart") then return end

	local instName = instance.Name:lower()
	local isTree = instName:find("tree") or instName:find("pine") or instName:find("oak") or instName:find("bamboo") or instName:find("birch") or instName:find("flora")

	if not isTree and instance:IsA("Model") then
		for _, child in ipairs(instance:GetChildren()) do
			if IsFoliagePart(child.Name) or IsTrunkOrStalkPart(child.Name) then
				isTree = true
				break
			end
		end
	end

	if not isTree then return end

	-- Process all descendant parts of the tree/bamboo model
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local partName = descendant.Name:lower()

			-- Invisible bounding boxes / outer hitboxes
			if descendant.Transparency >= 0.95 and not IsTrunkOrStalkPart(partName) then
				descendant.CanCollide = false
				descendant.CanTouch = false
				descendant.CanQuery = false

			elseif IsFoliagePart(partName) then
				-- Leaves/Canopies should never block player movement
				descendant.CanCollide = false
				descendant.CanTouch = false

			elseif IsTrunkOrStalkPart(partName) or instName:find("bamboo") then
				-- Tree Trunks & Bamboo Stalks remain physical world objects
				descendant.CanCollide = true
				descendant.CanTouch = true

			else
				-- Positional Fallback: If part is elevated high above base, assume foliage
				local parentModel = descendant:FindFirstAncestorOfClass("Model")
				if parentModel then
					local primary = parentModel.PrimaryPart or parentModel:FindFirstChildOfClass("BasePart")
					if primary and (descendant.Position.Y - primary.Position.Y) > 5 then
						descendant.CanCollide = false
					end
				end
			end
		end
	end
end

function TreeCollisionManager.Init()
	-- Scan all existing objects in Workspace
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Model") then
			TreeCollisionManager.ProcessTreeInstance(descendant)
		end
	end

	-- Listen for dynamically spawned trees/bamboo
	Workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("Model") then
			task.wait(0.1)
			TreeCollisionManager.ProcessTreeInstance(descendant)
		end
	end)

	print("[ASCEND] TreeCollisionManager Engine Initialized (Tree Trunk & Bamboo Stalk Collision Cleaned).")
end

return TreeCollisionManager