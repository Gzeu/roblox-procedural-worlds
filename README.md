# 🌍 Roblox Procedural Worlds

[![Lua](https://img.shields.io/badge/Lua-5.1-blue?logo=lua)](https://www.lua.org)
[![Python](https://img.shields.io/badge/Python-3.10+-green?logo=python)](https://python.org)
[![Roblox](https://img.shields.io/badge/Roblox-Studio-red?logo=roblox)](https://www.roblox.com)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

A fully-featured procedural open-world engine for Roblox Studio — 50+ Lua modules, a Python `.rbxlx` builder, and a visual web configurator.

---

## Architecture

```
roblox-procedural-worlds/
├── src/                        ← All Lua modules (ServerScriptService)
│   ├── init.server.lua         ← Entry point: boots WorldGenerator
│   ├── WorldGenerator.lua      ← Master orchestrator (v3.0)
│   ├── WorldConfig.lua         ← All tuneable constants
│   │
│   ├── ── Terrain ──
│   ├── ChunkHandler.lua        ← Voxel chunk gen + unloading (v3.0)
│   ├── BiomeResolver.lua       ← temp/moisture → biome lookup
│   ├── OreGenerator.lua        ← Underground ore veins
│   ├── RiverCarver.lua         ← River path carving
│   ├── DungeonGenerator.lua    ← Dungeon rooms
│   ├── VillageGenerator.lua    ← Village placement
│   ├── LODManager.lua          ← Level-of-detail registration
│   ├── StreamingManager.lua    ← Per-player chunk streaming
│   ├── ChunkPredictor.lua      ← Predictive pre-load
│   ├── AssetPlacer.lua         ← Tree/rock/bush surface props
│   ├── StructurePlacer.lua     ← Large structure placement
│   │
│   ├── ── AI ──
│   ├── MobAI.lua               ← FSM: Idle/Patrol/Alert/Chase/Strafe/Attack/Flee (v4.0)
│   ├── AIConfig.lua            ← Per-mob type configs
│   ├── AIDirector.lua          ← Spawn pacing + difficulty wave
│   ├── AIGroupBehavior.lua     ← Pack tactics
│   ├── AIMemory.lua            ← Per-mob event memory
│   ├── AINavigator.lua         ← PathfindingService wrapper
│   ├── BehaviorTree.lua        ← Composable behavior trees
│   ├── MobSpawner.lua          ← Spawn pool management
│   │
│   ├── ── Systems ──
│   ├── CombatSystem.lua        ← Hit detection, damage numbers
│   ├── SkillSystem.lua         ← Player skills + cooldowns
│   ├── CraftingSystem.lua      ← Crafting recipes
│   ├── Inventory.lua           ← Item storage
│   ├── QuestSystem.lua         ← Quest state machine
│   ├── ProceduralQuestGen.lua  ← Random quest generation
│   ├── ClanSystem.lua          ← Clan creation/management
│   ├── FactionSystem.lua       ← World factions + rep
│   ├── BaseBuilding.lua        ← Placeable structures
│   ├── EconomyManager.lua      ← Gold/trade
│   ├── DayNightCycle.lua       ← Lighting cycle
│   ├── WeatherManager.lua      ← Weather state machine
│   ├── AwakenSystem.lua        ← Power awakening
│   ├── FightingStyles.lua      ← Martial arts styles
│   ├── RunModifiers.lua        ← Run-specific modifiers
│   ├── LootTable.lua           ← Weighted loot rolls
│   ├── BossEncounter.lua       ← Boss spawn + phases
│   │
│   ├── ── Data / Persistence ──
│   ├── DataStoreManager.lua    ← DataStore v2 wrapper
│   ├── PlayerPersistence.lua   ← Auto-save player data
│   ├── SeedPersistence.lua     ← Save/load world seed
│   ├── SeedShare.lua           ← Share seed via chat/UI
│   │
│   ├── ── UI (Client) ──
│   ├── HUD.client.lua          ← HP/stamina/biome HUD
│   ├── InventoryUI.client.lua  ← Inventory grid UI
│   ├── MinimapUI.client.lua    ← Live minimap
│   ├── QuestTracker.client.lua ← Quest log sidebar
│   ├── DialogueUI.client.lua   ← NPC dialogue bubbles
│   ├── AmbienceClient.client.lua ← Audio ambience
│   ├── WeatherClient.lua       ← Client weather FX
│   │
│   └── ── Infrastructure ──
│       ├── EventBus.lua        ← Pub/sub event system
│       ├── ObjectPool.lua      ← Instance recycling
│       ├── NotificationBridge.lua ← Server→client toasts
│       ├── AdminPanel.lua      ← In-game admin commands
│       ├── AntiExploit.lua     ← Sanity checks
│       ├── AnimationManager.lua ← Animation controller
│       ├── ParticleEffects.lua ← VFX helpers
│       ├── SoundManager.lua    ← Audio controller
│       └── NPCDialogue.lua     ← NPC branching dialogue
│
├── tools/
│   ├── build_world.py          ← Generate .rbxlx from JSON config
│   ├── world-configurator.html ← Visual configurator + live preview
│   └── README_BUILDER.md       ← Builder documentation
│
├── configs/
│   └── default_world.json      ← Example world config
│
└── .github/
    └── workflows/              ← CI placeholder
```

---

## Quick Start

### Option A — Python Builder

```bash
# 1. Clone
git clone https://github.com/Gzeu/roblox-procedural-worlds
cd roblox-procedural-worlds

# 2. Configure (visual UI)
open tools/world-configurator.html   # macOS
start tools/world-configurator.html  # Windows

# 3. Download config → world_config.json, then build
python tools/build_world.py configs/default_world.json MyWorld.rbxlx

# 4. Open in Roblox Studio
# File → Open from File → MyWorld.rbxlx
```

### Option B — Rojo (recommended for dev)

```bash
npm install -g rojo
rojo serve default.project.json
# Then in Roblox Studio install Rojo plugin and connect
```

---

## Key Modules

| Module | Version | Highlights |
|--------|---------|------------|
| `WorldGenerator` | v3.0 | Chunk unloading, Regenerate(), metrics log |
| `MobAI` | v4.0 | STRAFE state, difficulty scaling, LKP, HP regen |
| `ChunkHandler` | v3.0 | Biome borders, snow cap, beach, UnloadChunk |
| `BiomeResolver` | — | Whittaker diagram (temp × moisture) |
| `AIDirector` | — | Difficulty waves, spawn pacing |
| `DataStoreManager` | — | DataStore v2, auto-retry, compression |

---

## World Config Fields

```json
{
  "worldName": "My World",
  "seed": 12345,
  "chunkSize": 64,
  "renderDistance": 3,
  "maxHeight": 120,
  "waterLevel": 20,
  "noiseScale": 0.05,
  "biomes": ["Forest", "Desert", "Tundra"],
  "mobs": { "density": 5, "difficulty": "normal", "bosses": true, "groupAI": true },
  "structures": { "villages": true, "dungeons": true, "rivers": true, "ores": true },
  "systems": { "dayNightCycle": true, "weather": true, "baseBuilding": false, "clans": false, "dayLengthMinutes": 20 }
}
```

---

## Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Commit your changes with clear messages
4. Open a Pull Request against `main`

Please follow existing module patterns (return a table, use EventBus for cross-module communication, avoid globals).

---

## License

MIT © Gzeu
