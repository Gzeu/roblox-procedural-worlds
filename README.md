# 🌍 roblox-procedural-worlds

> A fully modular, seed-driven procedural world generation framework for Roblox — built with Lua, designed for scalability.

[![Version](https://img.shields.io/badge/version-2.5.0-blue)](#)
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
| `MobSpawner` | Biome-aware mob spawning with AI |
| `OreGenerator` | Depth-based ore vein generation |
| `DayNightCycle` | Configurable 8-minute in-game day |
| `WeatherManager` + `WeatherClient` | Server/client weather sync |
| `CombatSystem` | Hitbox detection, damage, knockback |
| `QuestSystem` | Dynamic quest assignment & tracking |
| `NPCDialogue` + `NPCDialogueClient` | Branching dialogue trees |
| `Inventory` | Player inventory with slot management |
| `PlayerPersistence` | DataStore-backed player save/load |
| `LootTable` | Weighted loot drop system |
| `AdminPanel` | In-game admin controls |
| `AssetPlacer` | Biome-aware asset scatter |
| `StructurePlacer` | Pre-built structure placement |
| `SeedPersistence` | World seed save/restore |
| **`EventBus`** ⭐ | Pub/sub event system for decoupled modules |
| **`CraftingSystem`** ⭐ | Recipe-based crafting with level requirements |
| **`TeleportManager`** ⭐ | Named waypoints + cross-server teleport |
| **`ParticleEffects`** ⭐ | Preset particle emitter manager |

> ⭐ = Added in v2.5

---

## 🚀 Quick Start

1. Clone or copy into your Roblox Studio project (via [Rojo](https://rojo.space) — see `rojo/` folder)
2. Place `src/` contents into `ServerScriptService`
3. Configure `WorldConfig.lua` to your preferences
4. Hit **Play** — the world generates automatically from seed

```lua
-- Example: craft an item
local CraftingSystem = require(game.ServerScriptService.CraftingSystem)
local ok, msg = CraftingSystem.craft(player, "IronPickaxe", playerLevel)
print(msg) -- "Crafted IronPickaxe successfully!"

-- Example: teleport to a waypoint
local TeleportManager = require(game.ServerScriptService.TeleportManager)
TeleportManager.teleportToWaypoint(player, "Market")

-- Example: emit a particle burst
local ParticleEffects = require(game.ServerScriptService.ParticleEffects)
ParticleEffects.emit(character.HumanoidRootPart, "Heal", 0.5)

-- Example: subscribe to an event
local EventBus = require(game.ServerScriptService.EventBus)
EventBus.on("CraftingSystem:CraftSuccess", function(player, recipe)
    print(player.Name .. " crafted: " .. recipe)
end)
```

---

## 📁 Project Structure

```
roblox-procedural-worlds/
├── src/                    # All Lua modules (ServerScriptService)
│   ├── init.server.lua     # Bootstrap entry point
│   ├── WorldConfig.lua     # Central configuration
│   ├── EventBus.lua        # Pub/sub event system (v2.5)
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
│   ├── WeatherManager.lua
│   ├── WeatherClient.lua
│   ├── CombatSystem.lua
│   ├── QuestSystem.lua
│   ├── NPCDialogue.lua
│   ├── NPCDialogueClient.lua
│   ├── Inventory.lua
│   ├── PlayerPersistence.lua
│   ├── LootTable.lua
│   ├── AdminPanel.lua
│   ├── AssetPlacer.lua
│   ├── StructurePlacer.lua
│   ├── SeedPersistence.lua
│   ├── CraftingSystem.lua  # (v2.5)
│   ├── TeleportManager.lua # (v2.5)
│   └── ParticleEffects.lua # (v2.5)
├── rojo/                   # Rojo project config
├── docs/                   # Documentation
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE
```

---

## ⚙️ Configuration

All tuneable values live in `src/WorldConfig.lua`:

```lua
WorldConfig.CHUNK_SIZE        = 64     -- studs per chunk
WorldConfig.RENDER_DISTANCE   = 5      -- chunk radius
WorldConfig.NOISE_SCALE       = 0.008
WorldConfig.HEIGHT_MULTIPLIER = 120
WorldConfig.DAY_LENGTH_SECONDS= 480    -- 8 min real time
WorldConfig.TELEPORT_COOLDOWN = 10     -- seconds (v2.5)
WorldConfig.CRAFTING_ENABLED  = true   -- (v2.5)
WorldConfig.EVENT_BUS_DEBUG   = false  -- verbose logging (v2.5)
```

---

## 🗺️ Biomes

Tundra · Taiga · Grassland · Forest · Desert · Savanna · Jungle · **Swamp** · **Volcanic** · Ocean

---

## 🧪 EventBus Usage

All modules communicate through `EventBus` — no direct coupling:

```lua
-- Subscribe
local unsub = EventBus.on("Player:Joined", function(player) ... end)

-- Emit
EventBus.emit("MySystem:Event", data)

-- One-time
EventBus.once("WorldGenerator:Ready", function() ... end)

-- Unsubscribe
unsub()
```

---

## 📜 License

MIT — see [LICENSE](./LICENSE)

---

## 🤝 Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.
