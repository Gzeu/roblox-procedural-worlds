# 🌍 roblox-procedural-worlds

> A fully modular, seed-driven procedural world generation framework for Roblox — with a complete AI layer, anime RPG combat, roguelite dungeon runs, base building and player economy.

[![Version](https://img.shields.io/badge/version-6.1.0-blue)](#)
[![License](https://img.shields.io/badge/license-MIT-green)](./LICENSE)
[![Roblox](https://img.shields.io/badge/platform-Roblox%20Studio-red)](#)
[![Status](https://img.shields.io/badge/status-stable-brightgreen)](#)

---

## ✨ Feature Overview

| Module | Description |
|---|---|
| `WorldGenerator` | Seed-based orchestrator — boots all subsystems, streams chunks per player |
| `ChunkHandler` | FBM height map, biome fill, caves, water, ore injection, surface props |
| `BiomeResolver` | Inverse-square-distance blending across 9 biome poles (temp × moisture) |
| `WorldConfig` | Single source of truth — terrain, biome, AI, economy, RPG settings |
| `StreamingManager` | Heartbeat-driven chunk queue — loads near players, unloads far chunks |
| `ChunkPredictor` | Velocity-based predictive chunk pre-queuing |
| `LODManager` | 4-level LOD switching per registered chunk |
| `RiverCarver` | Noise-guided river channel carving post chunk-fill |
| `VillageGenerator` | Procedural NPC village layouts |
| `DungeonGenerator` | BSP room-based dungeon spawner |
| `MobSpawner` | Biome-aware mob spawning |
| `OreGenerator` | 3D-noise depth-based ore vein injection |
| `StructurePlacer` | Rare pre-built structure placement (ruins, temples, camps) per biome |
| `AssetPlacer` | Density-driven tree / rock / bush scatter |
| `DayNightCycle` | Configurable server-side day cycle (default 4 min) |
| `WeatherManager` | Server weather state machine → broadcasts via RemoteEvent |
| `WeatherClient` | Client-side weather visual handler |
| `SeedPersistence` | DataStore world seed save/restore |
| `SeedShare` | RemoteFunction so clients can query the current seed |
| `CombatSystem` | Hitbox detection, damage, knockback |
| `SkillSystem` | XP → level → skill points → 4 attributes |
| `BossEncounter` | HP-threshold phases, enrage timer, special attacks |
| `FightingStyles` | 4 unlockable stances, combo chains, stance meter |
| `AwakenSystem` | 3-stage transformation (Burst / Ascended / Mythic) |
| `ClanSystem` | Weighted clan roll (4 rarities), passive stat bonuses |
| `RunModifiers` | Roguelite boons & curses per dungeon/arena run |
| `QuestSystem` | Dynamic quest assignment & tracking |
| `ProceduralQuestGen` | Biome + player-level driven runtime quest generation |
| `NPCDialogue` | Branching dialogue trees with per-session choice history |
| `NPCDialogueClient` | Client-side dialogue UI handler |
| `Inventory` | Slot-based player inventory |
| `LootTable` | Weighted loot drop system |
| `CraftingSystem` | Recipe-based crafting |
| `BaseBuilding` | Snap-grid construction, collision check, serialization |
| `EconomyManager` | Player gold wallet + server-side listing market |
| `PlayerPersistence` | DataStore-backed player save/load |
| `DataStoreManager` | Centralised DataStore wrapper with retry logic |
| `AdminPanel` | In-game admin controls |
| `TeleportManager` | Named waypoints + cross-server teleport |
| `ParticleEffects` | Preset particle emitter manager |
| `NotificationBridge` | Server → client notification system |
| `AntiExploit` | Server-side sanity checks |
| `LeaderboardManager` | OrderedDataStore global leaderboard |
| `DailyRewards` | Streak-based daily reward system |
| `GamepassManager` | Gamepass ownership checks + perks |
| `DeveloperProductHandler` | Developer product purchase handling |
| `PremiumPerks` | Roblox Premium benefit handler |
| `TeleportManager` | Waypoints + cross-server teleport |
| `ClanSystem` 🏯 | Weighted clan roll, passive stat bonuses |
| `FactionSystem` | Faction allegiance + rep system |
| `ObjectPool` | Generic instance pooling |
| `EventBus` | Lightweight pub/sub event system |
| **`MobAI`** 🤖 | FSM: Idle/Patrol/Alert/Chase/Attack/Flee/Dead |
| **`AINavigator`** 🤖 | PathfindingService wrapper with auto-recompute |
| **`BehaviorTree`** 🤖 | Composable BT engine (8 node types) |
| **`AIDirector`** 🤖 | Dynamic Difficulty Adjustment (6 tiers) |
| **`AIConfig`** 🤖 | Per-mob config + BT presets |
| **`AIMemory`** 🧠 | Per-mob persistent memory (last target, observed positions) |
| **`AIGroupBehavior`** 🧠 | Pack coordination: alert leader, flanker, retreat signaler |

> 🤖 = v3.0 · 🧠⚔️ = v4.0 · 🥋⚡🏯🎲🏗️💰 = v5.0 · 🔧 = v6.1 fixes

---

## 🚀 Quick Start

### Prerequisites
- [Rojo](https://rojo.space) v7+ installed
- Roblox Studio open with an empty baseplate

### Setup

```bash
git clone https://github.com/Gzeu/roblox-procedural-worlds.git
cd roblox-procedural-worlds
python build.py          # generates the .rbxlx project file
```

Open the generated `.rbxlx` in Studio → press **F5** → world generates automatically.

### Manual setup (no Rojo)

1. Copy all files from `src/` into **ServerScriptService** in Studio
2. Rename `init.server.lua` → `Script` (set as ServerScript)
3. All other `.lua` files → `ModuleScript`
4. Press **F5**

> ⚠️ All modules use `script.Parent.ModuleName` for requires — they must all live in the **same folder** (ServerScriptService or a sub-folder).

---

## 🗂️ Project Structure

```
roblox-procedural-worlds/
├── src/
│   ├── init.server.lua           # Bootstrap — boots all systems
│   ├── WorldConfig.lua           # ← configure everything here
│   ├── EventBus.lua
│   │
│   ├── # ── World Generation ─────────────────────────
│   ├── WorldGenerator.lua
│   ├── ChunkHandler.lua
│   ├── BiomeResolver.lua
│   ├── StreamingManager.lua
│   ├── ChunkPredictor.lua
│   ├── LODManager.lua
│   ├── RiverCarver.lua
│   ├── VillageGenerator.lua
│   ├── DungeonGenerator.lua
│   ├── MobSpawner.lua
│   ├── OreGenerator.lua
│   ├── DayNightCycle.lua
│   ├── WeatherManager.lua
│   ├── WeatherClient.lua         # LocalScript
│   ├── AssetPlacer.lua
│   ├── StructurePlacer.lua
│   ├── SeedPersistence.lua
│   ├── SeedShare.lua
│   │
│   ├── # ── Player Systems ───────────────────────────
│   ├── CombatSystem.lua
│   ├── SkillSystem.lua
│   ├── QuestSystem.lua
│   ├── ProceduralQuestGen.lua
│   ├── NPCDialogue.lua
│   ├── NPCDialogueClient.lua     # LocalScript
│   ├── Inventory.lua
│   ├── PlayerPersistence.lua
│   ├── DataStoreManager.lua
│   ├── LootTable.lua
│   ├── CraftingSystem.lua
│   ├── AdminPanel.lua
│   ├── TeleportManager.lua
│   ├── ParticleEffects.lua
│   ├── NotificationBridge.lua
│   ├── AntiExploit.lua
│   ├── LeaderboardManager.lua
│   ├── DailyRewards.lua
│   ├── GamepassManager.lua
│   ├── DeveloperProductHandler.lua
│   ├── PremiumPerks.lua
│   │
│   ├── # ── v3.0 AI ──────────────────────────────────
│   ├── MobAI.lua
│   ├── AINavigator.lua
│   ├── BehaviorTree.lua
│   ├── AIDirector.lua
│   ├── AIConfig.lua
│   │
│   ├── # ── v4.0 Advanced AI + RPG ───────────────────
│   ├── AIMemory.lua
│   ├── AIGroupBehavior.lua
│   ├── BossEncounter.lua
│   │
│   ├── # ── v5.0 Anime RPG + Economy ─────────────────
│   ├── FightingStyles.lua
│   ├── AwakenSystem.lua
│   ├── ClanSystem.lua
│   ├── FactionSystem.lua
│   ├── RunModifiers.lua
│   ├── BaseBuilding.lua
│   ├── EconomyManager.lua
│   └── ObjectPool.lua
│
├── build.py                      # Rojo project builder
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE
```

---

## ⚙️ Configuration — WorldConfig.lua

```lua
-- Terrain
WorldConfig.Settings.ChunkSize         = 64       -- studs per chunk
WorldConfig.Settings.VoxelSize         = 4        -- stud resolution
WorldConfig.Settings.RenderDistance    = 3        -- chunks from player
WorldConfig.Settings.BaseY             = 20       -- base ground level
WorldConfig.Settings.TerrainAmplitude  = 60       -- height variation
WorldConfig.Settings.MountainAmplitude = 80       -- mountain peaks
WorldConfig.Settings.WaterLevel        = 16       -- ocean fill height
WorldConfig.Settings.CaveThreshold     = 0.35     -- cave density

-- AI
WorldConfig.AI_ENABLED                 = true
WorldConfig.AI_BEHAVIOR_TREE           = true
WorldConfig.AI_DIRECTOR_ENABLED        = true
WorldConfig.AI_DIRECTOR_DECAY_RATE     = 0.02
WorldConfig.AI_PATHFINDING_COOLDOWN    = 0.8

-- RPG
WorldConfig.SKILL_XP_BASE              = 100
WorldConfig.BOSS_ENRAGE_TIMER          = 120
WorldConfig.BOSS_BASE_XP               = 500
WorldConfig.AWAKEN_ENERGY_PER_KILL     = 8
WorldConfig.AWAKEN_ENERGY_PER_BOSS     = 40

-- Economy
WorldConfig.ECONOMY_STARTING_GOLD      = 250
WorldConfig.BUILDING_GRID_SIZE         = 4
WorldConfig.BUILDING_MAX_PER_PLAYER    = 100
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

## 🗺️ Biomes

| Biome | Temp | Moisture | Surface |
|---|---|---|---|
| Tundra   | Cold  | Low  | Ice / Snow |
| Snow     | Cold  | Mid  | Snow |
| Forest   | Mid   | High | Grass + Trees |
| Grassland| Mid   | Mid  | Grass |
| Swamp    | Mid   | Max  | Mud + Water |
| Jungle   | Hot   | Max  | Dense foliage |
| Desert   | Hot   | Low  | Sand |
| Volcano  | Max   | Min  | Rock + Lava |
| Ocean    | Mid   | 1.0  | Water fill |

---

## 🐛 Troubleshooting

### World doesn't generate on Play
Check Output for `[WorldGenerator] Seed: XXXXXXX`. If missing:
- Ensure `init.server.lua` is a **Script** (not ModuleScript) in ServerScriptService
- All other `.lua` files must be **ModuleScript**

### `BubbleChat` / `ChatScript` errors on Play
These are **Roblox built-in chat warnings** — not from this framework. They are cosmetic and do not affect world generation. Safe to ignore.

### Falling through the world / void
- World is generating but SpawnLocation is above empty terrain → move SpawnLocation to `Vector3.new(0, 60, 0)` in Studio
- Or set `WorldConfig.Settings.BaseY = 40` to raise base terrain

### `require` errors — module not found
All modules must be siblings in the **same folder**. Do not split them across ServerScriptService and ReplicatedStorage — only `WeatherClient` and `NPCDialogueClient` (LocalScripts) may reference ReplicatedStorage for RemoteEvents.

### Assets / structures not appearing
`AssetPlacer` and `StructurePlacer` look for models in **ServerStorage** by name. Add your tree/rock/bush and structure models there. Missing models produce a `warn()` but do not crash.

---

## 📜 License

MIT — see [LICENSE](./LICENSE)

---

## 🤝 Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.
