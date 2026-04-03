-- RunModifiers.lua
-- Roguelite curses and boons for dungeon / arena runs
-- v5.0 | roblox-procedural-worlds

local EventBus = require(script.Parent.EventBus)

local RunModifiers = {}

local activeRuns   = {}
local playerRunMap = {}

local BOONS = {
	{ name = "Warrior's Blessing", weight = 24, effects = { damageMultiplier = 0.12 } },
	{ name = "Swiftstep",          weight = 20, effects = { moveSpeed = 2, dodgeChance = 0.05 } },
	{ name = "Scholar's Sigil",    weight = 16, effects = { xpBonus = 0.15, magicDamage = 5 } },
	{ name = "Bulwark",            weight = 18, effects = { maxHP = 35, damageReduction = 0.05 } },
	{ name = "Fortune Echo",       weight = 12, effects = { lootMultiplier = 0.20 } },
}

local CURSES = {
	{ name = "Blood Moon",  weight = 25, effects = { enemyDamageMultiplier = 0.18 } },
	{ name = "Thin Air",    weight = 18, effects = { healMultiplier = -0.20 } },
	{ name = "Greed Tax",   weight = 20, effects = { shopPriceMultiplier = 0.18 } },
	{ name = "Ruin Pulse",  weight = 15, effects = { enemyHPMultiplier = 0.15 } },
	{ name = "Shadow Fog",  weight = 22, effects = { sightPenalty = 0.20 } },
}

local function weightedRoll(pool)
	local total = 0
	for _, e in ipairs(pool) do total += e.weight end
	local roll   = Random.new():NextNumber(0, total)
	local cursor = 0
	for _, e in ipairs(pool) do
		cursor += e.weight
		if roll <= cursor then return e end
	end
	return pool[1]
end

local function mergeEffects(modifiers)
	local out = {}
	for _, mod in ipairs(modifiers) do
		for key, value in pairs(mod.effects or {}) do
			out[key] = (out[key] or 0) + value
		end
	end
	return out
end

function RunModifiers.startRun(runId, players)
	activeRuns[runId] = {
		players   = players or {},
		boons     = {},
		curses    = {},
		startedAt = os.time(),
	}
	for _, player in ipairs(players or {}) do
		playerRunMap[player.UserId] = runId
	end
	EventBus.emit("RunModifiers:Started", runId, players)
	return activeRuns[runId]
end

function RunModifiers.autoRoll(runId, boonCount, curseCount)
	local run = activeRuns[runId]
	if not run then return false, "Run not found" end
	for _ = 1, boonCount  or 1 do table.insert(run.boons,  weightedRoll(BOONS))  end
	for _ = 1, curseCount or 1 do table.insert(run.curses, weightedRoll(CURSES)) end
	EventBus.emit("RunModifiers:Rolled", runId, run.boons, run.curses)
	return true, run
end

function RunModifiers.addModifier(runId, kind, modifier)
	local run = activeRuns[runId]
	if not run then return false, "Run not found" end
	if     kind == "boon"  then table.insert(run.boons,  modifier)
	elseif kind == "curse" then table.insert(run.curses, modifier)
	else   return false, "Unknown modifier kind"
	end
	EventBus.emit("RunModifiers:ModifierAdded", runId, kind, modifier)
	return true
end

function RunModifiers.getRun(runId)
	return activeRuns[runId]
end

function RunModifiers.getPlayerEffects(player)
	local runId = playerRunMap[player.UserId]
	local run   = runId and activeRuns[runId]
	if not run then return {} end
	local modifiers = {}
	for _, boon  in ipairs(run.boons)  do table.insert(modifiers, boon)  end
	for _, curse in ipairs(run.curses) do table.insert(modifiers, curse) end
	return mergeEffects(modifiers)
end

function RunModifiers.endRun(runId, success)
	local run = activeRuns[runId]
	if not run then return false, "Run not found" end
	for _, player in ipairs(run.players or {}) do
		playerRunMap[player.UserId] = nil
	end
	activeRuns[runId] = nil
	EventBus.emit("RunModifiers:Ended", runId, success)
	return true
end

return RunModifiers
