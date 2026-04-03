-- MobAI.lua
-- Finite State Machine for mob intelligence
-- States: Idle → Patrol → Alert → Chase → Attack → Flee
-- v3.0 | roblox-procedural-worlds

local PathfindingService = game:GetService("PathfindingService")
local RunService         = game:GetService("RunService")
local EventBus           = require(script.Parent.EventBus)
local AINavigator        = require(script.Parent.AINavigator)

local MobAI = {}
MobAI.__index = MobAI

-- ── State constants ──────────────────────────────────────────────
local STATE = {
	IDLE    = "Idle",
	PATROL  = "Patrol",
	ALERT   = "Alert",
	CHASE   = "Chase",
	ATTACK  = "Attack",
	FLEE    = "Flee",
	DEAD    = "Dead",
}

-- ── Default config ───────────────────────────────────────────────
local DEFAULTS = {
	detectRange     = 50,   -- studs to notice a player
	attackRange     = 6,    -- studs to melee attack
	fleeHealthPct   = 0.20, -- flee below 20% HP
	patrolRadius    = 30,   -- studs from home to wander
	alertDuration   = 3,    -- seconds paused in alert before chasing
	attackCooldown  = 1.5,  -- seconds between attacks
	patrolWaitMin   = 2,
	patrolWaitMax   = 5,
	moveSpeed       = 14,
	damage          = 10,
	maxHP           = 100,
	isHostile       = true,
}

-- ── Constructor ──────────────────────────────────────────────────
function MobAI.new(model, config)
	local self = setmetatable({}, MobAI)

	self.model      = model
	self.humanoid   = model:FindFirstChildOfClass("Humanoid")
	self.rootPart   = model:FindFirstChild("HumanoidRootPart")
	self.config     = setmetatable(config or {}, { __index = DEFAULTS })
	self.state      = STATE.IDLE
	self.target     = nil
	self.homePos    = self.rootPart and self.rootPart.Position or Vector3.new(0,0,0)
	self.hp         = self.config.maxHP
	self.lastAttack = 0
	self.alertTimer = 0
	self.patrolTarget = nil
	self.navigator  = AINavigator.new(model)
	self._connections = {}
	self._running   = false

	return self
end

-- ── Transition ───────────────────────────────────────────────────
function MobAI:setState(newState)
	if self.state == newState then return end
	local prev = self.state
	self.state = newState
	EventBus.emit("MobAI:StateChanged", self.model, prev, newState)
end

-- ── Nearest player within range ──────────────────────────────────
local function getNearestPlayer(origin, range)
	local Players = game:GetService("Players")
	local nearest, bestDist = nil, range
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local d = (hrp.Position - origin).Magnitude
				if d < bestDist then
					bestDist = d
					nearest = p
				end
			end
		end
	end
	return nearest, bestDist
end

-- ── Tick helpers ─────────────────────────────────────────────────
function MobAI:_tickIdle(dt)
	if not self.config.isHostile then return end
	local p, d = getNearestPlayer(self.rootPart.Position, self.config.detectRange)
	if p then
		self.target = p
		self.alertTimer = self.config.alertDuration
		self:setState(STATE.ALERT)
	end
end

function MobAI:_tickAlert(dt)
	self.alertTimer = self.alertTimer - dt
	if self.alertTimer <= 0 then
		self:setState(STATE.CHASE)
	end
end

function MobAI:_tickPatrol(dt)
	if not self.patrolTarget or
		(self.rootPart.Position - self.patrolTarget).Magnitude < 5 then
		local angle  = math.random() * math.pi * 2
		local radius = math.random(5, self.config.patrolRadius)
		self.patrolTarget = self.homePos +
			Vector3.new(math.cos(angle)*radius, 0, math.sin(angle)*radius)
	end
	self.navigator:moveTo(self.patrolTarget)

	if self.config.isHostile then
		local p, d = getNearestPlayer(self.rootPart.Position, self.config.detectRange)
		if p then
			self.target = p
			self:setState(STATE.CHASE)
		end
	end
end

function MobAI:_tickChase(dt)
	if not self.target or not self.target.Character then
		self:setState(STATE.PATROL)
		return
	end

	local targetHRP = self.target.Character:FindFirstChild("HumanoidRootPart")
	if not targetHRP then
		self:setState(STATE.PATROL)
		return
	end

	local dist = (self.rootPart.Position - targetHRP.Position).Magnitude

	-- Check flee condition
	if self.hp / self.config.maxHP <= self.config.fleeHealthPct then
		self:setState(STATE.FLEE)
		return
	end

	-- Lost sight
	if dist > self.config.detectRange * 1.5 then
		self.target = nil
		self:setState(STATE.PATROL)
		return
	end

	-- Close enough to attack
	if dist <= self.config.attackRange then
		self:setState(STATE.ATTACK)
		return
	end

	self.navigator:moveTo(targetHRP.Position)
end

function MobAI:_tickAttack(dt)
	if not self.target or not self.target.Character then
		self:setState(STATE.PATROL)
		return
	end

	local targetHRP = self.target.Character:FindFirstChild("HumanoidRootPart")
	if not targetHRP then
		self:setState(STATE.PATROL)
		return
	end

	local dist = (self.rootPart.Position - targetHRP.Position).Magnitude

	if dist > self.config.attackRange * 1.4 then
		self:setState(STATE.CHASE)
		return
	end

	local now = os.clock()
	if now - self.lastAttack >= self.config.attackCooldown then
		self.lastAttack = now
		local targetHum = self.target.Character:FindFirstChildOfClass("Humanoid")
		if targetHum then
			targetHum:TakeDamage(self.config.damage)
			EventBus.emit("MobAI:Attack", self.model, self.target, self.config.damage)
		end
	end
end

function MobAI:_tickFlee(dt)
	if not self.target or not self.target.Character then
		self:setState(STATE.IDLE)
		return
	end
	local targetHRP = self.target.Character:FindFirstChild("HumanoidRootPart")
	if targetHRP then
		local dir = (self.rootPart.Position - targetHRP.Position).Unit
		local fleePos = self.rootPart.Position + dir * 40
		self.navigator:moveTo(fleePos)
	end
	-- If far enough, recover
	if self.hp / self.config.maxHP > self.config.fleeHealthPct + 0.1 then
		self:setState(STATE.PATROL)
	end
end

-- ── Take damage ──────────────────────────────────────────────────
function MobAI:takeDamage(amount, attacker)
	if self.state == STATE.DEAD then return end
	self.hp = math.max(0, self.hp - amount)
	EventBus.emit("MobAI:Damaged", self.model, amount, self.hp)

	if self.hp <= 0 then
		self:setState(STATE.DEAD)
		self:stop()
		EventBus.emit("MobAI:Died", self.model, attacker)
		return
	end

	if attacker and self.config.isHostile and self.state == STATE.IDLE then
		self.target = attacker
		self:setState(STATE.CHASE)
	end
end

-- ── Heal ─────────────────────────────────────────────────────────
function MobAI:heal(amount)
	self.hp = math.min(self.config.maxHP, self.hp + amount)
end

-- ── Main loop ────────────────────────────────────────────────────
function MobAI:start()
	if self._running then return end
	self._running = true

	local conn = RunService.Heartbeat:Connect(function(dt)
		if self.state == STATE.DEAD then return end
		if not self.rootPart or not self.rootPart.Parent then
			self:stop()
			return
		end

		if     self.state == STATE.IDLE   then self:_tickIdle(dt)
		elseif self.state == STATE.PATROL then self:_tickPatrol(dt)
		elseif self.state == STATE.ALERT  then self:_tickAlert(dt)
		elseif self.state == STATE.CHASE  then self:_tickChase(dt)
		elseif self.state == STATE.ATTACK then self:_tickAttack(dt)
		elseif self.state == STATE.FLEE   then self:_tickFlee(dt)
		end
	end)
	table.insert(self._connections, conn)
end

function MobAI:stop()
	self._running = false
	for _, c in ipairs(self._connections) do c:Disconnect() end
	self._connections = {}
	self.navigator:stop()
end

MobAI.STATE = STATE
return MobAI
