-- CombatSystem.lua
-- Server-authoritative combat: hit detection, damage, knockback, death
-- v2.4.0

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local WorldConfig = require(script.Parent.WorldConfig)

local CombatSystem = {}

-- { [attackerModel] = lastAttackTick }
local cooldowns = {}
-- { [victimModel] = { hp, maxHp, isDead } }
local healthData = {}

local function getWeaponDamage(player)
	-- Read equipped weapon from player attributes (set by Inventory)
	local dmg = player:GetAttribute("WeaponDamage")
	return dmg and tonumber(dmg) or WorldConfig.Combat.BaseDamage
end

local function applyKnockback(victimRoot, attackerRoot)
	if not victimRoot or not attackerRoot then return end
	local dir = (victimRoot.Position - attackerRoot.Position).Unit
	local force = WorldConfig.Combat.KnockbackForce
	local bv = Instance.new("BodyVelocity")
	bv.Velocity       = dir * force + Vector3.new(0, force * 0.3, 0)
	bv.MaxForce       = Vector3.new(1e5, 1e5, 1e5)
	bv.P              = 1e4
	bv.Parent         = victimRoot
	task.delay(0.15, function() if bv and bv.Parent then bv:Destroy() end end)
end

local function registerMob(model)
	if healthData[model] then return end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	healthData[model] = {
		hp    = hum.MaxHealth,
		maxHp = hum.MaxHealth,
		isDead = false,
	}
end

local function dealDamage(attacker, victim, damage)
	local hum = victim:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	registerMob(victim)
	local data = healthData[victim]
	if not data or data.isDead then return end

	data.hp = math.max(0, data.hp - damage)
	hum.Health = data.hp

	-- Hit flash: tint victim parts briefly red
	task.spawn(function()
		for _, p in ipairs(victim:GetDescendants()) do
			if p:IsA("BasePart") then
				local orig = p.Color
				p.Color = Color3.fromRGB(255, 80, 80)
				task.wait(0.1)
				if p and p.Parent then p.Color = orig end
			end
		end
	end)

	if data.hp <= 0 then
		data.isDead = true
		CombatSystem.OnMobDeath(attacker, victim)
	end
end

function CombatSystem.OnMobDeath(attacker, mobModel)
	-- Notify quest system via attribute on attacker's player
	local player = Players:GetPlayerFromCharacter(attacker)
	if player then
		local mobType = mobModel:GetAttribute("MobType") or "Unknown"
		player:SetAttribute("LastKilledMob", mobType)
		player:SetAttribute("LastKilledTick", tick())
		-- QuestSystem.UpdateProgress hook (called externally to avoid circular require)
		player:SetAttribute("QuestKillEvent", (player:GetAttribute("QuestKillEvent") or 0) + 1)
	end
	task.delay(WorldConfig.Combat.MobRespawnTime, function()
		if mobModel and mobModel.Parent then
			mobModel:Destroy()
			healthData[mobModel] = nil
		end
	end)
end

function CombatSystem.PlayerAttack(player)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- Cooldown check
	local now = tick()
	local last = cooldowns[char] or 0
	local rate  = WorldConfig.Combat.AttackCooldown
	if now - last < rate then return end
	cooldowns[char] = now

	local damage = getWeaponDamage(player)
	local range  = WorldConfig.Combat.AttackRange

	-- Sphere overlap: find all humanoid models in range
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model")
			and obj ~= char
			and obj:FindFirstChildOfClass("Humanoid")
			and obj:GetAttribute("MobType") then
				local mobRoot = obj:FindFirstChild("HumanoidRootPart")
				if mobRoot then
					local dist = (root.Position - mobRoot.Position).Magnitude
					if dist <= range then
						dealDamage(char, obj, damage)
						applyKnockback(mobRoot, root)
					end
				end
		end
	end
end

function CombatSystem.RegisterMobHealth(model)
	registerMob(model)
end

function CombatSystem.GetHealth(model)
	return healthData[model]
end

function CombatSystem.Start()
	-- Clean up cooldowns on character removal
	Players.PlayerAdded:Connect(function(player)
		player.CharacterRemoving:Connect(function(char)
			cooldowns[char] = nil
		end)
	end)

	if WorldConfig.Debug then
		warn("[CombatSystem] Started")
	end
end

return CombatSystem
