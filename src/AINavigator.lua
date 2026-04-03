-- AINavigator.lua
-- PathfindingService wrapper with recompute-on-block and smooth steering
-- v3.0 | roblox-procedural-worlds

local PathfindingService = game:GetService("PathfindingService")
local EventBus           = require(script.Parent.EventBus)

local AINavigator = {}
AINavigator.__index = AINavigator

local AGENT_PARAMS = {
	AgentRadius      = 2.5,
	AgentHeight      = 5,
	AgentCanJump     = true,
	AgentCanClimb    = false,
	WaypointSpacing  = 4,
}

local RECOMPUTE_DIST   = 3   -- recompute if blocked within this distance
local WAYPOINT_REACH   = 4   -- studs to consider waypoint reached
local RECOMPUTE_COOLDOWN = 0.8 -- seconds between recomputes

function AINavigator.new(model)
	local self = setmetatable({}, AINavigator)
	self.model        = model
	self.humanoid     = model:FindFirstChildOfClass("Humanoid")
	self.rootPart     = model:FindFirstChild("HumanoidRootPart")
	self._waypoints   = {}
	self._wpIndex     = 1
	self._dest        = nil
	self._lastRecompute = 0
	self._blocked     = false
	return self
end

function AINavigator:moveTo(destination)
	if not self.rootPart then return end

	local now = os.clock()
	local same = self._dest and (self._dest - destination).Magnitude < 2
	if same and not self._blocked then return end
	if now - self._lastRecompute < RECOMPUTE_COOLDOWN then return end

	self._dest = destination
	self._lastRecompute = now
	self._blocked = false

	local path = PathfindingService:CreatePath(AGENT_PARAMS)
	local ok, err = pcall(function()
		path:ComputeAsync(self.rootPart.Position, destination)
	end)

	if not ok or path.Status ~= Enum.PathStatus.Success then
		-- Fallback: walk straight
		if self.humanoid then
			self.humanoid:MoveTo(destination)
		end
		return
	end

	self._waypoints = path:GetWaypoints()
	self._wpIndex   = 2  -- skip index 1 (current pos)

	path.Blocked:Connect(function(blockedIdx)
		if blockedIdx >= self._wpIndex then
			self._blocked = true
		end
	end)

	self:_advanceWaypoint()
end

function AINavigator:_advanceWaypoint()
	if not self._waypoints or self._wpIndex > #self._waypoints then return end
	local wp = self._waypoints[self._wpIndex]

	if wp.Action == Enum.PathWaypointAction.Jump and self.humanoid then
		self.humanoid.Jump = true
	end

	if self.humanoid then
		self.humanoid:MoveTo(wp.Position)
		self.humanoid.MoveToFinished:Wait()
	end

	self._wpIndex += 1
	if self._wpIndex <= #self._waypoints then
		self:_advanceWaypoint()
	end
end

function AINavigator:stop()
	self._waypoints = {}
	self._dest = nil
	if self.humanoid then
		self.humanoid:MoveTo(self.rootPart and self.rootPart.Position or Vector3.new())
	end
end

return AINavigator
