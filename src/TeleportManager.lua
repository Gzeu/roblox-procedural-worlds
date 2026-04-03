-- TeleportManager.lua
-- Manages in-world and cross-server teleportation with cooldowns and EventBus hooks
-- v2.5 | roblox-procedural-worlds

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local EventBus = require(script.Parent.EventBus)

local TeleportManager = {}
TeleportManager.__index = TeleportManager

local COOLDOWN_SECONDS = 10
local cooldowns = {} -- { [userId] = lastTeleportTime }

-- Named waypoints registered at runtime
local waypoints = {}

-- Register a named waypoint
-- @param name string
-- @param position Vector3
function TeleportManager.registerWaypoint(name, position)
	assert(type(name) == "string", "Waypoint name must be a string")
	assert(typeof(position) == "Vector3", "Position must be a Vector3")
	waypoints[name] = position
	EventBus.emit("TeleportManager:WaypointRegistered", name, position)
end

-- Get all registered waypoints
function TeleportManager.getWaypoints()
	return waypoints
end

-- Check if a player is on cooldown
function TeleportManager.isOnCooldown(player)
	local userId = player.UserId
	if not cooldowns[userId] then return false end
	return (os.clock() - cooldowns[userId]) < COOLDOWN_SECONDS
end

-- Remaining cooldown seconds
function TeleportManager.getCooldownRemaining(player)
	if not TeleportManager.isOnCooldown(player) then return 0 end
	local elapsed = os.clock() - cooldowns[player.UserId]
	return math.ceil(COOLDOWN_SECONDS - elapsed)
end

-- Teleport player to a Vector3 position (in-world)
-- @param player Player
-- @param position Vector3
-- @param bypassCooldown boolean
-- @returns boolean, string
function TeleportManager.teleportTo(player, position, bypassCooldown)
	if not bypassCooldown and TeleportManager.isOnCooldown(player) then
		local remaining = TeleportManager.getCooldownRemaining(player)
		return false, "Teleport on cooldown: " .. remaining .. "s remaining"
	end

	local character = player.Character
	if not character then
		return false, "Player has no character"
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return false, "HumanoidRootPart not found"
	end

	humanoidRootPart.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
	cooldowns[player.UserId] = os.clock()

	EventBus.emit("TeleportManager:PlayerTeleported", player, position)
	return true, "Teleported to " .. tostring(position)
end

-- Teleport player to a named waypoint
-- @param player Player
-- @param waypointName string
-- @returns boolean, string
function TeleportManager.teleportToWaypoint(player, waypointName)
	local pos = waypoints[waypointName]
	if not pos then
		return false, "Waypoint not found: " .. tostring(waypointName)
	end
	return TeleportManager.teleportTo(player, pos)
end

-- Cross-server teleport to another place
-- @param player Player
-- @param placeId number
-- @param jobId string? (optional, for specific server)
function TeleportManager.teleportToPlace(player, placeId, jobId)
	local options = Instance.new("TeleportOptions")
	if jobId then
		options.ServerInstanceId = jobId
	end

	local success, err = pcall(function()
		TeleportService:TeleportAsync(placeId, { player }, options)
	end)

	if not success then
		EventBus.emit("TeleportManager:TeleportFailed", player, placeId, err)
		return false, err
	end

	EventBus.emit("TeleportManager:CrossServerTeleport", player, placeId)
	return true, "Teleporting to place " .. placeId
end

-- Clean up cooldown on player leave
Players.PlayerRemoving:Connect(function(player)
	cooldowns[player.UserId] = nil
end)

return TeleportManager
