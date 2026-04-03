-- BehaviorTree.lua
-- Lightweight Behavior Tree engine: Sequence, Selector, Condition, Action, Decorator nodes
-- v3.0 | roblox-procedural-worlds
--
-- Node return values:
--   "SUCCESS" | "FAILURE" | "RUNNING"
--
-- Usage:
--   local BT = require(BehaviorTree)
--   local tree = BT.Sequence({
--       BT.Condition(function(ctx) return ctx.hp > 20 end),
--       BT.Action(function(ctx) ctx.mob:attack() return "SUCCESS" end),
--   })
--   local status = tree:tick(context)

local BT = {}

-- ── Base node ────────────────────────────────────────────────────
local Node = {}
Node.__index = Node

function Node:tick(ctx)
	return "FAILURE"
end

-- ── Sequence: runs children left→right, stops on first FAILURE ───
function BT.Sequence(children)
	local node = setmetatable({ children = children, _running = 0 }, Node)
	function node:tick(ctx)
		for i = self._running + 1, #self.children do
			local s = self.children[i]:tick(ctx)
			if s == "FAILURE" then self._running = 0; return "FAILURE" end
			if s == "RUNNING" then self._running = i - 1; return "RUNNING" end
		end
		self._running = 0
		return "SUCCESS"
	end
	return node
end

-- ── Selector: runs children left→right, stops on first SUCCESS ───
function BT.Selector(children)
	local node = setmetatable({ children = children }, Node)
	function node:tick(ctx)
		for _, child in ipairs(self.children) do
			local s = child:tick(ctx)
			if s == "SUCCESS" then return "SUCCESS" end
			if s == "RUNNING"  then return "RUNNING"  end
		end
		return "FAILURE"
	end
	return node
end

-- ── Parallel: runs all children, returns SUCCESS if >= minSuccess succeed ─
function BT.Parallel(children, minSuccess)
	minSuccess = minSuccess or #children
	local node = setmetatable({ children = children, minSuccess = minSuccess }, Node)
	function node:tick(ctx)
		local successes, failures = 0, 0
		for _, child in ipairs(self.children) do
			local s = child:tick(ctx)
			if s == "SUCCESS" then successes += 1 end
			if s == "FAILURE" then failures  += 1 end
		end
		if successes >= self.minSuccess then return "SUCCESS" end
		if failures  >  #self.children - self.minSuccess then return "FAILURE" end
		return "RUNNING"
	end
	return node
end

-- ── Condition: fn(ctx) → bool ────────────────────────────────────
function BT.Condition(fn, label)
	local node = setmetatable({ fn = fn, label = label or "Condition" }, Node)
	function node:tick(ctx)
		return self.fn(ctx) and "SUCCESS" or "FAILURE"
	end
	return node
end

-- ── Action: fn(ctx) → "SUCCESS" | "FAILURE" | "RUNNING" ──────────
function BT.Action(fn, label)
	local node = setmetatable({ fn = fn, label = label or "Action" }, Node)
	function node:tick(ctx)
		return self.fn(ctx) or "SUCCESS"
	end
	return node
end

-- ── Inverter: flips SUCCESS ↔ FAILURE ────────────────────────────
function BT.Inverter(child)
	local node = setmetatable({ child = child }, Node)
	function node:tick(ctx)
		local s = self.child:tick(ctx)
		if s == "SUCCESS" then return "FAILURE" end
		if s == "FAILURE" then return "SUCCESS" end
		return "RUNNING"
	end
	return node
end

-- ── Repeater: runs child N times (nil = infinite until FAILURE) ──
function BT.Repeater(child, times)
	local node = setmetatable({ child = child, times = times, _count = 0 }, Node)
	function node:tick(ctx)
		while not self.times or self._count < self.times do
			local s = self.child:tick(ctx)
			if s == "FAILURE" then self._count = 0; return "FAILURE" end
			if s == "RUNNING" then return "RUNNING" end
			self._count += 1
		end
		self._count = 0
		return "SUCCESS"
	end
	return node
end

-- ── Cooldown: prevents ticking child more than once per interval ─
function BT.Cooldown(child, interval)
	local node = setmetatable({ child = child, interval = interval, _last = 0 }, Node)
	function node:tick(ctx)
		local now = os.clock()
		if now - self._last < self.interval then return "FAILURE" end
		local s = self.child:tick(ctx)
		if s ~= "FAILURE" then self._last = now end
		return s
	end
	return node
end

-- ── Tree: top-level wrapper with context ─────────────────────────
function BT.Tree(root, context)
	local tree = { root = root, context = context or {} }
	function tree:tick(ctx)
		return self.root:tick(ctx or self.context)
	end
	return tree
end

return BT
