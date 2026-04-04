-- MobAI.lua
-- Finite State Machine for mob intelligence
-- v4.0 | States: Idle → Patrol → Alert → Chase → Strafe → Attack → Flee → Dead
-- New: STRAFE state, difficulty scaling, HP regen, LKP tracking, lootTable on death

local RunService = game:GetService("RunService")
local EventBus   = require(script.Parent.EventBus)
local AINavigator = require(script.Parent.AINavigator)

local MobAI = {}
MobAI.__index = MobAI

local STATE = {
	IDLE   = "Idle",   PATROL = "Patrol", ALERT  = "Alert",
	CHASE  = "Chase",  STRAFE = "Strafe", ATTACK = "Attack",
	FLEE   = "Flee",   DEAD   = "Dead",
}

local DIFFICULTY_MULT = {
	easy      = { hp=0.6,  dmg=0.5,  detect=0.7, speed=0.8  },
	normal    = { hp=1.0,  dmg=1.0,  detect=1.0, speed=1.0  },
	hard      = { hp=1.5,  dmg=1.4,  detect=1.3, speed=1.15 },
	nightmare = { hp=2.5,  dmg=2.0,  detect=1.6, speed=1.3  },
}

local DEFAULTS = {
	detectRange    = 50,  attackRange   = 6,    strafeRange    = 12,
	fleeHealthPct  = 0.20, patrolRadius  = 30,   alertDuration  = 2.5,
	attackCooldown = 1.5,  patrolWaitMin = 2,    patrolWaitMax  = 5,
	moveSpeed      = 14,   damage        = 10,   maxHP          = 100,
	isHostile      = true, regenRate     = 2,    lkpTimeout     = 8,
	difficulty     = "normal", lootTable = {},
}

function MobAI.new(model, config)
	local self = setmetatable({}, MobAI)
	self.model    = model
	self.humanoid = model:FindFirstChildOfClass("Humanoid")
	self.rootPart = model:FindFirstChild("HumanoidRootPart")
	local cfg  = setmetatable(config or {}, { __index = DEFAULTS })
	local diff = DIFFICULTY_MULT[cfg.difficulty] or DIFFICULTY_MULT.normal
	cfg.maxHP       = cfg.maxHP       * diff.hp
	cfg.damage      = cfg.damage      * diff.dmg
	cfg.detectRange = cfg.detectRange * diff.detect
	cfg.moveSpeed   = cfg.moveSpeed   * diff.speed
	self.config = cfg
	self.state = STATE.IDLE
	self.target = nil
	self.homePos = self.rootPart and self.rootPart.Position or Vector3.new(0,0,0)
	self.hp = cfg.maxHP
	self.lastAttack = 0
	self.alertTimer = 0
	self.patrolTarget = nil
	self.lastKnownPos = nil
	self.inCombat = false
	self.navigator = AINavigator.new(model)
	self._connections = {}
	self._running = false
	return self
end

function MobAI:setState(newState)
	if self.state == newState then return end
	local prev = self.state
	self.state = newState
	self.inCombat = (newState==STATE.CHASE or newState==STATE.ATTACK or newState==STATE.STRAFE)
	EventBus.emit("MobAI:StateChanged", self.model, prev, newState)
end

local function getNearestPlayer(origin, range)
	local Players = game:GetService("Players")
	local nearest, bestDist = nil, range
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local d = (hrp.Position - origin).Magnitude
				if d < bestDist then bestDist,nearest = d,p end
			end
		end
	end
	return nearest, bestDist
end

function MobAI:_tickIdle(dt)
	if self.hp < self.config.maxHP then self:heal(self.config.regenRate * dt) end
	if not self.config.isHostile then return end
	local p = getNearestPlayer(self.rootPart.Position, self.config.detectRange)
	if p then
		self.target = p
		self.alertTimer = self.config.alertDuration
		self:setState(STATE.ALERT)
	else
		task.delay(math.random(self.config.patrolWaitMin, self.config.patrolWaitMax), function()
			if self.state == STATE.IDLE then self:setState(STATE.PATROL) end
		end)
	end
end

function MobAI:_tickAlert(dt)
	self.alertTimer -= dt
	if self.alertTimer <= 0 then self:setState(STATE.CHASE) end
end

function MobAI:_tickPatrol(dt)
	if not self.patrolTarget or (self.rootPart.Position - self.patrolTarget).Magnitude < 5 then
		local angle  = math.random() * math.pi * 2
		local radius = math.random(5, self.config.patrolRadius)
		self.patrolTarget = self.homePos + Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
	end
	self.navigator:moveTo(self.patrolTarget)
	if self.config.isHostile then
		local p = getNearestPlayer(self.rootPart.Position, self.config.detectRange)
		if p then
			self.target = p
			self.alertTimer = self.config.alertDuration
			self:setState(STATE.ALERT)
		end
	end
end

function MobAI:_tickChase(dt)
	if not self.target or not self.target.Character then self:setState(STATE.PATROL); return end
	local tHRP = self.target.Character:FindFirstChild("HumanoidRootPart")
	if not tHRP then self:setState(STATE.PATROL); return end
	local dist = (self.rootPart.Position - tHRP.Position).Magnitude
	if self.hp / self.config.maxHP <= self.config.fleeHealthPct then self:setState(STATE.FLEE); return end
	if dist > self.config.detectRange * 1.5 then
		self.lastKnownPos = tHRP.Position
		self.target = nil
		self:setState(STATE.PATROL)
		self.navigator:moveTo(self.lastKnownPos)
		return
	end
	self.lastKnownPos = tHRP.Position
	if dist <= self.config.strafeRange then self:setState(STATE.STRAFE); return end
	self.navigator:moveTo(tHRP.Position)
end

function MobAI:_tickStrafe(dt)
	if not self.target or not self.target.Character then self:setState(STATE.PATROL); return end
	local tHRP = self.target.Character:FindFirstChild("HumanoidRootPart")
	if not tHRP then self:setState(STATE.PATROL); return end
	local dist = (self.rootPart.Position - tHRP.Position).Magnitude
	if dist <= self.config.attackRange then self:setState(STATE.ATTACK); return end
	if dist > self.config.strafeRange * 1.5 then self:setState(STATE.CHASE); return end
	if self.hp / self.config.maxHP <= self.config.fleeHealthPct then self:setState(STATE.FLEE); return end
	local toTarget = (tHRP.Position - self.rootPart.Position)
	local right = Vector3.new(toTarget.Z, 0, -toTarget.X).Unit
	local strafeDir = (math.random() > 0.5) and right or -right
	self.navigator:moveTo(self.rootPart.Position + strafeDir*8 + toTarget.Unit*4)
	local now = os.clock()
	if now - self.lastAttack >= self.config.attackCooldown then
		self.lastAttack = now
		local tHum = self.target.Character:FindFirstChildOfClass("Humanoid")
		if tHum and tHum.Health > 0 then
			tHum:TakeDamage(self.config.damage * 0.6)
			EventBus.emit("MobAI:Attack", self.model, self.target, self.config.damage*0.6)
		end
	end
end

function MobAI:_tickAttack(dt)
	if not self.target or not self.target.Character then self:setState(STATE.PATROL); return end
	local tHRP = self.target.Character:FindFirstChild("HumanoidRootPart")
	if not tHRP then self:setState(STATE.PATROL); return end
	local dist = (self.rootPart.Position - tHRP.Position).Magnitude
	if dist > self.config.attackRange * 1.4 then self:setState(STATE.STRAFE); return end
	if self.hp / self.config.maxHP <= self.config.fleeHealthPct then self:setState(STATE.FLEE); return end
	local now = os.clock()
	if now - self.lastAttack >= self.config.attackCooldown then
		self.lastAttack = now
		local tHum = self.target.Character:FindFirstChildOfClass("Humanoid")
		if tHum and tHum.Health > 0 then
			tHum:TakeDamage(self.config.damage)
			EventBus.emit("MobAI:Attack", self.model, self.target, self.config.damage)
		end
	end
end

function MobAI:_tickFlee(dt)
	if self.hp < self.config.maxHP then self:heal(self.config.regenRate * dt * 0.5) end
	if not self.target or not self.target.Character then self:setState(STATE.IDLE); return end
	local tHRP = self.target.Character:FindFirstChild("HumanoidRootPart")
	if tHRP then
		local dir = (self.rootPart.Position - tHRP.Position)
		self.navigator:moveTo(self.rootPart.Position + dir.Unit * 50)
	end
	if self.hp / self.config.maxHP > self.config.fleeHealthPct + 0.15 then
		self:setState(STATE.PATROL)
	end
end

function MobAI:takeDamage(amount, attacker)
	if self.state == STATE.DEAD then return end
	self.hp = math.max(0, self.hp - amount)
	EventBus.emit("MobAI:Damaged", self.model, amount, self.hp)
	if self.hp <= 0 then
		self:setState(STATE.DEAD); self:stop()
		EventBus.emit("MobAI:Died", self.model, attacker, self.config.lootTable)
		return
	end
	if attacker and self.config.isHostile and
	   (self.state==STATE.IDLE or self.state==STATE.PATROL) then
		self.target = attacker; self:setState(STATE.CHASE)
	end
end

function MobAI:heal(amount)
	self.hp = math.min(self.config.maxHP, self.hp + amount)
end

function MobAI:aggroOn(player)
	if self.state == STATE.DEAD then return end
	self.target = player; self:setState(STATE.CHASE)
end

function MobAI:start()
	if self._running then return end
	self._running = true
	local conn = RunService.Heartbeat:Connect(function(dt)
		if self.state == STATE.DEAD then return end
		if not self.rootPart or not self.rootPart.Parent then self:stop(); return end
		if     self.state==STATE.IDLE   then self:_tickIdle(dt)
		elseif self.state==STATE.PATROL then self:_tickPatrol(dt)
		elseif self.state==STATE.ALERT  then self:_tickAlert(dt)
		elseif self.state==STATE.CHASE  then self:_tickChase(dt)
		elseif self.state==STATE.STRAFE then self:_tickStrafe(dt)
		elseif self.state==STATE.ATTACK then self:_tickAttack(dt)
		elseif self.state==STATE.FLEE   then self:_tickFlee(dt)
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
