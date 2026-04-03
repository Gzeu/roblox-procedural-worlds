# 🌍 roblox-procedural-worlds

> A fully modular, seed-driven procedural world generation framework for Roblox — with a complete AI layer for mob intelligence and dynamic difficulty.

[![Version](https://img.shields.io/badge/version-3.0.0-blue)](#)
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

> 🤖 = Added in v3.0

---

## 🚀 Quick Start

1. Clone/copy into Roblox Studio via [Rojo](https://rojo.space) (see `rojo/` folder)
2. Place `src/` contents into `ServerScriptService`
3. Configure `WorldConfig.lua`
4. Hit **Play** — world generates and AI activates automatically

```lua
-- Spawn a mob with AI
local MobAI    = require(game.ServerScriptService.MobAI)
local AIConfig = require(game.ServerScriptService.AIConfig)
local AIDirector = require(game.ServerScriptService.AIDirector)

-- Apply dynamic difficulty scaling for the nearest player
local scaledConfig = AIDirector.applyScaling(player, AIConfig.Mobs.Goblin)

local mob = MobAI.new(goblinModel, scaledConfig)
mob:start()

-- Build a custom Behavior Tree
local BT = require(game.ServerScriptService.BehaviorTree)
local tree = BT.Tree(
    BT.Sequence({
        BT.Condition(function(ctx) return ctx.dist < 10 end),
        BT.Cooldown(
            BT.Action(function(ctx)
                ctx.mob:attack()
                return "SUCCESS"
            end),
            1.5
        )
    })
)
tree:tick({ mob = mob, dist = 8 })

-- Check player difficulty tier
print(AIDirector.getTierName(player))  -- "Normal", "Hard", etc.
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
│                     MobAI (FSM)                     │
│  Idle → Patrol → Alert → Chase → Attack → Flee      │
│                     ↕ delegates movement            │
│                  AINavigator                        │
│         PathfindingService + recompute              │
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
| Trivial  | < -0.60 | ×0.5 | ×0.6 | ×0.6 | +0% |
| Easy     | < -0.30 | ×0.75 | ×0.8 | ×0.8 | +0% |
| Normal   | 0.00    | ×1.0 | ×1.0 | ×1.0 | +0% |
| Hard     | > 0.30  | ×1.3 | ×1.3 | ×1.2 | +10% |
| Extreme  | > 0.60  | ×1.7 | ×1.7 | ×1.5 | +25% |
| Nightmare| > 0.85  | ×2.2 | ×2.2 | ×1.8 | +40% |

---

## 📁 Project Structure

```
roblox-procedural-worlds/
├── src/
│   ├── init.server.lua
│   ├── WorldConfig.lua
│   ├── EventBus.lua
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
│   ├── CombatSystem.lua
│   ├── QuestSystem.lua
│   ├── NPCDialogue.lua / NPCDialogueClient.lua
│   ├── Inventory.lua
│   ├── PlayerPersistence.lua
│   ├── LootTable.lua
│   ├── AdminPanel.lua
│   ├── AssetPlacer.lua / StructurePlacer.lua
│   ├── SeedPersistence.lua
│   ├── CraftingSystem.lua
│   ├── TeleportManager.lua
│   ├── ParticleEffects.lua
│   ├── MobAI.lua          # v3.0 ── FSM
│   ├── AINavigator.lua    # v3.0 ── Pathfinding
│   ├── BehaviorTree.lua   # v3.0 ── BT engine
│   ├── AIDirector.lua     # v3.0 ── DDA
│   └── AIConfig.lua       # v3.0 ── Configs + BT presets
├── rojo/
├── docs/
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE
```

---

## ⚙️ Configuration

```lua
-- WorldConfig.lua (v3.0 AI keys)
WorldConfig.AI_ENABLED              = true
WorldConfig.AI_BEHAVIOR_TREE        = true   -- use BT alongside FSM
WorldConfig.AI_DIRECTOR_ENABLED     = true   -- dynamic difficulty
WorldConfig.AI_DIRECTOR_DECAY_RATE  = 0.02   -- score drift per second
WorldConfig.AI_PATHFINDING_COOLDOWN = 0.8    -- recompute interval
WorldConfig.EVENT_BUS_DEBUG         = false  -- verbose logging
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
