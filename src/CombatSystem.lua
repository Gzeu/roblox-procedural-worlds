-- CombatSystem.lua
-- Handles melee/ranged combat, hit detection, damage calculation, status effects
-- v2.4.0

local WorldConfig = require(script.Parent.WorldConfig)
local CombatSystem = {}

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")

-- ── State ──────────────────────────────────────────────────────────
local activeCombatants = {}  -- [userId] = { hp, maxHp, effects, lastHit }
local statusEffects    = {}  -- [userId] = { [effectName] = { duration, tickDmg } }

local EFFECT_TICK = 1  -- seconds between DoT ticks

-- ── Helpers ────────────────────────────────────────────────────────
local function getHumanoid(character)
	return character and character:FindFirstChild("Humanoid")
end

local function clamp(v, lo, hi)
	return math.max(lo, math.min(hi, v))
end

-- ── Public API ─────────────────────────────────────────────────────
function CombatSystem.RegisterPlayer(player)
	local uid = player.UserId
	activeCombatants[uid] = {
		hp    = WorldConfig.PLAYER_MAX_HP,
		maxHp = WorldConfig.PLAYER_MAX_HP,
		effects = {},
		lastHit = 0,
	}
	statusEffects[uid] = {}
end

function CombatSystem.UnregisterPlayer(player)
	activeCombatants[player.UserId] = nil
	statusEffects[player.UserId]    = nil
end

---Applies damage to a player's character Humanoid.
---@param attacker Player|nil
---@param victim   Player
---@param rawDamage number
---@param damageType string  "Melee"|"Ranged"|"Magic"|"Fall"
function CombatSystem.DealDamage(attacker, victim, rawDamage, damageType)
	if not victim or not victim.Character then return end
	local hum = getHumanoid(victim.Character)
	if not hum or hum.Health <= 0 then return end

	-- Apply global AI damage multiplier when attacker is an NPC
	local finalDmg = rawDamage
	if attacker == nil then
		finalDmg = rawDamage * WorldConfig.AI_DAMAGE_MULTIPLIER
	end
	finalDmg = math.max(1, math.floor(finalDmg))

	hum:TakeDamage(finalDmg)

	local uid = victim.UserId
	if activeCombatants[uid] then
		activeCombatants[uid].hp = clamp(hum.Health, 0, hum.MaxHealth)
		activeCombatants[uid].lastHit = os.clock()
	end

	if WorldConfig.Debug then
		warn(string.format("[CombatSystem] %s dealt %d %s dmg to %s",
			attacker and attacker.Name or "NPC", finalDmg, damageType, victim.Name))
	end
end

---Applies a status effect (poison, burn, slow) to a player.
---@param victim     Player
---@param effectName string
---@param duration   number  seconds
---@param tickDamage number  damage per tick (0 for non-DoT)
function CombatSystem.ApplyStatusEffect(victim, effectName, duration, tickDamage)
	local uid = victim.UserId
	if not statusEffects[uid] then return end
	statusEffects[uid][effectName] = {
		duration  = duration,
		ticeDamage = tickDamage,
		nextTick  = os.clock() + EFFECT_TICK,
	}
	if WorldConfig.Debug then
		warn("[CombatSystem] Applied", effectName, "to", victim.Name)
	end
end

---Removes all active status effects from a player.
function CombatSystem.ClearEffects(victim)
	local uid = victim.UserId
	if statusEffects[uid] then
		statusEffects[uid] = {}
	end
end

---Returns combat record for a player.
function CombatSystem.GetRecord(player)
	return activeCombatants[player.UserId]
end

-- ── DoT tick loop ──────────────────────────────────────────────────
function CombatSystem.Init()
	Players.PlayerAdded:Connect(CombatSystem.RegisterPlayer)
	Players.PlayerRemoving:Connect(CombatSystem.UnregisterPlayer)
	for _, p in Players:GetPlayers() do
		CombatSystem.RegisterPlayer(p)
	end
end

function CombatSystem.Start()
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for uid, effects in statusEffects do
			local player = Players:GetPlayerByUserId(uid)
			if not player or not player.Character then continue end
			for name, eff in effects do
				eff.duration -= 0.016
				if eff.duration <= 0 then
					effects[name] = nil
					continue
				end
				if now >= eff.nextTick and eff.ticeDamage > 0 then
					eff.nextTick = now + EFFECT_TICK
					CombatSystem.DealDamage(nil, player, eff.ticeDamage, "Status")
				end
			end
		end
	end)
end

return CombatSystem
