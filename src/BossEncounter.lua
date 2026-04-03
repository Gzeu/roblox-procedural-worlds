-- BossEncounter.lua
-- Boss encounters with multi-phase HP thresholds, enrage timer, special attacks
-- v4.0 | roblox-procedural-worlds

local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")
local EventBus   = require(script.Parent.EventBus)
local WorldConfig = require(script.Parent.WorldConfig)

local BossEncounter = {}
BossEncounter.__index = BossEncounter

-- ── Phase definitions ────────────────────────────────────────────
-- Each phase activates when hp drops below hpPct threshold
-- Phases listed from highest HP to lowest (first = 100%, last = enrage)
local BOSS_PRESETS = {
	DragonBoss = {
		maxHP        = 5000,
		baseXP       = 1000,
		enrageTime   = 180,   -- seconds until enrage regardless of HP
		phases = {
			{
				hpPct   = 1.0,
				name    = "Resting",
				damageScale  = 1.0,
				speedScale   = 1.0,
				specialAttack = "FireBreath",
				attackCooldown = 4.0,
			},
			{
				hpPct   = 0.70,
				name    = "Wounded",
				damageScale  = 1.3,
				speedScale   = 1.1,
				specialAttack = "WingSlam",
				attackCooldown = 3.0,
			},
			{
				hpPct   = 0.40,
				name    = "Enraged",
				damageScale  = 1.8,
				speedScale   = 1.3,
				specialAttack = "TailWhip",
				attackCooldown = 2.0,
			},
			{
				hpPct   = 0.15,
				name    = "Berserker",
				damageScale  = 2.5,
				speedScale   = 1.5,
				specialAttack = "MeteorRain",
				attackCooldown = 1.5,
			},
		},
	},
	TrollKing = {
		maxHP        = 2000,
		baseXP       = 400,
		enrageTime   = 120,
		phases = {
			{
				hpPct   = 1.0,
				name    = "Calm",
				damageScale  = 1.0,
				speedScale   = 1.0,
				specialAttack = "GroundSlam",
				attackCooldown = 3.5,
			},
			{
				hpPct   = 0.60,
				name    = "Angered",
				damageScale  = 1.5,
				speedScale   = 1.2,
				specialAttack = "RockThrow",
				attackCooldown = 2.5,
			},
			{
				hpPct   = 0.25,
				name    = "Frenzy",
				damageScale  = 2.2,
				speedScale   = 1.4,
				specialAttack = "BoulderBarrage",
				attackCooldown = 1.8,
			},
		},
	},
}

-- ── Special attack handlers ──────────────────────────────────────
-- Each handler receives (bossInstance, nearbyPlayers)
local SpecialAttacks = {}

SpecialAttacks.FireBreath = function(boss, players)
	local root = boss.model:FindFirstChild("HumanoidRootPart")
	if not root then return end
	for _, p in ipairs(players) do
		if p.Character then
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - root.Position).Magnitude <= 35 then
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:TakeDamage(math.floor(boss:getCurrentDamage() * 0.8))
				end
				EventBus.emit("BossEncounter:SpecialHit", boss.model, p, "FireBreath")
			end
		end
	end
end

SpecialAttacks.WingSlam = function(boss, players)
	local root = boss.model:FindFirstChild("HumanoidRootPart")
	if not root then return end
	for _, p in ipairs(players) do
		if p.Character then
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - root.Position).Magnitude <= 20 then
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:TakeDamage(math.floor(boss:getCurrentDamage() * 1.4))
					-- knockback via BodyVelocity
					local bv = Instance.new("BodyVelocity")
					bv.Velocity = (hrp.Position - root.Position).Unit * 80
						+ Vector3.new(0, 30, 0)
					bv.MaxForce = Vector3.new(1e5,1e5,1e5)
					bv.Parent = hrp
					task.delay(0.25, function() bv:Destroy() end)
				end
				EventBus.emit("BossEncounter:SpecialHit", boss.model, p, "WingSlam")
			end
		end
	end
end

SpecialAttacks.GroundSlam = function(boss, players)
	local root = boss.model:FindFirstChild("HumanoidRootPart")
	if not root then return end
	for _, p in ipairs(players) do
		if p.Character then
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - root.Position).Magnitude <= 25 then
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				if hum then hum:TakeDamage(boss:getCurrentDamage()) end
				EventBus.emit("BossEncounter:SpecialHit", boss.model, p, "GroundSlam")
			end
		end
	end
end

SpecialAttacks.RockThrow = function(boss, players)
	local root = boss.model:FindFirstChild("HumanoidRootPart")
	if not root then return end
	for _, p in ipairs(players) do
		if p.Character then
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - root.Position).Magnitude <= 60 then
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				if hum then hum:TakeDamage(math.floor(boss:getCurrentDamage() * 0.6)) end
				EventBus.emit("BossEncounter:SpecialHit", boss.model, p, "RockThrow")
			end
		end
	end
end

-- Fallback for unimplemented specials
local function getSpecialHandler(name)
	return SpecialAttacks[name] or function(boss, players)
		-- Generic AoE
		local root = boss.model:FindFirstChild("HumanoidRootPart")
		if not root then return end
		for _, p in ipairs(players) do
			if p.Character then
				local hrp = p.Character:FindFirstChild("HumanoidRootPart")
				if hrp and (hrp.Position - root.Position).Magnitude <= 30 then
					local hum = p.Character:FindFirstChildOfClass("Humanoid")
					if hum then hum:TakeDamage(boss:getCurrentDamage()) end
				end
			end
		end
	end
end

-- ── Constructor ──────────────────────────────────────────────────
function BossEncounter.new(model, presetName)
	local preset = BOSS_PRESETS[presetName]
	if not preset then
		warn("[BossEncounter] Unknown preset: " .. tostring(presetName))
		preset = BOSS_PRESETS.DragonBoss
	end

	local self = setmetatable({}, BossEncounter)
	self.model        = model
	self.preset       = preset
	self.hp           = preset.maxHP
	self.maxHP        = preset.maxHP
	self.phaseIndex   = 1
	self.startTime    = os.clock()
	self.enraged      = false
	self.isAlive      = true
	self.lastSpecial  = 0
	self.baseDamage   = WorldConfig.BOSS_BASE_DAMAGE or 40
	self._connections = {}

	model:SetAttribute("IsBoss",    true)
	model:SetAttribute("BossPreset", presetName)
	model:SetAttribute("XPReward",  preset.baseXP)

	return self
end

-- ── Current phase ────────────────────────────────────────────────
function BossEncounter:getCurrentPhase()
	local phases = self.preset.phases
	local hpPct  = self.hp / self.maxHP
	local current = phases[1]
	for _, phase in ipairs(phases) do
		if hpPct <= phase.hpPct then
			current = phase
		end
	end
	return current
end

function BossEncounter:getCurrentDamage()
	local phase = self:getCurrentPhase()
	local scale = phase.damageScale * (self.enraged and 1.5 or 1.0)
	return math.floor(self.baseDamage * scale)
end

-- ── Phase transition ─────────────────────────────────────────────
function BossEncounter:checkPhaseTransition()
	local hpPct = self.hp / self.maxHP
	local phases = self.preset.phases
	for i = #phases, 2, -1 do
		if hpPct <= phases[i].hpPct and self.phaseIndex < i then
			self.phaseIndex = i
			EventBus.emit("BossEncounter:PhaseChange", self.model, i, phases[i].name)
			if WorldConfig.EVENT_BUS_DEBUG then
				warn(string.format("[BossEncounter] %s entered phase %d: %s",
					self.model.Name, i, phases[i].name))
			end
			return
		end
	end
end

-- ── Take damage ──────────────────────────────────────────────────
function BossEncounter:takeDamage(amount, attacker)
	if not self.isAlive then return end
	self.hp = math.max(0, self.hp - amount)
	self:checkPhaseTransition()
	EventBus.emit("BossEncounter:Damaged", self.model, amount, self.hp, self.maxHP)

	if self.hp <= 0 then
		self.isAlive = false
		self:stop()
		EventBus.emit("BossEncounter:Defeated", self.model, attacker)
	end
end

-- ── Main loop ────────────────────────────────────────────────────
function BossEncounter:start()
	local conn = RunService.Heartbeat:Connect(function(dt)
		if not self.isAlive then return end

		local now  = os.clock()
		local root = self.model:FindFirstChild("HumanoidRootPart")
		if not root or not root.Parent then self:stop(); return end

		-- Enrage timer
		if not self.enraged and now - self.startTime >= self.preset.enrageTime then
			self.enraged = true
			EventBus.emit("BossEncounter:Enraged", self.model)
			if WorldConfig.EVENT_BUS_DEBUG then
				warn("[BossEncounter] " .. self.model.Name .. " has ENRAGED!")
			end
		end

		-- Special attack tick
		local phase   = self:getCurrentPhase()
		local cooldown = phase.attackCooldown * (self.enraged and 0.6 or 1.0)
		if now - self.lastSpecial >= cooldown then
			self.lastSpecial = now
			local nearby = Players:GetPlayers()
			local handler = getSpecialHandler(phase.specialAttack)
			task.spawn(handler, self, nearby)
			EventBus.emit("BossEncounter:SpecialAttack",
				self.model, phase.specialAttack, phase.name)
		end
	end)
	table.insert(self._connections, conn)
end

function BossEncounter:stop()
	for _, c in ipairs(self._connections) do c:Disconnect() end
	self._connections = {}
end

-- ── Static spawn helper ──────────────────────────────────────────
function BossEncounter.spawn(position, presetName)
	local model = Instance.new("Model")
	model.Name  = presetName or "Boss"

	local part  = Instance.new("Part")
	part.Size        = Vector3.new(6, 8, 6)
	part.BrickColor  = BrickColor.new("Dark red")
	part.Anchored    = false
	part.CFrame      = CFrame.new(position + Vector3.new(0, 4, 0))
	part.Name        = "HumanoidRootPart"
	part.Parent      = model

	local hum = Instance.new("Humanoid")
	local preset = BOSS_PRESETS[presetName or "DragonBoss"]
	hum.MaxHealth = preset and preset.maxHP or 5000
	hum.Health    = hum.MaxHealth
	hum.Parent    = model

	model.Parent = workspace

	local boss = BossEncounter.new(model, presetName or "DragonBoss")
	boss:start()
	EventBus.emit("BossEncounter:Spawned", model, presetName)
	return boss
end

BossEncounter.PRESETS = BOSS_PRESETS
return BossEncounter
