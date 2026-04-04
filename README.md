# 🌍 roblox-procedural-worlds

> A fully modular, seed-driven procedural world generation framework for Roblox — with a complete AI layer, anime RPG combat, roguelite dungeon runs, base building, player economy, procedural animations and spatial audio.

[![Version](https://img.shields.io/badge/version-7.0.0-blue)](#)
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
| **`AnimationManager`** 🎬 | Procedural TweenService animations — idle sway, walk bob, attack lunge, death fade |
| **`SoundManager`** 🔊 | Positional 3D audio — rbxasset:// only, zero upload required |
| **`AmbienceClient`** 🎵 | Per-biome ambient crossfade (2s) — LocalScript, polls `CurrentBiome` attribute |
| **`InventoryRemote`** 📦 | Server RemoteFunction bridge — getSlots / drop / use / equip |

> 🤖 = v3.0 · 🧠 = v4.0 · 🥋⚡🏯🎲🏗️💰 = v5.0 · 🔧 = v6.1 · 🎬🔊🎵📦 = **v7.0**

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
4. Files ending in `.client.lua` → `LocalScript` inside **StarterPlayerScripts**
5. Press **F5**

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
│   ├── InventoryRemote.lua       # RemoteFunction bridge (v7.0)
│   ├── InventoryUI.client.lua    # LocalScript
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
│   ├── ObjectPool.lua
│   │
│   ├── # ── v7.0 Animations + Audio ──────────────────
│   ├── AnimationManager.lua      # Procedural TweenService anims
│   ├── SoundManager.lua          # 3D positional audio
│   ├── AmbienceClient.client.lua # LocalScript — biome crossfade
│   │
│   ├── # ── UI ───────────────────────────────────────
│   ├── HUD.client.lua            # LocalScript
│   ├── MinimapUI.client.lua      # LocalScript
│   ├── QuestTracker.client.lua   # LocalScript
│   └── DialogueUI.client.lua     # LocalScript
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

## 🎬 v7.0 — Animations & Audio

### AnimationManager API

```lua
local AnimationManager = require(script.Parent.AnimationManager)

AnimationManager.playIdle(mobModel)     -- gentle ±2° sway at 1 Hz
AnimationManager.playWalk(mobModel)     -- Y bob ±0.2 st at 4 Hz
AnimationManager.playAttack(mobModel)   -- forward lunge +1.5 st
AnimationManager.playDeath(mobModel)    -- fall + fade, destroy after 3s
AnimationManager.stop(mobModel)         -- cancel current anim cleanly
```

All animations are **TweenService-based** — no AnimationId uploads required. Works on any rig that has a `HumanoidRootPart` or any `BasePart`.

### SoundManager API

```lua
local SoundManager = require(script.Parent.SoundManager)

-- Play a positional 3D sound at world coordinates
SoundManager.playAtPosition("hit",       Vector3.new(0, 10, 0))
SoundManager.playAtPosition("explosion", bossHRP.Position, 1.0, 0.9)

-- Play near a player (server fallback)
SoundManager.playForPlayer(player, "levelup")

-- Swap looping ambient (called from AmbienceClient on client)
SoundManager.setAmbience("Forest")
```

Built-in sound keys: `hit`, `explosion`, `levelup`, `step`, `ambient_forest`, `click`, `death`, `splash`, `swing`, `build`

### AmbienceClient (LocalScript)

Place `AmbienceClient.client.lua` in **StarterPlayerScripts**. It automatically reads `character:GetAttribute("CurrentBiome")` every 5 seconds and crossfades the ambient loop over 2 seconds.

To drive it from the server set the attribute on the character:
```lua
-- In BiomeResolver or StreamingManager, server-side:
player.Character:SetAttribute("CurrentBiome", "Desert")
```

### InventoryRemote API

```lua
-- Client-side (from InventoryUI.client.lua):
local rf = ReplicatedStorage.ProceduralWorldsRemotes.InventoryRemote
local slots = rf:InvokeServer("getSlots")   -- returns array of {name, quantity, color}
rf:InvokeServer("use",   slotIndex)
rf:InvokeServer("drop",  slotIndex)
rf:InvokeServer("equip", slotIndex)
```

---

## 🧪 Testing Checklist

### Minimum test in Studio (F5 / Play Solo)

| # | What to verify | Expected result |
|---|---|---|
| 1 | Press **F5** | Output shows `[WorldGenerator] Seed: XXXXXXX` |
| 2 | Walk around | Terrain chunks load/unload, no void gaps |
| 3 | Check Output | No red errors from any `src/` module |
| 4 | Open Output → filter `warn` | Only cosmetic Roblox ChatScript warnings (safe to ignore) |
| 5 | Kill a mob | Death animation plays, model fades out and destroys |
| 6 | Walk into different terrain zones | AmbienceClient crossfades ambient sound |
| 7 | Open inventory (I key default) | Slots render via `InventoryUI.client.lua` |
| 8 | Craft or pick up item | Inventory slot count updates in HUD |
| 9 | Enter a dungeon area | `DungeonGenerator` rooms spawn, mobs present |
| 10 | Wait 60s idle | Day/Night cycle progresses, weather may change |

### Verifying animations (quick test script)

Paste this in the **Command Bar** during Play mode to test AnimationManager manually:

```lua
local AnimationManager = require(game.ServerScriptService.AnimationManager)
local mob = workspace:FindFirstChildWhichIsA("Model")
if mob then AnimationManager.playWalk(mob) end
```

### Verifying sound (Command Bar)

```lua
local SM = require(game.ServerScriptService.SoundManager)
SM.playAtPosition("explosion", Vector3.new(0, 20, 0), 1.0)
```

### Common test failures & fixes

| Symptom | Cause | Fix |
|---|---|---|
| `attempt to index nil (SoundManager)` | LocalScript trying to require a ServerScript | Use `InventoryRemote` from client; never require server modules directly |
| Ambient sound doesn't change | `CurrentBiome` attribute not set on character | Add `player.Character:SetAttribute("CurrentBiome", "Forest")` in server init |
| Animation plays but model teleports | `HumanoidRootPart` is welded / `Anchored = false` | Set `Anchored = true` on the root part or use `PrimaryPart` |
| `InventoryRemote` returns nil | `Inventory.getSlots` not implemented | Verify `Inventory.lua` exports `getSlots(player)` function |

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
│         triggers AnimationManager (v7.0) 🎬         │
│         triggers SoundManager (v7.0) 🔊             │
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
All modules must be siblings in the **same folder**. Do not split them across ServerScriptService and ReplicatedStorage — only `WeatherClient`, `AmbienceClient`, `InventoryUI`, `HUD`, `MinimapUI`, `QuestTracker`, and `DialogueUI` (LocalScripts) go into **StarterPlayerScripts**.

### Assets / structures not appearing
`AssetPlacer` and `StructurePlacer` look for models in **ServerStorage** by name. Add your tree/rock/bush and structure models there. Missing models produce a `warn()` but do not crash.

### Ambient sound doesn't change biome
Set the `CurrentBiome` attribute on the player's character from the server (e.g. inside `BiomeResolver` or `StreamingManager`) and `AmbienceClient` will detect it within 5 seconds.

---

## 📜 License

MIT — see [LICENSE](./LICENSE)

---

## 🤝 Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.
