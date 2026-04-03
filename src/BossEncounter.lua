-- BossEncounter.lua
-- Spawns, manages phases, loot drops and cleanup for world boss encounters
-- v2.7.0

local WorldConfig = require(script.Parent.WorldConfig)
local LootTable   = require(script.Parent.LootTable)
local BossEncounter = {}

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local Workspace   = game:GetService("Workspace")

-- ── Config ─────────────────────────────────────────────────────────
local BOSS_CATALOGUE = WorldConfig.BOSSES or {
	{
		id          = "TerrorGolem",
		displayName = "Terror Golem",
		minLevel    = 15,
		maxHp       = 5000,
		phases      = {
			{ hpThreshold=1.0, dmgMult=1.0,  speed=14, ability="Smash"     },
			{ hpThreshold=0.6, dmgMult=1.4,  speed=18, ability="RockShower" },
			{ hpThreshold=0.3, dmgMult=2.0,  speed=22, ability="Berserk"    },
		},
		rewardXP    = 2000,
		lootId      = "BossChest",
		spawnBiomes = { "Volcanic", "Tundra" },
	},
	{
		id          = "SwampWitch",
		displayName = "Swamp Witch",
		minLevel    = 20,
		maxHp       = 3500,
		phases      = {
			{ hpThreshold=1.0, dmgMult=1.0,  speed=12, ability="CurseAura"  },
			{ hpThreshold=0.5, dmgMult=1.6,  speed=15, ability="SummonToads" },
			{ hpThreshold=0.25,dmgMult=2.2,  speed=18, ability="DeathWail"  },
		},
		rewardXP    = 1800,
		lootId      = "WitchRelics",
		spawnBiomes = { "Swamp", "Jungle" },
	},
}

-- ── State ──────────────────────────────────────────────────────────
local activeBosses  = {}  -- [bossId] = { model, hp, phaseIndex, engaged }
local spawnCooldown = {}  -- [bossId] = nextSpawnTime (os.clock)

local RESPAWN_DELAY = WorldConfig.BOSS_RESPAWN_DELAY or 600  -- 10 min

-- ── Helpers ────────────────────────────────────────────────────────
local function getBossDef(id)
	for _, b in BOSS_CATALOGUE do if b.id == id then return b end end
	return nil
end

local function currentPhase(def, hp)
	local ratio = hp / def.maxHp
	local bestPhase = def.phases[1]
	for _, phase in def.phases do
		if ratio <= phase.hpThreshold then
			bestPhase = phase
		end
	end
	return bestPhase
end

-- ── Public API ─────────────────────────────────────────────────────

---Triggers a boss encounter at the given CFrame.
---@param bossId string
---@param spawnCF CFrame
function BossEncounter.Spawn(bossId, spawnCF)
	if activeBosses[bossId] then
		if WorldConfig.Debug then warn("[Boss] Already active:", bossId) end
		return false
	end
	local def = getBossDef(bossId)
	if not def then return false end
	local now = os.clock()
	if spawnCooldown[bossId] and now < spawnCooldown[bossId] then
		return false
	end

	-- Build a placeholder model (replaced by real asset via AssetPlacer in production)
	local model = Instance.new("Model")
	model.Name  = def.displayName
	local root  = Instance.new("Part")
	root.Name   = "HumanoidRootPart"
	root.Size   = Vector3.new(6, 8, 6)
	root.CFrame = spawnCF
	root.Anchored = false
	root.Parent = model
	local hum   = Instance.new("Humanoid")
	hum.MaxHealth = def.maxHp
	hum.Health    = def.maxHp
	hum.Parent    = model
	model.Parent  = Workspace

	activeBosses[bossId] = {
		model      = model,
		hp         = def.maxHp,
		phaseIndex = 1,
		engaged    = false,
		def        = def,
	}

	-- Death handler
	hum.Died:Connect(function()
		BossEncounter._OnDeath(bossId)
	end)

	if WorldConfig.Debug then
		warn("[Boss] Spawned", def.displayName, "at", tostring(spawnCF.Position))
	end
	return true
end

function BossEncounter._OnDeath(bossId)
	local record = activeBosses[bossId]
	if not record then return end
	local def = record.def

	-- Drop loot for all nearby players
	local bossPos = record.model.PrimaryPart
					and record.model.PrimaryPart.Position
					or Vector3.new(0, 0, 0)
	for _, player in Players:GetPlayers() do
		if player.Character then
			local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
			if rootPart and (rootPart.Position - bossPos).Magnitude < 200 then
				local drops = LootTable.Roll(def.lootId, 1)
				if WorldConfig.Debug then
					warn("[Boss] Loot for", player.Name, ":", drops)
				end
			end
		end
	end

	-- Cleanup
	record.model:Destroy()
	activeBosses[bossId] = nil
	spawnCooldown[bossId] = os.clock() + RESPAWN_DELAY
end

---Deals damage to a boss. Handles phase transitions.
function BossEncounter.DamageBoss(bossId, damage)
	local record = activeBosses[bossId]
	if not record then return end
	local hum = record.model:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	hum:TakeDamage(damage)
	record.hp = hum.Health
	-- Phase check
	local phase = currentPhase(record.def, record.hp)
	if WorldConfig.Debug then
		warn("[Boss]", bossId, "HP:", record.hp, "Phase ability:", phase.ability)
	end
end

function BossEncounter.GetActiveBosses()
	return activeBosses
end

function BossEncounter.Init()
end

function BossEncounter.Start()
	-- Heartbeat: mark bosses as engaged when players are within range
	RunService.Heartbeat:Connect(function()
		for bossId, record in activeBosses do
			if not record.model or not record.model.Parent then
				activeBosses[bossId] = nil
				continue
			end
			local root = record.model:FindFirstChild("HumanoidRootPart")
			if not root then continue end
			for _, player in Players:GetPlayers() do
				if player.Character then
					local pr = player.Character:FindFirstChild("HumanoidRootPart")
					if pr and (pr.Position - root.Position).Magnitude < 150 then
						record.engaged = true
					end
				end
			end
		end
	end)
end

return BossEncounter
