--!strict
-- ============================================================
-- MODULE: ObjectPool
-- Generic object pool — eliminates lag spikes from
-- repeated Instance.new() / Destroy() during mob spawn,
-- particle effects, ore nodes, projectiles, etc.
--
-- Usage:
--   local pool = ObjectPool.new(template, 20)
--   local obj  = pool:Acquire()
--   pool:Release(obj)
-- v1.0.0 | roblox-procedural-worlds
-- ============================================================

local ObjectPool = {}
ObjectPool.__index = ObjectPool

export type Pool = typeof(setmetatable({} :: {
	_template:  Instance,
	_parent:    Instance,
	_available: { Instance },
	_inUse:     { [Instance]: boolean },
	_maxSize:   number,
	_created:   number,
}, ObjectPool))

-- ── Constructor ──────────────────────────────────────────────────

--- Create a new pool.
--- @param template  The Instance to clone (must be archivable).
--- @param maxSize   Maximum pool size.
--- @param parent    Where to park inactive instances (default: Workspace).
function ObjectPool.new(template: Instance, maxSize: number, parent: Instance?): Pool
	local self = setmetatable({}, ObjectPool)
	self._template  = template
	self._parent    = parent or game:GetService("Workspace")
	self._available = {}
	self._inUse     = {}
	self._maxSize   = maxSize or 50
	self._created   = 0

	-- Pre-warm the pool with half capacity
	local prewarm = math.floor(maxSize * 0.5)
	for _ = 1, prewarm do
		local obj = template:Clone()
		obj.Parent = nil
		table.insert(self._available, obj)
		self._created += 1
	end

	return self
end

-- ── Acquire ──────────────────────────────────────────────────────

--- Get an instance from the pool. Creates one if none available.
function ObjectPool:Acquire(): Instance?
	local obj: Instance

	if #self._available > 0 then
		obj = table.remove(self._available) :: Instance
	else
		if self._created >= self._maxSize then
			warn("[ObjectPool] Pool exhausted for", self._template.Name,
				"(max:", self._maxSize, "). Consider increasing maxSize.")
			return nil
		end
		obj = self._template:Clone()
		self._created += 1
	end

	self._inUse[obj] = true
	return obj
end

-- ── Release ──────────────────────────────────────────────────────

--- Return an instance to the pool. Resets its parent and position.
function ObjectPool:Release(obj: Instance)
	if not self._inUse[obj] then
		warn("[ObjectPool] Tried to release an object not acquired from this pool:", obj.Name)
		return
	end

	self._inUse[obj] = nil
	obj.Parent = nil  -- park it
	table.insert(self._available, obj)
end

-- ── Utilities ────────────────────────────────────────────────────

--- How many are currently available.
function ObjectPool:Available(): number
	return #self._available
end

--- How many are currently in use.
function ObjectPool:InUse(): number
	local count = 0
	for _ in pairs(self._inUse) do count += 1 end
	return count
end

--- Destroy the entire pool and all instances.
function ObjectPool:Destroy()
	for _, obj in ipairs(self._available) do
		obj:Destroy()
	end
	for obj in pairs(self._inUse) do
		obj:Destroy()
	end
	self._available = {}
	self._inUse     = {}
	self._created   = 0
end

-- ── Global Registry ──────────────────────────────────────────────
-- Central registry so systems can share pools by name.

local registry: { [string]: Pool } = {}

--- Register a named pool for global access.
function ObjectPool.Register(name: string, pool: Pool)
	if registry[name] then
		warn("[ObjectPool] Overwriting existing pool:", name)
	end
	registry[name] = pool
end

--- Get a registered pool by name.
function ObjectPool.Get(name: string): Pool?
	return registry[name]
end

--- Convenience: acquire from a named pool.
function ObjectPool.AcquireFrom(name: string): Instance?
	local pool = registry[name]
	if not pool then
		warn("[ObjectPool] No pool registered as:", name)
		return nil
	end
	return pool:Acquire()
end

--- Convenience: release to a named pool.
function ObjectPool.ReleaseTo(name: string, obj: Instance)
	local pool = registry[name]
	if not pool then
		warn("[ObjectPool] No pool registered as:", name)
		return
	end
	pool:Release(obj)
end

--- Print stats for all registered pools.
function ObjectPool.PrintStats()
	print("[ObjectPool] === Pool Stats ===")
	for name, pool in pairs(registry) do
		print(string.format("  %-20s available=%-4d inUse=%-4d total=%d",
			name, pool:Available(), pool:InUse(), pool._created))
	end
end

return ObjectPool
