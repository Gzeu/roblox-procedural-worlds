-- AIMemory.lua
-- Per-mob memory: last known target position, sighting log, aggression cooldown
-- v4.0 | roblox-procedural-worlds

local RunService = game:GetService("RunService")
local EventBus   = require(script.Parent.EventBus)

local AIMemory = {}
AIMemory.__index = AIMemory

-- ── Config ───────────────────────────────────────────────────────
local MAX_SIGHTINGS        = 8    -- ring-buffer size for position memory
local SIGHTING_DECAY       = 30   -- seconds until a sighting is forgotten
local AGGRO_COOLDOWN       = 4    -- seconds after last attack before re-engaging
local MEMORY_SHARE_RADIUS  = 40   -- studs – broadcast last-known-pos to allies

-- ── Module-level registry (all mob memories keyed by model) ──────
local _registry = {}   -- { [model] = AIMemory instance }

-- ── Constructor ──────────────────────────────────────────────────
function AIMemory.new(mobModel)
	local self = setmetatable({}, AIMemory)
	self.model            = mobModel
	self.lastKnownPos     = nil        -- Vector3 | nil
	self.lastTargetId     = nil        -- Player UserId | nil
	self.sightings        = {}         -- { { pos, t } } ring buffer
	self.lastAttackTime   = 0
	self.aggroCooldownEnd = 0
	self.alertedBy        = nil        -- UserId that originally alerted this mob
	_registry[mobModel]   = self
	return self
end

-- ── Sighting log ─────────────────────────────────────────────────
function AIMemory:recordSighting(position, player)
	local now = os.clock()
	table.insert(self.sightings, { pos = position, t = now })
	if #self.sightings > MAX_SIGHTINGS then
		table.remove(self.sightings, 1)
	end
	self.lastKnownPos = position
	if player then
		self.lastTargetId = player.UserId
		self.alertedBy    = self.alertedBy or player.UserId
	end
end

-- ── Aggression cooldown ──────────────────────────────────────────
function AIMemory:recordAttack()
	local now = os.clock()
	self.lastAttackTime   = now
	self.aggroCooldownEnd = now + AGGRO_COOLDOWN
end

function AIMemory:isAggroCoolingDown()
	return os.clock() < self.aggroCooldownEnd
end

-- ── Last known position (pruned if stale) ────────────────────────
function AIMemory:getLastKnownPos()
	if not self.lastKnownPos then return nil end
	local newest = self.sightings[#self.sightings]
	if newest and os.clock() - newest.t > SIGHTING_DECAY then
		self.lastKnownPos = nil
		self.lastTargetId = nil
		return nil
	end
	return self.lastKnownPos
end

-- ── Forget everything (on death / despawn) ───────────────────────
function AIMemory:forget()
	self.sightings        = {}
	self.lastKnownPos     = nil
	self.lastTargetId     = nil
	self.alertedBy        = nil
	self.aggroCooldownEnd = 0
end

-- ── Share memory with nearby allies ─────────────────────────────
-- Call when a mob spots a player; nearby mobs with no target get updated
function AIMemory:shareWithAllies(position, player)
	local rootPart = self.model:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	for model, mem in pairs(_registry) do
		if model == self.model then continue end
		if not model.Parent then
			_registry[model] = nil
			continue
		end
		local allyRoot = model:FindFirstChild("HumanoidRootPart")
		if allyRoot then
			local dist = (rootPart.Position - allyRoot.Position).Magnitude
			if dist <= MEMORY_SHARE_RADIUS and not mem.lastTargetId then
				mem:recordSighting(position, player)
				EventBus.emit("AIMemory:SharedAlert", model, self.model, player)
			end
		end
	end
end

-- ── Static lookup ────────────────────────────────────────────────
function AIMemory.get(mobModel)
	return _registry[mobModel]
end

function AIMemory.remove(mobModel)
	_registry[mobModel] = nil
end

-- ── Decay loop: purge stale sightings every 5 seconds ────────────
local _lastDecay = 0
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if now - _lastDecay < 5 then return end
	_lastDecay = now
	for model, mem in pairs(_registry) do
		if not model.Parent then
			_registry[model] = nil
			continue
		end
		-- prune old sightings
		local pruned = {}
		for _, s in ipairs(mem.sightings) do
			if now - s.t < SIGHTING_DECAY then
				table.insert(pruned, s)
			end
		end
		mem.sightings = pruned
		if #pruned == 0 then
			mem.lastKnownPos = nil
			mem.lastTargetId = nil
		end
	end
end)

AIMemory.AGGRO_COOLDOWN       = AGGRO_COOLDOWN
AIMemory.MEMORY_SHARE_RADIUS  = MEMORY_SHARE_RADIUS

return AIMemory
