# 🌍 roblox-procedural-worlds

> A fully modular, seed-driven procedural world generation framework for Roblox — with a complete AI layer, anime RPG combat, roguelite dungeon runs, base building and player economy.

[![Version](https://img.shields.io/badge/version-5.0.0-blue)](#)
[![License](https://img.shields.io/badge/license-MIT-green)](./LICENSE)
[![Roblox](https://img.shields.io/badge/platform-Roblox%20Studio-red)](#)

---

## ✨ Features

| Module | Description |
|---|---|
| `WorldGenerator` | Noise-based procedural terrain generation |
| `ChunkHandler` | Async chunk load/unload with priority queue |
| `BiomeResolver` | Temperature/moisture biome assignment (10 biomes) |
| `StreamingManager` | Player-aware chunk streaming |
| `LODManager` | Level-of-Detail switching (4 levels) |
| `RiverCarver` | Midpoint displacement river paths |
| `VillageGenerator` | Procedural NPC village layouts |
| `DungeonGenerator` | BSP room-based dungeon system |
| `MobSpawner` | Biome-aware mob spawning |
| `OreGenerator` | Depth-based ore vein generation |
| `DayNightCycle` | Configurable 8-minute in-game day |
| `WeatherManager` + `WeatherClient` | Server/client weather sync |
| `CombatSystem` | Hitbox detection, damage, knockback |
| `QuestSystem` | Dynamic quest assignment & tracking |
| `NPCDialogue` + `NPCDialogueClient` | Branching dialogue trees |
| `Inventory` | Slot-based player inventory |
| `PlayerPersistence` | DataStore-backed save/load |
| `LootTable` | Weighted loot drop system |
| `AdminPanel` | In-game admin controls |
| `AssetPlacer` | Biome-aware asset scatter |
| `StructurePlacer` | Pre-built structure placement |
| `SeedPersistence` | World seed save/restore |
| `EventBus` | Pub/sub event system |
| `CraftingSystem` | Recipe-based crafting |
| `TeleportManager` | Named waypoints + cross-server teleport |
| `ParticleEffects` | Preset particle emitter manager |
| **`MobAI`** 🤖 | FSM: Idle/Patrol/Alert/Chase/Attack/Flee/Dead |
| **`AINavigator`** 🤖 | PathfindingService wrapper with recompute |
| **`BehaviorTree`** 🤖 | Composable BT engine (8 node types) |
| **`AIDirector`** 🤖 | Dynamic Difficulty Adjustment (6 tiers) |
| **`AIConfig`** 🤖 | Per-mob configs + BT presets |
| **`AIMemory`** 🧠 | Per-mob persistent memory (last target, observed positions) |
| **`AIGroupBehavior`** 🧠 | Pack coordination: alert leader, flanker, retreat signaler |
| **`SkillSystem`** ⚔️ | XP → level → skill points → 4 attributes |
| **`BossEncounter`** ⚔️ | HP-threshold phases, enrage timer, special attacks |
| **`NPCDialogue v2`** ⚔️ | Per-session choice history, quest integration hooks |
| **`FightingStyles`** 🥋 | Unlockable stances (Warrior/Rogue/Mystic/Berserker), combo chains, stance meter |
| **`AwakenSystem`** ⚡ | 3-stage transformation (Burst/Ascended/Mythic), energy from kills |
| **`ClanSystem`** 🏯 | Weighted clan roll (4 rarities), passive stat bonuses |
| **`RunModifiers`** 🎲 | Roguelite boons & curses per dungeon/arena run |
| **`BaseBuilding`** 🏗️ | Snap-grid construction, collision check, serialization |
| **`EconomyManager`** 💰 | Player gold wallet + server-side listing market |

> 🤖 = v3.0 · 🧠⚔️ = v4.0 · 🥋⚡🏯🎲🏗️💰 = v5.0

---

## 🚀 Quick Start

1. Clone/copy into Roblox Studio via [Rojo](https://rojo.space) (see `rojo/` folder)
2. Place `src/` contents into `ServerScriptService`
3. Configure `WorldConfig.lua`
4. Hit **Play** — world generates and all systems activate automatically

```lua
-- v5.0 — anime RPG example
local FightingStyles = require(game.ServerScriptService.FightingStyles)
local AwakenSystem   = require(game.ServerScriptService.AwakenSystem)
local ClanSystem     = require(game.ServerScriptService.ClanSystem)

-- Get player's current attack profile (combo + style bonuses)
local profile = FightingStyles.buildAttackProfile(player, "Heavy")
print(profile.damageMultiplier, profile.combo, profile.critChance)

-- Grant awaken energy on kill, then activate transformation
AwakenSystem.grantEnergy(player, 20)
local ok, stage, buffs = AwakenSystem.activate(player)
if ok then print("Activated:", stage, buffs.damage) end

-- Check clan passive bonuses
local bonuses = ClanSystem.getPassiveBonuses(player)
print(ClanSystem.getClan(player), bonuses.meleeDamage)
```

```lua
-- v5.0 — roguelite run example
local RunModifiers   = require(game.ServerScriptService.RunModifiers)
local EconomyManager = require(game.ServerScriptService.EconomyManager)

local runId = "dungeon_1"
RunModifiers.startRun(runId, { player })
RunModifiers.autoRoll(runId, 2, 1)  -- 2 boons, 1 curse
local effects = RunModifiers.getPlayerEffects(player)
print(effects.damageMultiplier, effects.enemyDamageMultiplier)

-- Economy: sell an item
EconomyManager.createListing(player, "IronSword", 1, 150)
print(EconomyManager.getBalance(player))
```

```lua
-- v5.0 — base building example
local BaseBuilding = require(game.ServerScriptService.BaseBuilding)

local ok, record = BaseBuilding.placeStructure(
    player, "Watchtower",
    Vector3.new(100, 50, 200), 90
)
if ok then
    print("Built #" .. record.id .. " at " .. tostring(record.position))
end
local saved = BaseBuilding.serializePlayerBuilds(player)
-- save `saved` to DataStore, reload with loadPlayerBuilds()
```

---

## 🤖 AI Architecture

```
┌─────────────────────────────────────────────────────┐
│                    AIDirector                       │
│  Tracks kill/death → score (-1..1) → tier (1-6)    │
│  Scales: damage, HP, spawnRate per player           │
└──────────────────────┬──────────────────────────────┘
                       │ applyScaling(player, config)
                       ▼
┌─────────────────────────────────────────────────────┐
│              AIGroupBehavior (v4.0)                 │
│  Pack roles: Alert Leader / Flanker / Retreat       │
│  Coordinates mobs via EventBus packId               │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│                     MobAI (FSM)                     │
│  Idle → Patrol → Alert → Chase → Attack → Flee      │
│         delegates movement to AINavigator           │
│         stores context in AIMemory (v4.0)           │
└──────────────────────┬──────────────────────────────┘
                       │ optional per-tick decisions
                       ▼
┌─────────────────────────────────────────────────────┐
│               BehaviorTree (optional)               │
│  Sequence / Selector / Parallel / Condition         │
│  Action / Inverter / Repeater / Cooldown            │
└─────────────────────────────────────────────────────┘
         All modules communicate via EventBus
```

### Dynamic Difficulty Tiers

| Tier | Score | Damage | HP | Spawn Rate | Loot Bonus |
|---|---|---|---|---|---|
| Trivial   | < -0.60 | ×0.5  | ×0.6  | ×0.6 | +0%  |
| Easy      | < -0.30 | ×0.75 | ×0.8  | ×0.8 | +0%  |
| Normal    |   0.00  | ×1.0  | ×1.0  | ×1.0 | +0%  |
| Hard      | > 0.30  | ×1.3  | ×1.3  | ×1.2 | +10% |
| Extreme   | > 0.60  | ×1.7  | ×1.7  | ×1.5 | +25% |
| Nightmare | > 0.85  | ×2.2  | ×2.2  | ×1.8 | +40% |

---

## 🥋 v5.0 — Anime RPG Systems

### Fighting Styles

| Style | Rarity | Dmg Mult | Combo Scaling | Crit | Unlock Level |
|---|---|---|---|---|---|
| Warrior   | Common    | ×1.00 | +8%/hit  | 5%  | Default |
| Rogue     | Rare      | ×0.92 | +11%/hit | 14% | Level 5  |
| Mystic    | Epic      | ×0.95 | +7%/hit  | 6%  | Level 10 |
| Berserker | Legendary | ×1.18 | +14%/hit | 10% | Level 20 |

### Awaken Stages

| Stage | Min Level | Duration | Damage | Speed | MaxHP | Crit |
|---|---|---|---|---|---|---|
| Burst    | 10 | 20s | +18% | +2  | +20  | +5%  |
| Ascended | 25 | 25s | +30% | +4  | +45  | +10% |
| Mythic   | 50 | 30s | +45% | +6  | +80  | +16% |

### Clans

| Clan | Rarity | Weight | Bonus |
|---|---|---|---|
| Ironfang   | Common    | 50% | +4 melee dmg, +10 maxHP |
| Moonveil   | Rare      | 28% | +6% dodge, +1 move speed |
| Stormcall  | Epic      | 15% | +8 magic dmg, +8% XP |
| Sunbreaker | Legendary |  7% | +8 melee dmg, +8% crit, +25 maxHP |

---

## 📁 Project Structure

```
roblox-procedural-worlds/
├── src/
│   ├── init.server.lua          # Bootstrap — loads all modules
│   ├── WorldConfig.lua
│   ├── EventBus.lua
│   │
│   ├── # ── World Generation ──────────────────────────
│   ├── WorldGenerator.lua
│   ├── ChunkHandler.lua
│   ├── BiomeResolver.lua
│   ├── StreamingManager.lua
│   ├── LODManager.lua
│   ├── RiverCarver.lua
│   ├── VillageGenerator.lua
│   ├── DungeonGenerator.lua
│   ├── MobSpawner.lua
│   ├── OreGenerator.lua
│   ├── DayNightCycle.lua
│   ├── WeatherManager.lua / WeatherClient.lua
│   ├── AssetPlacer.lua / StructurePlacer.lua
│   ├── SeedPersistence.lua
│   │
│   ├── # ── Player Systems ────────────────────────────
│   ├── CombatSystem.lua
│   ├── QuestSystem.lua
│   ├── NPCDialogue.lua / NPCDialogueClient.lua
│   ├── Inventory.lua
│   ├── PlayerPersistence.lua
│   ├── LootTable.lua
│   ├── AdminPanel.lua
│   ├── CraftingSystem.lua
│   ├── TeleportManager.lua
│   ├── ParticleEffects.lua
│   │
│   ├── # ── v3.0 AI ────────────────────────────────────
│   ├── MobAI.lua
│   ├── AINavigator.lua
│   ├── BehaviorTree.lua
│   ├── AIDirector.lua
│   └── AIConfig.lua
│   │
│   ├── # ── v4.0 AI + RPG ──────────────────────────────
│   ├── AIMemory.lua
│   ├── AIGroupBehavior.lua
│   ├── SkillSystem.lua
│   ├── BossEncounter.lua
│   └── NPCDialogue.lua          # v2 branching + quest hooks
│   │
│   ├── # ── v5.0 Anime RPG + Economy ───────────────────
│   ├── FightingStyles.lua
│   ├── AwakenSystem.lua
│   ├── ClanSystem.lua
│   ├── RunModifiers.lua
│   ├── BaseBuilding.lua
│   └── EconomyManager.lua
│
├── rojo/
├── docs/
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE
```

---

## ⚙️ Configuration

```lua
-- WorldConfig.lua — v5.0 keys

-- AI
WorldConfig.AI_ENABLED              = true
WorldConfig.AI_BEHAVIOR_TREE        = true
WorldConfig.AI_DIRECTOR_ENABLED     = true
WorldConfig.AI_DIRECTOR_DECAY_RATE  = 0.02
WorldConfig.AI_PATHFINDING_COOLDOWN = 0.8
WorldConfig.EVENT_BUS_DEBUG         = false

-- v4.0
WorldConfig.SKILL_XP_BASE           = 100
WorldConfig.SKILL_POINTS_PER_LEVEL  = 3
WorldConfig.BOSS_ENRAGE_TIMER       = 120
WorldConfig.BOSS_BASE_XP            = 500

-- v5.0
WorldConfig.BUILDING_GRID_SIZE        = 4
WorldConfig.BUILDING_MAX_PER_PLAYER   = 100
WorldConfig.ECONOMY_STARTING_GOLD     = 250
WorldConfig.AWAKEN_ENERGY_PER_KILL    = 8
WorldConfig.AWAKEN_ENERGY_PER_BOSS    = 40
WorldConfig.RUN_DEFAULT_BOON_COUNT    = 2
WorldConfig.RUN_DEFAULT_CURSE_COUNT   = 1
```

---

## 🗺️ Biomes

Tundra · Taiga · Grassland · Forest · Desert · Savanna · Jungle · Swamp · Volcanic · Ocean

---

## 📜 License

MIT — see [LICENSE](./LICENSE)

---

## 🤝 Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.
