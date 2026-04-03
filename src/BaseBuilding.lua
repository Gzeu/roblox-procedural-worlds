-- BaseBuilding.lua
-- Snap-grid construction, collision check, owner tags and serialization
-- v5.0 | roblox-procedural-worlds

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local EventBus          = require(script.Parent.EventBus)

local BaseBuilding = {}

local GRID_SIZE                 = 4
local MAX_STRUCTURES_PER_PLAYER = 100
local MIN_SPACING               = 6

local playerBuilds = {}
local nextBuildId  = 1

local function getBuildTable(player)
	local uid = player.UserId
	if not playerBuilds[uid] then playerBuilds[uid] = {} end
	return playerBuilds[uid]
end

local function snap(n)
	return math.floor((n / GRID_SIZE) + 0.5) * GRID_SIZE
end

function BaseBuilding.snapPosition(position)
	return Vector3.new(snap(position.X), snap(position.Y), snap(position.Z))
end

local function createFallbackModel(name, cf)
	local model = Instance.new("Model")
	model.Name  = name
	local part  = Instance.new("Part")
	part.Name          = "Core"
	part.Size          = Vector3.new(4, 4, 4)
	part.Anchored      = true
	part.CFrame        = cf
	part.TopSurface    = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent        = model
	model.PrimaryPart  = part
	return model
end

local function spawnModel(templateName, cf)
	local templates = ReplicatedStorage:FindFirstChild("BuildingTemplates")
	local template  = templates and templates:FindFirstChild(templateName)
	local model
	if template and template:IsA("Model") then
		model = template:Clone()
		if not model.PrimaryPart then
			local primary = model:FindFirstChildWhichIsA("BasePart", true)
			if primary then model.PrimaryPart = primary end
		end
		if model.PrimaryPart then model:PivotTo(cf) end
	else
		model = createFallbackModel(templateName, cf)
	end
	return model
end

local function collides(builds, position)
	for _, record in ipairs(builds) do
		if (record.position - position).Magnitude < MIN_SPACING then return true end
	end
	return false
end

function BaseBuilding.placeStructure(player, templateName, position, rotationY, parentFolder)
	local builds = getBuildTable(player)
	if #builds >= MAX_STRUCTURES_PER_PLAYER then return false, "Build limit reached" end
	local snapped = BaseBuilding.snapPosition(position)
	if collides(builds, snapped) then return false, "Too close to another structure" end
	local cf    = CFrame.new(snapped) * CFrame.Angles(0, math.rad(rotationY or 0), 0)
	local model = spawnModel(templateName or "Structure", cf)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("BuildId",     nextBuildId)
	model.Parent = parentFolder or workspace
	local record = {
		id           = nextBuildId,
		templateName = templateName,
		position     = snapped,
		rotationY    = rotationY or 0,
		model        = model,
	}
	nextBuildId += 1
	table.insert(builds, record)
	EventBus.emit("BaseBuilding:Placed", player, record)
	return true, record
end

function BaseBuilding.removeStructure(player, buildId)
	local builds = getBuildTable(player)
	for index, record in ipairs(builds) do
		if record.id == buildId then
			if record.model and record.model.Parent then record.model:Destroy() end
			table.remove(builds, index)
			EventBus.emit("BaseBuilding:Removed", player, buildId)
			return true
		end
	end
	return false, "Build not found"
end

function BaseBuilding.getPlayerBuilds(player)
	return getBuildTable(player)
end

function BaseBuilding.serializePlayerBuilds(player)
	local serialized = {}
	for _, record in ipairs(getBuildTable(player)) do
		table.insert(serialized, {
			id           = record.id,
			templateName = record.templateName,
			position     = { x = record.position.X, y = record.position.Y, z = record.position.Z },
			rotationY    = record.rotationY,
		})
	end
	return serialized
end

function BaseBuilding.loadPlayerBuilds(player, savedBuilds, parentFolder)
	for _, entry in ipairs(savedBuilds or {}) do
		BaseBuilding.placeStructure(
			player, entry.templateName,
			Vector3.new(entry.position.x, entry.position.y, entry.position.z),
			entry.rotationY, parentFolder
		)
	end
end

Players.PlayerRemoving:Connect(function(player)
	playerBuilds[player.UserId] = nil
end)

return BaseBuilding
