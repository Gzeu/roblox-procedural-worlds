-- AIConfig.lua
-- Per-mob AI configurations and BehaviorTree presets
-- v3.0 | roblox-procedural-worlds

local BT = require(script.Parent.BehaviorTree)

local AIConfig = {}

-- ── Base mob configs (used by AIDirector for scaling) ────────────
AIConfig.Mobs = {
	Goblin = {
		detectRange    = 45,
		attackRange    = 5,
		fleeHealthPct  = 0.15,
		patrolRadius   = 25,
		alertDuration  = 2,
		attackCooldown = 1.2,
		moveSpeed      = 16,
		damage         = 8,
		maxHP          = 60,
		isHostile      = true,
	},
	Skeleton = {
		detectRange    = 55,
		attackRange    = 7,
		fleeHealthPct  = 0.0,  -- Skeletons don't flee
		patrolRadius   = 35,
		alertDuration  = 1,
		attackCooldown = 1.8,
		moveSpeed      = 12,
		damage         = 14,
		maxHP          = 80,
		isHostile      = true,
	},
	Troll = {
		detectRange    = 60,
		attackRange    = 8,
		fleeHealthPct  = 0.10,
		patrolRadius   = 20,
		alertDuration  = 4,
		attackCooldown = 2.5,
		moveSpeed      = 10,
		damage         = 28,
		maxHP          = 250,
		isHostile      = true,
	},
	Dragon = {
		detectRange    = 120,
		attackRange    = 15,
		fleeHealthPct  = 0.0,
		patrolRadius   = 80,
		alertDuration  = 1,
		attackCooldown = 3.0,
		moveSpeed      = 20,
		damage         = 60,
		maxHP          = 1200,
		isHostile      = true,
	},
	Wolf = {
		detectRange    = 50,
		attackRange    = 4,
		fleeHealthPct  = 0.25,
		patrolRadius   = 40,
		alertDuration  = 1.5,
		attackCooldown = 0.9,
		moveSpeed      = 20,
		damage         = 12,
		maxHP          = 70,
		isHostile      = true,
	},
	Deer = {
		detectRange    = 35,
		attackRange    = 0,
		fleeHealthPct  = 1.0,  -- always flee when player is near
		patrolRadius   = 50,
		alertDuration  = 0.5,
		attackCooldown = 999,
		moveSpeed      = 18,
		damage         = 0,
		maxHP          = 40,
		isHostile      = false,
	},
}

-- ── BehaviorTree presets ─────────────────────────────────────────
-- Each preset builds a tree appropriate to the mob's role
-- ctx = { mob: MobAI instance, player: nearest Player, dist: number }

AIConfig.Trees = {}

AIConfig.Trees.Aggressive = BT.Tree(
	BT.Selector({
		-- If low HP, flee
		BT.Sequence({
			BT.Condition(function(ctx)
				return ctx.mob and ctx.mob.hp / ctx.mob.config.maxHP < ctx.mob.config.fleeHealthPct
			end, "LowHP"),
			BT.Action(function(ctx)
				ctx.mob:setState(ctx.mob.STATE and ctx.mob.STATE.FLEE or "Flee")
				return "SUCCESS"
			end, "Flee"),
		}),
		-- If player in attack range, attack
		BT.Sequence({
			BT.Condition(function(ctx)
				return ctx.dist and ctx.dist <= (ctx.mob.config.attackRange or 6)
			end, "InAttackRange"),
			BT.Cooldown(
				BT.Action(function(ctx)
					if ctx.player and ctx.player.Character then
						local hum = ctx.player.Character:FindFirstChildOfClass("Humanoid")
						if hum then hum:TakeDamage(ctx.mob.config.damage or 10) end
					end
					return "SUCCESS"
				end, "MeleeAttack"),
				1.5
			),
		}),
		-- If player detected, chase
		BT.Sequence({
			BT.Condition(function(ctx)
				return ctx.dist and ctx.dist <= (ctx.mob.config.detectRange or 50)
			end, "PlayerDetected"),
			BT.Action(function(ctx)
				if ctx.mob.navigator and ctx.player and ctx.player.Character then
					local hrp = ctx.player.Character:FindFirstChild("HumanoidRootPart")
					if hrp then ctx.mob.navigator:moveTo(hrp.Position) end
				end
				return "RUNNING"
			end, "Chase"),
		}),
		-- Default: patrol
		BT.Action(function(ctx)
			return "RUNNING"
		end, "Patrol"),
	})
)

AIConfig.Trees.Passive = BT.Tree(
	BT.Selector({
		-- Always flee from players
		BT.Sequence({
			BT.Condition(function(ctx)
				return ctx.dist and ctx.dist <= 35
			end, "PlayerNear"),
			BT.Action(function(ctx)
				if ctx.mob.navigator and ctx.player and ctx.player.Character then
					local hrp = ctx.player.Character:FindFirstChild("HumanoidRootPart")
					if hrp and ctx.mob.rootPart then
						local dir = (ctx.mob.rootPart.Position - hrp.Position).Unit
						ctx.mob.navigator:moveTo(ctx.mob.rootPart.Position + dir * 50)
					end
				end
				return "RUNNING"
			end, "FleeFromPlayer"),
		}),
		BT.Action(function(ctx) return "RUNNING" end, "Wander"),
	})
)

return AIConfig
